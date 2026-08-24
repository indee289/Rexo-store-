import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../providers/admin_provider.dart';

class PushBroadcastScreen extends ConsumerStatefulWidget {
  const PushBroadcastScreen({super.key});

  @override
  ConsumerState<PushBroadcastScreen> createState() =>
      _PushBroadcastScreenState();
}

class _PushBroadcastScreenState extends ConsumerState<PushBroadcastScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isSending = true);

    final result = await ref.read(adminActionsProvider.notifier).sendBroadcast(
          _titleController.text,
          _messageController.text,
        );

    if (!mounted) return;
    setState(() => _isSending = false);

    final actionState = ref.read(adminActionsProvider);
    actionState.when(
      data: (_) {
        _titleController.clear();
        _messageController.clear();
        // Surface the real delivery breakdown so it's clear whether FCM push
        // actually went out (vs only the in-app rows being inserted).
        final inserted = result?['inserted'] ?? 0;
        final pushed = result?['pushed'] ?? 0;
        final failed = result?['failed'] ?? 0;
        final pushError = result?['pushError'];
        final summary = pushError != null && pushError.toString().isNotEmpty
            ? 'In-app: $inserted • Push failed: $pushError'
            : 'In-app: $inserted • Pushed: $pushed • Failed: $failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Broadcast sent. $summary'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 6),
          ),
        );
      },
      loading: () {},
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.sanitize(error)),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 6),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Push Broadcast'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentPink.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentPink.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.notification,
                      color: AppColors.accentPink, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send Push Notification',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'This will be sent to all app users',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Notification Title',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Enter notification title...',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Message',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Enter notification message...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendBroadcast,
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Iconsax.send_1),
                label: Text(_isSending ? 'Sending...' : 'Send Broadcast'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
