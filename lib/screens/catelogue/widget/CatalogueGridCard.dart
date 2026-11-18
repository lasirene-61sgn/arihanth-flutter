import 'dart:async';
import 'dart:math' as math;
import 'package:arianth/screens/catelogue/model/catalogue_model.dart';
import 'package:arianth/services/widget/pdf_thumbnail.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';
import 'package:flutter/material.dart';
import '../../../app_color/app_color.dart';

class CatalogueGridCard extends StatefulWidget {
  final Catalogue item;
  final VoidCallback onTap;

  const CatalogueGridCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<CatalogueGridCard> createState() => _CatalogueGridCardState();
}

class _CatalogueGridCardState extends State<CatalogueGridCard>
    with SingleTickerProviderStateMixin {
  late PageController _imageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;
  String? role;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role");
    _imageController = PageController();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final images = widget.item.images ?? [];
      final imageCount = images.isNotEmpty ? images.length : (widget.item.productImage != null ? 1 : 0);
      if (imageCount > 1) {
        if (_currentPage < imageCount - 1) {
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

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        color: AppColor.white, // Pure white for cards
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.border, width: 1), // Standardized border
        boxShadow: [
          BoxShadow(
            // Use Primary (Midnight Navy) for a very subtle, professional shadow
            color: AppColor.primary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media Section
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: AppColor.surface, 
                      child: _buildMediaContent(context),
                    ),
                    if ((widget.item.images?.length ?? 0) > 1) ...[
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
                      if (_currentPage < (widget.item.images?.length ?? 0) - 1)
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, color: AppColor.primary, size: 14),
                            onPressed: () {
                              final count = widget.item.images?.length ?? 0;
                              if (_currentPage < count - 1) {
                                _imageController.animateToPage(_currentPage + 1,
                                    duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                              }
                            },
                            padding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ],
                ),
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.productName?.toUpperCase() ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColor.textPrimary,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role?.toLowerCase() == 'super_admin'
                          ? (widget.item.category?.name ?? '')
                          : ((widget.item.size != null && widget.item.size!.isNotEmpty)
                              ? widget.item.size!
                              : (widget.item.category?.name ?? '-')),
                      style: const TextStyle(
                        color: AppColor.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding:  EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColor.secondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.item.designCode ?? '-',
                            style:  TextStyle(
                              fontSize: 10,
                              color: AppColor.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusIcon(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    bool isAccepted = widget.item.designStatus == "Accept" || widget.item.designStatus == "Accepted";
    return Icon(
      isAccepted ? Icons.check_circle_rounded : Icons.pending_rounded,
      size: 18,
      color: isAccepted ? AppColor.success : AppColor.warning,
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    final images = widget.item.images ?? [];
    final imageCount = images.isNotEmpty ? images.length : (widget.item.productImage != null ? 1 : 0);

    if (imageCount == 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, color: AppColor.textSecondary, size: 30),
          const SizedBox(height: 4),
          Text(
            "Empty",
            style: TextStyle(fontSize: 12, color: AppColor.textSecondary, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    return PageView.builder(
      controller: _imageController,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
      },
      itemCount: imageCount,
      itemBuilder: (context, index) {
        final imageUrl = images.isNotEmpty ? images[index].imageUrl : widget.item.productImage;
        final isPdf = imageUrl?.toLowerCase().endsWith('.pdf') ?? false;

        if (isPdf) {
          return PdfThumbnail(url: imageUrl!, fit: BoxFit.contain);
        }

        return GestureDetector(
          onTap: () => FullScreenImageViewer.show(context, imageUrl!),
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              final double progress = _rotationController.value * 2 * math.pi;
              final double yaw = math.sin(progress) * 0.38;
              final double pitch = math.cos(progress * 2) * 0.04;
              final double lightShift = math.sin(progress);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0018)
                        ..rotateY(yaw)
                        ..rotateX(pitch),
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          child!,
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
                  Transform.translate(
                    offset: Offset(yaw * 16, -2),
                    child: Container(
                      width: 58 + (1 - yaw.abs()) * 20,
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.elliptical(50, 6)),
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
              imageUrl!,
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
                  const Icon(Icons.broken_image_outlined, color: AppColor.textSecondary, size: 30),
            ),
          ),
        );
      },
    );
  }
}