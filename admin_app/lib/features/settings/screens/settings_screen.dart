import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformSettings = ref.watch(adminPlatformSettingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform Settings section
            Text(
              'Platform Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            platformSettings.when(
              data: (settings) {
                if (settings.isEmpty) {
                  return PremiumCard(
                    child: Column(
                      children: [
                        _SettingTile(
                          icon: Iconsax.percentage_circle,
                          title: 'Commission Rate',
                          subtitle: 'Platform commission percentage',
                          trailing: const Text('10%'),
                          onTap: () =>
                              _showEditSettingDialog(context, ref, 'commission_rate', '10'),
                        ),
                        const Divider(height: 1),
                        _SettingTile(
                          icon: Iconsax.warning_2,
                          title: 'Maintenance Mode',
                          subtitle: 'Toggle platform maintenance',
                          trailing: Switch(
                            value: false,
                            onChanged: (value) {
                              ref
                                  .read(adminActionsProvider.notifier)
                                  .updatePlatformSetting(
                                      'maintenance_mode', value.toString());
                            },
                            activeColor: AppColors.primary,
                          ),
                          onTap: () {},
                        ),
                      ],
                    ),
                  );
                }
                return PremiumCard(
                  child: Column(
                    children: settings.map((setting) {
                      return _SettingTile(
                        icon: Iconsax.setting,
                        title: setting['key'] ?? '',
                        subtitle: 'Value: ${setting['value'] ?? 'N/A'}',
                        trailing: Icon(Iconsax.edit_2,
                            size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                        onTap: () => _showEditSettingDialog(
                          context,
                          ref,
                          setting['key'] ?? '',
                          setting['value']?.toString() ?? '',
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => const Text('Failed to load settings'),
            ),
            const SizedBox(height: 24),

            // Navigation section
            Text(
              'Administration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            PremiumCard(
              onTap: () => context.push('/settings/audit-logs'),
              child: Row(
                children: [
                  const Icon(Iconsax.document_text, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Audit Logs',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'View all admin actions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Iconsax.arrow_right_3, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 18),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sign out
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

  void _showEditSettingDialog(
      BuildContext context, WidgetRef ref, String key, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $key'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: key,
            hintText: 'Enter value...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(adminActionsProvider.notifier)
                  .updatePlatformSetting(key, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
