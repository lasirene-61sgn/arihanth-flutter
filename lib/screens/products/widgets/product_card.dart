import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/products/model/products_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/widget/form_field_common_button.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:flutter/material.dart';
import 'package:arianth/services/widget/pdf_thumbnail.dart';
import '../../../../services/widget/full_screen_image_viewer.dart';
import 'package:arianth/services/widget/pdf_full_viewer_screen.dart';
import '../../../services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/pdf_thumbnail.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;
  final VoidCallback onEdit;
  final Future<void> Function() onShare;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.isSelected = false,
    this.onSelectionChanged,
    required this.onEdit,
    required this.onShare,
    this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late PageController _imageController;
  int _currentPage = 0;
  String? role;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
    role = SharedPreferencesHelper().getString("role") ?? '';
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  void _nextPage(int count) {
    if (_currentPage < count - 1) {
      _imageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _imageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Collect all image URLs
    final List<String> imageUrls = [];
    if (widget.product.images != null && widget.product.images!.isNotEmpty) {
      for (var img in widget.product.images!) {
        if (img.imageUrl != null && img.imageUrl!.isNotEmpty) {
          imageUrls.add(img.imageUrl!);
        }
      }
    }
    
    // Fallback to single productImage if gallery is empty
    if (imageUrls.isEmpty && widget.product.productImage != null && widget.product.productImage!.isNotEmpty) {
      final path = widget.product.productImage!;
      imageUrls.add(path.startsWith('http') ? path : '${ApiClient.baseUrl}storage/$path');
    }

    final imageCount = imageUrls.length;

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        color: AppColor.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: widget.isSelected ? AppColor.primary : AppColor.divider,
            width: widget.isSelected ? 2 : 1,
          ),
        ),
        elevation: 2,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Image PageView
            SizedBox(
              width: 110,
              height: 180,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColor.background,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                    ),
                    child: imageCount > 0
                        ? PageView.builder(
                            controller: _imageController,
                            onPageChanged: (index) {
                              setState(() => _currentPage = index);
                            },
                            itemCount: imageCount,
                            itemBuilder: (context, index) {
                              final url = imageUrls[index];
                              final isPdf = url.toLowerCase().endsWith('.pdf');

                              if (isPdf) {
                                return GestureDetector(
                                  onTap: () => Get.to(() => PdfFullViewerScreen(url: url, title: widget.product.productName)),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                    child: PdfThumbnail(url: url, fit: BoxFit.contain),
                                  ),
                                );
                              }

                              return GestureDetector(
                                onTap: () => FullScreenImageViewer.show(context, url),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) => const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: AppColor.textHint,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : const Center(child: Icon(Icons.image, color: AppColor.textHint, size: 30)),
                  ),
                  // Navigation Arrows Overlay
                  if (imageCount > 1) ...[
                    if (_currentPage > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: AppColor.primary, size: 18),
                          onPressed: _previousPage,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    if (_currentPage < imageCount - 1)
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, color: AppColor.primary, size: 18),
                          onPressed: () => _nextPage(imageCount),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    // Image Indicator
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_currentPage + 1} / $imageCount',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Right Side: Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.onSelectionChanged != null)
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: Transform.scale(
                              scale: 1.2,
                              child: Checkbox(
                                value: widget.isSelected,
                                onChanged: widget.onSelectionChanged,
                                activeColor: AppColor.primary,
                                   checkColor: AppColor.textWhite,
                                side: const BorderSide(color: AppColor.black, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: widget.product.productName ?? ''));
                                  Toaster.showSuccess('Copied: ${widget.product.productName}');
                                },
                                child: Text(
                                  widget.product.productName ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColor.textPrimary, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 5),
                              if(widget.product.productCode != null) 
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: widget.product.productCode ?? ''));
                                    Toaster.showSuccess('Copied: ${widget.product.productCode}');
                                  },
                                  child: Text(
                                    'Code: ${widget.product.productCode ?? '-'}',
                                    style: const TextStyle(color: AppColor.textSecondary, fontSize: 12),
                                  ),
                                ),
                              if (!['buyer', 'key_user', 'user'].contains(role?.toLowerCase()))
                                Text(
                                  'BP Code: ${widget.product.bpCode ?? '-'}',
                                  style: const TextStyle(color: AppColor.textSecondary, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Specs Block
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category: ${widget.product.category?.name ?? '-'}',
                            style: const TextStyle(color: AppColor.textSecondary, fontSize: 11),
                          ),
                          Text(
                            'Subcategory: ${widget.product.subcategory?.name ?? '-'}',
                            style: const TextStyle(color: AppColor.textSecondary, fontSize: 11),
                          ),
                          if (widget.product.weightFrom != null)
                            Text(
                              'Weight: ${widget.product.weightFrom}g ${widget.product.weightTo != null ? "- ${widget.product.weightTo}g" : ""}',
                              style: const TextStyle(color: AppColor.primary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                      
                          SizedBox(
                            height: 28,
                            child: FormFeildCommonButton(
                              text: "Edit",
                              onPressed: widget.onEdit,
                            ),
                          ),
                        if (role?.toLowerCase() != "craftsman")
                          const SizedBox(width: 10),
                        _isSharing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColor.primary,
                                ),
                              )
                            : IconButton(
                                icon: Image.asset('assets/image/whatsapp.png', width: 24, height: 24),
                                onPressed: () async {
                                  setState(() => _isSharing = true);
                                  try {
                                    await widget.onShare();
                                  } finally {
                                    if (mounted) setState(() => _isSharing = false);
                                  }
                                },
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
