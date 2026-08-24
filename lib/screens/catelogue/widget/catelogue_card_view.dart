import 'dart:async';
import 'dart:typed_data';
import 'package:arianth/screens/catelogue/model/catalogue_model.dart';
import 'package:arianth/screens/designs/model/designs_model.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:arianth/services/widget/pdf_thumbnail.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import '../../../app_color/app_color.dart';

class CatalogueGridCard extends StatefulWidget {
  final Catalogue item;
  final VoidCallback onTap;

  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  const CatalogueGridCard({
    super.key,
    required this.item,
    required this.onTap,
    this.isSelected = false,
    required this.onSelectionChanged,
  });

  @override
  State<CatalogueGridCard> createState() => _CatalogueGridCardState();
}

class _CatalogueGridCardState extends State<CatalogueGridCard> {
  bool _isSharing = false;
  late PageController _imageController;
  int _currentPage = 0;
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

  // ── Share Logic ──────────────────────────────────────────────────────────────
  Future<void> _shareViaWhatsApp() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    final String? role = SharedPreferencesHelper().getString("role");
    final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(role?.toLowerCase());
    final currentImageUrl = (widget.item.images?.isNotEmpty == true && _currentPage < (widget.item.images?.length ?? 0))
        ? widget.item.images![_currentPage].imageUrl
        : null;
    final isPdf = currentImageUrl?.toLowerCase().endsWith('.pdf') ?? false;

    await ShareCardService.share(
      context,
      ShareCardItem(
        imageUrl: currentImageUrl,
        isPdf: isPdf,
        title: widget.item.productName,
        productCode: widget.item.designCode,
        category: widget.item.category?.name.toString(),
        weight: widget.item.weightFrom != null ? '${widget.item.weightFrom}g' : null,
      ),
    );
    if (mounted) setState(() => _isSharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final String? role = SharedPreferencesHelper().getString("role");
    final ProductImage? firstImage = (widget.item.images?.isNotEmpty == true)
        ? widget.item.images!.first
        : null;
    final bool isPdf = firstImage?.imageUrl?.toLowerCase().contains('.pdf') ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.primary, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Media Section (Top) ---
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4),
                      color: AppColor.white,
                      child: Center(
                        child: _buildMediaContent(),
                      ),
                    ),
                    if (_latestImageCount > 1) ...[
                      if (_currentPage > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: AppColor.primary, size: 14),
                            onPressed: () {
                              if (_currentPage > 0) {
                                _imageController.animateToPage(_currentPage - 1,
                                    duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                              }
                            },
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      if (_currentPage < _latestImageCount - 1)
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, color: AppColor.primary, size: 14),
                            onPressed: () {
                              if (_currentPage < _latestImageCount - 1) {
                                _imageController.animateToPage(_currentPage + 1,
                                    duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                              }
                            },
                            padding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                    // WhatsApp Icon (Top Left)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: _shareViaWhatsApp,
                        child: _isSharing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.whatsapp),
                              )
                            : Image.asset('assets/image/whatsapp.png', width: 22, height: 22),
                      ),
                    ),
                    // Checkbox (Top Right)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: SizedBox(
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
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider Line
              Divider(height: 1, color: AppColor.border.withOpacity(0.5)),

              // --- Content Section (Bottom) ---
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Design Code Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: widget.item.designCode ?? '-'));
                            Toaster.showSuccess("Design Code copied to clipboard");
                            widget.onTap(); // Manually trigger detail navigation
                          },
                          child: Text(
                            widget.item.designCode ?? '-',
                            style: const TextStyle(
                              color: AppColor.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      // Size and Weight Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left side: Showing Category Name
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColor.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              // Direct path to category name with a fallback '-'
                              widget.item.category?.name ?? '-',
                              style: const TextStyle(
                                color: AppColor.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Right side: Weight (keeping this if you still want the second pill,
                          // or you can remove this entire Container if you ONLY want category)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColor.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${widget.item.weightFrom ?? '-'}g',
                              style: const TextStyle(
                                color: AppColor.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
      ),
    );
  }


  Widget _buildMediaContent() {
    final images = widget.item.images ?? [];
    _latestImageCount = images.length;

    if (_latestImageCount == 0) {
      return const Icon(Icons.image_outlined, color: AppColor.textHint, size: 40);
    }

    return PageView.builder(
      controller: _imageController,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
      },
      itemCount: _latestImageCount,
      itemBuilder: (context, index) {
        final imageUrl = images[index].imageUrl;
        final isPdf = imageUrl?.toLowerCase().endsWith('.pdf') ?? false;

        if (isPdf) {
          return PdfThumbnail(url: imageUrl ?? '');
        }
        
        return GestureDetector(
          onTap: () => FullScreenImageViewer.show(context, imageUrl!),
          child: Image.network(
            imageUrl ?? '',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image_outlined, color: AppColor.textHint, size: 40),
          ),
        );
      },
    );
  }
}