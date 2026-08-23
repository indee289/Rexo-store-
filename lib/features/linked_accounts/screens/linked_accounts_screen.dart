import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/linked_accounts_provider.dart';

class LinkedAccountsScreen extends ConsumerStatefulWidget {
  const LinkedAccountsScreen({super.key});

  @override
  ConsumerState<LinkedAccountsScreen> createState() =>
      _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends ConsumerState<LinkedAccountsScreen> {
  final _instagramController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _tiktokController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _instagramController.dispose();
    _youtubeController.dispose();
    _tiktokController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(linkedAccountsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Linked Accounts',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Iconsax.arrow_left, color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: accountsAsync.when(
        data: (accounts) {
          _populateControllers(accounts);
          return _buildContent(accounts);
        },
        loading: () => const ShimmerLoading(),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.warning_2,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load linked accounts',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(linkedAccountsProvider),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _populateControllers(List<Map<String, dynamic>> accounts) {
    for (final account in accounts) {
      final platform = account['platform'] as String?;
      final handle = account['handle'] as String? ?? '';
      switch (platform) {
        case 'instagram':
          if (_instagramController.text.isEmpty) {
            _instagramController.text = handle;
          }
          break;
        case 'youtube':
          if (_youtubeController.text.isEmpty) {
            _youtubeController.text = handle;
          }
          break;
        case 'tiktok':
          if (_tiktokController.text.isEmpty) {
            _tiktokController.text = handle;
          }
          break;
      }
    }
  }

  Widget _buildContent(List<Map<String, dynamic>> accounts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect your social media accounts to showcase your reach and engagement to brands.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildPlatformField(
            label: 'Instagram',
            controller: _instagramController,
            icon: Iconsax.instagram,
            hint: '@your_handle',
            color: const Color(0xFFE1306C),
          ),
          const SizedBox(height: 16),
          _buildPlatformField(
            label: 'YouTube',
            controller: _youtubeController,
            icon: Iconsax.video_play,
            hint: 'Channel name or URL',
            color: const Color(0xFFFF0000),
          ),
          const SizedBox(height: 16),
          _buildPlatformField(
            label: 'TikTok',
            controller: _tiktokController,
            icon: Iconsax.music,
            hint: '@your_handle',
            color: const Color(0xFF000000),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAccounts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save Accounts',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Show verified status
          if (accounts.isNotEmpty) ...[
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 16),
            Text(
              'Account Status',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...accounts.map((account) => _buildAccountStatus(account)),
          ],
        ],
      ),
    );
  }

  Widget _buildPlatformField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildAccountStatus(Map<String, dynamic> account) {
    final platform = account['platform'] as String? ?? '';
    final verified = account['verified'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            verified ? Iconsax.tick_circle : Iconsax.clock,
            size: 16,
            color: verified ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Text(
            platform[0].toUpperCase() + platform.substring(1),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: verified
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              verified ? 'Verified' : 'Pending',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: verified ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAccounts() async {
    setState(() => _isSaving = true);

    final notifier = ref.read(linkedAccountsActionsProvider.notifier);

    // Save each non-empty field
    if (_instagramController.text.trim().isNotEmpty) {
      await notifier.saveAccount(
        platform: 'instagram',
        handle: _instagramController.text.trim(),
      );
    }
    if (_youtubeController.text.trim().isNotEmpty) {
      await notifier.saveAccount(
        platform: 'youtube',
        handle: _youtubeController.text.trim(),
      );
    }
    if (_tiktokController.text.trim().isNotEmpty) {
      await notifier.saveAccount(
        platform: 'tiktok',
        handle: _tiktokController.text.trim(),
      );
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Accounts saved successfully',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
