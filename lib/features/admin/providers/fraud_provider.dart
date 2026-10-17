import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Heuristic wallet fraud/risk detection for admins.
///
/// This reads the existing `deposits` and `withdrawals` tables (snake_case,
/// user_id/amount/status/created_at) and derives risk flags in-code — no schema
/// change required. It is intentionally conservative and review-only; it never
/// blocks or mutates money. Admins use the flags to investigate.
///
/// Flags produced:
///   • Large withdrawal        (amount ≥ ₹50,000)                 — high
///   • Large deposit           (amount ≥ ₹1,00,000)               — medium
///   • Rapid withdrawals       (≥3 by one user within 24h)        — high
///   • Fast deposit→withdrawal (withdrawal within 60m of a deposit) — high
class RiskFlag {
  final String type; // 'deposit' | 'withdrawal'
  final String id;
  final String userId;
  final num amount;
  final String status;
  final DateTime? createdAt;
  final String reason;
  final String severity; // 'high' | 'medium'

  const RiskFlag({
    required this.type,
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.reason,
    required this.severity,
  });
}

const double _largeWithdrawal = 50000;
const double _largeDeposit = 100000;

DateTime? _parseDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

num _amt(dynamic v) => v is num ? v : num.tryParse('${v ?? 0}') ?? 0;

final flaggedActivityProvider = FutureProvider<List<RiskFlag>>((ref) async {
  final client = SupabaseService.client;

  List<Map<String, dynamic>> deposits = [];
  List<Map<String, dynamic>> withdrawals = [];
  try {
    final d = await client
        .from('deposits')
        .select('id, user_id, amount, status, created_at')
        .order('created_at', ascending: false)
        .limit(500);
    deposits = List<Map<String, dynamic>>.from(d);
  } catch (_) {/* ignore */}
  try {
    final w = await client
        .from('withdrawals')
        .select('id, user_id, amount, status, created_at')
        .order('created_at', ascending: false)
        .limit(500);
    withdrawals = List<Map<String, dynamic>>.from(w);
  } catch (_) {/* ignore */}

  final flags = <RiskFlag>[];
  final now = DateTime.now();

  // Index deposits per user for the deposit→withdrawal proximity check.
  final depositsByUser = <String, List<DateTime>>{};
  for (final d in deposits) {
    final uid = (d['user_id'] ?? '').toString();
    final ts = _parseDate(d['created_at']);
    if (uid.isNotEmpty && ts != null) {
      (depositsByUser[uid] ??= []).add(ts);
    }
  }

  // Per-withdrawal flags + velocity.
  final withdrawalsByUser = <String, int>{};
  for (final w in withdrawals) {
    final uid = (w['user_id'] ?? '').toString();
    final ts = _parseDate(w['created_at']);
    final amount = _amt(w['amount']);
    final id = (w['id'] ?? '').toString();
    final status = (w['status'] ?? '').toString();

    if (ts != null && now.difference(ts).inHours <= 24) {
      withdrawalsByUser[uid] = (withdrawalsByUser[uid] ?? 0) + 1;
    }

    if (amount >= _largeWithdrawal) {
      flags.add(RiskFlag(
        type: 'withdrawal',
        id: id,
        userId: uid,
        amount: amount,
        status: status,
        createdAt: ts,
        reason: 'Large withdrawal (≥ ₹${_largeWithdrawal.toStringAsFixed(0)})',
        severity: 'high',
      ));
    }

    // Fast deposit → withdrawal (same user, deposit within 60 min before).
    if (ts != null && uid.isNotEmpty) {
      final recentDeposit = (depositsByUser[uid] ?? []).any((dt) {
        final diff = ts.difference(dt).inMinutes;
        return diff >= 0 && diff <= 60;
      });
      if (recentDeposit) {
        flags.add(RiskFlag(
          type: 'withdrawal',
          id: id,
          userId: uid,
          amount: amount,
          status: status,
          createdAt: ts,
          reason: 'Withdrawal within 60 min of a deposit',
          severity: 'high',
        ));
      }
    }
  }

  // Rapid-withdrawal velocity flag (one per user).
  withdrawalsByUser.forEach((uid, count) {
    if (count >= 3) {
      flags.add(RiskFlag(
        type: 'withdrawal',
        id: 'velocity-$uid',
        userId: uid,
        amount: count,
        status: '—',
        createdAt: now,
        reason: '$count withdrawals in the last 24 hours',
        severity: 'high',
      ));
    }
  });

  // Large-deposit flags.
  for (final d in deposits) {
    final amount = _amt(d['amount']);
    if (amount >= _largeDeposit) {
      flags.add(RiskFlag(
        type: 'deposit',
        id: (d['id'] ?? '').toString(),
        userId: (d['user_id'] ?? '').toString(),
        amount: amount,
        status: (d['status'] ?? '').toString(),
        createdAt: _parseDate(d['created_at']),
        reason: 'Large deposit (≥ ₹${_largeDeposit.toStringAsFixed(0)})',
        severity: 'medium',
      ));
    }
  }

  // Highest severity + most recent first.
  flags.sort((a, b) {
    if (a.severity != b.severity) return a.severity == 'high' ? -1 : 1;
    final ad = a.createdAt ?? DateTime(1970);
    final bd = b.createdAt ?? DateTime(1970);
    return bd.compareTo(ad);
  });

  return flags;
});
