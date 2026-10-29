import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.error,
    this.helper,
    this.padding = const EdgeInsets.only(bottom: 18),
  });

  final String label;
  final Widget child;
  final String? error;
  final String? helper;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTextStyles.smallMedium.copyWith(color: AppColors.ink2),
          ),
          const SizedBox(height: 7),
          child,
          if (error != null && error!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              error!,
              style: AppTextStyles.smallMedium.copyWith(color: AppColors.bad),
            ),
          ],
          if (helper != null && helper!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              helper!,
              style: AppTextStyles.small.copyWith(color: AppColors.ink3),
            ),
          ],
        ],
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.autofillHints,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.errorText,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final TextStyle? style;
  final TextAlign textAlign;
  final int maxLines;
  final String? errorText;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      enabled: enabled,
      autofillHints: autofillHints,
      textAlign: textAlign,
      maxLines: obscureText ? 1 : maxLines,
      style: style ?? AppTextStyles.body.copyWith(color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: suffixIcon,
        errorText: errorText,
        suffixIconColor: AppColors.ink3,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.hintText = 'Mínimo 8 caracteres',
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.focusNode,
    this.autofillHints = const <String>[AutofillHints.password],
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      hintText: widget.hintText,
      obscureText: _hidden,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      errorText: widget.errorText,
      autofillHints: widget.autofillHints,
      suffixIcon: IconButton(
        onPressed: () => setState(() => _hidden = !_hidden),
        tooltip: _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
        icon: Icon(_hidden ? LucideIcons.eye : LucideIcons.eyeOff, size: 19),
      ),
    );
  }
}

class CodeField extends StatelessWidget {
  const CodeField({
    super.key,
    required this.controller,
    this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hintText: 'A B C D 1 2 3 4',
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      onChanged: onChanged,
      errorText: errorText,
      style: AppTextStyles.h3.copyWith(
        fontFamily: AppTextStyles.mono,
        letterSpacing: 5,
      ),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
        LengthLimitingTextInputFormatter(8),
        TextInputFormatter.withFunction((
          TextEditingValue oldValue,
          TextEditingValue newValue,
        ) {
          return newValue.copyWith(text: newValue.text.toUpperCase());
        }),
      ],
    );
  }
}
