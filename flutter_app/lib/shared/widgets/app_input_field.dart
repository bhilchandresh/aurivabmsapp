import 'package:flutter/material.dart';
import '../../core/theme/app_extensions.dart';

class AppInputField extends StatelessWidget {
  final String? label;
  final String hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final int maxLines;
  final double fontSize;
  final bool filled;
  final Color? fillColor;
  final double contentPaddingVertical;
  final double? labelFontSize;

  const AppInputField({
    super.key,
    this.label,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.fontSize = 16,
    this.filled = false,
    this.fillColor,
    this.contentPaddingVertical = 16.0,
    this.labelFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final bodyMediumColor = Theme.of(context).textTheme.bodyMedium?.color;
    final bodyLargeColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null && label!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: label!.endsWith('*')
                ? RichText(
                    text: TextSpan(
                      text: label!.substring(0, label!.length - 1).toUpperCase(),
                      style: context.typography.inputLabel.copyWith(
                        fontWeight: FontWeight.bold,
                        color: bodyMediumColor,
                        letterSpacing: 0.5,
                        fontSize: labelFontSize,
                      ),
                      children: const [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : Text(
                    label!.toUpperCase(),
                    style: context.typography.inputLabel.copyWith(
                      fontWeight: FontWeight.bold,
                      color: bodyMediumColor,
                      letterSpacing: 0.5,
                      fontSize: labelFontSize,
                    ),
                  ),
          ),
        TextFormField(
          onChanged: onChanged,
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          maxLines: maxLines,
          style: context.typography.inputText.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: bodyLargeColor,
          ),
          decoration: InputDecoration(
            filled: filled,
            fillColor: fillColor,
            border: filled ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
            ) : null,
            enabledBorder: filled ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
            ) : null,
            focusedBorder: filled ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade500, width: 1.5),
            ) : null,
            hintText: hintText,
            hintStyle: context.typography.searchHint.copyWith(
              fontSize: fontSize,
              color: bodyMediumColor,
            ),
            prefixIcon: prefixIcon != null
                ? Container(
                    width: 42,
                    alignment: maxLines > 1 ? Alignment.topCenter : Alignment.center,
                    padding: EdgeInsets.only(
                      top: maxLines > 1 ? 16 : 0,
                    ),
                    child: IconTheme(
                      data: IconThemeData(
                        color: bodyMediumColor,
                      ),
                      child: prefixIcon!,
                    ),
                  )
                : null,
            prefixIconConstraints: BoxConstraints(
              minWidth: 40,
              minHeight: maxLines > 1 ? (maxLines * 24.0) : 40,
            ),
            suffixIcon: suffixIcon != null
                ? IconTheme(
                    data: IconThemeData(
                      color: bodyMediumColor,
                    ),
                    child: suffixIcon!,
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: contentPaddingVertical,
            ),
          ),
        ),
      ],
    );
  }
}
