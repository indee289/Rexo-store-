import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../services/r2_storage_service.dart';
import '../../../services/supabase_service.dart';

/// Realtime stream provider for KYC documents.
/// Subscribes to Supabase Realtime so admin verification actions
/// (pending -> approved/rejected) reflect immediately without app restart.
final kycDocumentsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = SupabaseService.currentUser;
  if (user == null) return Stream.value([]);

  return SupabaseService.client
      .from('kyc_documents')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id);
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

      // Upload to Cloudflare R2
      final fileBytes = await file.readAsBytes();
      final contentType = _getContentType(fileExt);

      final publicUrl = await R2StorageService.uploadFile(
        'kyc-documents/$filePath',
        fileBytes,
        contentType,
      );

      // Save reference in kyc_documents table
      await SupabaseService.client.from('kyc_documents').insert({
        'user_id': user.id,
        'document_type': documentType,
        'document_url': publicUrl,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      state = const AsyncValue.data(null);
      // Realtime stream will auto-update, but invalidate to force immediate refresh
      ref.invalidate(kycDocumentsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}

/// KYC actions provider
final kycActionsProvider =
    StateNotifierProvider<KycNotifier, AsyncValue<void>>((ref) {
  return KycNotifier(ref);
});
