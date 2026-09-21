import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Visual variants for [PremiumTextField].
enum PremiumTextFieldVariant { standard, search, multiline }

/// Instagram-style text field — flat gray fill (#EFEFEF), no borders,
/// small radius, 14pt body text.
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
    final IconData? prefix =
        _isSearch ? Iconsax.search_normal : widget.prefixIcon;

    Widget? suffix = widget.suffix;
    if (_isSearch && _controller.text.isNotEmpty) {
      suffix = GestureDetector(
        onTap: _clear,
        behavior: HitTestBehavior.opaque,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Iconsax.close_circle,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    OutlineInputBorder border(Color color, [double width = 1]) =>
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
          : Icon(prefix, size: 20, color: AppColors.textSecondary),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surfaceAlt,
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(Colors.transparent),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, 1),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      labelStyle:
          AppTextStyles.subheadline.copyWith(color: AppColors.textSecondary),
      floatingLabelStyle:
          AppTextStyles.footnote.copyWith(color: AppColors.textSecondary),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: _isSearch ? 12 : 14,
      ),
      isDense: _isSearch,
    );

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
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      cursorColor: AppColors.textPrimary,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
    );
  }
}
