import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/image_upload_field.dart';
import '../../../services/supabase_service.dart';
import '../../admin/providers/admin_provider.dart';

class CreateCampaignScreen extends ConsumerStatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  ConsumerState<CreateCampaignScreen> createState() =>
      _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _campaignNameController = TextEditingController();
  final _slotsController = TextEditingController();
  final _budgetController = TextEditingController();
  final _companyNameController = TextEditingController();

  String _selectedCategory = 'Logo';
  String _selectedPlatform = 'Instagram';
  String _selectedGender = 'all';
  String _selectedPageProfileCategory = 'Comedy';
  String? _coverImageUrl;
  bool _isSubmitting = false;

  static const List<String> _categories = [
    'Logo',
    'UGC',
    'Barter',
    'Clipping',
    'Paid',
    'Repost',
  ];

  static const List<String> _platforms = [
    'Instagram',
    'Facebook',
    'YouTube',
  ];

  static const List<String> _genders = [
    'all',
    'male',
    'female',
  ];

  static const List<String> _pageProfileCategories = [
    'Comedy',
    'Vlog',
    'Meme',
    'Funny',
    'Tech',
    'Travel',
    'Other',
  ];

  @override
  void dispose() {
    _campaignNameController.dispose();
    _slotsController.dispose();
    _budgetController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final data = <String, dynamic>{
        'brand_id': SupabaseService.currentUser?.id,
        'title': _campaignNameController.text.trim(),
        'category': _selectedCategory,
        'platform': _selectedPlatform,
        'total_slots': int.parse(_slotsController.text.trim()),
        'budget': double.parse(_budgetController.text.trim()),
        'company_name': _companyNameController.text.trim(),
        'gender': _selectedGender,
        'page_profile_category': _selectedPageProfileCategory,
        'status': 'active',
      };

      if (_coverImageUrl != null && _coverImageUrl!.isNotEmpty) {
        data['cover_image_url'] = _coverImageUrl;
      }

      await SupabaseService.client.from('campaigns').insert(data);
      ref.invalidate(adminCampaignsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campaign created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create campaign: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Create Campaign',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Iconsax.arrow_left),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campaign Name
              _buildLabel('Campaign Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _campaignNameController,
                decoration: _inputDecoration(
                  hint: 'Enter campaign name',
                  icon: Iconsax.edit,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campaign name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Category Dropdown
              _buildLabel('Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration(
                  hint: 'Select category',
                  icon: Iconsax.category,
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),

              const SizedBox(height: 20),

              // Platform Dropdown
              _buildLabel('Platform'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPlatform,
                decoration: _inputDecoration(
                  hint: 'Select platform',
                  icon: Iconsax.global,
                ),
                items: _platforms
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPlatform = value);
                  }
                },
              ),

              const SizedBox(height: 20),

              // Slots
              _buildLabel('Slots'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _slotsController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  hint: 'Number of slots',
                  icon: Iconsax.people,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Slots is required';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Budget
              _buildLabel('Budget'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  hint: 'Campaign budget',
                  icon: Iconsax.wallet_3,
                  prefix: '\u20B9 ',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Budget is required';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Company Name
              _buildLabel('Company Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _companyNameController,
                decoration: _inputDecoration(
                  hint: 'Enter company name',
                  icon: Iconsax.building,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Company name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Campaign Cover Image
              ImageUploadField(
                label: 'Campaign Cover Image',
                storageFolder: 'campaign-images',
                onImageUploaded: (url) {
                  setState(() => _coverImageUrl = url);
                },
              ),

              const SizedBox(height: 20),

              // Gender Dropdown
              _buildLabel('Gender'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: _inputDecoration(
                  hint: 'Select gender',
                  icon: Iconsax.user,
                ),
                items: _genders
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedGender = value);
                  }
                },
              ),

              const SizedBox(height: 20),

              // Page Profile Category Dropdown
              _buildLabel('Page Profile Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPageProfileCategory,
                decoration: _inputDecoration(
                  hint: 'Select page profile category',
                  icon: Iconsax.tag,
                ),
                items: _pageProfileCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPageProfileCategory = value);
                  }
                },
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit Campaign',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      prefixText: prefix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
