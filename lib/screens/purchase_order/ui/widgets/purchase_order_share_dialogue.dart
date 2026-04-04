import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/purchase_order/model/purchase_orders_model.dart';
import 'package:arianth/screens/purchase_order/riverpod/purchase_orders_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PurchaseOrderShareDialog extends ConsumerStatefulWidget {
  final Set<String> selectedOrderIds;

  const PurchaseOrderShareDialog({super.key, required this.selectedOrderIds});

  static Future<void> show(
      BuildContext context, WidgetRef ref, Set<String> selectedOrderIds) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: PurchaseOrderShareDialog(selectedOrderIds: selectedOrderIds),
      ),
    );
  }

  @override
  ConsumerState<PurchaseOrderShareDialog> createState() =>
      _PurchaseOrderShareDialogState();
}

class _PurchaseOrderShareDialogState
    extends ConsumerState<PurchaseOrderShareDialog> {
  late PageController _pageController;
  int _currentPage = 0;

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final poState = ref.watch(purchaseOrderListProvider);

    // Get the actual PurchaseOrder objects for the selected IDs
    final selectedOrders = poState.purchaseOrders
        .where((po) => widget.selectedOrderIds.contains(po.id.toString()))
        .toList();

    if (selectedOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColor.darkNavy : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('No orders selected or found.'),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header/Close ──
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),

        // ── Carousel ──
        SizedBox(
          height: 520, // Enough for the share card (500) + bottom indicators
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: selectedOrders.length,
            itemBuilder: (context, index) {
              final po = selectedOrders[index];
              return _buildOrderCard(context, po, isDark);
            },
          ),
        ),

        const SizedBox(height: 16),

        // ── Indicator/Footer ──
        if (selectedOrders.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Order ${_currentPage + 1} of ${selectedOrders.length}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderCard(BuildContext context, PurchaseOrder po, bool isDark) {
    final firstImageUrl = po.displayImageUrls.isNotEmpty ? po.displayImageUrls.first : null;

    return Center(
      child: Container(
        width: 320,
        height: 500,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColor.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // ── Details Layer ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section (60%)
                  Expanded(
                    flex: 6,
                    child: Container(
                      width: double.infinity,
                      color: isDark ? AppColor.darkNavy : Colors.grey.shade100,
                      child: firstImageUrl != null
                          ? Image.network(
                              firstImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.image_not_supported,
                                      size: 50, color: Colors.grey)),
                            )
                          : const Center(
                              child: Icon(Icons.image_outlined,
                                  size: 60, color: Colors.grey)),
                    ),
                  ),

                  // Info Section (40%)
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (po.purchaseOrderCode ?? 'Order N/A').toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColor.primary : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _infoRow(context, Icons.person_outline,
                              po.bpCode ?? 'No BP', isDark),
                          const SizedBox(height: 6),
                          _infoRow(context, Icons.calendar_today_outlined,
                              po.createdAt ?? '-', isDark),
                          const SizedBox(height: 6),
                          _infoRow(context, Icons.category_outlined,
                              po.items?.first.categoryName ?? 'Category N/A', isDark),
                          
                          const Spacer(),
                          
                          // WhatsApp Share Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _sharePo(context, po),
                              icon: Image.asset('assets/image/whatsapp.png',
                                  width: 20, height: 20),
                              label: const Text('Share on WhatsApp',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── General Share Button (Top Right) ──
              Positioned(
                top: 12,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.black38,
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(Icons.share, size: 18, color: Colors.white),
                    onPressed: () => _sharePo(context, po),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isDark ? AppColor.coolLavender : Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColor.coolLavender : Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _sharePo(BuildContext context, PurchaseOrder po) {
    final String? role = SharedPreferencesHelper().getString("role");
    final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(role?.toLowerCase());
    ShareCardService.share(
      context,
      ShareCardItem(
        imageUrl: po.displayImageUrls.isNotEmpty ? po.displayImageUrls.first : null,
        title: po.purchaseOrderCode,
        bpCode: restricted ? null : po.bpCode,
        productCode: restricted ? null : po.items?.first.product?.productCode,
        category: po.items?.first.categoryName,
        gramsDetail: (po.items != null && po.items!.isNotEmpty && po.items!.first.grams != null)
            ? List.generate(po.items!.first.grams!.length, (i) {
                final g = po.items!.first.grams![i];
                final q = (po.items!.first.quantity != null && po.items!.first.quantity!.length > i) ? po.items!.first.quantity![i] : "1";
                final iT = (po.items!.first.individualTotals != null && po.items!.first.individualTotals!.length > i) ? po.items!.first.individualTotals![i] : "1";
                return "$g Grams(x$q) = $iT Grams";
              }).join('\n')
            : null,
        subtitle: "Date: ${po.createdAt}",
      ),
    );
  }
}
