import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/work_orders/model/work_orders_model.dart';
import 'package:arianth/screens/work_orders/riverpod/work_orders_notifier.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/form_field_common_button.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:arianth/services/widget/reusable_table_view.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';
import 'package:arianth/services/widget/pdf_thumbnail.dart';
import 'package:arianth/services/widget/pdf_full_viewer_screen.dart';
import 'package:get/get.dart';

class WorkOrdersTable extends StatelessWidget {
  final WorkOrderListState state;
  final String? role;
  final String? activeStatus;
  final Set<String> selectedIds;
  final Function(Set<String>) onSelectionChanged;

  const WorkOrdersTable({
    super.key,
    required this.state,
    this.role,
    this.activeStatus,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  bool isToday(String? dateString) {
    if (dateString == null || dateString.isEmpty) return false;
    const String format = 'dd-MM-yyyy';
    try {
      final DateFormat formatter = DateFormat(format);
      final DateTime date = formatter.parse(dateString);
      final today = DateTime.now();
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    } catch (e) {
      return false;
    }
  }

  Widget _buildHighlightedCell(
    WorkOrder item,
    String Function(WorkOrder item) valueExtractor, {
    bool canCopy = false,
  }) {
    final dateForComparison = role != "Craftsman"
        ? item.craftsmanDueDate
        : item.dueDate;

    final bool shouldHighlight =
        (role != "Key User" && role != "User" && isToday(dateForComparison));

    final String displayText = valueExtractor(item);
    const double fontSize = 14.0;

    Widget cellContent = Text(
      displayText.isEmpty ? '-' : displayText,
      style: TextStyle(
        fontSize: fontSize,
        color: shouldHighlight
            ? Colors.red.shade400
            : AppColor.textPrimary,
        fontWeight: shouldHighlight ? FontWeight.bold : FontWeight.w400,
      ),
      overflow: TextOverflow.ellipsis,
    );

    if (canCopy && displayText.isNotEmpty) {
      cellContent = GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: displayText));
          Toaster.showSuccess('Copied: $displayText');
        },
        child: cellContent,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: Alignment.centerLeft,
      child: cellContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReusableDataTable<WorkOrder>(
      items: state.workOrders,
      getItemId: (partner) => partner.id.toString(),
      enableSelection: true,
      stickyCheckbox: true,
      selectedIds: selectedIds,
      onSelectionChanged: onSelectionChanged,
      stickyFirstColumn: true,
      columns: [
        if (!['buyer', 'key_user', 'user'].contains(role?.toLowerCase()))
          TableColumnConfig(
            header: 'BP Code',
            flex: 2,
            width: 60,
            isSticky: true,
            cellBuilder: (partner) => _buildHighlightedCell(
              partner as WorkOrder,
              (item) => role == "craftsman" ? item.workOrderNumber ?? "" : item.bpCode ?? '_',
            ),
          ),
        TableColumnConfig(
          header: 'Image',
          width: 80,
          isSticky: false,
          cellBuilder: (partner) {
            final imageUrl = partner.productImageUrl ?? partner.productImage;
            return SizedBox(
              width: 55,
              height: 55,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? (imageUrl.toLowerCase().endsWith('.pdf')
                      ? GestureDetector(
                          onTap: () => Get.to(() => PdfFullViewerScreen(
                                url: imageUrl,
                                title: partner.workOrderNumber,
                                enableRedaction: true,
                                backgroundColor: AppColor.background,
                                appBarColor: AppColor.background,
                                textColor: AppColor.textPrimary,
                              )),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: PdfThumbnail(
                              url: imageUrl,
                              fit: BoxFit.cover,
                              enableRedaction: true,
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () => FullScreenImageViewer.show(context, imageUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.image_not_supported,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ))
                  : const Icon(Icons.image, size: 20, color: Colors.grey),
            );
          },
        ),
        TableColumnConfig(
          header: role == "craftsman" ? "Category" : 'Order Number',
          flex: 1,
          cellBuilder: (partner) => _buildHighlightedCell(
            partner as WorkOrder,
            (item) => role == "craftsman" ? partner.productCategory ?? '-' : partner.workOrderNumber ?? '-',
            canCopy: true,
          ),
        ),
        if (!['buyer', 'key_user', 'user'].contains(role?.toLowerCase()))
          TableColumnConfig(
            header: role == "craftsman" ? "Weight" : 'Buyer Name',
            flex: 1,
            cellBuilder: (partner) => _buildHighlightedCell(
              partner as WorkOrder,
              (item) => role == "craftsman" ? " ${partner.weightFrom ?? ''}-${partner.weightTo ?? ''}" : item.customerName ?? '',
            ),
          ),
        TableColumnConfig(
          header: 'Product Code',
          flex: 1,
          width: 80,
          cellBuilder: (partner) => _buildHighlightedCell(
            partner as WorkOrder,
            (item) => partner.productCode ?? '-',
            canCopy: true,
          ),
        ),
        TableColumnConfig(
          header: 'Product Name',
          flex: 1,
          width: 80,
          cellBuilder: (partner) => _buildHighlightedCell(
            partner as WorkOrder,
            (item) => partner.productName ?? '-',
            canCopy: true,
          ),
        ),
        if (!['buyer', 'key_user', 'user'].contains(role?.toLowerCase()))
          TableColumnConfig(
            header: 'Status',
            flex: 1,
            cellBuilder: (partner) => _buildHighlightedCell(
              partner as WorkOrder,
              (item) => partner.status ?? '-',
            ),
          ),
        TableColumnConfig(
          header: 'Action',
          flex: 1,
          cellBuilder: (partner) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (role != 'craftsman' && role != 'Craftsman')
                  if (['buyer', 'key_user', 'user'].contains(role?.toLowerCase())
                      ? activeStatus == 'New'
                      : true)
                    FormFeildCommonButton(
                      text: activeStatus == 'Completed' ? "Copy" : "Edit",
                      onPressed: () async {
                        final id = partner.id;
                        Get.toNamed(AppRoutes.workOrdersAdd, arguments: id.toString());
                      },
                    ),
                IconButton(
                  icon: Image.asset('assets/image/whatsapp.png', width: 24, height: 24),
                  onPressed: () {
                    final imageUrl = partner.productImageUrl ?? partner.productImage;
                    final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(role?.toLowerCase());
                    final bool isPdf = imageUrl?.toLowerCase().endsWith('.pdf') ?? false;

                    // Format date with time for sharing
                    String? sharedOrderDate;
                    if (partner.createdAt != null && partner.createdAt.toString().isNotEmpty && partner.createdAt.toString() != 'null') {
                      try {
                        final parsed = DateTime.parse(partner.createdAt.toString());
                        sharedOrderDate = DateFormat('dd-MMM-yyyy HH:mm').format(parsed);
                      } catch (e) {
                        sharedOrderDate = partner.createdAt.toString();
                      }
                    }

                    // Format due date without timezone
                    String? sharedDueDate;
                    if (partner.dueDate != null && partner.dueDate!.isNotEmpty && partner.dueDate != 'null') {
                      try {
                        final parsed = DateTime.parse(partner.dueDate!);
                        sharedDueDate = DateFormat('dd-MMM-yyyy').format(parsed);
                      } catch (e) {
                        sharedDueDate = partner.dueDate;
                      }
                    }

                    ShareCardService.share(
                      context,
                      ShareCardItem(
                        workOrderNumber: partner.workOrderNumber,
                        imageUrl: imageUrl, // The Service must handle downloading/converting this if isPdf is true
                        title: partner.productName,
                        category: partner.productCategory,
                        quantity: partner.quantity,
                        weight: partner.weightFrom != null ? '${partner.weightFrom}-${partner.weightTo}g' : null,
                        size: partner.size,
                        stone: partner.stone,
                        enamel: partner.enamel,
                        hallmark: partner.hallmark,
                        rodium: partner.rodium,
                        hook: partner.hook,
                        type: partner.type,
                        openClose: partner.openClose,
                        isPdf: isPdf,
                        narration: partner.narrationCraftsman,
                        subtitle: 'WO# ${partner.workOrderNumber ?? ""}',
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
      isLoading: state.isLoading && state.workOrders.isEmpty,
      headerColor: AppColor.tableHeader,
      selectedRowColor: AppColor.primary.withValues(alpha: 0.05),
      rowHoverColor: AppColor.surface,
      borderRadius: 12,
      onRowTap: (partner) {
        Get.toNamed(
          AppRoutes.workOrdersDetails,
          arguments: partner.id.toString(),
        );
      },
      minTableWidth: 1400,
      rowHeight: 64,
      headerHeight: 56,
    );
  }
}
