import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ProductDetailsViewScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailsViewScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsViewScreen> createState() => _ProductDetailsViewScreenState();
}

class _ProductDetailsViewScreenState extends ConsumerState<ProductDetailsViewScreen> {
  String? role;
  List<String> _imageUrls = [];
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role") ?? '';
    Future.microtask(() {
      _fetchProductDetails();
    });
  }

  Future<void> _fetchProductDetails() async {
    await ref.read(productListProvider.notifier).productDetail(widget.productId);

    final productState = ref.read(productListProvider);
    final product = productState.productDetail;

    if (product != null) {
      setState(() {
        _imageUrls = [];
        if (product.images != null && product.images!.isNotEmpty) {
          for (var img in product.images!) {
            if (img.imageUrl != null && img.imageUrl!.isNotEmpty) {
              _imageUrls.add(img.imageUrl!);
            }
          }
        }
        
        // Fallback to single productImage if gallery is empty
        if (_imageUrls.isEmpty && product.productImage != null && product.productImage!.isNotEmpty) {
          final path = product.productImage!;
          _imageUrls.add(path.startsWith('http') ? path : '${ApiClient.baseUrl}storage/$path');
        }
      });
    }
  }

  Widget _buildInfoRow(String label, String? value, {bool isHeader = false}) {
    if (value == null || value.trim().isEmpty || value == 'null' || value == '0' || value == '0.0') {
      return const SizedBox.shrink();
    }

    final bool isClickToCopyType = [
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
    final state = ref.watch(productListProvider);
    final p = state.productDetail;
    final bool isCraftsman = role?.toLowerCase() == 'craftsman';

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text("Product Details", style: TextStyle(color: AppColor.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppColor.white, size: 20), onPressed: () => Get.back()),
      ),
      body: state.isLoading || p == null
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Image Section ---
                  if (_imageUrls.isNotEmpty)
                    Container(
                      height: 300,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColor.background,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Stack(
                        children: [
                          PageView.builder(
                            itemCount: _imageUrls.length,
                            itemBuilder: (context, index) {
                              final imageUrl = _imageUrls[index];
                              return GestureDetector(
                                onTap: () => FullScreenImageViewer.show(context, imageUrl),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) => const Center(
                                      child: Icon(Icons.image_not_supported, color: AppColor.textHint),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_imageUrls.length > 1)
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
                    ),

                  const SizedBox(height: 10),

                  // --- Product Info ---
                  _buildInfoRow("Product Name", p.productName, isHeader: true),
                  _buildInfoRow("Product Code", p.productCode, isHeader: isCraftsman),
                  if (!['buyer', 'key_user', 'user'].contains(role?.toLowerCase()))
                    _buildInfoRow("BP Code", p.bpCode),
                  _buildInfoRow("Category", p.category?.name),
                  _buildInfoRow("Sub Category", p.subcategory?.name),
                  _buildInfoRow("Type", p.type),

                  if (!isCraftsman) ...[
                    _buildInfoRow("Relabel Code", p.relabelCode),
                  ],

                  _buildInfoRow("Weight Range", (p.weightFrom != null && p.weightTo != null)
                      ? "${p.weightFrom} - ${p.weightTo}gm"
                      : null),

                  _buildInfoRow("Size", p.size),
                  _buildInfoRow("Length", p.length),
                  _buildInfoRow("Stone Work", p.stone),
                  _buildInfoRow("Enamel Work", p.enamel),

                  _buildInfoRow("Hallmark", p.hallmark),
                  _buildInfoRow("Rodium", p.rodium),
                  _buildInfoRow("Hook", p.hook),
                  _buildInfoRow("Open / Close", p.openClose),

                  const SizedBox(height: 100),
                ],
              ),
            ),
      floatingActionButton: (p != null && !state.isLoading)
          ? FloatingActionButton(
              onPressed: _isSharing
                  ? null
                  : () async {
                      setState(() => _isSharing = true);
                      try {
                        await ShareCardService.share(
                          context,
                          ShareCardItem(
                            imageUrl: _imageUrls.isNotEmpty ? _imageUrls[0] : null,
                            title: p.productName,
                            bpCode: (isCraftsman || ["super_admin", "buyer", "key_user", "user"].contains(role?.toLowerCase())) ? null : p.bpCode,
                            productCode: p.productCode,
                            category: p.category?.name,
                            weight: "${p.weightFrom ?? ''}-${p.weightTo ?? ''} gm",
                            size: p.size,
                            refNo: p.productCode,
                            subtitle: 'Product Code: ${p.productCode}',
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

