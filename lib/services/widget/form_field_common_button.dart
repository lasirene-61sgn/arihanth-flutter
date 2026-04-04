import 'package:arianth/app_color/app_color.dart';
import 'dart:async'; // Add this import for FutureOr
import 'package:flutter/material.dart';

class FormFeildCommonButton extends StatelessWidget {
  final String text;
  // Change VoidCallback? to Function()? to accept both sync and async functions
  final Function()? onPressed;
  final bool isLoading;
  final bool isViewBtn;
  final Color? backgroundColor;
  final Color? textColor;

  const FormFeildCommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isViewBtn = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveBg = backgroundColor ?? AppColor.primary;
    final Color effectiveText = textColor ?? AppColor.white;

    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBg,
          foregroundColor: effectiveText,
          disabledBackgroundColor: effectiveBg.withOpacity(0.6),
          disabledForegroundColor: effectiveText.withOpacity(0.6),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: isLoading
            ? SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveText),
                ),
              )
            : Text(
                text,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}