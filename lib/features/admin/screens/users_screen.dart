import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../services/supabase_service.dart';
import '../providers/admin_provider.dart';

/// Admin user management — rebuilt layout.
///
/// Old layout: a `PremiumAppBar` over a `Column` whose raw Material
/// `TextField` search box scrolled away with the list, user rows built on the
/// admin-local `PremiumCard`, and an action sheet made of a bare
/// `showModalBottomSheet` containing a `Divider` and five `ListTile`s.
///
/// New layout: the standard collapsing large title with the search field
/// **pinned** into it, so it stays reachable while scrolling a long user list;
/// rows on the shared card surface with the role as a status chip; and the
/// action sheet rebuilt as grouped rows in a glass sheet.
///
/// Every Supabase write is unchanged, including the live column names
/// (`isVerified`, `isBanned`, `role`) and the fact that identity is matched on
/// `uid` (text) rather than `id`.
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserActions(Map<String, dynamic> user) {
    // Live users identity column is `uid` (text), not `id` (uuid).
    // All updates use .eq('uid', ...) to target the correct row.
    final uid = user['uid']?.toString() ?? '';

    showGlassSheet<void>(
      context: context,
      title: (user['name'] ?? 'Unknown User').toString(),
      subtitle: (user['email'] ?? '').toString(),
      // A Builder so the rows pop the *sheet* route, not this screen.
      child: Builder(
        builder: (sheetContext) => GlassGroup(
          children: [
            // Verify: sets "isVerified" = true (live camelCase column)
            GlassRow(
              icon: AppIcons.verify,
              iconColor: AppColors.success,
              title: 'Verify user',
              showChevron: false,
              onTap: () {
                Navigator.pop(sheetContext);
                _performUserAction(
                  uid,
                  'verify',
                  'User verified successfully',
                );
              },
            ),
            // Ban: sets "isBanned" = true (live column — no account_status)
            GlassRow(
              icon: AppIcons.close_circle,
              title: 'Ban user',
              destructive: true,
              showChevron: false,
              onTap: () {
                Navigator.pop(sheetContext);
                _performUserAction(uid, 'ban', 'User banned successfully');
              },
            ),
            // Unban: sets "isBanned" = false
            GlassRow(
              icon: AppIcons.tick_circle,
              iconColor: AppColors.warning,
              title: 'Unban user',
              showChevron: false,
              onTap: () {
                Navigator.pop(sheetContext);
                _performUserAction(uid, 'unban', 'User unbanned successfully');
              },
            ),
            // Role changes use the live `role` column
            GlassRow(
              icon: AppIcons.user_edit,
              title: 'Change role to admin',
              showChevron: false,
              onTap: () {
                Navigator.pop(sheetContext);
                _performUserAction(
                  uid,
                  'role_admin',
                  'User role changed to admin',
                );
              },
            ),
            GlassRow(
              icon: AppIcons.user,
              iconColor: AppColors.textSecondary,
              title: 'Change role to creator',
              showChevron: false,
              onTap: () {
                Navigator.pop(sheetContext);
                _performUserAction(
                  uid,
                  'role_creator',
                  'User role changed to creator',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Runs the chosen action.
  ///
  /// Takes no `BuildContext`: the old version was handed the *sheet's* context,
  /// popped it, and then tried to raise a snackbar through it. This uses the
  /// screen's own context instead, guarded by `mounted`.
  Future<void> _performUserAction(
    String uid,
    String action,
    String successMessage,
  ) async {
    try {
      switch (action) {
        // Live column: "isVerified" (camelCase boolean). Identity: uid (text).
        case 'verify':
          await SupabaseService.client
              .from('users')
              .update({'isVerified': true}).eq('uid', uid);
          break;
        // Live column: "isBanned" (boolean). No account_status column exists.
        case 'ban':
          await SupabaseService.client
              .from('users')
              .update({'isBanned': true}).eq('uid', uid);
          break;
        case 'unban':
          await SupabaseService.client
              .from('users')
              .update({'isBanned': false}).eq('uid', uid);
          break;
        // Role changes use the live `role` text column.
        case 'role_admin':
          await SupabaseService.client
              .from('users')
              .update({'role': 'admin'}).eq('uid', uid);
          break;
        case 'role_creator':
          await SupabaseService.client
              .from('users')
              .update({'role': 'creator'}).eq('uid', uid);
          break;
      }

      ref.invalidate(adminUsersProvider);

      if (mounted) {
        showGlassSnackBar(
          context,
          message: successMessage,
          tone: GlassToastTone.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: ErrorUtils.sanitize(e),
          tone: GlassToastTone.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminUsersProvider(_searchQuery));

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          GlassLargeTitleHeader(
            title: 'Users',
            subtitle: 'Verify, ban and change roles',
            // Pinned so search survives scrolling a long list.
            bottom: GlassHeaderSearch(
              child: GlassTextField.search(
                controller: _searchController,
                hint: 'Search users…',
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            bottomHeight: GlassHeaderSearch.height,
          ),

          users.when(
            data: (userList) {
              if (userList.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: GlassEmptyState(
                    icon: AppIcons.people,
                    title: 'No users found',
                    message: 'Try a different name or email.',
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  110,
                ),
                sliver: SliverList.separated(
                  itemCount: userList.length,
                  separatorBuilder: (_, __) => AppSpacing.gapSm,
                  itemBuilder: (context, index) {
                    final user = userList[index];
                    return RepaintBoundary(
                      child: _UserCard(
                        user: user,
                        onTap: () => _showUserActions(user),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: GlassListSkeleton(itemCount: 8),
            ),
            error: (error, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: GlassErrorState(
                message: ErrorUtils.sanitize(error),
                onRetry: () => ref.invalidate(adminUsersProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;

  const _UserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = (user['name'] ?? 'Unknown').toString();
    final email = (user['email'] ?? '').toString();
    final role = (user['role'] ?? 'user').toString().toLowerCase();

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          PremiumAvatar(name: name, size: 44),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTextStyles.callout.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: AppTextStyles.footnote
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.gapSm,
          GlassChip.status(label: role, color: _roleColor(role)),
        ],
      ),
    );
  }
}

Color _roleColor(String? role) {
  switch (role?.toLowerCase()) {
    case 'admin':
      return AppColors.primary;
    case 'influencer':
      return AppColors.success;
    case 'brand':
      return AppColors.accentPurple;
    default:
      return AppColors.warning;
  }
}
