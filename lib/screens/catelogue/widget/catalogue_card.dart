import 'dart:async';
import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/catelogue/model/catalogue_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:arianth/services/widget/pdf_full_viewer_screen.dart';
import 'package:arianth/services/widget/pdf_thumbnail.dart';
import 'package:get/get.dart';
import '../../../../services/widget/full_screen_image_viewer.dart';

class CatalogueCard extends StatefulWidget {
  final Catalogue item;
  final VoidCallback onTap;

  const CatalogueCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<CatalogueCard> createState() => _CatalogueCardState();
}

class _CatalogueCardState extends State<CatalogueCard> {
  late PageController _imageController;
  int _currentPage = 0;
  bool _isSharing = false;
  Timer? _autoSlideTimer;
  int _latestImageCount = 0;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_latestImageCount > 1) {
        if (_currentPage < _latestImageCount - 1) {
          _imageController.animateToPage(
            _currentPage + 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          _imageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
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
    if (widget.item.images != null && widget.item.images!.isNotEmpty) {
      for (var img in widget.item.images!) {
        if (img.imageUrl != null && img.imageUrl!.isNotEmpty) {
          imageUrls.add(img.imageUrl!);
        }
      }
    }
    
    // Fallback to single productImage
    if (imageUrls.isEmpty && widget.item.productImage != null && widget.item.productImage!.isNotEmpty) {
      final path = widget.item.productImage!;
      imageUrls.add(path.startsWith('http') ? path : '${ApiClient.baseUrl}storage/$path');
    }

    final imageCount = imageUrls.length;
    _latestImageCount = imageCount;
    final String? role = SharedPreferencesHelper().getString("role");

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        color: AppColor.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColor.divider),
        ),
        elevation: 1,
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
                                  onTap: () => Get.to(() => PdfFullViewerScreen(url: url, title: widget.item.productName)),
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
                    Text(
                      widget.item.productName ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColor.textPrimary, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: widget.item.designCode ?? '-'));
                        Toaster.showSuccess("Design Code copied to clipboard");
                      },
                      child: Text(
                        'Design Code: ${widget.item.designCode ?? '-'}',
                        style: const TextStyle(color: AppColor.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      'BP Code: ${widget.item.bpCode ?? '-'}',
                      style: const TextStyle(color: AppColor.textSecondary, fontSize: 11),
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
                                  'Category: ${widget.item.category?.name ?? '-'}',
                                  style: const TextStyle(color: AppColor.textSecondary, fontSize: 11),
                                ),
                                if (widget.item.size != null && widget.item.size!.isNotEmpty)
                                  Text(
                                    'Size: ${widget.item.size}',
                                    style: const TextStyle(color: AppColor.textSecondary, fontSize: 11),
                                  ),
                                if (role?.toLowerCase() == 'super_admin' && widget.item.subcategory?.name != null)
                                  Text(
                                    'Subcategory: ${widget.item.subcategory?.name}',
                                    style: const TextStyle(color: AppColor.textSecondary, fontSize: 11),
                                  ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _isSharing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColor.primary,
                                ),
                              )
                            : IconButton(
                                icon: Image.asset('assets/image/whatsapp.png', width: 22, height: 22),
                                onPressed: () async {
                                  setState(() => _isSharing = true);
                                  try {
                                    final String? role = SharedPreferencesHelper().getString("role");
                                    final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(role?.toLowerCase());
                                      final currentUrl = (imageUrls.isNotEmpty && _currentPage < imageUrls.length)
                                          ? imageUrls[_currentPage]
                                          : null;
                                      final isPdf = currentUrl?.toLowerCase().endsWith('.pdf') ?? false;

                                      await ShareCardService.share(
                                        context,
                                        ShareCardItem(
                                          imageUrl: currentUrl,
                                          isPdf: isPdf,
                                          title: widget.item.productName,
                                          bpCode: widget.item.bpCode,
                                          productCode: widget.item.designCode,
                                          category: widget.item.category?.name,
                                          weight: widget.item.weightFrom != null ? '${widget.item.weightFrom}g' : null,
                                        ),
                                    );
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
