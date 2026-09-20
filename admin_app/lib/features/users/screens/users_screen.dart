import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../services/supabase_service.dart';
import '../../admin/providers/admin_provider.dart';

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

  void _showUserActions(BuildContext context, Map<String, dynamic> user) {
    // Live users identity column is `uid` (text), not `id` (uuid).
    // All updates use .eq('uid', ...) to target the correct row.
    final uid = user['uid']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user['name'] ?? 'Unknown User',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                user['email'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              // Verify: sets "isVerified" = true (live camelCase column)
              ListTile(
                leading: const Icon(Iconsax.verify, color: AppColors.success),
                title: const Text('Verify user'),
                onTap: () => _performUserAction(
                  context,
                  uid,
                  'verify',
                  'User verified successfully',
                ),
              ),
              // Ban: sets "isBanned" = true (live column — no account_status)
              ListTile(
                leading: const Icon(Iconsax.close_circle, color: AppColors.error),
                title: const Text('Ban user'),
                onTap: () => _performUserAction(
                  context,
                  uid,
                  'ban',
                  'User banned successfully',
                ),
              ),
              // Unban: sets "isBanned" = false
              ListTile(
                leading: const Icon(Iconsax.tick_circle, color: AppColors.warning),
                title: const Text('Unban user'),
                onTap: () => _performUserAction(
                  context,
                  uid,
                  'unban',
                  'User unbanned successfully',
                ),
              ),
              // Role changes use the live `role` column
              ListTile(
                leading: const Icon(Iconsax.user_edit, color: AppColors.primary),
                title: const Text('Change role to admin'),
                onTap: () => _performUserAction(
                  context,
                  uid,
                  'role_admin',
                  'User role changed to admin',
                ),
              ),
              ListTile(
                leading: Icon(Iconsax.user,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                title: const Text('Change role to creator'),
                onTap: () => _performUserAction(
                  context,
                  uid,
                  'role_creator',
                  'User role changed to creator',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performUserAction(
    BuildContext context,
    String uid,
    String action,
    String successMessage,
  ) async {
    Navigator.pop(context);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.sanitize(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = ref.watch(adminUsersProvider(_searchQuery));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('User management'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Iconsax.search_normal,
                    color: theme.colorScheme.onSurface.withOpacity(0.4)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Users list
          Expanded(
            child: users.when(
              data: (userList) {
                if (userList.isEmpty) {
                  return const Center(child: Text('No users found'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: userList.length,
                  itemBuilder: (context, index) {
                    final user = userList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PremiumCard(
                        onTap: () => _showUserActions(context, user),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              child: Text(
                                (user['name'] ?? 'U')
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    user['email'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRoleColor(user['role'])
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (user['role'] ?? 'user').toString().toLowerCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getRoleColor(user['role']),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, _) => Center(
                child: Text(ErrorUtils.sanitize(error)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return AppColors.primary;
      case 'influencer':
        return AppColors.success;
      case 'brand':
        return Colors.purple;
      default:
        return AppColors.warning;
    }
  }
}
