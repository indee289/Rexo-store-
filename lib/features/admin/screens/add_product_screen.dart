import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../services/r2_storage_service.dart';
import '../../../services/supabase_service.dart';
import '../providers/admin_provider.dart';

/// The two kinds of product an admin can create.
enum ProductType { ecommerce, digital }

/// Full-screen "Add Product" page.
///
/// Step 1 asks the admin to choose a product type (physical e-commerce vs
/// digital). That choice drives which fields are shown and which are required:
///   * Common (both): title, description, price, category, >= 4 images.
///   * E-commerce only: stock (required), original price (optional, for
///     discount display) and shipping/delivery notes (optional, folded into
///     the description since there is no dedicated column).
///   * Digital: lighter — no stock tracking (stock is set high so it never
///     shows as out of stock).
///
/// On submit it performs a REAL Supabase insert through
/// [AdminActionsNotifier.createProduct]; the success message is only shown
/// after the write actually succeeds. The product list is refreshed via the
/// provider's own `ref.invalidate(adminProductsProvider)`.
class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  /// Minimum number of images an admin must upload before submitting.
  static const int minImages = 4;

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _shippingController = TextEditingController();

  ProductType _type = ProductType.ecommerce;
  String? _category;

  /// Public R2 URLs of images already uploaded (in display order).
  final List<String> _imageUrls = [];

  bool _isUploadingImages = false;
  bool _isSubmitting = false;

  /// Set to true only after the user tries to submit, so the "at least 4
  /// images" error does not show before they have had a chance to add any.
  bool _showImageError = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _originalPriceController.dispose();
    _shippingController.dispose();
    super.dispose();
  }

  bool get _isEcommerce => _type == ProductType.ecommerce;

  bool get _busy => _isUploadingImages || _isSubmitting;

  // --------------------------------------------------------------------------
  // Image handling
  // --------------------------------------------------------------------------

  Future<void> _pickImages() async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      _showError('You must be signed in to upload images.');
      return;
    }

    final picker = ImagePicker();
    final List<XFile> picked = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (picked.isEmpty) return;

    setState(() => _isUploadingImages = true);

    int uploaded = 0;
    try {
      for (final file in picked) {
        final ext = file.path.split('.').last;
        final fileName = '${const Uuid().v4()}.$ext';
        final path = 'product-images/${user.id}/$fileName';
        final bytes = await File(file.path).readAsBytes();
        final url = await R2StorageService.uploadFile(
          path,
          bytes,
          _contentTypeFor(ext),
        );
        if (!mounted) return;
        setState(() => _imageUrls.add(url));
        uploaded++;
      }
    } catch (e) {
      _showError('Image upload failed: ${ErrorUtils.sanitize(e)}');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImages = false;
          if (_imageUrls.length >= AddProductScreen.minImages) {
            _showImageError = false;
          }
        });
        if (uploaded > 0) {
          _showInfo('Uploaded $uploaded image${uploaded == 1 ? '' : 's'}.');
        }
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _imageUrls.removeAt(index));
  }

  String _contentTypeFor(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  // --------------------------------------------------------------------------
  // Submit
  // --------------------------------------------------------------------------

  Future<void> _submit() async {
    // Re-check the image count on submit and surface the inline error.
    final enoughImages = _imageUrls.length >= AddProductScreen.minImages;
    setState(() => _showImageError = !enoughImages);

    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk || !enoughImages) {
      if (!enoughImages) {
        _showError(
          'Please upload at least ${AddProductScreen.minImages} product images.',
        );
      }
      return;
    }

    if (_category == null || _category!.isEmpty) {
      _showError('Please select a category.');
      return;
    }

    final user = SupabaseService.currentUser;
    if (user == null) {
      _showError('You must be signed in to create a product.');
      return;
    }

    final price = double.parse(_priceController.text.trim());

    // Fold optional shipping notes into the description (no dedicated column).
    final description = StringBuffer(_descriptionController.text.trim());
    if (_isEcommerce && _shippingController.text.trim().isNotEmpty) {
      description
        ..write('\n\nShipping & Delivery:\n')
        ..write(_shippingController.text.trim());
    }

    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': description.toString(),
      'price': price,
      'category': _category,
      'product_type': _isEcommerce ? 'ecommerce' : 'digital',
      'images': _imageUrls,
      'image_url': _imageUrls.first,
      'is_active': true,
      'seller_id': user.id,
    };

    if (_isEcommerce) {
      data['stock'] = int.parse(_stockController.text.trim());
      final originalRaw = _originalPriceController.text.trim();
      if (originalRaw.isNotEmpty) {
        data['original_price'] = double.parse(originalRaw);
      }
    } else {
      // Digital goods are not stock-tracked; keep a high number so the
      // storefront never renders them as out of stock.
      data['stock'] = 999999;
    }

    setState(() => _isSubmitting = true);
    final ok =
        await ref.read(adminActionsProvider.notifier).createProduct(data);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      _showInfo('Product created successfully.');
      Navigator.of(context).pop(true);
    } else {
      final state = ref.read(adminActionsProvider);
      final message = state.hasError
          ? ErrorUtils.sanitize(state.error)
          : 'Could not create the product. Please try again.';
      _showError(message);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Add Product'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              _sectionTitle('1. Product type'),
              const SizedBox(height: 8),
              _buildTypeSelector(),
              const SizedBox(height: 24),
              _sectionTitle('2. Product images'),
              const SizedBox(height: 4),
              Text(
                'Upload at least ${AddProductScreen.minImages} images. '
                'The first image is used as the main thumbnail.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              _buildImageSection(),
              const SizedBox(height: 24),
              _sectionTitle('3. Details'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _titleController,
                label: 'Title *',
                hint: 'e.g. Wireless Headphones',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description *',
                hint: 'Describe the product',
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildCategoryDropdown(categoriesAsync),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _priceController,
                label: 'Price (\u20B9) *',
                hint: '0.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim());
                  if (value == null) return 'Enter a valid price';
                  if (value <= 0) return 'Price must be greater than 0';
                  return null;
                },
              ),
              // ---- E-commerce only fields ----
              if (_isEcommerce) ...[
                const SizedBox(height: 24),
                _sectionTitle('4. Physical product details'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _stockController,
                  label: 'Stock quantity *',
                  hint: 'e.g. 50',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (v) {
                    final value = int.tryParse((v ?? '').trim());
                    if (value == null) return 'Enter a valid stock quantity';
                    if (value < 0) return 'Stock cannot be negative';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _originalPriceController,
                  label: 'Original price (\u20B9) — optional',
                  hint: 'Shown crossed-out for discounts',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (v) {
                    final raw = (v ?? '').trim();
                    if (raw.isEmpty) return null; // optional
                    final value = double.tryParse(raw);
                    if (value == null || value <= 0) {
                      return 'Enter a valid original price';
                    }
                    final price = double.tryParse(_priceController.text.trim());
                    if (price != null && value <= price) {
                      return 'Original price should be higher than price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _shippingController,
                  label: 'Shipping & delivery details — optional',
                  hint: 'e.g. Ships in 2-3 days, free delivery over \u20B9499',
                  maxLines: 3,
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSubmitBar(),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _typeCard(
            type: ProductType.ecommerce,
            icon: Iconsax.box,
            title: 'E-commerce',
            subtitle: 'Physical item · full details',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _typeCard(
            type: ProductType.digital,
            icon: Iconsax.cloud,
            title: 'Digital',
            subtitle: 'Downloadable · fewer details',
          ),
        ),
      ],
    );
  }

  Widget _typeCard({
    required ProductType type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _type == type;
    return GestureDetector(
      onTap: _busy ? null : () => setState(() => _type = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.08)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: selected
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selected ? AppColors.primary : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < _imageUrls.length; i++)
              _imageThumb(i, _imageUrls[i]),
            _addImageTile(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              _imageUrls.length >= AddProductScreen.minImages
                  ? Iconsax.tick_circle
                  : Iconsax.info_circle,
              size: 14,
              color: _imageUrls.length >= AddProductScreen.minImages
                  ? AppColors.success
                  : (_showImageError
                      ? AppColors.error
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(width: 6),
            Text(
              '${_imageUrls.length}/${AddProductScreen.minImages} minimum images',
              style: TextStyle(
                fontSize: 12,
                color: _showImageError &&
                        _imageUrls.length < AddProductScreen.minImages
                    ? AppColors.error
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
              ),
            ),
          ],
        ),
        if (_showImageError &&
            _imageUrls.length < AddProductScreen.minImages)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Add at least ${AddProductScreen.minImages} images to continue.',
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
      ],
    );
  }

  Widget _imageThumb(int index, String url) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 90,
                color: Theme.of(context).colorScheme.surface,
                child: const Icon(Iconsax.gallery_slash, size: 24),
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Main',
                  style: TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: _busy ? null : () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.close_circle,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addImageTile() {
    return GestureDetector(
      onTap: _busy ? null : _pickImages,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showImageError &&
                    _imageUrls.length < AddProductScreen.minImages
                ? AppColors.error
                : Theme.of(context).dividerColor,
          ),
        ),
        child: _isUploadingImages
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.gallery_add,
                      color: AppColors.primary, size: 26),
                  const SizedBox(height: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryDropdown(AsyncValue<List<String>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) {
        // Guard against a stale selection that is no longer in the list.
        final value =
            (_category != null && categories.contains(_category)) ? _category : null;
        return DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: _inputDecoration('Category *', 'Select a category'),
          items: categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: _busy ? null : (v) => setState(() => _category = v),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Category is required' : null,
        );
      },
      loading: () => const LinearProgressIndicator(color: AppColors.primary),
      error: (_, __) => _buildTextField(
        controller: TextEditingController(text: _category),
        label: 'Category *',
        hint: 'Type a category',
        onChanged: (v) => _category = v.trim().isEmpty ? null : v.trim(),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Category is required' : null,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      enabled: !_isSubmitting,
      decoration: _inputDecoration(label, hint),
    );
  }

  InputDecoration _inputDecoration(String label, String? hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildSubmitBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _busy ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isUploadingImages ? 'Uploading images…' : 'Create Product',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
