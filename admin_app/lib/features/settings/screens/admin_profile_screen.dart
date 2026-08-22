import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';

final adminProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;
  return await SupabaseService.getUserProfile(user.id);
});

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(adminProfileProvider);
    final currentUser = SupabaseService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Avatar
            profileAsync.when(
              data: (profile) {
                final name = profile?['full_name'] ?? profile?['name'] ?? 'Admin';
                final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'A';
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        firstLetter,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentUser?.email ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(
                color: AppColors.primary,
              ),
              error: (_, __) => Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Text(
                      'A',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser?.email ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Contact info card
            PremiumCard(
              child: ListTile(
                leading: const Icon(Iconsax.sms, color: AppColors.primary),
                title: const Text(
                  'Email',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                subtitle: Text(
                  currentUser?.email ?? 'rexoagency.in@gmail.com',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Sign out button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).signOut();
                  context.go('/login');
                },
                icon: const Icon(Iconsax.logout),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
