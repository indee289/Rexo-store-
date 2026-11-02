import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glass/glass.dart';

/// Visual variants for the [PremiumTextField] shim.
enum PremiumTextFieldVariant { standard, search, multiline }

/// **Migration shim.** Use [GlassTextField] directly.
///
/// Forwards to [GlassTextField]. The old treatment (flat opaque grey `#EFEFEF`
/// fill, 8px radius, floating Material label) is gone; inputs are now recessed
/// glass wells with a brand-red focus rim and the label sitting above the
/// field.
///
/// Scheduled for deletion once every call-site is migrated.
class PremiumTextField extends StatelessWidget {
  final TextEditingController? controller;
  final PremiumTextFieldVariant variant;
  final String? hint;
  final String? label;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  const PremiumTextField({
    super.key,
    this.controller,
    this.variant = PremiumTextFieldVariant.standard,
    this.hint,
    this.label,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.prefixText,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.validator,
  });

  const PremiumTextField.search({
    Key? key,
    TextEditingController? controller,
    String? hint,
    bool enabled = true,
    bool autofocus = false,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) : this(
          key: key,
          controller: controller,
          variant: PremiumTextFieldVariant.search,
          hint: hint,
          enabled: enabled,
          autofocus: autofocus,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        );

  const PremiumTextField.multiline({
    Key? key,
    TextEditingController? controller,
    String? hint,
    String? label,
    bool enabled = true,
    int minLines = 3,
    int maxLines = 6,
    int? maxLength,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
  }) : this(
          key: key,
          controller: controller,
          variant: PremiumTextFieldVariant.multiline,
          hint: hint,
          label: label,
          enabled: enabled,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          minLines: minLines,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          validator: validator,
        );

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case PremiumTextFieldVariant.search:
        return GlassTextField.search(
          controller: controller,
          hint: hint,
          enabled: enabled,
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        );
      case PremiumTextFieldVariant.multiline:
        return GlassTextField.multiline(
          controller: controller,
          hint: hint,
          label: label,
          enabled: enabled,
          minLines: minLines,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          validator: validator,
        );
      case PremiumTextFieldVariant.standard:
        return GlassTextField(
          controller: controller,
          hint: hint,
          label: label,
          prefixIcon: prefixIcon,
          suffix: suffix,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          enabled: enabled,
          autofocus: autofocus,
          minLines: minLines,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          prefixText: prefixText,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          validator: validator,
        );
    }
  }
}
