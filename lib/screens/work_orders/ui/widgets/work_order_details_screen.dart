import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arianth/screens/work_orders/riverpod/work_orders_notifier.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';
import 'package:arianth/services/widget/pdf_thumbnail.dart';
import 'package:arianth/services/widget/pdf_full_viewer_screen.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:get/get.dart';

class WorkOrderDetailsScreen extends ConsumerStatefulWidget {
  final String? workOrderId;

  const WorkOrderDetailsScreen({super.key, this.workOrderId});

  @override
  ConsumerState<WorkOrderDetailsScreen> createState() => _WorkOrderDetailsScreenState();
}

class _WorkOrderDetailsScreenState extends ConsumerState<WorkOrderDetailsScreen> {
  String? role;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role") ?? '';
    if (widget.workOrderId != null && widget.workOrderId != "null") {
      Future.microtask(() => ref.read(workOrderListProvider.notifier).workOrderDetail(widget.workOrderId, context));
    }
  }

  String _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty || date.toString() == 'null') return "-";
    try {
      final parsed = DateTime.parse(date.toString());
      return DateFormat('dd-MMM-yyyy').format(parsed);
    } catch (e) {
      return date.toString();
    }
  }

  /// New Layout Row matching your image (Label : Value)
  Widget _buildInfoRow(String label, String? value, {bool isHeader = false}) {
    // Hide logic for empty values
    if (value == null || value.isEmpty || value == 'null' || value == '0' || value == '0.0') {
      return const SizedBox.shrink();
    }

    final bool isClickToCopyType = [
      "Order Number",
      "Product Name",
      "Product Code",
    ].contains(label);

    Widget valueText = Text(
      value,
      style: TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontWeight: isHeader ? FontWeight.bold : FontWeight.w600,
      ),
    );

    if (isClickToCopyType) {
      valueText = GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          Toaster.showSuccess('Copied: $value');
        },
        child: valueText,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          const Text(" :  ", style: TextStyle(color: Colors.black54)),
          Expanded(
            flex: 3,
            child: valueText,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workOrderListProvider);
    final wo = state.workOrderDetail;
    final bool isCraftsman = role?.toLowerCase() == 'craftsman';

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text("Order Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Get.back()),
        actions: [
          if (!isCraftsman) // Only show edit for admins/buyers
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () => Get.toNamed('/work-orders/add', arguments: widget.workOrderId),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : wo == null
          ? const Center(child: Text("Data not found"))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Section ---
            if (wo.productImageUrl != null || wo.productImage != null)
              Container(
                height: 220,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Builder(builder: (context) {
                    final imageUrl = wo.productImageUrl ?? wo.productImage!;
                    if (imageUrl.toLowerCase().endsWith('.pdf')) {
                      return GestureDetector(
                        onTap: () => Get.to(() => PdfFullViewerScreen(
                                url: imageUrl,
                                title: wo.workOrderNumber,
                                enableRedaction: true,
                                backgroundColor: AppColor.background,
                                appBarColor: AppColor.background,
                                textColor: AppColor.textPrimary,
                              )),
                        child: PdfThumbnail(
                          url: imageUrl,
                          fit: BoxFit.contain,
                          showAllPages: true,
                          enableRedaction: true,
                        ),
                      );
                    }
                    return GestureDetector(
                      onTap: () => FullScreenImageViewer.show(context, imageUrl),
                      child: Image.network(imageUrl, fit: BoxFit.contain),
                    );
                  }),
                ),
              ),

            const SizedBox(height: 10),
            // const Divider(thickness: 1),

            // --- DATA SECTION (Clean Row Style) ---

            // Work Order Number is always visible
            _buildInfoRow("Order Number", wo.workOrderNumber, isHeader: true),
            _buildInfoRow("Order Date", _formatDate(wo.createdAt)),
            if(['buyer', 'key_user', 'user'].contains(role?.toLowerCase()))
              ...[
                _buildInfoRow("Due Date", _formatDate(wo.dueDate)),
              ] ,
            if(['super_admin', 'craftsman', ].contains(role?.toLowerCase()))
              ...[
                _buildInfoRow("Due Date", _formatDate(wo.craftsmanDueDate)),
              ],
            // HIDE if craftsman or restricted roles: status, customer, bp code, ref no, product code
            if (!isCraftsman && !['buyer', 'key_user', 'user'].contains(role?.toLowerCase())) ...[

              _buildInfoRow("Status", wo.status),
              _buildInfoRow("Customer", wo.customerName),
              _buildInfoRow("BP Code", wo.bpCode),
              _buildInfoRow("Ref No", wo.referenceNo),
              _buildInfoRow("Product Name", wo.productName),
              _buildInfoRow("Product Code", wo.productCode),
              _buildInfoRow("Admin Notes", wo.narrationAdmin),
            ],




            // const Divider(thickness: 1, height: 30),

            // --- Specs ---

            _buildInfoRow("Category", wo.productCategory),
            _buildInfoRow("SubCategory", wo.subcategory),
            _buildInfoRow("Weight", "${wo.weightFrom ?? ''} - ${wo.weightTo ?? ''} gm"),
            _buildInfoRow("Size", wo.size),
            _buildInfoRow("type", wo.type),
            _buildInfoRow("Length", wo.length),
            _buildInfoRow("Stone", wo.stone),
            _buildInfoRow("Enamel", wo.enamel),

            // const Divider(thickness: 1, height: 30),

            // --- Technical ---
            _buildInfoRow("Hallmark", wo.hallmark),
            _buildInfoRow("Rodium", wo.rodium),
            _buildInfoRow("Hook", wo.hook),
            _buildInfoRow("Open/Close", wo.openClose),
            // Notes section
            if (wo.narrationAdmin != null && wo.narrationAdmin!.isNotEmpty &&
                ['buyer', 'key_user', 'user'].contains(role?.toLowerCase())) ...[
              // const Divider(thickness: 1, height: 30),
              _buildInfoRow("Notes", wo.narrationAdmin),

            ],

            if (wo.narrationCraftsman != null && wo.narrationCraftsman!.isNotEmpty &&
                !['buyer', 'key_user', 'user'].contains(role?.toLowerCase())) ...[
              // const Divider(thickness: 1, height: 30),
              _buildInfoRow("Craftsman Notes", wo.narrationCraftsman),

            ],

            const SizedBox(height: 10),

            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: (wo != null && !state.isLoading)
          ? FloatingActionButton(

        onPressed: _isSharing ? null : () async {
          setState(() => _isSharing = true);
          try {
            final imageUrl = wo.productImageUrl ?? wo.productImage;
             final bool isPdf = imageUrl?.toLowerCase().endsWith('.pdf') ?? false;

            // Always show image in share card as per latest request "user show image"
            final String? shareImageUrl = imageUrl;

            // Format date with time for sharing
            String? sharedOrderDate;
            if (wo.createdAt != null && wo.createdAt.toString().isNotEmpty && wo.createdAt.toString() != 'null') {
              try {
                final parsed = DateTime.parse(wo.createdAt.toString());
                sharedOrderDate = DateFormat('dd-MMM-yyyy HH:mm').format(parsed);
              } catch (e) {
                sharedOrderDate = wo.createdAt.toString();
              }
            }

            // Format due date without timezone
            String? sharedDueDate;
            if (wo.dueDate != null && wo.dueDate!.isNotEmpty && wo.dueDate != 'null') {
              try {
                final parsed = DateTime.parse(wo.dueDate!);
                sharedDueDate = DateFormat('dd-MMM-yyyy').format(parsed);
              } catch (e) {
                sharedDueDate = wo.dueDate;
              }
            }

            await ShareCardService.share(
              context,
              ShareCardItem(
                workOrderNumber: wo.workOrderNumber,
                imageUrl: shareImageUrl,
                title: wo.productName,
                category: wo.productCategory,
                quantity: wo.quantity,
                type: wo.type,
                weight: wo.weightFrom != null ? '${wo.weightFrom}-${wo.weightTo}g' : null,
                size: wo.size,
                stone: wo.stone,
                enamel: wo.enamel,
                hallmark: wo.hallmark,
                rodium: wo.rodium,
                hook: wo.hook,
                openClose: wo.openClose,
                narration: wo.narrationCraftsman,
                isPdf: isPdf,
                subtitle: 'WO# ${wo.workOrderNumber ?? ""}',
              ),
            );
          } finally {
            if (mounted) setState(() => _isSharing = false);
          }
        },
        backgroundColor: AppColor.primary, // Your theme color
        shape: const CircleBorder(),
        child: _isSharing
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            :  Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColor.primary, width: 0),
              image: DecorationImage(image: AssetImage('assets/image/whatsapp.png',) ,fit: BoxFit.cover)
          ),
        ),
        // child: Padding(
        //   padding: const EdgeInsets.all(12.0),
        //   child: _isSharing
        //       ? const SizedBox(
        //           width: 24,
        //           height: 24,
        //           child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        //         )
        //       : Image.asset(
        //           'assets/image/whatsapp.png',
        //           fit: BoxFit.contain,
        //         ),
        // ),
      )
          : null,
    );
  }
}