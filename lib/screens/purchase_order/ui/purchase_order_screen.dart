import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/screens/purchase_order/model/purchase_orders_model.dart';
import 'package:arianth/screens/purchase_order/riverpod/purchase_orders_notifier.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/common_notifiers/pdf_download_notifier.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:arianth/screens/purchase_order/ui/widgets/purchase_order_approval_dialog.dart';
import 'package:arianth/screens/purchase_order/ui/widgets/purchase_order_status.dart';
import 'package:arianth/screens/purchase_order/ui/widgets/purchase_order_dialogue.dart';
import 'package:arianth/services/widget/universal_filter_dialog.dart';
import 'package:arianth/screens/purchase_order/ui/widgets/purchase_order_share_dialogue.dart';
import 'package:arianth/screens/purchase_order/ui/widgets/purchase_craftsman_bulk_accept_dialog.dart';
import 'package:arianth/screens/purchase_order/ui/widgets/purchase_craftsman_bulk_reject_dialog.dart';
import 'package:arianth/screens/purchase_order/ui/widgets/purchase_craftsman_bulk_complete_dialog.dart';
import 'package:arianth/screens/purchase_order/ui/widgets/purchase_order_card.dart';
import 'package:arianth/screens/purchase_order/ui/widgets/purchase_reallocate_dialog.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/localization/language_selector.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:arianth/services/widget/form_field_common_button.dart';
import 'package:arianth/services/widget/resuable_responsive_desktop_header.dart';
import 'package:arianth/services/widget/reusable_table_view.dart';
import 'package:arianth/services/widget/pagination_controls.dart';
import 'package:arianth/services/widget/share_template.dart';
import 'package:flutter/material.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_color/app_color.dart';
import '../../../services/widget/reusable_bottom_nav_bar.dart';
import '../../../services/widget/reusable_fillter_dialog.dart';
import '../../../services/widget/reusable_share_card.dart';
import '../../../services/widget/reusable_sort.dart';
import '../../../services/widget/custom_msg.dart';
import '../../../services/widget/enterprise_search_bar.dart';
import '../../../services/widget/no_data_widget.dart';

class PurchaseOrderScreen extends ConsumerStatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  ConsumerState<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends ConsumerState<PurchaseOrderScreen> {
  Set<String> selectedIds = {};
  String? selectedFilter;
  String? selectedSort;
  bool isAscending = true;
  String? _activeStatus = 'New';
  String? role;
  bool _isBulkSharing = false;


  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role") ?? '';
    Future.microtask(() async {
      final productState = ref.read(productListProvider.notifier);
      final purchaseState = ref.read(purchaseOrderListProvider.notifier);
      final future = <Future>[];
        future.add(purchaseState.fetchPurchaseOrders(customUrl:role == "craftsman"?"api/common/purchase-orders?tab=allocated&sort=desc": "api/common/purchase-orders?tab=created&sort=desc"));
      future.add(productState.fetchCraftBPCodes());
      future.add(productState.fetchBPCodes());
      future.add(productState.fetchCategories());

      await Future.wait(future);
    });
  }

  bool get isMobile =>
      MediaQuery
          .of(context)
          .size
          .width < 600;
  bool searchToggle = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseOrderListProvider);
    final notifier = ref.read(purchaseOrderListProvider.notifier);
    final pdfState = ref.watch(pdfDownloadProvider);

    return Stack(
      children: [
        Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        // Prevents tint color when scrolling through PO table
        scrolledUnderElevation: 0,
        // Fix: Keeps AppBar white during scroll
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(
              height: 1.0, color: Colors.white24),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),

        // 🔵 Toggle between Screen Title and Enterprise Search Bar
        title: !searchToggle
            ? Text(
          ref.watchTr('purchase_orders'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
            : EnterpriseSearchBar(
          controller: _searchController,
            hintText: 'Search order number, customer or BP code...',
          onChanged: (value) {
            final Map<String, String> statusToTab = {
              'All': 'all',
              'New': 'created',
              'Allocated': 'allocated',
              'In Process': 'in_process',
              'For Approval': 'for_approval',
              'Completed': 'completed',
              'Rejected': 'rejected',
            };
            final tab = statusToTab[_activeStatus] ?? 'all';
            final url = "api/common/purchase-orders?tab=$tab&search=$value";
            
            ref.read(purchaseOrderListProvider.notifier).fetchPurchaseOrders(
                customUrl: url);
          },
          onCancel: () {
            setState(() {
              _searchController.clear();
              searchToggle = false;
            });
            final Map<String, String> statusToTab = {
              'All': 'all',
              'New': 'created',
              'Allocated': 'allocated',
              'In Process': 'in_process',
              'For Approval': 'for_approval',
              'Completed': 'completed',
              'Rejected': 'rejected',
            };
            final tab = statusToTab[_activeStatus] ?? 'all';
            final url = "api/common/purchase-orders?tab=$tab";
            ref.read(purchaseOrderListProvider.notifier).fetchPurchaseOrders(
                customUrl: url);
          },
        ),

        actions: [
          if (selectedIds.isNotEmpty && (_activeStatus != "New" && _activeStatus != "All" || role?.toLowerCase() == 'super_admin'))
            _isBulkSharing
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    icon: Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage("assets/image/whatsapp.png"),
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    onPressed: _shareSelected,
                  ),
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () => LanguageSelector.show(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: PurchaseOrderStatusCards(
              onStatusChanged: (status) =>
                  setState(() {
                    _activeStatus = status;
                    selectedIds.clear();
                  }),
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              children: [
                _buildSelectAllBar(state),
                const SizedBox(height: 10),
                Expanded(child: _buildPreTable()),
              ],
            ),
          ),

          if (state.nextUrl != null || state.previousUrl != null)
            PaginationControls(
              count: state.count,
              label: 'PurchaseOrder',
              onNext: notifier.goToNextPage,
              onPrevious: notifier.goToPreviousPage,
              isFirstPage: state.previousUrl == null,
              isLastPage: state.nextUrl == null,
              isLoading: state.isLoading,
            ),
        ],
      ),
      floatingActionButton: _buildFab(),

      bottomNavigationBar: ERPBottomNavigationBar(
        actions: [
          NavActionItem(
            label: ref.watchTr('filter'),
            icon: Icons.filter_list_alt,
            color: AppColor.primary,
            onPressed: _showFilterDialog,
          ),
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
            label: ref.watchTr('new_po'),
            icon: Icons.add,
            color: AppColor.primary,
            isFloatingCenter: true,
            // ⭐️ Pops up in center
            onPressed: () => Get.toNamed(AppRoutes.purchaseOrderAdd),
          ),
          NavActionItem(
            label: ref.watchTr('sort'),
            icon: Icons.sort_by_alpha,
            color: Colors.purple,
            onPressed: _showSortMenu,
          ),
          NavActionItem(
            label: ref.watchTr('print'),
            icon: Icons.print,
            color: selectedIds.isNotEmpty ? AppColor.primary : Colors.black,
            onPressed: _printTable,
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

  Widget _buildSelectAllBar(PurchaseOrderListState state) {
    if (state.purchaseOrders.isEmpty) return const SizedBox.shrink();

    bool isAllSelectedOnPage = state.purchaseOrders.isNotEmpty && 
        state.purchaseOrders.every((po) => selectedIds.contains(po.id.toString()));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isAllSelectedOnPage) {
              selectedIds.clear();
            } else {
              for (var po in state.purchaseOrders) {
                selectedIds.add(po.id.toString());
              }
            }
          });
        },
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isAllSelectedOnPage,
                activeColor: AppColor.primary,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      for (var po in state.purchaseOrders) {
                        selectedIds.add(po.id.toString());
                      }
                    } else {
                      selectedIds.clear();
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isAllSelectedOnPage ? "Deselect All" : "Select All Items",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColor.textSecondary,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            if (selectedIds.isNotEmpty)
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
          ],
        ),
      ),
    );
  }

  Widget? _buildFab() {
    final isCraftsman = role?.toLowerCase() == 'craftsman';
    final isAdmin = role == 'Admin' || role == 'super_admin';
    final hasSelection = selectedIds.isNotEmpty;

    if (_activeStatus == 'New' && hasSelection && !isCraftsman) {
      return FloatingActionButton.extended(
        onPressed: () async {
          await PurchaseOrderAllocatedDialog.show(context, ref, selectedIds);
          setState(() => selectedIds.clear());
        },
        backgroundColor: AppColor.primary,
        icon: const Icon(Icons.assignment_ind, color: AppColor.textWhite),
        label: const Text('Allocate', style: TextStyle(color: AppColor.textWhite, fontWeight: FontWeight.bold)),
      );
    }
    if (_activeStatus == 'For Approval' && hasSelection && !isCraftsman) {
      return FloatingActionButton.extended(
        onPressed: () async {
          await PurchaseOrderApprovalDialog.show(context, ref, selectedIds);
          setState(() => selectedIds.clear());
        },
        backgroundColor: AppColor.primary,
        icon: const Icon(Icons.check_circle_outline, color: AppColor.textWhite),
        label: const Text('Approve', style: TextStyle(color: AppColor.textWhite, fontWeight: FontWeight.bold)),
      );
    }
    if (_activeStatus == 'Allocated' && isCraftsman && hasSelection) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: () async {
              await PurchaseCraftsmanBulkRejectDialog.show(context, ref, selectedIds);
              setState(() => selectedIds.clear());
            },
            backgroundColor: AppColor.primary,
            icon: const Icon(Icons.cancel_outlined, color: AppColor.textWhite),
            label: const Text('Reject', style: TextStyle(color: AppColor.textWhite, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            onPressed: () async {
              await PurchaseCraftsmanBulkAcceptDialog.show(context, ref, selectedIds);
              setState(() => selectedIds.clear());
            },
            backgroundColor: AppColor.primary,
            icon: const Icon(Icons.check_circle_outline, color: AppColor.textWhite),
            label: const Text('Accept', style: TextStyle(color: AppColor.textWhite, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    if (_activeStatus == 'In Process' && isCraftsman && hasSelection) {
      return FloatingActionButton.extended(
        onPressed: () async {
          await PurchaseCraftsmanBulkCompleteDialog.show(context, ref, selectedIds);
          setState(() => selectedIds.clear());
        },
        backgroundColor: AppColor.primary,
        icon: const Icon(Icons.check_circle_outline, color: AppColor.textWhite),
        label: const Text('Complete', style: TextStyle(color: AppColor.textWhite, fontWeight: FontWeight.bold)),
      );
    }
    if (_activeStatus == 'Rejected' && isAdmin && selectedIds.length == 1) {
      return FloatingActionButton.extended(
        onPressed: () async {
          await PurchaseReallocateDialog.show(context, ref, selectedIds);
          setState(() => selectedIds.clear());
        },
        backgroundColor: AppColor.primary,
        icon: const Icon(Icons.sync_alt, color: AppColor.textWhite),
        label: const Text('Reallocate', style: TextStyle(color: AppColor.textWhite, fontWeight: FontWeight.bold)),
      );
    }
    return null;
  }





  void _printTable() async {
    if (selectedIds.isEmpty) {
      Get.snackbar("Info", "Please select items to print");
      return;
    }

    final ids = selectedIds.join(',');
    final endpoint = "api/common/purchase-orders/generate-pdf?ids=$ids";

    await ref.read(pdfDownloadProvider.notifier).downloadPDF(
      endpoint: endpoint,
      fileName: "PurchaseOrders_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );

    final finalState = ref.read(pdfDownloadProvider);
    if (finalState.error != null) {
      Toaster.showError(finalState.error!);
    } else if (finalState.filePath != null) {
      Toaster.showSuccess("PDF Downloaded successfully");
    }
  }

  Future<void> _shareSelected() async {
    if (selectedIds.isEmpty) return;

    setState(() {
      _isBulkSharing = true;
    });

    try {
      final orders = ref.read(purchaseOrderListProvider).purchaseOrders;
      final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(role?.toLowerCase());
      List<ShareCardItem> allShareItems = [];

      for (var id in selectedIds) {
        final selected = orders.firstWhere((po) => po.id.toString() == id, orElse: () => orders.first);
        if (selected.items != null) {
          allShareItems.addAll(selected.items!.map((item) {
            String? sharedDueDate;
            if (selected.dueDate != null && selected.dueDate!.isNotEmpty && selected.dueDate != 'null') {
              try {
                final parsed = DateTime.parse(selected.dueDate!);
                sharedDueDate = DateFormat('dd-MMM-yyyy').format(parsed);
              } catch (e) {
                sharedDueDate = selected.dueDate;
              }
            }

            return ShareCardItem(
              imageUrl: item.image ?? item.imageUrl,
              title: item.productCategory ?? 'Purchase Order',
              bpCode: restricted ? null : selected.bpCode,
              productCode: restricted ? null : selected.orderNumber,
              category: item.subCategory,
              narration: restricted ? null : item.notes,
              dueDate: sharedDueDate,
              gramsDetail: (item.grams != null && item.grams!.isNotEmpty)
                  ? List.generate(item.grams!.length, (i) {
                      final g = item.grams![i];
                      final q = (item.quantity != null && item.quantity!.length > i) ? item.quantity![i] : "1";
                      final iT = (item.individualTotals != null && item.individualTotals!.length > i) ? item.individualTotals![i] : "1";
                      return "$g Grams(x$q) = $iT Grams";
                    }).join('\n')
                  : null,
              subtitle: 'PO# ${selected.orderNumber}  |  Due: ${sharedDueDate ?? ""}',
            );
          }));
        }
      }

      if (allShareItems.isEmpty) {
        Toaster.showError("No selected items found on current page");
        return;
      }

      await ShareCardService.shareMultiple(context, allShareItems);
    } catch (e) {
      debugPrint('Bulk share error: $e');
      Toaster.showError("Failed to share selected items");
    } finally {
      if (mounted) {
        setState(() {
          _isBulkSharing = false;
        });
      }
    }
  }

  void _showFilterDialog() {
    UniversalFilterDialog.show(
      context,
      ref,
      module: FilterModule.purchaseOrder,
      activeStatus: _activeStatus,
      role: role,
      onApply: (url) {
        ref.read(purchaseOrderListProvider.notifier).fetchPurchaseOrders(customUrl: url);
      },
    );
  }

  void _showSortMenu() {
    showSortDrawer(
      context: context,
      ref: ref,
      config: SortDrawerConfig(
        title: ref.watchTr('sort_po'),
        subtitle: ref.watchTr('choose_order'),
        fields: [], // No fields needed for unified sort
        initialAscending: isAscending,
        onApply: (_, ascending) {
          final sortOrder = ascending ? 'asc' : 'desc';
          final Map<String, String> statusToTab = {
            'All': 'all',
            'New': 'created',
            'Allocated': 'allocated',
            'In Process': 'in_process',
            'For Approval': 'for_approval',
            'Completed': 'completed',
            'Rejected': 'rejected',
          };
          final tab = statusToTab[_activeStatus] ?? 'all';
          ref.read(purchaseOrderListProvider.notifier).fetchPurchaseOrders(customUrl: "api/common/purchase-orders?tab=$tab&sort=$sortOrder");
          setState(() {
            isAscending = ascending;
          });
        },
        onClear: () {
          final Map<String, String> statusToTab = {
            'All': 'all',
            'New': 'created',
            'Allocated': 'allocated',
            'In Process': 'in_process',
            'For Approval': 'for_approval',
            'Completed': 'completed',
            'Rejected': 'rejected',
          };
          final tab = statusToTab[_activeStatus] ?? 'all';
          ref.read(purchaseOrderListProvider.notifier).fetchPurchaseOrders(customUrl:"api/common/purchase-orders?tab=$tab");
          setState(() {
            isAscending = true;
          });
        },
      ),
    );
  }


  Widget _buildPreTable() {
    final state = ref.watch(purchaseOrderListProvider);
    return Padding(
      padding: isMobile
          ? const EdgeInsets.fromLTRB(4, 0, 4, 4)
          : const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: state.isLoading && state.purchaseOrders.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : state.purchaseOrders.isEmpty
              ? const NoDataWidget(
                  title: "No Purchase Orders Found",
                  subtitle: "We couldn't find any orders matching your criteria. Try adjusting your filters or search.",
                  icon: Icons.assignment_outlined,
                )
              : ListView.separated(
              itemCount: state.purchaseOrders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              itemBuilder: (context, index) {
                final partner = state.purchaseOrders[index];
                return GestureDetector(
                  onTap: () {
                    Get.toNamed(
                      AppRoutes.purchaseOrderDetails,
                      arguments: partner.id.toString(),
                    );
                  },
                  child: PurchaseOrderCard(
                    purchaseOrder: partner,
                    role: role,
                    activeStatus: _activeStatus,
                    isSelected: selectedIds.contains(partner.id.toString()),
                    onSelectionChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedIds.add(partner.id.toString());
                        } else {
                          selectedIds.remove(partner.id.toString());
                        }
                      });
                    },
                    onEdit: () => Get.toNamed(
                      AppRoutes.purchaseOrderAdd,
                      arguments: partner.id.toString(),
                    ),
                    onShare: () async {
                      final items = partner.items ?? [];
                      if (items.isEmpty) return;
                      
                      final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(role?.toLowerCase());
                      List<ShareCardItem> shareItems = items.map((item) {
                        // Format dates without timezone
                        String? sharedDueDate;
                        if (partner.dueDate != null && partner.dueDate!.isNotEmpty && partner.dueDate != 'null') {
                          try {
                            final parsed = DateTime.parse(partner.dueDate!);
                            sharedDueDate = DateFormat('dd-MMM-yyyy').format(parsed);
                          } catch (e) {
                            sharedDueDate = partner.dueDate;
                          }
                        }

                        return ShareCardItem(
                          imageUrl: item.image ?? item.imageUrl,
                          title: item.productCategory ?? 'Purchase Order',
                          bpCode: restricted ? null : partner.bpCode,
                          productCode: restricted ? null : partner.orderNumber,
                          category: item.subCategory,
                          // weight: item.totalWeight?.toString(),
                          narration: restricted ? null : item.notes,
                          dueDate: sharedDueDate,
                          gramsDetail: (item.grams != null && item.grams!.isNotEmpty)
                              ? List.generate(item.grams!.length, (i) {
                                  final g = item.grams![i];
                                  final q = (item.quantity != null && item.quantity!.length > i) ? item.quantity![i] : "1";
                                  final iT = (item.individualTotals != null && item.individualTotals!.length > i) ? item.individualTotals![i] : "1";
                                  return "$g Grams(x$q) = $iT Grams";
                                }).join('\n')
                              : null,
                          subtitle: 'PO# ${partner.orderNumber}  |  Due: ${sharedDueDate ?? ""}',
                        );
                      }).toList();

                      await ShareCardService.shareMultiple(context, shareItems);
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showImageGallery(BuildContext context, PurchaseOrder order) {
    final images = order.displayImageUrls;

    if (images.isEmpty) {
      Toaster.showError('No images available for this order.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PageView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      images[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColor.primary,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined, color: Colors.white54, size: 50),
                            SizedBox(height: 10),
                            Text(
                              "Failed to load image",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
