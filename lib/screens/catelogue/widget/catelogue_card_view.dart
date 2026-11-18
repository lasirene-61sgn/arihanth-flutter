import 'dart:async';
import 'dart:math' as math;
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

class _CatalogueGridCardState extends State<CatalogueGridCard>
    with SingleTickerProviderStateMixin {
  bool _isSharing = false;
  late PageController _imageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;
  int _latestImageCount = 0;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();

    // 3D continuous rotation animation (smooth natural turntable rotation around Y-axis)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

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
    _rotationController.dispose();
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
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              final double progress = _rotationController.value * 2 * math.pi;
              // Primary natural Y-axis turntable rotation (~22 degrees)
              final double yaw = math.sin(progress) * 0.38;
              // Subtle natural vertical breathing/pitch (~2.5 degrees)
              final double pitch = math.cos(progress * 2) * 0.04;
              // Dynamic light reflection/sheen shift (-1.0 to 1.0)
              final double lightShift = math.sin(progress);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0018) // Realistic depth perspective
                        ..rotateY(yaw)           // Horizontal turntable
                        ..rotateX(pitch),        // Micro-pitch
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          child!,
                          // Dynamic specular highlight reflection for natural 3D lighting
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: LinearGradient(
                                    begin: Alignment(-1.0 + lightShift * 0.6, -1.0),
                                    end: Alignment(1.0 + lightShift * 0.6, 1.0),
                                    colors: [
                                      Colors.white.withValues(alpha: (0.16 + lightShift.abs() * 0.12).clamp(0.0, 0.3)),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: (0.05 + (-lightShift).clamp(0.0, 1.0) * 0.08)),
                                    ],
                                    stops: const [0.0, 0.45, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Natural 3D ground shadow that responds to rotation angle
                  Transform.translate(
                    offset: Offset(yaw * 16, -2),
                    child: Container(
                      width: 58 + (1 - yaw.abs()) * 20,
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.elliptical(50, 6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 7,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            child: Image.network(
              imageUrl ?? '',
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                final total = loadingProgress.expectedTotalBytes;
                final loaded = loadingProgress.cumulativeBytesLoaded;
                final double? progress = total != null && total > 0 ? loaded / total : null;

                return Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColor.primary),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image_outlined, color: AppColor.textHint, size: 40),
            ),
          ),
        );
      },
    );
  }
}