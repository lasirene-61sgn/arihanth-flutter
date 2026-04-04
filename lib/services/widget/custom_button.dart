import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;

  // 🔹 ENHANCEMENT 1 & 3: Simplified Icon and Size Control
  final IconData? iconData;
  final double iconSize; // Used with iconData
  final bool iconRight; // Controls icon position

  // 🔹 ENHANCEMENT 2: Small button flag for quick styling
  final bool isSmall;

  // Existing properties for padding and custom text style
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  // The original 'icon' widget is removed in favor of iconData,
  // but you can keep it if you need to pass a complex custom widget.
  // If keeping the original 'icon', adjust the constructor and logic.

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 12,
    this.fontSize = 16,
    this.fontWeight = FontWeight.bold,

    // 🔹 New properties in constructor
    this.iconData,
    this.iconSize = 18,
    this.iconRight = false,
    this.isSmall = false,

    this.padding,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Determine dynamic size based on isSmall flag
    final buttonHeight = isSmall ? 36.0 : (height ?? 50.0);
    final buttonFontSize = isSmall ? 14.0 : fontSize;
    final buttonRadius = isSmall ? 8.0 : borderRadius;

    // Create the icon widget if iconData is provided
    final Widget? buttonIcon = iconData != null
        ? Icon(
      iconData,
      size: iconSize,
      color: textColor ?? Theme.of(context).colorScheme.onPrimary,
    )
        : null;

    final textWidget = Text(
      text,
      style: textStyle ??
          TextStyle(
            fontSize: buttonFontSize,
            fontWeight: fontWeight,
            fontFamily: 'Times New Roman',
            color: textColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
    );

    // Build the list of children based on icon position
    List<Widget> children = [];
    
    if (text.isNotEmpty) {
      children.add(textWidget);
    }
    
    if (buttonIcon != null) {
      if (children.isEmpty) {
        children.add(buttonIcon);
      } else {
        if (iconRight) {
          children.addAll([
            const SizedBox(width: 8),
            buttonIcon,
          ]);
        } else {
          children.insertAll(0, [
            buttonIcon,
            const SizedBox(width: 8),
          ]);
        }
      }
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: textColor ?? Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          padding: padding ?? (isSmall ? const EdgeInsets.symmetric(horizontal: 8) : null),
          minimumSize: isSmall ? Size.zero : null,
          tapTargetSize: isSmall ? MaterialTapTargetSize.shrinkWrap : null,
          elevation: 2,
        ),
        child: isLoading
            ? SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(textColor ?? Theme.of(context).colorScheme.onPrimary),
          ),
        )
            : Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),


      ),
    );
  }
}