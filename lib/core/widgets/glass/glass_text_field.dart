import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Visual variants for [GlassTextField].
enum GlassTextFieldVariant { standard, search, multiline }

/// Frosted input field.
///
/// A recessed glass well rather than a bordered box: the fill is translucent,
/// the rim is a hairline, and focus is signalled by the rim turning brand red
/// and a soft red glow appearing — no jarring border-width change.
///
/// Labels render **above** the field instead of as a floating Material label,
/// because a floating label crossing a translucent rim reads as a visual
/// artefact on glass.
class GlassTextField extends StatefulWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.variant = GlassTextFieldVariant.standard,
    this.hint,
    this.label,
    this.helperText,
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
    this.focusNode,
  });

  /// Pill-shaped search field with a leading magnifier and a clear button.
  const GlassTextField.search({
    super.key,
    this.controller,
    this.hint,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  })  : variant = GlassTextFieldVariant.search,
        label = null,
        helperText = null,
        prefixIcon = null,
        suffix = null,
        keyboardType = null,
        textInputAction = TextInputAction.search,
        obscureText = false,
        minLines = 1,
        maxLines = 1,
        maxLength = null,
        inputFormatters = null,
        prefixText = null,
        textCapitalization = TextCapitalization.none,
        validator = null;

  /// Tall multi-line field for descriptions and messages.
  const GlassTextField.multiline({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.helperText,
    this.enabled = true,
    this.minLines = 3,
    this.maxLines = 6,
    this.maxLength,
    this.onChanged,
    this.validator,
    this.focusNode,
  })  : variant = GlassTextFieldVariant.multiline,
        prefixIcon = null,
        suffix = null,
        keyboardType = TextInputType.multiline,
        textInputAction = TextInputAction.newline,
        obscureText = false,
        autofocus = false,
        inputFormatters = null,
        prefixText = null,
        textCapitalization = TextCapitalization.sentences,
        onSubmitted = null;

  final TextEditingController? controller;
  final GlassTextFieldVariant variant;
  final String? hint;
  final String? label;
  final String? helperText;
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
  final FocusNode? focusNode;

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _ownsController = false;
  bool _ownsFocusNode = false;
  bool _focused = false;
  bool _obscured = false;

  bool get _isSearch => widget.variant == GlassTextFieldVariant.search;
  bool get _isMultiline => widget.variant == GlassTextFieldVariant.multiline;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _ownsController = widget.controller == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _ownsFocusNode = widget.focusNode == null;
    _obscured = widget.obscureText;
    _focusNode.addListener(_onFocusChanged);
    // The search variant repaints to show/hide its clear button.
    if (_isSearch) _controller.addListener(_onTextChanged);
  }

  void _onFocusChanged() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  void _onTextChanged() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (_isSearch) _controller.removeListener(_onTextChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = _isSearch ? AppRadius.pillAll : AppRadius.allMd;

    final IconData? prefix =
        _isSearch ? Iconsax.search_normal : widget.prefixIcon;

    Widget? suffix = widget.suffix;
    if (widget.obscureText) {
      suffix = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _obscured = !_obscured),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(
            _obscured ? Iconsax.eye : Iconsax.eye_slash,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
      );
    } else if (_isSearch && _controller.text.isNotEmpty) {
      suffix = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _clear,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Icon(
            Iconsax.close_circle,
            size: 19,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final field = TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      obscureText: _obscured,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      minLines: _isMultiline ? widget.minLines : 1,
      maxLines: _obscured ? 1 : (_isMultiline ? widget.maxLines : 1),
      maxLength: widget.maxLength,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      cursorColor: AppColors.primary,
      cursorRadius: const Radius.circular(2),
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixText: _isSearch ? null : widget.prefixText,
        prefixIcon: prefix == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(prefix, size: 20, color: AppColors.textSecondary),
              ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        // The glass well is painted by the wrapper below, so the Material
        // decoration itself must be completely transparent and border-free.
        filled: false,
        isDense: true,
        counterText: '',
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
        errorStyle: AppTextStyles.footnote.copyWith(color: AppColors.error),
        contentPadding: EdgeInsets.fromLTRB(
          prefix == null ? 16 : 0,
          _isSearch ? 13 : 15,
          suffix == null ? 16 : 0,
          _isSearch ? 13 : 15,
        ),
      ),
    );

    // Recessed glass well. No BackdropFilter here: inputs are small and often
    // appear many-to-a-form, and the translucent fill over the page backdrop
    // already reads as glass. Blurring each one would cost a save-layer per
    // field for no visible gain.
    final well = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: widget.enabled
            ? AppGlass.recessed(false)
            : AppColors.surfaceAlt.withOpacity(0.18),
        borderRadius: radius,
        border: Border.all(
          color: _focused ? AppColors.primaryRim : AppColors.border,
          width: _focused ? 1.4 : AppGlass.borderWidth,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: -4,
                ),
              ]
            : const [],
      ),
      child: field,
    );

    if (widget.label == null && widget.helperText == null) return well;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
            child: Text(
              widget.label!,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
        well,
        if (widget.helperText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              widget.helperText!,
              style:
                  AppTextStyles.footnote.copyWith(color: AppColors.textHint),
            ),
          ),
        ],
      ],
    );
  }
}
