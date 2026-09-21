import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Visual variants for [PremiumTextField].
enum PremiumTextFieldVariant { standard, search, multiline }

/// Clean teal-focused text field: #F8FAFC fill, 12px radius, 1px border,
/// 2px teal on focus, floating label or hint, prefix/suffix icons.
class PremiumTextField extends StatefulWidget {
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
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  late final TextEditingController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _ownsController = widget.controller == null;
    if (_isSearch) _controller.addListener(_onChanged);
  }

  bool get _isSearch => widget.variant == PremiumTextFieldVariant.search;
  bool get _isMultiline => widget.variant == PremiumTextFieldVariant.multiline;

  void _onChanged() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  void dispose() {
    if (_isSearch) _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
    final hintColor =
        isDark ? AppColors.darkTextHint : AppColors.textHint;
    final labelColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    final IconData? prefix =
        _isSearch ? Iconsax.search_normal : widget.prefixIcon;

    Widget? suffix = widget.suffix;
    if (_isSearch && _controller.text.isNotEmpty) {
      suffix = IconButton(
        icon: const Icon(Iconsax.close_circle, size: 18),
        color: hintColor,
        onPressed: _clear,
      );
    }

    // Borderless filled fields; only the focus state shows a green outline.
    OutlineInputBorder _border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: color == Colors.transparent
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );

    InputDecoration decoration = InputDecoration(
      hintText: widget.hint,
      labelText: widget.label,
      prefixText: _isSearch ? null : widget.prefixText,
      prefixIcon: prefix == null
          ? null
          : Icon(prefix, size: 20, color: hintColor),
      suffixIcon: suffix,
      filled: true,
      fillColor: fillColor,
      border: _border(Colors.transparent),
      enabledBorder: _border(Colors.transparent),
      focusedBorder: _border(AppColors.primary, 1.5),
      errorBorder: _border(AppColors.error),
      focusedErrorBorder: _border(AppColors.error, 1.5),
      hintStyle: TextStyle(fontSize: 14, color: hintColor),
      labelStyle: TextStyle(fontSize: 14, color: labelColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    if (_isSearch) {
      decoration = decoration.copyWith(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
    }

    return TextFormField(
      controller: _controller,
      decoration: decoration,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      minLines: _isMultiline ? widget.minLines : 1,
      maxLines: widget.obscureText ? 1 : (_isMultiline ? widget.maxLines : 1),
      maxLength: widget.maxLength,
      style: TextStyle(fontSize: 14, color: textColor),
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
    );
  }
}
