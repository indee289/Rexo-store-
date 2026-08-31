import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../providers/addresses_provider.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingAddress;

  const AddAddressScreen({super.key, this.existingAddress});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _line1Controller;
  late final TextEditingController _line2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;
  bool _isDefault = false;
  bool _isSaving = false;

  bool get _isEditing => widget.existingAddress != null;

  @override
  void initState() {
    super.initState();
    final addr = widget.existingAddress;
    _nameController = TextEditingController(text: addr?['name'] ?? '');
    _phoneController = TextEditingController(text: addr?['phone'] ?? '');
    _line1Controller =
        TextEditingController(text: addr?['address_line1'] ?? '');
    _line2Controller =
        TextEditingController(text: addr?['address_line2'] ?? '');
    _cityController = TextEditingController(text: addr?['city'] ?? '');
    _stateController = TextEditingController(text: addr?['state'] ?? '');
    _pincodeController = TextEditingController(text: addr?['pincode'] ?? '');
    _isDefault = addr?['is_default'] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: _isEditing ? 'Edit Address' : 'Add Address',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter full name',
                icon: Iconsax.user,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter phone number',
                icon: Iconsax.call,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Phone is required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                controller: _line1Controller,
                label: 'Address Line 1',
                hint: 'House no., Street, Area',
                icon: Iconsax.location,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                controller: _line2Controller,
                label: 'Address Line 2 (Optional)',
                hint: 'Landmark, Building name',
                icon: Iconsax.building,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: 'City',
                      icon: Iconsax.buildings,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildTextField(
                      controller: _stateController,
                      label: 'State',
                      hint: 'State',
                      icon: Iconsax.map,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                controller: _pincodeController,
                label: 'Pincode',
                hint: '6-digit pincode',
                icon: Iconsax.hashtag,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Pincode is required';
                  if (v.length != 6) return 'Enter valid 6-digit pincode';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              // Default toggle
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppRadius.allMd,
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.star_1,
                      size: 20,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Set as default address',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _isDefault,
                      onChanged: (v) => setState(() => _isDefault = v),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Save button
              PremiumButton(
                label: _isEditing ? 'Update Address' : 'Save Address',
                gradient: true,
                loading: _isSaving,
                onPressed: _isSaving ? null : _saveAddress,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        PremiumTextField(
          controller: controller,
          hint: hint,
          prefixIcon: icon,
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final notifier = ref.read(addressesActionsProvider.notifier);
    bool success;

    if (_isEditing) {
      success = await notifier.updateAddress(
        addressId: widget.existingAddress!['id'],
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine1: _line1Controller.text.trim(),
        addressLine2: _line2Controller.text.trim().isEmpty
            ? null
            : _line2Controller.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        isDefault: _isDefault,
      );
    } else {
      success = await notifier.addAddress(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine1: _line1Controller.text.trim(),
        addressLine2: _line2Controller.text.trim().isEmpty
            ? null
            : _line2Controller.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        isDefault: _isDefault,
      );
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Address updated' : 'Address saved',
              style: AppTextStyles.bodyMedium,
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save address. Try again.',
              style: AppTextStyles.bodyMedium,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
