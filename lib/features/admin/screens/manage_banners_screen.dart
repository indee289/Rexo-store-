import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/image_upload_field.dart';
import '../../home/providers/banners_provider.dart';
import '../providers/admin_provider.dart';

/// Admin manage banners — rebuilt layout.
///
/// Old layout: a `PremiumAppBar` with an "add" `IconButton` *and* a
/// `FloatingActionButton` doing the same thing; admin-local `PremiumCard`
/// rows whose three actions were `GestureDetector`s with 6px of padding
/// (well under a usable tap target); two bespoke chip `Container`s; and an
/// edit screen that was another long single-column form with a Material
/// `Switch`, a hand-built three-segment `_LinkTypeSelector` and a
/// `DropdownButtonFormField` for the campaign picker.
///
/// New layout: one add affordance instead of two, rows on the shared card
/// surface with actions as `GlassIconButton`s (which guarantee the 44pt tap
/// target), the chips from the shared set, and an edit screen split into named
/// groups with the shared switch row, segmented control and a campaign picker
/// sheet.
///
/// This screen keeps a fixed [GlassAppBar] rather than the collapsing large
/// title: the list is a `ReorderableListView`, which owns its own scrollable
/// and cannot be driven from a shared `CustomScrollView`.
///
/// `adminBannersProvider`, `bannersActionsProvider`
/// (`toggleVisibility` / `deleteBanner` / `updateBanner` / `createBanner`),
/// the drag-to-reorder `sort_order` writes and the saved payload are all
/// unchanged.
class ManageBannersScreen extends ConsumerWidget {
  const ManageBannersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(adminBannersProvider);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: 'Manage banners',
        showBack: true,
        actions: [
          GlassIconButton(
            icon: AppIcons.add,
            tooltip: 'Add banner',
            size: 36,
            iconSize: 19,
            onTap: () => _openEdit(context, ref, null),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(adminBannersProvider);
          await ref.read(adminBannersProvider.future);
        },
        child: banners.when(
          data: (list) => list.isEmpty
              ? CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: GlassEmptyState(
                        icon: AppIcons.image,
                        title: 'No banners yet',
                        message: 'Upload your first home banner.',
                        actionLabel: 'Add banner',
                        onAction: () => _openEdit(context, ref, null),
                      ),
                    ),
                  ],
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    100,
                  ),
                  itemCount: list.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex--;
                    final reordered = [...list];
                    final item = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, item);
                    for (int i = 0; i < reordered.length; i++) {
                      await ref
                          .read(bannersActionsProvider.notifier)
                          .updateBanner(
                            reordered[i]['id'] as String,
                            {'sort_order': i},
                          );
                    }
                  },
                  itemBuilder: (context, index) {
                    final banner = list[index];
                    return _BannerAdminCard(
                      key: ValueKey(banner['id']),
                      banner: banner,
                      onEdit: () => _openEdit(context, ref, banner),
                    );
                  },
                ),
          loading: () => const GlassListSkeleton(itemCount: 3),
          error: (e, _) => GlassErrorState(
            title: 'Failed to load banners',
            message: ErrorUtils.sanitize(e),
            onRetry: () => ref.invalidate(adminBannersProvider),
          ),
        ),
      ),
    );
  }

  void _openEdit(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? banner,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BannerEditScreen(existing: banner),
      ),
    ).then((_) => ref.invalidate(adminBannersProvider));
  }
}

// ─── Banner Admin Card ────────────────────────────────────────────────────────

class _BannerAdminCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> banner;
  final VoidCallback onEdit;

  const _BannerAdminCard({
    super.key,
    required this.banner,
    required this.onEdit,
  });

  @override
  ConsumerState<_BannerAdminCard> createState() => _BannerAdminCardState();
}

class _BannerAdminCardState extends ConsumerState<_BannerAdminCard> {
  bool _toggling = false;
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.banner;
    final imageUrl = b['image_url'] as String? ?? '';
    final title = b['title'] as String?;
    final isVisible = b['is_visible'] as bool? ?? true;
    final linkType = b['link_type'] as String? ?? 'none';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        // Two rows rather than one.
        //
        // Everything used to sit on a single line: drag handle, 64px
        // thumbnail, title, two status chips and three actions. Once the
        // actions became real 44pt tap targets that left roughly 76px for the
        // title and chips on a 360px screen, so the title truncated to nothing
        // and the chips could not sit side by side. The actions now get their
        // own row, which also lets them carry labels.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(AppIcons.drag, size: 20, color: AppColors.textHint),
                AppSpacing.gapSm,
                ClipRRect(
                  borderRadius: AppRadius.allSm,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 64,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _Placeholder(),
                        )
                      : const _Placeholder(),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title?.isNotEmpty == true ? title! : 'Banner',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.callout.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          GlassChip.status(
                            label: _linkLabel(linkType),
                            color: AppColors.primary,
                          ),
                          GlassChip.status(
                            label: isVisible ? 'Visible' : 'Hidden',
                            color: isVisible
                                ? AppColors.success
                                : AppColors.textHint,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
            Row(
              children: [
                Expanded(
                  child: GlassButton.outline(
                    label: 'Edit',
                    icon: AppIcons.edit,
                    size: GlassButtonSize.small,
                    onPressed: widget.onEdit,
                  ),
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: GlassButton.glass(
                    label: isVisible ? 'Hide' : 'Show',
                    icon: isVisible ? AppIcons.eye_slash : AppIcons.eye,
                    size: GlassButtonSize.small,
                    loading: _toggling,
                    onPressed: _toggling ? null : () => _toggle(isVisible),
                  ),
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: GlassButton.outline(
                    label: 'Delete',
                    icon: AppIcons.trash,
                    size: GlassButtonSize.small,
                    loading: _deleting,
                    onPressed: _deleting ? null : _delete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(bool current) async {
    setState(() => _toggling = true);
    await ref
        .read(bannersActionsProvider.notifier)
        .toggleVisibility(widget.banner['id'] as String, current);
    if (mounted) setState(() => _toggling = false);
  }

  Future<void> _delete() async {
    final ok = await showGlassConfirm(
      context: context,
      title: 'Delete banner?',
      message: 'This cannot be undone.',
      icon: AppIcons.trash,
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _deleting = true);
    await ref
        .read(bannersActionsProvider.notifier)
        .deleteBanner(widget.banner['id'] as String);
    if (mounted) setState(() => _deleting = false);
  }
}

String _linkLabel(String linkType) => switch (linkType) {
      'campaign' => 'Campaign',
      'page' => 'Page',
      _ => 'No link',
    };

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 48,
      color: AppColors.primaryGlass,
      child: const Icon(AppIcons.image, color: AppColors.primary, size: 20),
    );
  }
}

// ─── Banner Edit/Create Screen ────────────────────────────────────────────────

class _BannerEditScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  const _BannerEditScreen({this.existing});

  @override
  ConsumerState<_BannerEditScreen> createState() => _BannerEditScreenState();
}

class _BannerEditScreenState extends ConsumerState<_BannerEditScreen> {
  final _titleCtrl = TextEditingController();
  final _pageCtrl = TextEditingController();
  String? _imageUrl;
  String _linkType = 'none';
  String? _linkedCampaignId;
  String? _linkedCampaignTitle;
  bool _isVisible = true;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  /// Index into [_linkTypes] for the segmented control.
  static const _linkTypes = ['none', 'campaign', 'page'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e['title'] as String? ?? '';
      _imageUrl = e['image_url'] as String?;
      _linkType = e['link_type'] as String? ?? 'none';
      _linkedCampaignId = e['link_campaign_id'] as String?;
      _pageCtrl.text = e['link_page'] as String? ?? '';
      _isVisible = e['is_visible'] as bool? ?? true;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_imageUrl == null || _imageUrl!.isEmpty) {
      showGlassSnackBar(
        context,
        message: 'Please upload a banner image first.',
        tone: GlassToastTone.error,
      );
      return;
    }

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'title': _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      'image_url': _imageUrl,
      'link_type': _linkType,
      'link_campaign_id': _linkType == 'campaign' ? _linkedCampaignId : null,
      'link_page': _linkType == 'page' ? _pageCtrl.text.trim() : null,
      'is_visible': _isVisible,
    };

    bool ok;
    if (_isEdit) {
      ok = await ref
          .read(bannersActionsProvider.notifier)
          .updateBanner(widget.existing!['id'] as String, data);
    } else {
      ok = await ref.read(bannersActionsProvider.notifier).createBanner(data);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      showGlassSnackBar(
        context,
        message: _isEdit ? 'Banner updated.' : 'Banner added!',
        tone: GlassToastTone.success,
      );
      Navigator.pop(context);
    } else {
      final err = ref.read(bannersActionsProvider);
      showGlassSnackBar(
        context,
        message: err.hasError
            ? ErrorUtils.sanitize(err.error)
            : 'Could not save banner.',
        tone: GlassToastTone.error,
      );
    }
  }

  /// Campaign picker, replacing the Material `DropdownButtonFormField`.
  Future<void> _pickCampaign(List<Map<String, dynamic>> list) async {
    final picked = await showGlassSheet<Map<String, dynamic>>(
      context: context,
      title: 'Link a campaign',
      child: Builder(
        builder: (sheetContext) => SingleChildScrollView(
          child: GlassGroup(
            children: [
              for (final c in list)
                GlassRow(
                  title: c['title'] as String? ?? 'Untitled',
                  showChevron: false,
                  trailing: c['id'] == _linkedCampaignId
                      ? const Icon(
                          AppIcons.tick_circle,
                          size: 20,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(c),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _linkedCampaignId = picked['id'] as String?;
        _linkedCampaignTitle = picked['title'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(adminCampaignsProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              GlassLargeTitleHeader(
                title: _isEdit ? 'Edit banner' : 'Add banner',
                subtitle: 'Shown on the home screen',
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
                      _sectionLabel('Artwork'),
                      ImageUploadField(
                        currentImageUrl: _imageUrl,
                        storageFolder: 'banners',
                        label: 'Banner image',
                        onImageUploaded: (url) =>
                            setState(() => _imageUrl = url),
                      ),
                      AppSpacing.gapLg,
                      GlassTextField(
                        controller: _titleCtrl,
                        label: 'Title (optional)',
                        hint: 'e.g. Summer Sale, New Feature',
                        prefixIcon: AppIcons.edit,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: GlassSection(
                  title: 'Visibility',
                  children: [
                    GlassSwitchRow(
                      title: 'Visible on home',
                      subtitle: 'Toggle off to hide without deleting',
                      icon: AppIcons.eye,
                      value: _isVisible,
                      onChanged: (v) => setState(() => _isVisible = v),
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          0,
                          AppSpacing.xl,
                          AppSpacing.xs,
                        ),
                        child: Text(
                          'LINK TO (OPTIONAL)',
                          style: AppTextStyles.caption1.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      GlassTabBar(
                        labels: const ['No link', 'Campaign', 'Page'],
                        selectedIndex: _linkTypes.indexOf(_linkType) < 0
                            ? 0
                            : _linkTypes.indexOf(_linkType),
                        onSelected: (i) => setState(() {
                          _linkType = _linkTypes[i];
                          _linkedCampaignId = null;
                          _linkedCampaignTitle = null;
                          _pageCtrl.clear();
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              if (_linkType == 'campaign')
                SliverToBoxAdapter(
                  child: campaigns.when(
                    data: (list) => GlassSection(
                      children: [
                        GlassRow(
                          icon: AppIcons.volume_high,
                          title: 'Campaign',
                          subtitle: _linkedCampaignId == null
                              ? 'None selected'
                              : null,
                          trailingText: _linkedCampaignTitle ??
                              (_linkedCampaignId == null ? 'Choose' : 'Linked'),
                          onTap: () => _pickCampaign(list),
                        ),
                      ],
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: GlassLoader(size: 22),
                    ),
                    error: (_, __) => const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: GlassErrorState(
                        title: 'Could not load campaigns',
                        compact: true,
                      ),
                    ),
                  ),
                ),

              if (_linkType == 'page')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: GlassTextField(
                      controller: _pageCtrl,
                      label: 'Page route',
                      hint: 'e.g. /campaigns, /wallet, /jobs',
                      prefixIcon: AppIcons.link,
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
              label: _isEdit ? 'Save changes' : 'Add banner',
              icon: _isEdit ? AppIcons.save_2 : AppIcons.add,
              size: GlassButtonSize.large,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
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
}
