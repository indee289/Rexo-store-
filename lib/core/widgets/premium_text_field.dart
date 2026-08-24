import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_glass.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// The visual/behavioral variants of [PremiumTextField].
enum PremiumTextFieldVariant {
  /// A standard single-line field (login, forms, ...).
  standard,

  /// A rounded, frosted "pill" search field with a leading search glyph and a
  /// clear affordance once text is present.
  search,

  /// A multi-line field that grows with content (bio, message composer, ...).
  multiline,
}

/// A premium text field (Layer-2 primitive) that consumes the app's shared
/// `inputDecorationTheme`.
///
/// Rather than re-styling every border/fill inline, this widget leans on the
/// theme's `inputDecorationTheme` (single source of truth) and only layers the
/// per-variant affordances on top:
///
///   * [PremiumTextFieldVariant.standard] – theme defaults, optional prefix
///     Iconsax glyph, optional label/hint.
///   * [PremiumTextFieldVariant.search] – a frosted, pill-shaped field with a
///     leading `Iconsax.search_normal` glyph and a clear button that appears
///     once the field is non-empty. The frost uses the [AppGlass] tokens for a
///     modern, iOS-style look.
///   * [PremiumTextFieldVariant.multiline] – grows between [minLines] and
///     [maxLines].
///
/// Fully token-driven: no raw color literals, no inline font construction.
class PremiumTextField extends StatefulWidget {
  final TextEditingController? controller;
  final PremiumTextFieldVariant variant;
  final String? hint;
  final String? label;

  /// Optional leading Iconsax glyph. Ignored for the search variant (which
  /// always uses `Iconsax.search_normal`).
  final IconData? prefixIcon;

  /// Optional trailing widget (e.g. a visibility toggle). Ignored for the
  /// search variant, which manages its own clear button.
  final Widget? suffix;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final int minLines;
  final int maxLines;
  final int? maxLength;

  /// Optional input formatters (e.g. digits-only, phone filtering).
  final List<TextInputFormatter>? inputFormatters;

  /// Optional static prefix text shown before the input (e.g. a currency
  /// symbol). Ignored for the search variant.
  final String? prefixText;

  /// Auto-capitalization behavior for the field.
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

  /// Convenience constructor for the search variant.
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

  /// Convenience constructor for the multiline variant.
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
    if (_isSearch) _controller.addListener(_onSearchChanged);
  }

  bool get _isSearch => widget.variant == PremiumTextFieldVariant.search;
  bool get _isMultiline =>
      widget.variant == PremiumTextFieldVariant.multiline;

  void _onSearchChanged() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  void dispose() {
    if (_isSearch) _controller.removeListener(_onSearchChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Prefix glyph: search always uses the search glyph; other variants use
    // whatever the caller provided.
    final IconData? prefix =
        _isSearch ? Iconsax.search_normal : widget.prefixIcon;

    // Trailing affordance: search shows a clear button once non-empty.
    Widget? suffix = widget.suffix;
    if (_isSearch && _controller.text.isNotEmpty) {
      suffix = IconButton(
        icon: const Icon(Iconsax.close_circle, size: 20),
        splashRadius: 20,
        color: theme.colorScheme.onSurface.withOpacity(0.5),
        onPressed: _clear,
      );
    }

    // Start from the theme's shared decoration and only override what each
    // variant needs, so borders/fills/hints stay centrally controlled.
    InputDecoration decoration = InputDecoration(
      hintText: widget.hint,
      labelText: widget.label,
      prefixText: _isSearch ? null : widget.prefixText,
      prefixIcon: prefix == null ? null : Icon(prefix, size: 20),
      suffixIcon: suffix,
    );

    if (_isSearch) {
      // Frosted pill: keep the theme's border logic but round it to a pill and
      // tint the fill with the glass token for the iOS-style look.
      final pill = OutlineInputBorder(
        borderRadius: AppRadius.pillAll,
        borderSide: BorderSide(color: AppGlass.border(isDark), width: 1),
      );
      decoration = decoration.copyWith(
        isDense: true,
        filled: true,
        fillColor: AppGlass.surface(isDark),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: pill,
        enabledBorder: pill,
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.pillAll,
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
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
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
    );
  }
}
