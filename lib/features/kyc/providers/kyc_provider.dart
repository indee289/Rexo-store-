import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../services/supabase_service.dart';

/// Provider to fetch KYC document status for the current user
final kycDocumentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  final response = await SupabaseService.client
      .from('kyc_documents')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// KYC upload notifier
class KycNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  KycNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Upload a KYC document
  Future<bool> uploadDocument({
    required File file,
    required String documentType,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    state = const AsyncValue.loading();

    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExt';
      final filePath = '${user.id}/$fileName';

      // Upload to Supabase Storage
      await SupabaseService.client.storage
          .from('kyc-documents')
          .upload(filePath, file);

      final publicUrl = SupabaseService.client.storage
          .from('kyc-documents')
          .getPublicUrl(filePath);

      // Save reference in kyc_documents table
      await SupabaseService.client.from('kyc_documents').insert({
        'user_id': user.id,
        'document_type': documentType,
        'document_url': publicUrl,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      state = const AsyncValue.data(null);
      ref.invalidate(kycDocumentsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// KYC actions provider
final kycActionsProvider =
    StateNotifierProvider<KycNotifier, AsyncValue<void>>((ref) {
  return KycNotifier(ref);
});
