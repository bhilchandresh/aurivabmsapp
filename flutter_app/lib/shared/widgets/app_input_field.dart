import 'package:flutter/material.dart';
import '../../core/theme/app_extensions.dart';

class AppInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final int maxLines;

  const AppInputField({
    super.key,
    required this.label,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final bodyMediumColor = Theme.of(context).textTheme.bodyMedium?.color;
    final bodyLargeColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label.toUpperCase(),
            style: context.typography.inputLabel.copyWith(
              fontWeight: FontWeight.bold,
              color: bodyMediumColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          maxLines: maxLines,
          style: context.typography.inputText.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: bodyLargeColor,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: context.typography.searchHint.copyWith(
              fontSize: 16,
              color: bodyMediumColor,
            ),
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: IconTheme(
                      data: IconThemeData(
                        color: bodyMediumColor,
                      ),
                      child: prefixIcon!,
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            suffixIcon: suffixIcon != null
                ? IconTheme(
                    data: IconThemeData(
                      color: bodyMediumColor,
                    ),
                    child: suffixIcon!,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
