import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLength,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final IconData? prefixIcon;
  final int? maxLength;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      validator: validator,
      maxLength: maxLength,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon,
        counterText: '',
      ),
    );
  }
}
