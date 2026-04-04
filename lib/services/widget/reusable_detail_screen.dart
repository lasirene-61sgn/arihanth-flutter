import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_color/app_color.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';

/// Configuration object for a single field (Key: Value)
class DetailItem {
  final String label;
  final String? value;
  final bool copyable;
  // NEW: Optional image URL/Asset path
  final String? imageUrl;
  // NEW: Image size
  final double imageSize;

  DetailItem({
    required this.label,
    this.value,
    this.copyable = false,
    this.imageUrl, // <--- ADDED
    this.imageSize = 40, // <--- ADDED
  });
}

/// Configuration object for a group of fields (e.g., "Address Info")
class DetailSection {
  final String? title;
  final List<DetailItem> items;

  DetailSection({this.title, required this.items});
}
/// Configuration object for a group of fields (e.g., "Address Info")
class ReusableDetailView extends StatelessWidget {
  final String title;
  final List<DetailSection> sections;
  final VoidCallback? onBackPressed;
  final Widget? action;
  final double maxWidth;
  final bool isLoading;
  final bool showEmpty;

  const ReusableDetailView({
    super.key,
    required this.title,
    required this.sections,
    this.onBackPressed,
    this.action,
    this.maxWidth = 1000, // Max width for web centered view
    this.isLoading = false,
    this.showEmpty = false,
  });

  @override
  Widget build(BuildContext context) {

    bool  isMobile = MediaQuery.of(context).size.width < 600;
    // 1. Clean data: Filter out sections where all items are null/empty
    // Unless showEmpty is true, in which case we keep all items.
    final validSections = sections.map((section) {
      final validItems = section.items.where((item) {
        if (showEmpty) return true;
        // Keep item if it has a value OR an image to display
        return (item.value != null && item.value!.trim().isNotEmpty) ||
            item.imageUrl != null && item.imageUrl!.trim().isNotEmpty;
      }).toList();
      return DetailSection(title: section.title, items: validItems);
    }).where((section) => section.items.isNotEmpty).toList();

    if (validSections.isEmpty) {
      return _buildEmptyState(context);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Uses app's true theme
      appBar: isMobile ? AppBar(
        title: Text(title, style: const TextStyle(color: AppColor.white, fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: AppColor.appBarBackground, // Brand color
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColor.white),
        leading: onBackPressed != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBackPressed)
            : null,
        actions: action != null ? [action!] : null,
      ) : null,
      body: Column(
        children: [

          if(!isMobile)Container(
            width: double.infinity,
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 50),
            decoration: BoxDecoration(
              color: AppColor.appBarBackground, // Theme color
              border: Border(
                left: BorderSide(
                  color: AppColor.divider,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: AppColor.textPrimary),),
                if (action != null) action!,
              ],
            ),

          ),
          Expanded(
            child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: validSections.length,
                      itemBuilder: (context, index) {
                        return _buildSectionCard(context, validSections[index]);
                      },
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, DetailSection section) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? AppColor.primary : Colors.white),
        borderRadius: BorderRadius.circular(16), // Rounded premium corners
        boxShadow: isDark ? null : [ // no shadow in dark mode
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Softer, more premium shadow
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: isDark ? Border.all(color: AppColor.coolLavender.withOpacity(0.3), width: 1) // subtle border for dark mode
                       : Border.all(color: Colors.grey.shade100, width: 1), // Thinner, lighter border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title (if exists)
          if (section.title != null) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? (isDark ? AppColor.primary : Colors.white),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: isDark ? AppColor.coolLavender.withOpacity(0.3) : Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                   Container(
                     width: 4,
                     height: 16,
                     decoration: BoxDecoration(
                       color: AppColor.primary, // Brand accent
                       borderRadius: BorderRadius.circular(2),
                     ),
                   ),
                   const SizedBox(width: 10),
                   Text(
                     section.title!.toUpperCase(),
                     style: TextStyle(
                       color: theme.colorScheme.onSurface, // Uses scheme onSurface (white in dark mode)
                       fontSize: 14,
                       fontWeight: FontWeight.w700,
                       letterSpacing: 0.8,
                     ),
                   ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 24),

          // Grid of Items
          Padding(
            padding: EdgeInsets.fromLTRB(24, section.title != null ? 24 : 0, 24, 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive Logic:
                // If width > 600 (Tablet/Web), show 2 columns.
                // Otherwise (Mobile), show 1 column.
                final isWide = constraints.maxWidth > 600;

                return Wrap(
                  spacing: 24, // Horizontal gap
                  runSpacing: 28, // Vertical gap
                  children: section.items.map((item) {
                    return SizedBox(
                      // On web: 50% minus half the gap. On mobile: 100%
                      width: isWide
                          ? (constraints.maxWidth - 24) / 2
                          : constraints.maxWidth,
                      child: _buildDetailItem(context, item),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, DetailItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine if we show the image
    final bool hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    // Determine if we show the value
    final bool hasValue = item.value != null && item.value!.isNotEmpty;

    // Use a Row to align image and text vertically
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Image (if present)
        if (hasImage) ...[
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: item.imageSize,
                height: item.imageSize,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), // softer curve
                  border: Border.all(color: isDark ? AppColor.coolLavender.withOpacity(0.5) : Colors.grey.shade200, width: 1.5),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                ),
                child: GestureDetector(
                  onTap: () => FullScreenImageViewer.show(context, item.imageUrl!),
                  child: Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: isDark ? AppColor.darkNavy : Colors.grey.shade100, child: Icon(Icons.broken_image, size: 24, color: isDark ? Colors.white54 : Colors.grey)),
                  ),
                ),
              ),
              Positioned(
                bottom: -8,
                right: -8,
                child: Material(
                  color: AppColor.primary, // Brand color for primary actions
                  shape: const CircleBorder(),
                  elevation: 3,
                  shadowColor: AppColor.primary.withOpacity(0.4),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () async {
                      final Uri uri = Uri.parse(item.imageUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open image URL')),
                          );
                        }
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(Icons.download_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],

        // 2. Label and Value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: TextStyle(
                  color: isDark ? AppColor.coolLavender : Colors.grey[500], // themed muted color
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6), // slightly more space
              // Only build the InkWell/Value if there's a value
              if (hasValue) InkWell(
                onTap: item.copyable
                    ? () {
                  Clipboard.setData(ClipboardData(text: item.value!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: isDark ? AppColor.primary : Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text('${item.label} copied!', style: TextStyle(color: isDark ? AppColor.primary : Colors.white)),
                        ],
                      ), 
                      backgroundColor: isDark ? AppColor.surface : AppColor.textPrimary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      duration: const Duration(seconds: 2)
                    ),
                  );
                }
                    : null,
                borderRadius: BorderRadius.circular(4), // for ink splash
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        item.value!,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface, // theme color, white in dark mode
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.4, // Good line height for readability
                        ),
                      ),
                    ),
                    if (item.copyable) ...[
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Icons.copy_rounded, size: 14, color: isDark ? AppColor.coolLavender : Colors.grey[400]),
                      ),
                    ]
                  ],
                ),
              ),
              // If there's an image but no value, ensure there's a fallback placeholder
              if (!hasValue && !hasImage)
                Text(
                  '-',
                  style: TextStyle(
                    color: isDark ? AppColor.coolLavender.withOpacity(0.5) : Colors.grey[300],
                    fontSize: 15,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: AppColor.textPrimary)),
        backgroundColor: AppColor.appBarBackground,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 60, color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No details available",
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}