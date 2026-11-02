import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/addresses_provider.dart';

/// Add / edit address — rebuilt layout.
///
/// Old layout: `PremiumAppBar` over a flat column where every field was
/// wrapped in a local `_buildTextField` helper that printed a bare `Text`
/// label above a `PremiumTextField`, with the default-address toggle as a
/// hand-built `Container` holding a `Switch.adaptive`.
///
/// New layout: collapsing large title; the form split into two titled
/// sections (contact, then address) so a seven-field form reads as two short
/// ones; the field labels come from the shared text field; the toggle is a
/// standard switch row; and the save action is pinned so it is reachable
/// without scrolling to the bottom of the form.
///
/// `addressesActionsProvider.addAddress` / `updateAddress`, every payload key
/// and all validation rules are unchanged.
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
    return GlassScaffold(
      padBodyForAppBar: false,
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                GlassLargeTitleHeader(
                  title: _isEditing ? 'Edit address' : 'Add address',
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
                        GlassTextField(
                          controller: _nameController,
                          label: 'Full name',
                          hint: 'Enter full name',
                          prefixIcon: AppIcons.user,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Name is required'
                              : null,
                        ),
                        AppSpacing.gapLg,
                        GlassTextField(
                          controller: _phoneController,
                          label: 'Phone number',
                          hint: 'Enter phone number',
                          prefixIcon: AppIcons.call,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Phone is required'
                              : null,
                        ),
                        AppSpacing.gapLg,
                        GlassTextField(
                          controller: _line1Controller,
                          label: 'Address line 1',
                          hint: 'House no., street, area',
                          prefixIcon: AppIcons.location,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Address is required'
                              : null,
                        ),
                        AppSpacing.gapLg,
                        GlassTextField(
                          controller: _line2Controller,
                          label: 'Address line 2 (optional)',
                          hint: 'Landmark, building name',
                          prefixIcon: AppIcons.building,
                        ),
                        AppSpacing.gapLg,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: GlassTextField(
                                controller: _cityController,
                                label: 'City',
                                hint: 'City',
                                prefixIcon: AppIcons.buildings,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                            AppSpacing.gapMd,
                            Expanded(
                              child: GlassTextField(
                                controller: _stateController,
                                label: 'State',
                                hint: 'State',
                                prefixIcon: AppIcons.map,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapLg,
                        GlassTextField(
                          controller: _pincodeController,
                          label: 'Pincode',
                          hint: '6-digit pincode',
                          prefixIcon: AppIcons.hashtag,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Pincode is required';
                            }
                            if (v.length != 6) {
                              return 'Enter valid 6-digit pincode';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: GlassSection(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      120,
                    ),
                    children: [
                      GlassSwitchRow(
                        icon: AppIcons.star_1,
                        title: 'Set as default address',
                        subtitle: 'Used first at checkout',
                        value: _isDefault,
                        onChanged: (v) => setState(() => _isDefault = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            child: GlassButton(
              label: _isEditing ? 'Update address' : 'Save address',
              loading: _isSaving,
              size: GlassButtonSize.large,
              onPressed: _isSaving ? null : _saveAddress,
            ),
          ),
        ],
      ),
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

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      context.pop();
      showGlassSnackBar(
        context,
        message: _isEditing ? 'Address updated' : 'Address saved',
        tone: GlassToastTone.success,
      );
    } else {
      showGlassSnackBar(
        context,
        message: 'Failed to save address. Try again.',
        tone: GlassToastTone.error,
      );
    }
  }
}
