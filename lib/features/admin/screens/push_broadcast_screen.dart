import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/admin_provider.dart';

/// Admin push broadcast — rebuilt layout.
///
/// Old layout: a `PremiumAppBar` over a scroll column with a hand-built tinted
/// notice box, two bare Material `TextField`s each preceded by its own bold
/// `Text` label, and an `ElevatedButton.icon` at the bottom of the scroll that
/// hand-rolled its own spinner.
///
/// New layout: a collapsing large title, the "goes to everyone" warning as a
/// card whose rim carries the weight of that, both inputs from the shared text
/// field with built-in labels, and send pinned to the bottom with the shared
/// loading state.
///
/// `adminActionsProvider.sendBroadcast`, the empty-field guard and the full
/// delivery breakdown (inserted / pushed / failed / pushError) are unchanged.
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
      showGlassSnackBar(
        context,
        message: 'Please fill in all fields',
        tone: GlassToastTone.warning,
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
        showGlassSnackBar(
          context,
          message: 'Broadcast sent. $summary',
          tone: GlassToastTone.success,
          duration: const Duration(seconds: 6),
        );
      },
      loading: () {},
      error: (error, _) {
        showGlassSnackBar(
          context,
          message: ErrorUtils.sanitize(error),
          tone: GlassToastTone.error,
          duration: const Duration(seconds: 6),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      padBodyForAppBar: false,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const GlassLargeTitleHeader(
                title: 'Push broadcast',
                subtitle: 'Send a notification to every user',
                showBack: true,
              ),

              SliverToBoxAdapter(
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
                      // This goes to everyone, so the warning is prominent.
                      GlassCard(
                        rim: AppColors.accentPink.withOpacity(0.35),
                        child: Row(
                          children: [
                            const GlassIconBubble(
                              icon: AppIcons.notification,
                              color: AppColors.accentPink,
                              size: 40,
                              iconSize: 20,
                            ),
                            AppSpacing.gapMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Goes to all app users',
                                    style: AppTextStyles.headline.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'There is no undo once a broadcast is sent.',
                                    style: AppTextStyles.footnote.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapXl,
                      GlassTextField(
                        controller: _titleController,
                        label: 'Notification title',
                        hint: 'Enter notification title…',
                        prefixIcon: AppIcons.notification,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      AppSpacing.gapLg,
                      GlassTextField.multiline(
                        controller: _messageController,
                        label: 'Message',
                        hint: 'Enter notification message…',
                        minLines: 4,
                        maxLines: 8,
                      ),
                    ],
                  ),
                ),
              ),

              // Clearance for the pinned action.
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            child: GlassButton(
              label: _isSending ? 'Sending…' : 'Send broadcast',
              icon: AppIcons.send_1,
              size: GlassButtonSize.large,
              loading: _isSending,
              onPressed: _isSending ? null : _sendBroadcast,
            ),
          ),
        ],
      ),
    );
  }
}
