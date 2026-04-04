import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomInputField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final TextStyle? style;
  final InputDecoration? decoration;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextAlign textAlign;
  final bool hideCounterText;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final bool isLoading;
  final TextStyle? hintStyle;

  const CustomInputField({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines,
    this.maxLength,
    this.style,
    this.decoration,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.textAlign = TextAlign.start,
    this.hideCounterText = false,
    this.focusNode,
    this.inputFormatters,
    this.isLoading = false,
    this.hintStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Using Theme instead of hardcoded BoxDecoration for better consistency
    return TextFormField(
      focusNode: focusNode,
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      enabled: enabled,
      readOnly: readOnly,
      textAlign: textAlign,
      maxLines: maxLines ?? 1,
      maxLength: maxLength,
      style: style ?? theme.textTheme.bodyLarge,
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      decoration: (decoration ??
          InputDecoration(
            labelText: labelText,
            hintText: hintText,
            hintStyle: hintStyle,
            prefixIcon: prefixIcon != null 
              ? IconTheme(
                  data: IconThemeData(color: theme.colorScheme.primary), 
                  child: prefixIcon!
                )
              : null,
            suffixIcon: isLoading
                ? SizedBox(
                    width: 90,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Loading....",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  )
                : suffixIcon,
            counterText: hideCounterText ? '' : null,
          )),
    );
  }
}