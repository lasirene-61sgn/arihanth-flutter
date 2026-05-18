
import 'package:arianth/app_color/app_color.dart';
import 'dart:ui'; // Added import for ImageFilter
import 'package:arianth/screens/designs/model/designs_model.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:arianth/services/widget/form_field_common_button.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:arianth/services/widget/pdf_thumbnail.dart';
import '../../../../services/widget/full_screen_image_viewer.dart';
import 'package:arianth/services/widget/pdf_full_viewer_screen.dart'; // Added import
import 'package:get/get.dart'; // Added import

class DesignCard extends StatefulWidget {
  final Design design;
  final String? role;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;
  final VoidCallback onEdit;
  final Future<void> Function() onShare;
  final VoidCallback onApprove;
  final bool isApproving;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const DesignCard({
    super.key,
    required this.design,
    this.role,
    this.isSelected = false,
    this.onSelectionChanged,
    required this.onEdit,
    required this.onShare,
    required this.onApprove,
    this.isApproving = false,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.showQrCode = true,
  });

  final bool showQrCode;

  @override
  State<DesignCard> createState() => _DesignCardState();
}

class _DesignCardState extends State<DesignCard> {
  late PageController _imageController;
  int _currentPage = 0;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final images = widget.design.images ?? [];
    if (_currentPage < images.length - 1) {
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
    final images = widget.design.images ?? [];
    final imageCount = images.length;

    return GestureDetector(
      onTap: (){
        widget.onEdit();
      },
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
        child: Stack(
          children: [
            Row(
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
                                  final imageUrl = widget.design.images?[index].imageUrl;

                                  if (imageUrl != null && imageUrl.toLowerCase().endsWith('.pdf')) {
                                    return GestureDetector(
                                      onTap: () {
                                        Get.to(() => PdfFullViewerScreen(url: imageUrl, title: widget.design.designName));
                                      },
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          ImageFiltered(
                                            imageFilter: (widget.design.isLocked == 1 && widget.role?.toLowerCase() != 'super_admin')
                                                ? ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0)
                                                : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                              child: PdfThumbnail(url: imageUrl, fit: BoxFit.contain),
                                            ),
                                          ),
                                          if (widget.design.isLocked == 1 && widget.role?.toLowerCase() != 'super_admin')
                                            Image.asset('assets/image/tara_text_bg.png', width: 40, height: 40, fit: BoxFit.contain),
                                        ],
                                      ),
                                    );
                                  }

                                  return imageUrl != null && imageUrl.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () => FullScreenImageViewer.show(context, imageUrl),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              ImageFiltered(
                                                imageFilter: (widget.design.isLocked == 1 && widget.role?.toLowerCase() != 'super_admin')
                                                    ? ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0)
                                                    : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
                                                child: ClipRRect(
                                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                                  child: Image.network(
                                                    imageUrl,
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
                                                    errorBuilder: (context, error, stackTrace) => Center(
                                                      child: const Icon(
                                                        Icons.image_not_supported,
                                                        color: AppColor.textHint,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (widget.design.isLocked == 1 && widget.role?.toLowerCase() != 'super_admin')
                                                Image.asset('assets/image/tara_logo_color.jpeg', width: 40, height: 40, fit: BoxFit.contain),
                                            ],
                                          ),
                                        )
                                      : Center(child: const Icon(Icons.image, color: Colors.white24, size: 30));
                                },
                              )
                            : Center(child: const Icon(Icons.image, color: Colors.white24, size: 30)),
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
                              onPressed: _nextPage,
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
                      if (widget.onFavoriteToggle != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: widget.onFavoriteToggle,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: Colors.red,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              const TextSpan(text: 'DESIGN: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.textPrimary, fontSize: 13)),
                                              TextSpan(text: widget.design.designName ?? '', style: const TextStyle(color: AppColor.textPrimary, fontSize: 13)),
                                            ],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      _buildStatusBadge(widget.design.designStatus),
                                    ],
                                  ),
                                  if (!['buyer', 'key_user', 'user'].contains(widget.role?.toLowerCase())) ...[
                                    const SizedBox(height: 5),
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: widget.design.designCode ?? '-'));
                                        Toaster.showSuccess("Design Code copied to clipboard");
                                      },
                                      child: Text(
                                        'Code: ${widget.design.designCode ?? '-'}',
                                        style: const TextStyle(color: AppColor.textSecondary, fontSize: 12),
                                      ),
                                    ),
                                    Text(
                                      'Client: ${widget.design.bpCode ?? '-'}',
                                      style: const TextStyle(color: AppColor.textSecondary, fontSize: 12),
                                    ),
                                  ],
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
                              if (widget.role?.toLowerCase() == 'super_admin') ...[
                                Text(
                                  'Category: ${widget.design.category ?? '-'}',
                                  style: const TextStyle(color: AppColor.textSecondary, fontSize: 11),
                                ),
                                Text(
                                  'Subcategory: ${widget.design.subCategory ?? '-'}',
                                  style: const TextStyle(color: AppColor.textSecondary, fontSize: 11),
                                ),
                                if (widget.design.weightFrom != null)
                                  Text(
                                    'Weight: ${widget.design.weightFrom}g',
                                    style: const TextStyle(color: AppColor.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                              ] else ...[
                                Text(
                                  (widget.design.size != null && widget.design.size!.isNotEmpty)
                                      ? widget.design.size!
                                      : (widget.design.category ?? '-'),
                                  style: const TextStyle(color: AppColor.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                if (widget.design.weightFrom != null)
                                  Text(
                                    '${widget.design.weightFrom}g',
                                    style: const TextStyle(color: AppColor.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (widget.role == 'super_admin' && widget.design.designStatus?.toLowerCase() == 'pending')
                              SizedBox(
                                height: 28,
                                child: ElevatedButton(
                                  onPressed: widget.isApproving ? null : widget.onApprove,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColor.primary,
                                    foregroundColor: AppColor.textWhite,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: widget.isApproving
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.textWhite),
                                        )
                                      : const Text('Approve', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            const SizedBox(width: 8),

                            if (widget.design.isLocked != 1 && widget.role?.toLowerCase() == 'super_admin')
                              _isSharing
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColor.primary,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // WhatsApp Icon
                                        IconButton(
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
                                        
                                        // QR Code Icon (Only if qrImageUrl is not empty, status is accepted and showQrCode is true)
                                        if (widget.showQrCode &&
                                            widget.design.qrImageUrl != null && 
                                            widget.design.qrImageUrl!.isNotEmpty && 
                                            widget.design.designStatus?.toLowerCase() == 'accepted') ...[
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.qr_code_2, color: AppColor.primary, size: 24),
                                            onPressed: () => FullScreenImageViewer.show(context, widget.design.qrImageUrl!),
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ],
                                      ],
                                    ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),


              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    if (status == null || status.isEmpty) return const SizedBox.shrink();
    
    Color color;
    switch (status.toLowerCase()) {
      case 'accepted':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red.shade400;
        break;
      case 'pending':
        color = AppColor.primary;
        break;
      default:
        color = AppColor.coolLavender;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
