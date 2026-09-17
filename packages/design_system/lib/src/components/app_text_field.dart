import 'package:flutter/material.dart';

/// An outlined Material form field that preserves caller-owned input on errors.
final class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.helperText,
    this.errorText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.autovalidateMode = AutovalidateMode.disabled,
    super.key,
  }) : assert(controller == null || initialValue == null),
       assert(!obscureText || maxLines == 1);

  final String label;
  final TextEditingController? controller;
  final String? initialValue, helperText, errorText, hintText;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged, onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool obscureText, enabled, readOnly;
  final int? maxLines;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    initialValue: initialValue,
    focusNode: focusNode,
    validator: validator,
    onChanged: onChanged,
    onFieldSubmitted: onSubmitted,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    textCapitalization: textCapitalization,
    autofillHints: autofillHints,
    obscureText: obscureText,
    enabled: enabled,
    readOnly: readOnly,
    maxLines: maxLines,
    autovalidateMode: autovalidateMode,
    style: Theme.of(context).textTheme.bodyLarge,
    decoration: InputDecoration(
      labelText: label,
      helperText: helperText,
      hintText: hintText,
      errorText: errorText,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      helperMaxLines: 4,
    ),
  );
}
