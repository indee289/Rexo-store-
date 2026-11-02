import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import 'audit_logs_screen.dart';

/// Admin settings — rebuilt layout.
///
/// Old layout: a `PremiumAppBar` over a scroll column of admin-local
/// `PremiumCard`s, where the settings rows were a local `_SettingTile` built
/// from a bare `InkWell`, the audit-logs entry was a hand-assembled row with
/// its own chevron, and editing a setting opened an `AlertDialog` with a raw
/// `TextField` plus `TextButton`/`ElevatedButton` actions.
///
/// New layout: the standard collapsing large title and two grouped sections,
/// so the settings rows and the audit-logs entry share one row treatment with
/// chevrons and separators coming from the group. The edit flow is a glass
/// dialog with the shared text field, and sign-out is a destructive button.
///
/// `adminPlatformSettingsProvider`, `adminActionsProvider.updatePlatformSetting`,
/// `authProvider.signOut` and the `/login` redirect are unchanged.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformSettings = ref.watch(adminPlatformSettingsProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          const GlassLargeTitleHeader(
            title: 'Settings',
            subtitle: 'Platform configuration',
          ),

          platformSettings.when(
            data: (settings) {
              if (settings.isEmpty) {
                // No editable platform settings configured — show a clean
                // note instead of non-functional placeholder toggles.
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionLabel('Platform settings'),
                        GlassCard(
                          level: GlassLevel.subtle,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              const Icon(
                                AppIcons.setting,
                                size: 20,
                                color: AppColors.textHint,
                              ),
                              AppSpacing.gapMd,
                              Expanded(
                                child: Text(
                                  'No editable platform settings.',
                                  style: AppTextStyles.footnote.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverToBoxAdapter(
                child: GlassSection(
                  title: 'Platform settings',
                  children: [
                    for (final setting in settings)
                      GlassRow(
                        icon: AppIcons.setting,
                        title: (setting['key'] ?? '').toString(),
                        subtitle: 'Value: ${setting['value'] ?? 'N/A'}',
                        trailing: const Icon(
                          AppIcons.edit_2,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                        onTap: () => _editSetting(
                          context,
                          ref,
                          (setting['key'] ?? '').toString(),
                          setting['value']?.toString() ?? '',
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: GlassLoader(),
              ),
            ),
            error: (_, __) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: GlassErrorState(
                  title: 'Failed to load settings',
                  compact: true,
                  onRetry: () => ref.invalidate(adminPlatformSettingsProvider),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: GlassSection(
              title: 'Administration',
              children: [
                GlassRow(
                  icon: AppIcons.document_text,
                  title: 'Audit logs',
                  subtitle: 'View all admin actions',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuditLogsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: GlassButton.destructive(
                label: 'Sign out',
                icon: AppIcons.logout,
                onPressed: () {
                  ref.read(authProvider.notifier).signOut();
                  context.go('/login');
                },
              ),
            ),
          ),

          // Clearance for the floating admin dock.
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }

  /// Edits one platform setting.
  ///
  /// The controller is created here and disposed once the dialog closes — the
  /// old `AlertDialog` version never disposed it.
  Future<void> _editSetting(
    BuildContext context,
    WidgetRef ref,
    String key,
    String currentValue,
  ) async {
    final controller = TextEditingController(text: currentValue);
    try {
      final saved = await showGlassDialog(
        context: context,
        title: 'Edit $key',
        icon: AppIcons.setting,
        confirmLabel: 'Save',
        cancelLabel: 'Cancel',
        content: GlassTextField(
          controller: controller,
          label: key,
          hint: 'Enter value…',
        ),
      );

      if (saved == true) {
        ref
            .read(adminActionsProvider.notifier)
            .updatePlatformSetting(key, controller.text);
      }
    } finally {
      controller.dispose();
    }
  }
}

/// Group heading matching the tracked-caps header used by `GlassSection`.
Widget _sectionLabel(String text) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      0,
      AppSpacing.xs,
      AppSpacing.md,
    ),
    child: Text(
      text.toUpperCase(),
      style: AppTextStyles.caption1.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );
}
