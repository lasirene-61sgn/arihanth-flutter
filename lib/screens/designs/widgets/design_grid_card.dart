import 'dart:typed_data';
import 'package:arianth/screens/designs/model/designs_model.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:flutter/material.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/pdf_thumbnail.dart';
import 'package:arianth/services/widget/pdf_full_viewer_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import '../../../app_color/app_color.dart';

class DesignGridCard extends StatefulWidget {
  final Design item;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final bool isApproving;

  const DesignGridCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onApprove,
    this.isApproving = false,
  });

  @override
  State<DesignGridCard> createState() => _DesignGridCardState();
}

class _DesignGridCardState extends State<DesignGridCard> {
  bool _isSharing = false;
  String? role;

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role") ?? '';
  }

  Future<void> _shareViaWhatsApp() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(role?.toLowerCase());
    await ShareCardService.share(
      context,
      ShareCardItem(
        imageUrl: widget.item.imageUrl,
        title: widget.item.productName,
        productCode: restricted ? null : widget.item.designCode,
        category: widget.item.category,
        isLocked: (widget.item.isLocked == 1 && role?.toLowerCase() != 'super_admin'),
        showWatermark: (widget.item.isLocked == 1 && role?.toLowerCase() != 'super_admin'),
      ),
    );
    if (mounted) setState(() => _isSharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final String? firstImageUrl = widget.item.imageUrl;
    final bool isPdf = firstImageUrl?.toLowerCase().contains('.pdf') ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.primary, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap:widget.item.isLocked == 1 ? null : widget.onTap,
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
                        child: _buildMediaContent(isPdf, firstImageUrl),
                      ),
                    ),
                    if (widget.item.isLocked != 1 && role?.toLowerCase() == 'super_admin')
                      Positioned(
                        top: 4,
                        right: 4,
                        child: _buildPopupMenu(),
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
                      // if (!['buyer', 'key_user', 'user'].contains(role?.toLowerCase()))
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: widget.item.designCode ?? '-'));
                            Toaster.showSuccess("Design Code copied to clipboard");
                            widget.onTap(); // Manually trigger detail navigation
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColor.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
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
                          // 1. Category Pill (Now shows Category for everyone)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColor.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              // Always show category name, fallback to '-' if null
                              widget.item.category ?? '-',
                              style: const TextStyle(
                                color: AppColor.black,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // 2. Weight Pill (Kept as is)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColor.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.item.weightFrom != null ? '${widget.item.weightFrom} gm' : '-',
                              style: const TextStyle(
                                color: AppColor.black,
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
            if (role == 'super_admin' && widget.item.designStatus?.toLowerCase() == 'pending')
               _buildApproveButton(),
              if(widget.item.isLocked == 1 && role?.toLowerCase() != 'super_admin') Container(
                width:100,
                padding: const EdgeInsets.symmetric(vertical: 1),
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColor.border, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.lock_clock, size: 12, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Text(
                      'Locked',
                      style: TextStyle(
                        color: AppColor.textHint,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'whatsapp') _shareViaWhatsApp();
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'whatsapp',
          child: Row(
            children: [
              _isSharing
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF25D366)),
              )
                  : const Icon(Icons.share, size: 18, color: Color(0xFF25D366)),
              const SizedBox(width: 10),
              const Text('Share via WhatsApp', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert, size: 18, color: AppColor.textHint),
    );
  }

  Widget _buildMediaContent(bool isPdf, String? imageUrl) {
    if (imageUrl == null) {
      return const Icon(Icons.image_outlined, color: AppColor.textHint, size: 40);
    }
    final content = isPdf
        ? GestureDetector(
            onTap: () => Get.to(() => PdfFullViewerScreen(url: imageUrl, title: widget.item.designName)),
            child: PdfThumbnail(url: imageUrl),
          )
        : Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
          );

    return Stack(
      alignment: Alignment.center,
      children: [
        ImageFiltered(
          imageFilter: (widget.item.isLocked == 1 && role?.toLowerCase() != 'super_admin')
              ? ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0)
              : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
          child: content,
        ),
        if (widget.item.isLocked == 1 && role?.toLowerCase() != 'super_admin')
          Image.asset('assets/image/tara_text_bg.png', width: 60, height: 60, fit: BoxFit.contain),
      ],
    );
  }

  Widget _buildApproveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
      child: SizedBox(
        width: double.infinity,
        height: 24,
        child: ElevatedButton(
          onPressed: widget.isApproving ? null : widget.onApprove,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: AppColor.textWhite,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: widget.isApproving
              ? const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.textWhite),
                )
              : const Text(
                  'Approve',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
