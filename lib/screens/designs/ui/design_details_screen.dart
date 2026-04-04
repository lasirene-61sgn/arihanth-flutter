import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/designs/model/designs_model.dart';
import 'package:arianth/screens/designs/riverpod/designs_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // Added import for ImageFilter

class DesignDetailsScreen extends ConsumerStatefulWidget {
  final String? designId;
  const DesignDetailsScreen({super.key, this.designId});

  @override
  ConsumerState<DesignDetailsScreen> createState() => _DesignDetailsScreenState();
}

class _DesignDetailsScreenState extends ConsumerState<DesignDetailsScreen> {
  String? role;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role") ?? '';
    Future.microtask(() {
      if (widget.designId != null) {
        ref.read(designsProvider.notifier).designDetail(widget.designId!);
      }
    });
  }

  // --- Helper: Label : Value (Hides if empty) ---
  Widget _buildInfoRow(String label, String? value, {bool isHeader = false}) {
    if (value == null || value.trim().isEmpty || value == 'null' || value == '0' || value == '0.0') {
      return const SizedBox.shrink();
    }

    final bool isClickToCopyType = [
      "Design Code",
      "Product Name",
      "Product Code",
    ].contains(label);

    Widget valueWidget = Text(
      value,
      style: TextStyle(
        color: AppColor.textPrimary,
        fontSize: 14,
        fontWeight: isHeader ? FontWeight.bold : FontWeight.w600,
      ),
    );

    if (isClickToCopyType) {
      valueWidget = GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          Toaster.showSuccess('Copied: $value');
        },
        child: valueWidget,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: AppColor.textSecondary,
                fontSize: 14,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          const Text(" :  ", style: TextStyle(color: AppColor.textHint)),
          Expanded(
            flex: 3,
            child: valueWidget,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(designsProvider);
    final d = state.designDetails;
    final bool isCraftsman = role?.toLowerCase() == 'craftsman';

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text("Design Details", style: TextStyle(color: AppColor.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppColor.white, size: 20), onPressed: () => Get.back()),
      ),
      body: state.isSaving || d == null
          ? const Center(child: CircularProgressIndicator(color: AppColor.softOrange))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Section ---
            if (d.images != null && d.images!.isNotEmpty)
              Container(
                height: 300,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: d.images!.length,
                      itemBuilder: (context, index) {
                        final imageData = d.images![index];
                        final imageUrl = imageData.imageUrl;
                        if (imageUrl == null || imageUrl.isEmpty) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: (d.isLocked == 1 && role?.toLowerCase() != 'super_admin') ? null : () => FullScreenImageViewer.show(context, imageUrl),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ImageFiltered(
                                imageFilter: (d.isLocked == 1 && role?.toLowerCase() != 'super_admin')
                                    ? ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0)
                                    : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                  ),
                                ),
                              ),
                              if (d.isLocked == 1 && role?.toLowerCase() != 'super_admin')
                                Image.asset('assets/image/tara_text_bg.png', width: 80, height: 80, fit: BoxFit.contain),
                            ],
                          ),
                        );
                      },
                    ),
                    if (d.images!.length > 1)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "Swipe for more images",
                              style: TextStyle(color: AppColor.textWhite, fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else if (d.imageUrl != null && d.imageUrl!.isNotEmpty)
              Container(
                height: 300,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: GestureDetector(
                  onTap: (d.isLocked == 1 && role?.toLowerCase() != 'super_admin') ? null : () => FullScreenImageViewer.show(context, d.imageUrl!),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ImageFiltered(
                        imageFilter: (d.isLocked == 1 && role?.toLowerCase() != 'super_admin')
                            ? ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0)
                            : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(d.imageUrl!, fit: BoxFit.contain),
                        ),
                      ),
                      if (d.isLocked == 1 && role?.toLowerCase() != 'super_admin')
                        Image.asset('assets/image/tara_logo_color.jpeg', width: 80, height: 80, fit: BoxFit.contain),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // --- Design Info ---
            if (!['buyer', 'key_user', 'user'].contains(role?.toLowerCase()))
              _buildInfoRow("Design Code", d.designCode, isHeader: true),
            _buildInfoRow("Product Name", d.productName),
            _buildInfoRow("Category", d.category),
            _buildInfoRow("Sub Category", d.subCategory),
            // Status removed as requested

            // const Divider(height: 30),

            // --- Product Specs (Role Based Hiding) ---
            if (!isCraftsman && !['buyer', 'key_user', 'user'].contains(role?.toLowerCase())) ...[
              _buildInfoRow("BP Code", d.bpCode),
              // _buildInfoRow("Relabel Code", d.relabelCode),
              _buildInfoRow("Product Code", d.productCode), // Only Admin/Buyer sees this
            ],

            _buildInfoRow("Type", d.type),
            _buildInfoRow("Order Type", d.orderType),

            _buildInfoRow("Weight", d.weightFrom != null ? "${d.weightFrom} gm" : null),

            _buildInfoRow("Size", d.size),
            _buildInfoRow("Length", d.length),
            _buildInfoRow("Stone", d.stone),
            _buildInfoRow("Enamel", d.enamel),

            // const Divider(height: 30),

            // --- Technical Info ---
            _buildInfoRow("Hallmark", d.hallmark),
            _buildInfoRow("Rodium", d.rodium),
            _buildInfoRow("Hook", d.hook),
            _buildInfoRow("Open / Close", d.openClose),

            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),

      // --- WhatsApp Share FAB ---
      floatingActionButton: (d != null && !state.isSaving)
          ? FloatingActionButton(
              onPressed: _isSharing
                  ? null
                  : () async {
                      setState(() => _isSharing = true);
                      try {
                        final bool restricted = ['super_admin', 'buyer', 'key_user', 'user'].contains(role?.toLowerCase());
                        await ShareCardService.share(
                          context,
                          ShareCardItem(
                            imageUrl: d.imageUrl,
                            title: d.productName,
                            bpCode: (isCraftsman || restricted) ? null : d.bpCode,
                            productCode: (isCraftsman || restricted) ? null : d.productCode, // Hide in share too
                            category: d.category,
                            weight: "${d.weightFrom ?? ''} gm",
                            size: d.size,
                            refNo: (isCraftsman || restricted) ? null : d.designCode, // Hide design code too
                            subtitle: (isCraftsman || restricted) ? null : 'Design Code: ${d.designCode}',
                            isLocked: (d.isLocked == 1 && role?.toLowerCase() != 'super_admin'),
                            showWatermark: (d.isLocked == 1 && role?.toLowerCase() != 'super_admin'),
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _isSharing = false);
                      }
                    },
              backgroundColor: AppColor.primary,
              shape: const CircleBorder(),
              child: _isSharing
                  ? const CircularProgressIndicator(
                      color: AppColor.textWhite,
                    )
                  : Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColor.primary, width: 0),
                          image: const DecorationImage(
                              image: AssetImage(
                                'assets/image/whatsapp.png',
                              ),
                              fit: BoxFit.cover)),
                    ),
            )
          : null,
    );
  }
}