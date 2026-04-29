import 'package:flutter/material.dart';
import '../../app_color/app_color.dart';
import 'custom_button.dart';

class PaginationControls extends StatelessWidget {
  final int count;
  final int? currentCount;
  final String label;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool isFirstPage;
  final bool isLastPage;
  final String? loadedLabel;
  final bool isLoading;

  const PaginationControls({
    super.key,
    required this.count,
    this.currentCount,
    required this.label,
    required this.onNext,
    required this.onPrevious,
    required this.isFirstPage,
    required this.isLastPage,
    this.loadedLabel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.background,
        border: Border(top: BorderSide(color: AppColor.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🔹 Total Count Display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$label: $count',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColor.sidebarColor == AppColor.white ? AppColor.jetBlack : AppColor.sidebarColor,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (currentCount != null)
                  Text(
                    '${loadedLabel ?? "Loaded Catalogue"}: $currentCount',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColor.textHint,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          Row(
            children: [
              CustomButton(
                width: isMobile ? 50 : 120,
                text: isMobile ? "" : 'Previous',
                iconData: Icons.arrow_back_ios_new,
                iconSize: 14,
                onPressed: isFirstPage || isLoading ? null : onPrevious,
                isSmall: true,
                backgroundColor: isFirstPage || isLoading ? AppColor.divider : AppColor.primary,
                textColor: isFirstPage || isLoading ? AppColor.textHint : AppColor.textWhite,
              ),
              const SizedBox(width: 12),
              CustomButton(
                width: isMobile ? 50 : 100,
                text: isMobile ? "" : 'Next',
                iconData: Icons.arrow_forward_ios,
                iconSize: 14,
                iconRight: true,
                onPressed: isLastPage || isLoading ? null : onNext,
                isSmall: true,
                backgroundColor: isLastPage || isLoading ? AppColor.divider : AppColor.primary,
                textColor: isLastPage || isLoading ? AppColor.textHint : AppColor.textWhite,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
