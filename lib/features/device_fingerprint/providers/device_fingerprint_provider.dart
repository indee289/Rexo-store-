import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../services/supabase_service.dart';

/// Device fingerprint state
class DeviceFingerprintState {
  final bool isRecording;
  final String? error;

  const DeviceFingerprintState({
    this.isRecording = false,
    this.error,
  });

  DeviceFingerprintState copyWith({
    bool? isRecording,
    String? error,
  }) {
    return DeviceFingerprintState(
      isRecording: isRecording ?? this.isRecording,
      error: error,
    );
  }
}

/// Device fingerprint notifier
class DeviceFingerprintNotifier extends StateNotifier<DeviceFingerprintState> {
  DeviceFingerprintNotifier() : super(const DeviceFingerprintState());

  /// Record device fingerprint after login
  Future<void> recordDeviceFingerprint() async {
    state = state.copyWith(isRecording: true, error: null);

    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(isRecording: false);
        return;
      }

      // Gather device info
      String operatingSystem = 'unknown';
      try {
        operatingSystem = Platform.operatingSystem;
      } catch (_) {
        // Platform not available on web
        operatingSystem = 'web';
      }

      final deviceInfo = {
        'platform': operatingSystem,
        'os_version': _getOsVersion(),
        'recorded_at': DateTime.now().toIso8601String(),
      };

      // Generate a fingerprint hash based on device info
      final fingerprintHash = _generateFingerprintHash(deviceInfo, userId);

      // Upsert into device_fingerprints table
      await SupabaseService.client.from('device_fingerprints').upsert(
        {
          'id': const Uuid().v4(),
          'user_id': userId,
          'fingerprint_hash': fingerprintHash,
          'device_info': deviceInfo,
          'ip_address': 'unknown',
          'is_trusted': false,
          'first_seen_at': DateTime.now().toIso8601String(),
          'last_seen_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'fingerprint_hash',
      );

      state = state.copyWith(isRecording: false);
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        error: 'Failed to record device fingerprint',
      );
    }
  }

  /// Get OS version safely
  String _getOsVersion() {
    try {
      return Platform.operatingSystemVersion;
    } catch (_) {
      return 'unknown';
    }
  }

  /// Generate a simple fingerprint hash from device info
  String _generateFingerprintHash(Map<String, dynamic> info, String userId) {
    final raw = '${userId}_${info['platform']}_${info['os_version']}';
    // Simple hash using hashCode (not cryptographic, but sufficient for fingerprinting)
    return raw.hashCode.toRadixString(16);
  }
}

/// Provider for device fingerprint notifier
final deviceFingerprintProvider =
    StateNotifierProvider<DeviceFingerprintNotifier, DeviceFingerprintState>((ref) {
  return DeviceFingerprintNotifier();
});
