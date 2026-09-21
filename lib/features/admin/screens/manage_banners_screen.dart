import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/image_upload_field.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../home/providers/banners_provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/premium_card.dart';

class ManageBannersScreen extends ConsumerWidget {
  const ManageBannersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(adminBannersProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Manage Banners',
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add_circle, color: AppColors.primary),
            onPressed: () => _openEdit(context, ref, null),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _openEdit(context, ref, null),
        child: const Icon(Iconsax.add, color: Colors.white),
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
                      child: EmptyState(
                        icon: Iconsax.image,
                        title: 'No banners yet',
                        subtitle: 'Tap + to upload your first banner.',
                        cta: PremiumButton(
                          label: 'Add Banner',
                          icon: Iconsax.add,
                          expand: false,
                          onPressed: () => _openEdit(context, ref, null),
                        ),
                      ),
                    ),
                  ],
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 100),
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
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: 3,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: ShimmerCard(height: 100),
            ),
          ),
          error: (e, _) => Center(
            child: EmptyState(
              icon: Iconsax.warning_2,
              title: 'Failed to load banners',
              subtitle: ErrorUtils.sanitize(e),
              cta: PremiumButton(
                label: 'Retry',
                icon: Iconsax.refresh,
                variant: PremiumButtonVariant.tonal,
                expand: false,
                onPressed: () => ref.invalidate(adminBannersProvider),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openEdit(
      BuildContext context, WidgetRef ref, Map<String, dynamic>? banner) {
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

  const _BannerAdminCard({super.key, required this.banner, required this.onEdit});

  @override
  ConsumerState<_BannerAdminCard> createState() => _BannerAdminCardState();
}

class _BannerAdminCardState extends ConsumerState<_BannerAdminCard> {
  bool _toggling = false;
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final b = widget.banner;
    final imageUrl = b['image_url'] as String? ?? '';
    final title = b['title'] as String?;
    final isVisible = b['is_visible'] as bool? ?? true;
    final linkType = b['link_type'] as String? ?? 'none';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            // Drag handle
            Icon(Iconsax.drag,
                size: 20,
                color: isDark ? AppColors.darkTextHint : AppColors.textHint),
            const SizedBox(width: AppSpacing.sm),

            // Thumbnail
            ClipRRect(
              borderRadius: AppRadius.allSm,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 64,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),

            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title?.isNotEmpty == true ? title! : 'Banner',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _LinkChip(linkType: linkType, isDark: isDark),
                      const SizedBox(width: 6),
                      _VisibilityChip(isVisible: isVisible),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit
                _iconBtn(
                  icon: Iconsax.edit,
                  color: AppColors.primary,
                  onTap: widget.onEdit,
                ),
                // Hide/Show
                _toggling
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.warning),
                      )
                    : _iconBtn(
                        icon: isVisible ? Iconsax.eye_slash : Iconsax.eye,
                        color: AppColors.warning,
                        onTap: () => _toggle(isVisible),
                      ),
                // Delete
                _deleting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.error),
                      )
                    : _iconBtn(
                        icon: Iconsax.trash,
                        color: AppColors.error,
                        onTap: () => _delete(context),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 64,
        height: 48,
        color: AppColors.primary.withOpacity(0.10),
        child: const Icon(Iconsax.image, color: AppColors.primary, size: 20),
      );

  Widget _iconBtn(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
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

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Banner?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deleting = true);
    await ref
        .read(bannersActionsProvider.notifier)
        .deleteBanner(widget.banner['id'] as String);
    if (mounted) setState(() => _deleting = false);
  }
}

class _LinkChip extends StatelessWidget {
  final String linkType;
  final bool isDark;
  const _LinkChip({required this.linkType, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final label = switch (linkType) {
      'campaign' => 'Campaign',
      'page' => 'Page',
      _ => 'No link',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: AppRadius.allSm,
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10,
              color: AppColors.primary,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  final bool isVisible;
  const _VisibilityChip({required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isVisible ? AppColors.success : AppColors.textHint)
            .withOpacity(0.12),
        borderRadius: AppRadius.allSm,
      ),
      child: Text(
        isVisible ? 'Visible' : 'Hidden',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isVisible ? AppColors.success : AppColors.textHint,
        ),
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please upload a banner image first.'),
        backgroundColor: AppColors.error,
      ));
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
      ok = await ref
          .read(bannersActionsProvider.notifier)
          .createBanner(data);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Banner updated.' : 'Banner added!'),
        backgroundColor: AppColors.success,
      ));
      Navigator.pop(context);
    } else {
      final err = ref.read(bannersActionsProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err.hasError
            ? ErrorUtils.sanitize(err.error)
            : 'Could not save banner.'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final campaigns = ref.watch(adminCampaignsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: _isEdit ? 'Edit Banner' : 'Add Banner'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image upload
            _Label('Banner Image *', isDark),
            const SizedBox(height: AppSpacing.sm),
            ImageUploadField(
              currentImageUrl: _imageUrl,
              storageFolder: 'banners',
              label: 'Upload Banner Image',
              onImageUploaded: (url) => setState(() => _imageUrl = url),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Title
            _Label('Title (Optional)', isDark),
            const SizedBox(height: AppSpacing.sm),
            PremiumTextField(
              controller: _titleCtrl,
              hint: 'e.g. Summer Sale, New Feature',
              prefixIcon: Iconsax.edit,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Visibility toggle
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Visible on Home', isDark),
                      Text(
                        'Toggle off to hide without deleting.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isVisible,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isVisible = v),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Link type
            _Label('Link To (Optional)', isDark),
            const SizedBox(height: AppSpacing.sm),
            _LinkTypeSelector(
              selected: _linkType,
              isDark: isDark,
              onChanged: (v) => setState(() {
                _linkType = v;
                _linkedCampaignId = null;
                _linkedCampaignTitle = null;
                _pageCtrl.clear();
              }),
            ),

            if (_linkType == 'campaign') ...[
              const SizedBox(height: AppSpacing.md),
              _Label('Select Campaign', isDark),
              const SizedBox(height: AppSpacing.sm),
              campaigns.when(
                data: (list) => DropdownButtonFormField<String>(
                  value: _linkedCampaignId,
                  hint: const Text('Choose a campaign'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceAlt
                        : AppColors.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.allMd,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  items: list
                      .map((c) => DropdownMenuItem<String>(
                            value: c['id'] as String,
                            child: Text(
                              c['title'] as String? ?? 'Untitled',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (id) => setState(() {
                    _linkedCampaignId = id;
                    _linkedCampaignTitle = list.firstWhere(
                        (c) => c['id'] == id,
                        orElse: () => {})['title'] as String?;
                  }),
                ),
                loading: () => const LinearProgressIndicator(
                    color: AppColors.primary),
                error: (_, __) =>
                    const Text('Could not load campaigns'),
              ),
            ],

            if (_linkType == 'page') ...[
              const SizedBox(height: AppSpacing.md),
              _Label('Page Route', isDark),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField(
                controller: _pageCtrl,
                hint: 'e.g. /campaigns, /wallet, /jobs',
                prefixIcon: Iconsax.link,
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),

            PremiumButton(
              label: _isEdit ? 'Save Changes' : 'Add Banner',
              icon: _isEdit ? Iconsax.save_2 : Iconsax.add,
              loading: _saving,
              onPressed: _save,
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final bool isDark;
  const _Label(this.text, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
    );
  }
}

class _LinkTypeSelector extends StatelessWidget {
  final String selected;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _LinkTypeSelector({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  static const _options = [
    ('none', Iconsax.slash, 'No Link'),
    ('campaign', Iconsax.send_2, 'Campaign'),
    ('page', Iconsax.link, 'Page'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
        borderRadius: AppRadius.allMd,
      ),
      child: Row(
        children: _options.map((o) {
          final isSelected = o.$1 == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  borderRadius: AppRadius.allSm,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(o.$2,
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(o.$3,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary),
                        )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
