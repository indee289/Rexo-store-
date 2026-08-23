import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/image_upload_field.dart';
import '../../../services/supabase_service.dart';
import '../providers/campaigns_provider.dart';

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
  String _selectedGender = 'All';
  String _selectedPageProfileCategory = 'Comedy';
  bool _isSubmitting = false;
  String? _coverImageUrl;

  final List<String> _categories = [
    'Logo',
    'UGC',
    'Barter',
    'Clipping',
    'Paid',
    'Repost',
  ];

  final List<String> _platforms = [
    'Instagram',
    'Facebook',
    'YouTube',
  ];

  final List<String> _genders = [
    'All',
    'Male',
    'Female',
  ];

  final List<String> _pageProfileCategories = [
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
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Store platform lowercase for DB CHECK constraint compatibility
      final platformForDb = _selectedPlatform.toLowerCase();

      await SupabaseService.client.from('campaigns').insert({
        'brand_id': user.id,
        'title': _campaignNameController.text.trim(),
        'category': _selectedCategory,
        'platform': platformForDb,
        'total_slots': int.tryParse(_slotsController.text.trim()) ?? 1,
        'filled_slots': 0,
        'budget': double.tryParse(_budgetController.text.trim()) ?? 0,
        'company_name': _companyNameController.text.trim(),
        'cover_image_url': _coverImageUrl,
        'gender': _selectedGender,
        'page_profile_category': _selectedPageProfileCategory,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      // Invalidate campaigns list to refresh
      ref.invalidate(campaignsListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Campaign created successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to create campaign. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Create Campaign',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Iconsax.arrow_left,
              color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Campaign Name
              _buildLabel('Campaign Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _campaignNameController,
                hint: 'Enter campaign name',
                icon: Iconsax.document_text,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a campaign name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 2. Category dropdown
              _buildLabel('Category'),
              const SizedBox(height: 8),
              _buildDropdown(
                value: _selectedCategory,
                items: _categories,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              // 3. Platform dropdown
              _buildLabel('Platform'),
              const SizedBox(height: 8),
              _buildDropdown(
                value: _selectedPlatform,
                items: _platforms,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPlatform = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              // 4. Slots (number)
              _buildLabel('Slots'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _slotsController,
                hint: 'Number of slots (e.g. 10)',
                icon: Iconsax.people,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter number of slots';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 5. Budget (number)
              _buildLabel('Budget (\u20B9)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _budgetController,
                hint: 'Total budget',
                icon: Iconsax.money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the budget';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 6. Company Name
              _buildLabel('Company Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _companyNameController,
                hint: 'Enter company name',
                icon: Iconsax.building,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter company name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 7. Campaign Cover Image
              ImageUploadField(
                label: 'Campaign Cover Image',
                storageFolder: 'campaign-assets',
                onImageUploaded: (url) {
                  _coverImageUrl = url;
                },
              ),

              const SizedBox(height: 16),

              // 8. Gender dropdown
              _buildLabel('Gender'),
              const SizedBox(height: 8),
              _buildDropdown(
                value: _selectedGender,
                items: _genders,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedGender = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              // 9. Page Profile Category dropdown
              _buildLabel('Page Profile Category'),
              const SizedBox(height: 8),
              _buildDropdown(
                value: _selectedPageProfileCategory,
                items: _pageProfileCategories,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPageProfileCategory = value);
                  }
                },
              ),

              const SizedBox(height: 32),

              // Submit button
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
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Create Campaign',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(
          fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
        prefixIcon: maxLines == 1
            ? Icon(icon,
                size: 20,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.4))
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Iconsax.arrow_down_1, size: 20),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
