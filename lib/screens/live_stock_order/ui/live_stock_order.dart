import 'package:arianth/screens/live_stock_order/riverpod/live_stock_order_notifier.dart';
import 'package:arianth/screens/live_stock_order/model/stock_order_detail_model.dart';
import 'package:arianth/screens/live_stock_order/widgets/stock_order_card.dart';
import 'package:arianth/screens/live_stock_order/widgets/status_card.dart';
import 'package:arianth/screens/live_stock_order/widgets/bulk_action_dialogs.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/localization/language_selector.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:arianth/services/widget/enterprise_search_bar.dart';
import 'package:arianth/services/widget/no_data_widget.dart';
import 'package:arianth/services/widget/pagination_controls.dart';
import 'package:arianth/services/widget/reusable_bottom_nav_bar.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:arianth/services/widget/universal_filter_dialog.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/common_notifiers/pdf_download_notifier.dart';
import 'package:flutter/material.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app_color/app_color.dart';

class LiveStockOrder extends ConsumerStatefulWidget {
  const LiveStockOrder({super.key});

  @override
  ConsumerState<LiveStockOrder> createState() => _LiveStockOrderState();
}

class _LiveStockOrderState extends ConsumerState<LiveStockOrder> {
  Set<String> selectedIds = {};
  String? role;
  bool searchToggle = false;
  final TextEditingController _searchController = TextEditingController();
  String? selectedFilter;
  String? selectedSort;
  String _activeStatus = 'New';

  final Map<String, String> statusToTab = {
    'All': 'all-orders',
    'New': 'new-orders',
    'Allocated': 'allocated-orders',
    'In Process': 'in-process-orders',
    'For Approval': 'for-approval-orders',
    'Completed': 'completed-orders',
    'Rejected': 'rejected-orders',
  };

  String _getTabValue() {
    return statusToTab[_activeStatus] ?? 'all-orders';
  }

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role") ?? '';
    // Initial status set in StockOrderStatusCards will trigger first fetch
  }

  bool get isMobile => MediaQuery.of(context).size.width < 600;


  Widget _buildActiveFilterRibbon() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.divider)),
      ),
      child: Row(
        children: [
          Text("${ref.watchTr('filtering')}:", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColor.primary)),
          const SizedBox(width: 8),
          Chip(
            label: Text("$selectedFilter: ${_searchController.text}", style:  const TextStyle(fontSize: 10)),
            backgroundColor: AppColor.primary.withOpacity(0.1),
            deleteIcon: const Icon(Icons.close, size: 12, color: AppColor.primary),
            onDeleted: () {
              setState(() {
                selectedFilter = null;
                _searchController.clear();
                UniversalFilterDialog.clearCache(FilterModule.stockOrder);
              });
              String url = "api/common/live-stock-orders?tab=${statusToTab[_activeStatus] ?? 'new-orders'}";
              ref.read(liveStockOrderNotifierProvider.notifier).fetchLiveStockOrders(customUrl: url);
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            side: BorderSide.none,
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                selectedFilter = null;
                _searchController.clear();
                UniversalFilterDialog.clearCache(FilterModule.stockOrder);
              });
              String url = "api/common/live-stock-orders?tab=${statusToTab[_activeStatus] ?? 'new-orders'}";
              ref.read(liveStockOrderNotifierProvider.notifier).fetchLiveStockOrders(customUrl: url);
            },
            child: Text(ref.watchTr('reset_btn'), style: const TextStyle(fontSize: 11, color: Colors.red)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveStockOrderNotifierProvider);
    final notifier = ref.read(liveStockOrderNotifierProvider.notifier);
    final pdfState = ref.watch(pdfDownloadProvider);

    return Stack(
      children: [
        Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(height: 1.0, color: Colors.white24),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        title: !searchToggle
            ? Text(
                ref.watchTr('live_stock_order'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : EnterpriseSearchBar(
                controller: _searchController,
                hintText: 'Search order number...',
                onChanged: (value) {
                  final url = "api/common/stock-orders?tab=${_getTabValue()}&search=$value";
                  notifier.fetchLiveStockOrders(customUrl: url);
                },
                onCancel: () {
                  setState(() {
                    _searchController.clear();
                    searchToggle = false;
                  });
                  notifier.fetchLiveStockOrders(customUrl: "api/common/stock-orders?tab=${_getTabValue()}");
                },
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () => LanguageSelector.show(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          StockOrderStatusCards(
            key: const PageStorageKey('stock_order_tabs'),
            onStatusChanged: (status) => setState(() {
              _activeStatus = status;
              selectedIds.clear();
            }),
          ),
          if (selectedFilter != null) _buildActiveFilterRibbon(),
          _buildSelectAllBar(state),
          const SizedBox(height: 10),
          Expanded(child: _buildPreTable(state)),
          if (state.nextUrl != null || state.previousUrl != null)
            PaginationControls(
              count: state.count,
              currentCount: state.liveStockOrders.length,
              label: 'Total Orders',
              loadedLabel: 'Loaded Orders',
              onNext: notifier.goToNextPage,
              onPrevious: notifier.goToPreviousPage,
              isFirstPage: state.previousUrl == null,
              isLastPage: state.nextUrl == null,
              isLoading: state.isLoading,
            ),
        ],
      ),
      bottomNavigationBar: ERPBottomNavigationBar(
        actions: [
          NavActionItem(
            label: selectedFilter == null ? ref.watchTr('filter') : ref.watchTr('filtered'),
            icon: Icons.filter_list_alt,
            color: AppColor.primary,
            onPressed: _showFilterDialog,
          ),
          if (selectedFilter != null || selectedSort != null)
            NavActionItem(
              label: ref.watchTr('reset'),
              icon: Icons.refresh,
              color: Colors.red,
              onPressed: () {
                _searchController.clear();
                String url = "api/common/live-stock-orders?tab=${statusToTab[_activeStatus] ?? 'new-orders'}";
                ref.read(liveStockOrderNotifierProvider.notifier).fetchLiveStockOrders(customUrl: url);
                setState(() {
                  selectedFilter = null;
                  selectedSort = null;
                });
                UniversalFilterDialog.clearCache(FilterModule.stockOrder);
              },
            )
          else
            NavActionItem(
              label: ref.watchTr('search'),
              icon: Icons.search,
              color: AppColor.primary,
              onPressed: () {
                setState(() {
                  searchToggle = true;
                });
              },
            ),
          if (role?.toLowerCase() != 'craftsman')
            NavActionItem(
              label: ref.watchTr('create'),
              icon: Icons.add,
              color: AppColor.primary,
              isFloatingCenter: true,
              onPressed: () => Get.toNamed(AppRoutes.stockOrderAdd),
            ),
          NavActionItem(
            label: ref.watchTr('print'),
            icon: Icons.print,
            color: selectedIds.isNotEmpty ? AppColor.primary : Colors.black,
            onPressed: _printTable,
          ),
          NavActionItem(
            label: ref.watchTr('share'),
            icon: Icons.share,
            color: selectedIds.isNotEmpty ? AppColor.primary : Colors.black,
            onPressed: _shareSelected,
          ),
        ],
      ),
    ),
    if (pdfState.isLoading)
      Container(
        color: Colors.black.withOpacity(0.5),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    ]);
  }

  Widget _buildSelectAllBar(LiveStockOrderState state) {
    if (state.liveStockOrders.isEmpty) return const SizedBox.shrink();

    bool isAllSelectedOnPage = state.liveStockOrders.isNotEmpty &&
        state.liveStockOrders.every((po) => selectedIds.contains(po.id.toString()));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isAllSelectedOnPage) {
              selectedIds.clear();
            } else {
              for (var po in state.liveStockOrders) {
                selectedIds.add(po.id.toString());
              }
            }
          });
        },
        child: Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: isAllSelectedOnPage,
                  activeColor: AppColor.primary,
                  side: const BorderSide(color: AppColor.black, width: 1.5),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        for (var po in state.liveStockOrders) {
                          selectedIds.add(po.id.toString());
                        }
                      } else {
                        selectedIds.clear();
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Text(
                  isAllSelectedOnPage ? "Deselect All" : "Select All Items",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColor.textSecondary,
                    fontSize: 14,
                  ),
                ),
               if(selectedIds.isNotEmpty)...[

                 const SizedBox(height: 2),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                   decoration: BoxDecoration(
                     color: AppColor.primary.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Text(
                     "${selectedIds.length} Selected",
                     style: const TextStyle(
                       color: AppColor.primary,
                       fontWeight: FontWeight.bold,
                       fontSize: 12,
                     ),
                   ),
                 ),
               ]
              ],
            ),
            const Spacer(),
            if (selectedIds.isNotEmpty) ...[
              _buildBulkActions(),

            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBulkActions() {
    final r = role?.toLowerCase();
    if (r == 'buyer') return const SizedBox.shrink();

    final List<Widget> actions = [];

    if (_activeStatus == 'New' && r == 'super_admin') {
      actions.add(_actionBtn('Allocate', Icons.assignment_ind, () async {
        await StockOrderBulkAllocateDialog.show(context, ref, selectedIds);
        setState(() => selectedIds.clear());
      }));
    } else if (_activeStatus == 'For Approval' && r == 'super_admin') {
      actions.add(_actionBtn('Approve', Icons.check_circle_outline, () async {
        await StockOrderBulkCompleteDialog.show(context, ref, selectedIds);
        setState(() => selectedIds.clear());
      }, color: Colors.green));
    } else if (_activeStatus == 'Allocated' && r == 'craftsman') {
      actions.add(_actionBtn('Reject', Icons.cancel_outlined, () async {
        await StockOrderBulkRejectDialog.show(context, ref, selectedIds);
        setState(() => selectedIds.clear());
      }, color: Colors.red));
      actions.add(const SizedBox(width: 8));
      actions.add(_actionBtn('Accept', Icons.check_circle_outline, () async {
        await StockOrderBulkAcceptDialog.show(context, ref, selectedIds);
        setState(() => selectedIds.clear());
      }, color: Colors.green));
    } else if (_activeStatus == 'In Process' && r == 'craftsman') {
      actions.add(_actionBtn('Complete', Icons.check_circle_outline, () async {
        await StockOrderBulkCompleteDialog.show(context, ref, selectedIds);
        setState(() => selectedIds.clear());
      }, color: Colors.green));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onPressed, {Color? color}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColor.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildPreTable(LiveStockOrderState state) {
    return Padding(
      padding: isMobile
          ? const EdgeInsets.fromLTRB(4, 0, 4, 4)
          : const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: state.isLoading && state.liveStockOrders.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : state.liveStockOrders.isEmpty
              ? const NoDataWidget(
                  title: "No Stock Orders Found",
                  subtitle: "We couldn't find any stock orders matching your criteria.",
                  icon: Icons.assignment_outlined,
                )
              : ListView.separated(
                  itemCount: state.liveStockOrders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  itemBuilder: (context, index) {
                    final order = state.liveStockOrders[index];
                    return GestureDetector(
                      onTap: () {
                        Get.toNamed(
                          AppRoutes.stockOrderDetails,
                          arguments: order.id?.toString() ?? "",
                        );
                      },
                      child: StockOrderCard(
                        stockOrder: order,
                        role: role,
                        isSelected: selectedIds.contains(order.id.toString()),
                        onSelectionChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedIds.add(order.id.toString());
                            } else {
                              selectedIds.remove(order.id.toString());
                            }
                          });
                        },
                        onShare: () async {
                          final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(role?.toLowerCase());
                          
                          String? sharedOrderDate;
                          if (order.createdAt != null && order.createdAt!.isNotEmpty && order.createdAt != 'null') {
                            try {
                              sharedOrderDate = DateFormat('dd-MMM-yyyy').format(DateTime.parse(order.createdAt!));
                            } catch (_) {}
                          }

                          await ShareCardService.share(
                            context,
                            ShareCardItem(
                              imageUrl: order.imageUrl,
                              title: order.designCode ?? 'Stock Order',
                              bpCode: restricted ? null : order.buyer?.bpCode,
                              productCode: order.orderNumber,
                              narration: order.notes,
                              size: order.size,
                              orderDate: sharedOrderDate,
                              gramsDetail: order.grams != null
                                  ? '${order.grams} gm × ${order.quantity ?? 1} = ${order.totalWeightDisplay}'
                                  : null,
                              subtitle: 'Stock# ${order.orderNumber}',
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }

  void _showFilterDialog() {
    UniversalFilterDialog.show(
      context,
      ref,
      module: FilterModule.stockOrder,
      role: role,
      onApply: (url) {
                 setState(() { selectedFilter = ref.watchTr("filtered"); });
        ref.read(liveStockOrderNotifierProvider.notifier).fetchLiveStockOrders(customUrl: url);
      },
    );
  }

  Future<void> _shareSelected() async {
    if (selectedIds.isEmpty) return;

    try {
      final orders = ref.read(liveStockOrderNotifierProvider).liveStockOrders;
      final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(role?.toLowerCase());
      List<ShareCardItem> allShareItems = [];

      for (var id in selectedIds) {
        final selected = orders.firstWhere((po) => po.id.toString() == id);
        
        String? sharedOrderDate;
        if (selected.createdAt != null && selected.createdAt != 'null' && selected.createdAt!.isNotEmpty) {
          try {
            sharedOrderDate = DateFormat('dd-MMM-yyyy').format(DateTime.parse(selected.createdAt!));
          } catch (_) {}
        }

        allShareItems.add(ShareCardItem(
          imageUrl: selected.imageUrl,
          title: selected.designCode ?? 'Stock Order',
          bpCode: restricted ? null : selected.buyer?.bpCode,
          productCode: selected.orderNumber,
          narration: selected.notes,
          size: selected.size,
          orderDate: sharedOrderDate,
          gramsDetail: selected.grams != null
              ? '${selected.grams} gm × ${selected.quantity ?? 1} = ${selected.totalWeightDisplay}'
              : null,
          subtitle: 'Stock# ${selected.orderNumber}',
        ));
      }

      if (allShareItems.isEmpty) {
        Toaster.showError("No selected items found");
        return;
      }

      await ShareCardService.shareMultiple(context, allShareItems);
    } catch (e) {
      Toaster.showError("Failed to share selected items");
    }
  }

  void _printTable() async {
    if (selectedIds.isEmpty) {
      Get.snackbar("Info", "Please select items to print");
      return;
    }

    final ids = selectedIds.join(',');
    final endpoint = "api/common/stock-orders/generate-pdf?ids=$ids&tab=${_getTabValue()}";

    await ref.read(pdfDownloadProvider.notifier).downloadPDF(
      endpoint: endpoint,
      fileName: "StockOrders_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );

    final finalState = ref.read(pdfDownloadProvider);
    if (finalState.error != null) {
      Toaster.showError(finalState.error!);
    } else if (finalState.filePath != null) {
      Toaster.showSuccess("PDF Downloaded successfully");
    }
  }
}