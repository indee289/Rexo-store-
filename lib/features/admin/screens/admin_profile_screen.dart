import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';

final adminProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;
  return await SupabaseService.getUserProfile(user.id);
});

/// Admin profile — rebuilt layout.
///
/// Old layout: a **raw Material `AppBar`** (the last one in the user app) over
/// a centred column with a `CircleAvatar` initial, hardcoded 32/20/14/12pt
/// text, a hand-built role pill, a `PremiumCard` wrapping a `ListTile` for the
/// email, and an `OutlinedButton.icon` for sign out. The loading and error
/// branches each duplicated the whole header.
///
/// New layout: collapsing large title; one identity hero card shared by all
/// three async states (so loading no longer rebuilds a different header); the
/// email as a grouped row; and sign out isolated in a danger section behind a
/// glass confirm, since it was previously a single unguarded tap.
///
/// `adminProfileProvider`, `authProvider.signOut` and the `/login` route are
/// unchanged.
class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(adminProfileProvider);
    final currentUser = SupabaseService.currentUser;
    final email = currentUser?.email ?? '';

    final name = profileAsync.maybeWhen(
      data: (p) => (p?['full_name'] ?? p?['name'] ?? 'Admin').toString(),
      orElse: () => 'Admin',
    );

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          const GlassLargeTitleHeader(title: 'Profile'),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: GlassCard(
                borderRadius: AppRadius.allXl,
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    PremiumAvatar(
                      name: name,
                      size: PremiumAvatar.sizeLg,
                    ),
                    AppSpacing.gapLg,
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title1.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: AppTextStyles.subheadline
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                    AppSpacing.gapSm,
                    GlassChip.status(
                      label: 'Admin',
                      color: AppColors.roleAdmin,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: GlassSection(
              title: 'Contact',
              children: [
                GlassRow(
                  icon: AppIcons.sms,
                  title: 'Email',
                  subtitle: email.isEmpty ? 'No email' : email,
                  showChevron: false,
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: GlassSection(
              title: 'Session',
              // 110 clears the floating admin dock, which overlays content
              // because AdminShell's GlassScaffold extends its body behind the
              // bottom bar. The previous `padding.bottom + xxl` left the last
              // row partly underneath the dock.
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                110,
              ),
              children: [
                GlassRow(
                  icon: AppIcons.logout,
                  title: 'Sign out',
                  destructive: true,
                  showChevron: false,
                  onTap: () => _signOut(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showGlassConfirm(
      context: context,
      title: 'Sign out',
      message: 'You will need to sign in again to access admin tools.',
      icon: AppIcons.logout,
      confirmLabel: 'Sign out',
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (!ok) return;

    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) context.go('/login');
  }
}
