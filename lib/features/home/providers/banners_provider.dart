import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Key under which the banners JSON array is stored in the already-cached
/// platform_settings table (single row, column `value` is a JSON string).
///
/// The dedicated `banners` table returns PGRST205 (missing from the PostgREST
/// schema cache), so banners are persisted as a JSON array inside
/// platform_settings instead. platform_settings RLS already allows anyone to
/// read and only admins to write, and platform_settings.key is UNIQUE.
const String _bannersKey = 'home_banners';

/// Read all banners from the platform_settings row.
///
/// Returns an empty list when the row is missing, the value is null/empty, or
/// the stored JSON cannot be parsed.
Future<List<Map<String, dynamic>>> _readBanners() async {
  try {
    final row = await SupabaseService.client
        .from('platform_settings')
        .select('value')
        .eq('key', _bannersKey)
        .maybeSingle();

    if (row == null) return <Map<String, dynamic>>[];

    final value = row['value'];
    if (value == null || (value is String && value.isEmpty)) {
      return <Map<String, dynamic>>[];
    }

    final decoded = jsonDecode(value as String);
    if (decoded is! List) return <Map<String, dynamic>>[];

    return decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  } catch (_) {
    return <Map<String, dynamic>>[];
  }
}

/// Persist the full banners list back to the platform_settings row.
Future<void> _writeBanners(List<Map<String, dynamic>> list) async {
  await SupabaseService.client.from('platform_settings').upsert(
    {
      'key': _bannersKey,
      'value': jsonEncode(list),
      'updated_at': DateTime.now().toIso8601String(),
    },
    onConflict: 'key',
  );
}

/// Live banners for the home carousel — only visible ones, sorted by sort_order.
final bannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final all = await _readBanners();
    final visible =
        all.where((b) => b['is_visible'] == true).toList();
    visible.sort((a, b) => ((a['sort_order'] as num?) ?? 0)
        .compareTo((b['sort_order'] as num?) ?? 0));
    return visible;
  } catch (_) {
    return [];
  }
});

/// All banners for admin (including hidden), sorted by sort_order.
final adminBannersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final all = await _readBanners();
  all.sort((a, b) => ((a['sort_order'] as num?) ?? 0)
      .compareTo((b['sort_order'] as num?) ?? 0));
  return all;
});

/// Banner actions notifier.
class BannersActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  BannersActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<bool> createBanner(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final list = await _readBanners();
      final now = DateTime.now().toIso8601String();
      final id = DateTime.now().microsecondsSinceEpoch.toString();

      int maxSortOrder = -1;
      for (final b in list) {
        final so = (b['sort_order'] as num?)?.toInt() ?? 0;
        if (so > maxSortOrder) maxSortOrder = so;
      }
      final sortOrder = data['sort_order'] ?? (maxSortOrder + 1);

      list.add({
        ...data,
        'id': id,
        'is_visible': data['is_visible'] ?? true,
        'sort_order': sortOrder,
        'created_at': now,
        'updated_at': now,
      });

      await _writeBanners(list);
      state = const AsyncValue.data(null);
      ref.invalidate(adminBannersProvider);
      ref.invalidate(bannersProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateBanner(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final list = await _readBanners();
      final index = list.indexWhere((b) => b['id'] == id);
      if (index == -1) {
        state = const AsyncValue.data(null);
        return false;
      }

      final existing = list[index];
      list[index] = {
        ...existing,
        ...data,
        'id': id,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _writeBanners(list);
      state = const AsyncValue.data(null);
      ref.invalidate(adminBannersProvider);
      ref.invalidate(bannersProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleVisibility(String id, bool current) async {
    return updateBanner(id, {'is_visible': !current});
  }

  Future<bool> deleteBanner(String id) async {
    state = const AsyncValue.loading();
    try {
      final list = await _readBanners();
      list.removeWhere((b) => b['id'] == id);

      await _writeBanners(list);
      state = const AsyncValue.data(null);
      ref.invalidate(adminBannersProvider);
      ref.invalidate(bannersProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final bannersActionsProvider =
    StateNotifierProvider<BannersActionsNotifier, AsyncValue<void>>(
        (ref) => BannersActionsNotifier(ref));
