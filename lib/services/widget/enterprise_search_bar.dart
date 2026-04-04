import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arianth/app_color/app_color.dart';

class EnterpriseSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onChanged;
  final VoidCallback onCancel;
  final bool autofocus;

  const EnterpriseSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onCancel,
    this.autofocus = true,
  });

  @override
  State<EnterpriseSearchBar> createState() => _EnterpriseSearchBarState();
}

class _EnterpriseSearchBarState extends State<EnterpriseSearchBar> {
  Timer? _debounce;

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onChanged(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColor.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        autofocus: widget.autofocus,
        onChanged: _onChanged,
        style: const TextStyle(
          color: AppColor.textPrimary,
          fontSize: 14,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 13),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: AppColor.textHint, size: 18),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: IconButton(
            icon: const Icon(Icons.cancel, size: 18, color: AppColor.textHint),
            onPressed: widget.onCancel,
          ),
        ),
      ),
    );
  }
}
