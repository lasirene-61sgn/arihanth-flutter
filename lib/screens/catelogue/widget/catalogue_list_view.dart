import 'dart:async';
import 'dart:math' as math;
import 'package:arianth/screens/catelogue/riverpod/catalogue_notifier.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/pdf_full_viewer_screen.dart';
import 'package:arianth/services/widget/pdf_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../../app_color/app_color.dart';
import '../../../../services/widget/full_screen_image_viewer.dart';
import '../model/catalogue_model.dart';

class CatalogueListView extends ConsumerStatefulWidget {
  final Set<String> selectedIds;
  final Function(String, bool) onSelectionChanged;

  const CatalogueListView({
    super.key,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<CatalogueListView> createState() => _CatalogueListViewState();
}

class _CatalogueListViewState extends ConsumerState<CatalogueListView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogueProvider);

    if (state.isLoading && state.catalogues.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColor.primary));
    }

    if (state.catalogues.isEmpty) {
      return const Center(child: Text("No catalogues found", style: TextStyle(color: AppColor.textPrimary)));
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: state.isLoading ? state.catalogues.length + 1 : state.catalogues.length,
      itemBuilder: (context, index) {
        if (index == state.catalogues.length) {
          return const Center(child: CircularProgressIndicator(color: AppColor.primary));
        }
        final item = state.catalogues[index];
        return _CataloguePageItem(
          item: item,
          isSelected: widget.selectedIds.contains(item.id.toString()),
          onSelectionChanged: (selected) {
            widget.onSelectionChanged(item.id.toString(), selected ?? false);
          },
        );
      },
    );
  }
}

class _CataloguePageItem extends StatefulWidget {
  final Catalogue item; // Using dynamic or Catalogue model if available
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  const _CataloguePageItem({
    required this.item,
    this.isSelected = false,
    required this.onSelectionChanged,
  });

  @override
  State<_CataloguePageItem> createState() => _CataloguePageItemState();
}

class _CataloguePageItemState extends State<_CataloguePageItem>
    with SingleTickerProviderStateMixin {
  late PageController _imageController;
  int _currentImageIndex = 0;
  late AnimationController _rotationController;
  Timer? _autoSlideTimer;
  int _latestImageCount = 0;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_latestImageCount > 1) {
        if (_currentImageIndex < _latestImageCount - 1) {
          _imageController.animateToPage(
            _currentImageIndex + 1,
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
    final String? role = SharedPreferencesHelper().getString("role");
    final List<String> imageUrls = [];
    if (widget.item.images != null && widget.item.images!.isNotEmpty) {
      for (var img in widget.item.images!) {
        if (img.imageUrl != null && img.imageUrl!.isNotEmpty) {
          imageUrls.add(img.imageUrl!);
        }
      }
    }
    
    if (imageUrls.isEmpty && widget.item.productImage != null && widget.item.productImage!.isNotEmpty) {
      final path = widget.item.productImage!;
      imageUrls.add(path.startsWith('http') ? path : '${ApiClient.baseUrl}storage/$path');
    }

    _latestImageCount = imageUrls.length;

    return Column(
      children: [
        
        Expanded(
          flex: 7,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                color: AppColor.surface,
                child: imageUrls.isEmpty
                    ? const Center(child: Icon(Icons.image, size: 80, color: AppColor.textHint))
                    : PageView.builder(
                        controller: _imageController,
                        onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                        itemCount: imageUrls.length,
                        itemBuilder: (context, idx) {
                          final url = imageUrls[idx];
                          final isPdf = url.toLowerCase().endsWith('.pdf');

                          if (isPdf) {
                            return GestureDetector(
                              onTap: () => Get.to(() => PdfFullViewerScreen(url: url, title: widget.item.productName)),
                              child: PdfThumbnail(url: url, fit: BoxFit.contain),
                            );
                          }

                          return GestureDetector(
                            onTap: () => FullScreenImageViewer.show(context, url),
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
                                      offset: Offset(yaw * 20, -4),
                                      child: Container(
                                        width: 80 + (1 - yaw.abs()) * 25,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(Radius.elliptical(60, 6)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.12),
                                              blurRadius: 8,
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
                                url,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  final total = loadingProgress.expectedTotalBytes;
                                  final loaded = loadingProgress.cumulativeBytesLoaded;
                                  final double? progress = total != null && total > 0 ? loaded / total : null;

                                  return Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        value: progress,
                                        strokeWidth: 2.5,
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppColor.primary),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 50)),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Image Progress Indicator
              if (imageUrls.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      imageUrls.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == index ? AppColor.primary : AppColor.divider,
                        ),
                      ),
                    ),
                  ),
                ),
              // Share Button (Floating in image area or top right)
              Positioned(
                top: 16,
                right: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  child: IconButton(
                    icon: Image.asset('assets/image/whatsapp.png', width: 24, height: 24),
                    onPressed: () {
                      final role = SharedPreferencesHelper().getString("role");
                      final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(role?.toLowerCase());
                      ShareCardService.share(
                        context,
                        ShareCardItem(
                          imageUrl: imageUrls.isNotEmpty ? imageUrls[0] : null,
                          title: widget.item.productName,
                          bpCode: restricted ? null : widget.item.bpCode,
                          productCode: restricted ? null : widget.item.designCode,
                          category: widget.item.category?.name,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Selection Checkbox (Top Left)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
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
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom 30%: Details Section
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5)),
              ],
            ),
            child: InkWell(
              onTap: () => Get.toNamed(AppRoutes.catalogueDetails, arguments: widget.item.id?.toString()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.category?.name ?? '-',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.item.designCode ?? '-',
                          style: const TextStyle(color: AppColor.primary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text("${widget.item.weightFrom ?? '-'} GM",
                    style: TextStyle(color: AppColor.textSecondary, fontSize: 16),
                  ),
                  const Spacer(),
                  const Center(
                    child: Icon(Icons.keyboard_arrow_down, color: AppColor.divider),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
