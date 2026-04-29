import 'package:arianth/services/widget/no_data_widget.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/screens/work_orders/model/work_orders_model.dart';
import 'package:arianth/screens/work_orders/riverpod/work_orders_notifier.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/common_notifiers/pdf_download_notifier.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:arianth/screens/work_orders/ui/widgets/allocate_order_dialog_utf8.dart';
import 'package:arianth/screens/work_orders/ui/widgets/approval_dialog.dart';
import 'package:arianth/screens/work_orders/ui/widgets/craftsman_bulk_accept_dialog.dart';
import 'package:arianth/screens/work_orders/ui/widgets/craftsman_bulk_reject_dialog.dart';
import 'package:arianth/screens/work_orders/ui/widgets/craftsman_bulk_complete_dialog.dart';
import 'package:arianth/screens/work_orders/ui/widgets/status_card.dart';
import 'package:arianth/screens/work_orders/ui/widgets/work_order_card.dart';
import 'package:arianth/screens/work_orders/ui/widgets/work_orders_table.dart';
import 'package:arianth/services/widget/pagination_controls.dart';
import 'package:arianth/services/widget/universal_filter_dialog.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/localization/language_selector.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:arianth/services/widget/reusable_table_view.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_color/app_color.dart';
import '../../../services/widget/form_field_common_button.dart';
import '../../../services/widget/reusable_bottom_nav_bar.dart';
import '../../../services/widget/reusable_fillter_dialog.dart';
import '../../../services/widget/reusable_share_card.dart';
import '../../../services/widget/reusable_sort.dart';
import '../../../services/widget/enterprise_search_bar.dart';

class WorkOrdersScreen extends ConsumerStatefulWidget {
  const WorkOrdersScreen({super.key});

  @override
  ConsumerState<WorkOrdersScreen> createState() => _WorkOrdersScreenState();
}

class _WorkOrdersScreenState extends ConsumerState<WorkOrdersScreen> {
  bool selectAll = false;
  Set<String> selectedIds = {};
  String? selectedFilter;
  String? selectedSort;
  bool isAscending = true;
  String? role;
  String? userBpCode;
  String? _activeStatus;
  late final ScrollController actionRow;

  bool _isBulkSharing = false;
  // New state for visible mobile actions
  Set<String> visibleActions = {
    'add',
    'allocate',
    'edit',
    'view',
    'filter',
    'sort',
    'export',
  };
  final GlobalKey _workOrderTemplateKey = GlobalKey();

  // Mapping strictly to api/super-admin URLs
  final Map<String, String> statusToTab = {
    'All': 'all-orders',
    'New': 'new-orders',
    'Allocated': 'allocated-orders',
    'In Process': 'in-process-orders',
    'For Approval': 'for-approval-orders',
    'Completed': 'completed-orders',
    'Rejected': 'rejected-orders',
    'Overdue': 'overdue-orders',
  };

  String _getTabValue() {
    return statusToTab[_activeStatus] ?? 'all-orders';
  }

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role") ?? '';
    userBpCode = SharedPreferencesHelper().getString("userBpCode") ?? '';

    selectedIds.clear();
    actionRow = ScrollController();
    Future.microtask(() async {
      final productNotifier = ref.read(productListProvider.notifier);
      final workOrderNotifier = ref.read(workOrderListProvider.notifier);

      String initialTab = (role?.toLowerCase() == 'craftsman') ? 'allocated-orders' : 'new-orders';
      _activeStatus = (role?.toLowerCase() == 'craftsman') ? 'Allocated' : 'New';

      final futures = <Future>[
        productNotifier.fetchCategories(),
        productNotifier.fetchBPCodes(),
        productNotifier.fetchCraftBPCodes(),
        workOrderNotifier.fetchWorkOrders(
          urls: "api/common/work-orders?tab=$initialTab",
        ),

      ];

      await Future.wait(futures);
    });
  }

  bool get isMobile => MediaQuery.of(context).size.width < 600;
  bool searchToggle = false;
  final TextEditingController _searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workOrderListProvider);
    final notifier = ref.read(workOrderListProvider.notifier);
    final pdfState = ref.watch(pdfDownloadProvider);

    return Stack(
      children: [
        Scaffold(
      appBar: AppBar(
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
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),

        // 🔵 Toggle between Screen Title and Enterprise Search Bar
        title: !searchToggle
            ? Text(
          ref.watchTr('work_orders'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
                   :
          EnterpriseSearchBar(
          controller: _searchController,
          hintText: 'Search order number, customer or BP code...',
          onChanged: (value) async {
            await ref.read(workOrderListProvider.notifier).fetchWorkOrders(
                urls: "api/common/work-orders?tab=${_getTabValue()}&search=$value");
          },
          onCancel: () async {
            setState(() {
              _searchController.clear();
              searchToggle = false;
            });
            await ref.read(workOrderListProvider.notifier).fetchWorkOrders(
                urls: "api/common/work-orders?tab=${_getTabValue()}");
          },
        ),


        actions: [

          if (selectedIds.isNotEmpty && (_activeStatus != "New" && _activeStatus != "Allocated" && _activeStatus != "All" || role?.toLowerCase() == 'super_admin'))
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
                        )
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: WorkOrderStatusCards(
              onStatusChanged: (status) => setState(() {
                _activeStatus = status;
                selectedIds.clear();
              }),
            ),
          ),

          const SizedBox(height: 10),
          _buildSelectAllBar(state),
          const SizedBox(height: 10),
          Flexible(fit: FlexFit.loose, child: _buildPreTable()),

          if (state.nextUrl != null || state.history.isNotEmpty || state.previousUrl != null)
            PaginationControls(
              count: state.count,
              currentCount: state.workOrders.length,
              label: 'Total WorkOrder',
              loadedLabel: 'Loaded WorkOrder',
              onNext: notifier.goToNextPage,
              onPrevious: notifier.goToPreviousPage,
              isFirstPage: state.history.isEmpty && state.previousUrl == null,
              isLastPage: state.nextUrl == null,
              isLoading: state.isLoading,
            ),
        ],
      ),
      // floatingActionButton: _buildBulkActions(isFab: true),
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
          if (role != 'craftsman' && role != 'Craftsman')
          NavActionItem(
            label: ref.watchTr('create'),
            icon: Icons.add,
            color: AppColor.primary,
            isFloatingCenter: true,
            onPressed: _openCreateWorkOrderDialog,
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
      ],
    );

  }
  Widget _buildSelectAllBar(WorkOrderListState state) {
    if (state.workOrders.isEmpty) return const SizedBox.shrink();

    // Check if all items on current page are selected
    bool isAllSelectedOnPage = state.workOrders.every((wo) => selectedIds.contains(wo.id.toString()));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isAllSelectedOnPage) {
              // Deselect all
              selectedIds.clear();
            } else {
              // Select all current page IDs
              for (var wo in state.workOrders) {
                selectedIds.add(wo.id.toString());
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
                        for (var wo in state.workOrders) {
                          selectedIds.add(wo.id.toString());
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
            Text(
              isAllSelectedOnPage ? "Deselect All" : "Select All Items",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            if (selectedIds.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  const SizedBox(width: 8),
                  _buildBulkActions(isFab: false),
                ],
              ),
          ],
        ),
      ),
    );
  }


  // via a provider like ref.read(shareServiceProvider) or ref.read(printServiceProvider).
  void _printTable() async {
    if (selectedIds.isEmpty) {
      Get.snackbar("Info", "Please select items to print");
      return;
    }

    final ids = selectedIds.join(',');
    final endpoint = "api/common/work-orders/generate-pdf?work_order_ids=$ids&tab=${_getTabValue()}";

    await ref.read(pdfDownloadProvider.notifier).downloadPDF(
      endpoint: endpoint,
      fileName: "WorkOrders_${DateTime.now().millisecondsSinceEpoch}.pdf",
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
      final state = ref.read(workOrderListProvider);
      final List<WorkOrder> selectedItems = state.workOrders
          .where((item) => selectedIds.contains(item.id.toString()))
          .toList();

      final List<ShareCardItem> shareItems = selectedItems.map((partner) {
        final imageUrl = partner.productImageUrl ?? partner.productImage;
        final bool isPdf = imageUrl?.toLowerCase().endsWith('.pdf') ?? false;

        return ShareCardItem(
          workOrderNumber: partner.workOrderNumber,
          imageUrl: imageUrl,
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
        );
      }).toList();

      if (shareItems.isEmpty) {
        Toaster.showError("No selected items found on current page");
        return;
      }

      await ShareCardService.shareMultiple(context, shareItems);
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
      module: FilterModule.workOrder,
      activeStatus: _activeStatus,
      role: role,
      onApply: (url) {
        ref.read(workOrderListProvider.notifier).fetchWorkOrders(urls: url);
      },
    );
  }
  void _showSortMenu() {
    showSortDrawer(
      context: context,
      ref: ref,
      config: SortDrawerConfig(
        title: ref.watchTr('sort_wo'),
        subtitle: ref.watchTr('choose_order'),
        fields: [], // No fields needed for the unified sort
        initialAscending: isAscending,
        onApply: (_, ascending) {
          final sortOrder = ascending ? 'asc' : 'desc';
          ref.read(workOrderListProvider.notifier).fetchWorkOrders(urls: "api/common/work-orders?tab=${_getTabValue()}&sort=$sortOrder");
          setState(() {
            isAscending = ascending;
          });
        },
        onClear: () {
          ref.read(workOrderListProvider.notifier).fetchWorkOrders(urls: "api/common/work-orders?tab=${_getTabValue()}"); // Default
          setState(() {
            isAscending = true;
          });
        },
      ),
    );
  }



  Widget _buildPreTable() {
    final state = ref.watch(workOrderListProvider);

    return Padding(
      padding: isMobile
          ? const EdgeInsets.fromLTRB(4, 0, 4, 4)
          : const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: state.isLoading  && state.workOrders.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : state.workOrders.isEmpty
              ? const NoDataWidget(
                  title: "No Work Orders Found",
                  subtitle: "We couldn't find any orders matching your criteria. Try adjusting your filters or search.",
                  icon: Icons.assignment_outlined,
                )
              : isMobile
          ? ListView.separated(
              itemCount: state.workOrders.length + (state.isLoading ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              itemBuilder: (context, index) {
                if (index == state.workOrders.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: CircularProgressIndicator(color: AppColor.primary),
                    ),
                  );
                }
                final partner = state.workOrders[index];
                return GestureDetector(
                  onTap: (){
                    Get.toNamed(AppRoutes.workOrdersDetails, arguments: partner.id.toString());
                  },
                  child: WorkOrderCard(
                    workOrder: partner,
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
                    onEdit: () async {
                      final id = partner.id;
                      Get.toNamed(AppRoutes.workOrdersAdd, arguments: id.toString());
                    },
                    onShare: () async {
                      final imageUrl = partner.productImageUrl ?? partner.productImage;
                      final bool isPdf = imageUrl?.toLowerCase().endsWith('.pdf') ?? false;

                      // 1. DATES: Format with time for Order Date
                      String? sharedOrderDate;
                      if (partner.createdAt != null && partner.createdAt.toString() != 'null') {
                        try {
                          final parsed = DateTime.parse(partner.createdAt.toString());
                          sharedOrderDate = DateFormat('dd-MMM-yyyy HH:mm').format(parsed);
                        } catch (e) {
                          sharedOrderDate = partner.createdAt.toString();
                        }
                      }

                      // 2. DATES: Format Due Date
                      String? sharedDueDate;
                      if (partner.dueDate != null && partner.dueDate != 'null') {
                        try {
                          final parsed = DateTime.parse(partner.dueDate!);
                          sharedDueDate = DateFormat('dd-MMM-yyyy').format(parsed);
                        } catch (e) {
                          sharedDueDate = partner.dueDate;
                        }
                      }

                      await ShareCardService.share(
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
                );
              },
            )
          : WorkOrdersTable(
              state: state,
              role: role,
              activeStatus: _activeStatus,
              selectedIds: selectedIds,
              onSelectionChanged: (newSelection) {
                setState(() => selectedIds = newSelection);
              },
            ),
    );
  }

  Widget _buildBulkActions({required bool isFab}) {
    if (selectedIds.isEmpty || role == 'buyer') return const SizedBox.shrink();

    final List<Widget> actions = [];

    if (_activeStatus == 'New' && role?.toLowerCase() == 'super_admin') {
      actions.add(
        _buildActionBtn(
          label: 'Allocate',
          icon: Icons.assignment_ind,
          onPressed: () async {
            await WorkOrderAllocatedDialog.show(context, ref, selectedIds);
            setState(() {
              selectedIds.clear();
            });
          },
          isFab: isFab,
        ),
      );
    } else if (_activeStatus == 'For Approval') {
      actions.add(
        _buildActionBtn(
          label: 'Approve',
          icon: Icons.check_circle_outline,
          backgroundColor: Colors.green.withOpacity(0.1),
          textColor: Colors.green,
          onPressed: () async {
            await WorkOrderApprovalDialog.show(context, ref, selectedIds);
            setState(() {
              selectedIds.clear();
            });
          },
          isFab: isFab,
        ),
      );
    } else if (_activeStatus == 'Rejected' && (role == 'Admin' || role == 'super_admin')) {
      actions.add(
        _buildActionBtn(
          label: 'Reallocate',
          icon: Icons.sync_alt,
          onPressed: () async {
            await WorkOrderAllocatedDialog.show(context, ref, selectedIds);
            setState(() {
              selectedIds.clear();
            });
          },
          isFab: isFab,
        ),
      );
    } else if (_activeStatus == 'In Process' && (role == 'craftsman' || role == 'Craftsman')) {
      actions.add(
        _buildActionBtn(
          label: 'Complete',
          icon: Icons.check_circle_outline,
          backgroundColor: Colors.green.withOpacity(0.1),
          textColor: Colors.green,
          onPressed: () async {
            await CraftsmanBulkCompleteDialog.show(context, ref, selectedIds);
            setState(() => selectedIds.clear());
          },
          isFab: isFab,
        ),
      );
    } else if (_activeStatus == 'Allocated' && role?.toLowerCase() == 'craftsman') {
      actions.add(
        _buildActionBtn(
          label: 'Reject',
          icon: Icons.cancel_outlined,
          backgroundColor: Colors.red.withOpacity(0.1),
          textColor: Colors.red,
          onPressed: () async {
            await CraftsmanBulkRejectDialog.show(context, ref, selectedIds);
            setState(() => selectedIds.clear());
          },
          isFab: isFab,
        ),
      );
      actions.add(const SizedBox(width: 8));
      actions.add(
        _buildActionBtn(
          label: 'Accept',
          icon: Icons.check_circle_outline,
          backgroundColor: Colors.green.withOpacity(0.1),
          textColor: Colors.green,
          onPressed: () async {
            await CraftsmanBulkAcceptDialog.show(context, ref, selectedIds);
            setState(() => selectedIds.clear());
          },
          isFab: isFab,
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    if (isFab) {
      if (actions.length == 1) return actions[0];
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    );
  }

  Widget _buildActionBtn({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isFab,
    Color? backgroundColor,
    Color? textColor,
  }) {
    if (isFab) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: backgroundColor ?? AppColor.primary,
        icon: Icon(icon, color: textColor ?? AppColor.textWhite),
        label: Text(label, style: TextStyle(color: textColor ?? AppColor.textWhite, fontWeight: FontWeight.bold)),
        heroTag: label,
      );
    } else {
      return FormFeildCommonButton(
        text: label,
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        textColor: textColor,
      );
    }
  }
}
  void _openCreateWorkOrderDialog() {
   Get.toNamed(AppRoutes.workOrdersAdd);
  }




