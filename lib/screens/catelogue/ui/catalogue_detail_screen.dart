import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/catelogue/model/catalogue_model.dart';
import 'package:arianth/screens/catelogue/riverpod/catalogue_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/services.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';
import 'package:get/get.dart';

class CatalogueDetailScreen extends ConsumerStatefulWidget {
  final String? catalogueId;
  const CatalogueDetailScreen({super.key, this.catalogueId});

  @override
  ConsumerState<CatalogueDetailScreen> createState() => _CatalogueDetailScreenState();
}

class _CatalogueDetailScreenState extends ConsumerState<CatalogueDetailScreen> {
  bool _isSharing = false;
   String? role;
  @override
  void initState() {
    super.initState();
     role = SharedPreferencesHelper().getString("role");
    Future.microtask(() async {
      if (widget.catalogueId != null) {
        await ref.read(catalogueProvider.notifier).catalogueDetail(widget.catalogueId!);
      }
    });
  }

  // --- Helper: Label : Value (Only shows if value is present) ---
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
        fontSize: 12,
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
                fontSize: 12,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          const Text(" :  ", style: TextStyle(color: AppColor.textSecondary)),
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
    final state = ref.watch(catalogueProvider);
    final c = state.catalogueDetail;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text("Catalogue Details", style: TextStyle(color: AppColor.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColor.white, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: state.isFetchingDetail || c == null
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Section ---
            if (c.imageUrl != null || c.productImage != null)
              Container(
                height: 250,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: GestureDetector(
                    onTap: () => FullScreenImageViewer.show(context, c.imageUrl ?? c.productImage!),
                    child: Image.network(c.imageUrl ?? c.productImage!, fit: BoxFit.contain),
                  ),
                ),
              ),

            const SizedBox(height: 10),

            _buildInfoRow("Design Code", c.designCode, isHeader: true),
            // --- Product Info ---
            _buildInfoRow("Product Name", c.productName, isHeader: true),
            _buildInfoRow("Product Code", c.productCode),
            if(['super_admin'].contains(role?.toLowerCase()))...[
              _buildInfoRow("BP Code", c.bpCode),
            ],
            _buildInfoRow("Category", c.categoryName),
            _buildInfoRow("Sub Category", c.subcategoryName),
            _buildInfoRow("Type", c.type),

            // const Divider(height: 30),

            // --- Specifications ---
            _buildInfoRow("Weight", c.weightFrom != null ? "${c.weightFrom} gm" : null),
            _buildInfoRow("Size", c.size),
            _buildInfoRow("Length", c.length),
            _buildInfoRow("Stone", c.stone),
            _buildInfoRow("Enamel", c.enamel),
            _buildInfoRow("Hallmark", c.hallmark),
            _buildInfoRow("Rodium", c.rodium),
            _buildInfoRow("Hook", c.hook),
            _buildInfoRow("Open / Close", c.openClose),

            // const Divider(height: 30),

            // --- Creator Info ---
            _buildInfoRow("Creator", c.creator?.name ?? c.creator?.fullName),
            _buildInfoRow("Creator Mobile", c.creator?.mobileNo),

            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),

      // --- WhatsApp Share FAB ---
      floatingActionButton: (c != null && !state.isFetchingDetail)
          ? FloatingActionButton(
              onPressed: _isSharing
                  ? null
                  : () async {
                      setState(() => _isSharing = true);
                      try {
                        final String? role = SharedPreferencesHelper().getString("role");
                        final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(role?.toLowerCase());
                        await ShareCardService.share(
                          context,
                          ShareCardItem(
                            imageUrl: c.imageUrl ?? c.productImage,
                            title: c.productName,
                            productCode: restricted ? null : c.productCode,
                            category: c.categoryName,
                            weight: "${c.weightFrom ?? ''} gm",
                            size: c.size,
                            refNo: restricted ? null : c.designCode,
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