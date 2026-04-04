import 'package:flutter/material.dart';
import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/services/widget/reuseable_dropdown.dart';

class WorkOrderDropdownWidget<T> extends StatelessWidget {
  final String label;
  final String fieldKeyName;
  final List<T> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;

  // Searchable properties
  final bool isSearchable;
  final bool allowNew;
  final Future<T?> Function(String)? onNewItemAdded;
  final String? hintText;
  final bool readOnly;
  final String Function(T)? itemLabel;
  final String Function(T)? selectedItemLabel;
  final bool isLoading;

  const WorkOrderDropdownWidget({
    super.key,
    required this.label,
    required this.fieldKeyName,
    required this.items,
    this.value,
    this.onChanged,
    this.validator,
    this.isSearchable = false,
    this.allowNew = false,
    this.onNewItemAdded,
    this.hintText,
    this.readOnly = false,
    this.itemLabel,
    this.selectedItemLabel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearchable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColor.black,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: WebSearchableDropdown<T>(
              items: items,
              itemLabel: itemLabel ?? (v) => v.toString(),
              selectedItemLabel: selectedItemLabel,
              selectedValue: value,
              hintText: hintText ?? 'Select $label',
              allowNew: allowNew,
              readOnly: readOnly,
              onChanged: onChanged,
              onNewItemAdded: onNewItemAdded,
              validator: validator,
            ),
          ),
        ],
      );
    }

    // Traditional Dropdown
    T? safeValue = value;
    if (value is String) {
      final strVal = (value as String).trim();
      safeValue = (strVal.isNotEmpty && items.contains(strVal as T)) ? (strVal as T) : null;
    } else {
      safeValue = items.contains(value) ? value : null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColor.black,
          ),
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: _inputDecoration().copyWith(
            errorText: validator?.call(safeValue),
          ),
          child: DropdownButtonHideUnderline(
            child: isLoading
                ? Row(
                    children: const [
                      SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Loading....",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  )
                : DropdownButton<T>(
                    value: safeValue,
                    hint: hintText != null
                        ? Text(
                            hintText!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColor.primary),
                          )
                        : null,
                    isDense: true,
                    isExpanded: true,
                    dropdownColor: AppColor.surface,
                    style: TextStyle(
                      color:
                          safeValue == null ? AppColor.primary : AppColor.black,
                      fontSize: 12,
                    ),
                    items: items
                        .map(
                          (e) => DropdownMenuItem<T>(
                            value: e,
                            child: Text(
                                itemLabel != null ? itemLabel!(e) : e.toString(),
                                style: const TextStyle(
                                    fontSize: 12, color: AppColor.black)),
                          ),
                        )
                        .toList(),
                    onChanged: readOnly ? null : onChanged,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: AppColor.textSecondary),
                  ),
          ),
        ),
        if (validator?.call(safeValue) != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              validator!(safeValue)!,
              style: const TextStyle(color: Colors.red, fontSize: 11),
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColor.divider, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColor.divider, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColor.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColor.error, width: 1.5),
      ),
      fillColor: readOnly ? AppColor.surface.withOpacity(0.5) : AppColor.surface,
      filled: true,
    );
  }
}
