import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/screens/repairs/model/repair_model.dart';
import 'package:arianth/services/widget/no_data_widget.dart';
import 'package:arianth/screens/repairs/riverpod/repairs_notifier.dart';
import 'package:arianth/services/common_notifiers/pdf_download_notifier.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:arianth/services/widget/tara_text_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import '../../../services/widget/enterprise_search_bar.dart';
import '../../../services/widget/reusable_sort.dart';
import 'widgets/repair_card.dart';
import 'widgets/allocate_repair_dialog.dart';
import 'widgets/repair_completion_dialog.dart';
import 'package:arianth/services/widget/reusable_bottom_nav_bar.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:arianth/services/widget/pagination_controls.dart';
import 'package:arianth/services/widget/universal_filter_dialog.dart';
import 'package:arianth/services/widget/form_field_common_button.dart';

class RepairsScreen extends ConsumerStatefulWidget {
  const RepairsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RepairsScreen> createState() => _RepairsScreenState();
}

class _TabDef {
  final String key;
  final String label;
  const _TabDef({required this.key, required this.label});
}

class _RepairsScreenState extends ConsumerState<RepairsScreen>
    with SingleTickerProviderStateMixin {
  String? role;
  Set<String> selectedIds = {};
  bool searchToggle = false;
  final TextEditingController _searchController = TextEditingController();
  String? selectedFilter;
  bool isAscending = true;
  bool _isBulkSharing = false;
  late final List<_TabDef> _tabs;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role")?.toLowerCase() ?? '';
    // Compute tabs once and cache — never recomputed, so TabController index is stable
    _tabs = _roleTabs();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
      _onTabChanged();
    });

    Future.microtask(() {
      final initialTab = _tabs.isNotEmpty ? _tabs.first.key : null;
      ref.read(repairListProvider.notifier).fetchRepairs(tab: initialTab);
      ref.read(productListProvider.notifier).fetchBPCodes();
    });
  }

  /// Returns the tab list appropriate for the current [role].
  List<_TabDef> _roleTabs() {
    if (role == 'craftsman' || role == 'craftsman_staff') {
      return [
        const _TabDef(key: 'all',              label: 'All'),
        const _TabDef(key: 'assigned',         label: 'Assigned'),
        const _TabDef(key: 'in_process',       label: 'In Process'),
        const _TabDef(key: 'pending_approval', label: 'Pending Approval'),
        const _TabDef(key: 'completed',        label: 'Completed'),
      ];
    } else {
      // Super Admin, Admin, and Buyer see entire set of tabs
      return [
        const _TabDef(key: 'all',                label: 'All'),
        const _TabDef(key: 'new',                label: 'New'),
        const _TabDef(key: 'accepted',           label: 'Accepted'),
        const _TabDef(key: 'allocated',          label: 'Allocated'),
        const _TabDef(key: 'craftsman_approval', label: 'Craftsman Approval'),
        const _TabDef(key: 'approval',           label: 'Approval'),
        const _TabDef(key: 'buyer_approval',     label: 'Buyer Approval'),
        const _TabDef(key: 'completed',          label: 'Completed'),
        const _TabDef(key: 'rejected',           label: 'Rejected'),
      ];
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = _tabs[_tabController.index].key;
    setState(() {
      selectedIds.clear();
      selectedFilter = null;
      _searchController.clear();
    });
    ref.read(repairListProvider.notifier).changeTab(tab);
  }


  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repairListProvider);
    final pdfState = ref.watch(pdfDownloadProvider);



    return Stack(
      children: [
        Scaffold(
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
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            title: !searchToggle
                ? Text(
                    ref.watchTr('repairs') ?? 'Sample/Repair',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : EnterpriseSearchBar(
                    controller: _searchController,
                    hintText: 'Search sample/repairs...',
                    onChanged: (value) {
                      final tab = _tabs[_tabController.index].key;
                      ref.read(repairListProvider.notifier).fetchRepairs(
                          customUrl:
                              "api/common/repairs?tab=$tab&search=$value");
                    },
                    onCancel: () {
                      setState(() {
                        _searchController.clear();
                        searchToggle = false;
                      });
                      ref.read(repairListProvider.notifier).changeTab(
                            _tabs[_tabController.index].key,
                          );
                    },
                  ),
            actions: [
              if (selectedIds.isNotEmpty)
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
                        tooltip: 'Share selected',
                        icon: Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage('assets/image/whatsapp.png'),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        onPressed: _shareSelected,
                      ),
            ],
          ),
          body: Column(
            children: [
              _buildTabBar(state),
              if (selectedFilter != null) _buildActiveFilterRibbon(),
              _buildSelectAllBar(state),
              Expanded(
                child: (state.isLoading && state.repairs.isEmpty)
                    ?

                const Center(
                        child: CircularProgressIndicator(
                            color: AppColor.primary))
                    : state.repairs.isEmpty
                        ? const NoDataWidget(
                            title: "No Repairs Found",
                            subtitle:
                                "Your repair list is currently empty. Try searching or adjusting your filters.",
                            icon: Icons.build_circle_outlined,
                          )
                        : ListView.builder(
                            itemCount: state.repairs.length,
                            itemBuilder: (context, index) {
                              final repair = state.repairs[index];
                              final status = (repair.status ?? '').toLowerCase();
                              final craftsmanStatus = (repair.craftsmanStatus ?? '').toLowerCase();
                              final isPending = status == 'pending' || status == 'new';
                              final isAccepted = status == 'accepted' || status == 'allocated';
                              final activeTabKey = _tabs[_tabController.index].key.toLowerCase();
                              final isCraftsmanApprovalTab = activeTabKey == 'craftsman_approval';
                              final isBuyerApprovalTab = activeTabKey == 'buyer_approval';

                              final isSuperAdmin = role == 'super_admin' || role == 'admin';
                              final isCraftsman = role == 'craftsman' || role == 'craftsman_staff';
                              final isBuyer = role == 'buyer' || role == 'key_user' || role == 'user';

                              // Effective craftsman status: if craftsmanStatus is set, prefer it
                              final effectiveCraftsmanStatus = craftsmanStatus.isNotEmpty ? craftsmanStatus : status;

                              // --- Super Admin Actions ---
                              // 1. New tab: only Accept, Reject, Edit, Share
                              // 2. Accepted tab: only Allocate, Edit, Share
                              // 3. Allocated tab: no workflow buttons, only Edit, Share
                              // 4. Craftsman Approval tab: only Approve, Edit, Share
                              // 5. Buyer Approval tab: only Complete, Edit, Share
                              // 6. Completed / Rejected: only Edit, Share
                              // 7. All tab: matches the item's individual state
                              bool superAdminCanAccept = false;
                              bool superAdminCanApprove = false;
                              bool superAdminCanAllocate = false;
                              bool superAdminCanCompleteBuyer = false;
                              bool superAdminCanReject = false;

                              if (isSuperAdmin) {
                                switch (activeTabKey) {
                                  case 'new':
                                    superAdminCanAccept = true;
                                    superAdminCanReject = true;
                                    break;
                                  case 'accepted':
                                    superAdminCanAllocate = true;
                                    break;
                                  case 'allocated':
                                    // allocated no need button
                                    break;
                                  case 'craftsman_approval':
                                    superAdminCanApprove = true;
                                    break;
                                  case 'buyer_approval':
                                    superAdminCanCompleteBuyer = true;
                                    break;
                                  case 'approval':
                                    superAdminCanApprove = true;
                                    break;
                                  case 'completed':
                                  case 'rejected':
                                    break;
                                  case 'all':
                                  default:
                                    if (isPending) {
                                      superAdminCanAccept = true;
                                      superAdminCanReject = true;
                                    } else if (status == 'accepted') {
                                      superAdminCanAllocate = true;
                                    } else if (status == 'craftsman_approval') {
                                      superAdminCanApprove = true;
                                    } else if (status == 'buyer_approval') {
                                      superAdminCanCompleteBuyer = true;
                                    }
                                    break;
                                }
                              }

                              // --- Craftsman Actions ---
                              // 1. Assigned tab: only Accept, Reject, Share
                              // 2. In Process tab: only Complete, Share
                              // 3. Other tabs / All: strictly per status
                              bool craftsmanCanAccept = false;
                              bool craftsmanCanReject = false;
                              bool craftsmanCanComplete = false;

                              if (isCraftsman) {
                                switch (activeTabKey) {
                                  case 'assigned':
                                    craftsmanCanAccept = true;
                                    craftsmanCanReject = true;
                                    break;
                                  case 'in_process':
                                    craftsmanCanComplete = true;
                                    break;
                                  case 'pending_approval':
                                  case 'completed':
                                    break;
                                  case 'all':
                                  default:
                                    if (effectiveCraftsmanStatus == 'in_process' ||
                                        effectiveCraftsmanStatus == 'accepted' ||
                                        effectiveCraftsmanStatus == 'craftsman_accepted') {
                                      craftsmanCanComplete = true;
                                    } else if (effectiveCraftsmanStatus == 'allocated' ||
                                        effectiveCraftsmanStatus == 'assigned') {
                                      craftsmanCanAccept = true;
                                      craftsmanCanReject = true;
                                    }
                                    break;
                                }
                              }

                              // --- Buyer Actions ---
                              // 1. Approval tab: Accept & Complete buttons
                              // 2. New tab: only Edit, Share
                              // 3. Other tabs: only Share
                              bool buyerCanAccept = false;
                              bool buyerCanComplete = false;
                              bool buyerCanReject = false;

                              if (isBuyer) {
                                switch (activeTabKey) {
                                  case 'approval':
                                  case 'buyer_approval':
                                    buyerCanAccept = true;
                                    buyerCanComplete = true;
                                    break;
                                  case 'new':
                                  case 'accepted':
                                  case 'allocated':
                                  case 'rejected':
                                  case 'completed':
                                    break;
                                  case 'all':
                                  default:
                                    if (status == 'approval' ||
                                        status == 'buyer_approval' ||
                                        status == 'craftsman_completed') {
                                      buyerCanAccept = true;
                                      buyerCanComplete = true;
                                    }
                                    break;
                                }
                              }

                              // Edit button permission:
                              // Super Admin can edit on tabs
                              // Buyer can ONLY edit on 'new' tab / pending state
                              bool canEdit = false;
                              if (isSuperAdmin) {
                                canEdit = true;
                              } else if (isBuyer) {
                                canEdit = (activeTabKey == 'new' || isPending);
                              }

                              final currentRepairId = repair.id?.toString();
                              final isThisRepairBusy = state.activeActionRepairId != null &&
                                  state.activeActionRepairId == currentRepairId;

                              final isAcceptLoading = isThisRepairBusy &&
                                  (state.activeActionType == 'accept' ||
                                      state.activeActionType == 'buyer_accept');
                              final isApproveLoading = isThisRepairBusy && state.activeActionType == 'approve';
                              final isRejectLoading = isThisRepairBusy && state.activeActionType == 'reject';
                              final isAllocateLoading = isThisRepairBusy && state.activeActionType == 'allocate';
                              final isCompleteLoading = isThisRepairBusy &&
                                  (state.activeActionType == 'complete' ||
                                      state.activeActionType == 'buyer_complete');

                              return RepairListCard(
                                repair: repair,
                                role: role,
                                isAcceptLoading: isAcceptLoading,
                                isApproveLoading: isApproveLoading,
                                isRejectLoading: isRejectLoading,
                                isAllocateLoading: isAllocateLoading,
                                isCompleteLoading: isCompleteLoading,
                                isSelected: selectedIds
                                    .contains(repair.id.toString()),
                                onSelectionChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedIds.add(repair.id.toString());
                                    } else {
                                      selectedIds
                                          .remove(repair.id.toString());
                                    }
                                  });
                                },
                                onEdit: canEdit
                                    ? () => Get.toNamed(
                                        AppRoutes.repairsAdd,
                                        arguments: repair.id.toString())
                                    : null,
                                onShare: () => _shareRepair(repair),
                                onAccept: superAdminCanAccept
                                    ? () => _handleSingleAccept(repair)
                                    : (craftsmanCanAccept
                                        ? () => _handleSingleAccept(repair)
                                        : (buyerCanAccept ? () => _handleSingleBuyerAccept(repair) : null)),
                                onApprove: superAdminCanApprove
                                    ? () => _handleSingleApprove(repair)
                                    : null,
                                onComplete: superAdminCanCompleteBuyer
                                    ? () => _handleSingleBuyerComplete(repair)
                                    : (craftsmanCanComplete
                                        ? () => _handleSingleCraftsmanComplete(repair)
                                        : (buyerCanComplete ? () => _handleSingleBuyerComplete(repair) : null)),
                                onReject: superAdminCanReject
                                    ? () => _handleSingleReject(repair)
                                    : (craftsmanCanReject
                                        ? () => _handleSingleReject(repair)
                                        : (buyerCanReject ? () => _handleSingleBuyerReject(repair) : null)),
                                onAllocate: superAdminCanAllocate
                                    ? () => _handleSingleAllocate(repair)
                                    : null,
                                onTap: () {
                                  Get.toNamed(AppRoutes.repairsDetails,
                                      arguments: repair.id.toString());
                                },
                              );
                            },
                          ),
              ),

              // Pagination
              if (state.nextUrl != null || state.previousUrl != null)
                PaginationControls(
                  count: state.count ?? 0,
                  label: 'Repair',
                  onNext: () =>
                      ref.read(repairListProvider.notifier).goToNextPage(),
                  onPrevious: () =>
                      ref.read(repairListProvider.notifier).goToPreviousPage(),
                  isFirstPage: state.previousUrl == null,
                  isLastPage: state.nextUrl == null,
                  isLoading: state.isLoading,
                ),
            ],
          ),

          bottomNavigationBar: ERPBottomNavigationBar(
            actions: [
              NavActionItem(
                label: selectedFilter == null
                    ? ref.watchTr('filter')
                    : ref.watchTr('filtered'),
                icon: Icons.filter_list_alt,
                color: AppColor.primary,
                onPressed: () {
                  UniversalFilterDialog.show(
                    context,
                    ref,
                    module: FilterModule.repair,
                    role: role,
                    onApply: (url) {
                      setState(() {
                        selectedFilter = ref.watchTr("filtered");
                      });
                      ref
                          .read(repairListProvider.notifier)
                          .fetchRepairs(customUrl: url);
                    },
                  );
                },
              ),
              NavActionItem(
                label: ref.watchTr('search'),
                icon: Icons.search,
                color: AppColor.primary,
                onPressed: () {
                  setState(() => searchToggle = true);
                },
              ),
              if (role == 'buyer' || role == 'admin' || role == 'super_admin')
                NavActionItem(
                  label: ref.watchTr('create') ?? 'Create',
                  icon: Icons.add,
                  color: AppColor.primary,
                  isFloatingCenter: true,
                  onPressed: () => Get.toNamed(AppRoutes.repairsAdd),
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
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildTabBar(RepairListState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: AppColor.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          indicatorPadding: const EdgeInsets.all(2),
          labelColor: AppColor.textWhite,
          unselectedLabelColor: AppColor.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: List.generate(_tabs.length, (i) {
            final tab = _tabs[i];
            final count = state.counts[tab.key] ?? 0;
            final isActive = _tabController.index == i;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tab.label),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColor.textWhite.withValues(alpha: 0.2)
                          : AppColor.divider,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        color: isActive
                            ? AppColor.textWhite
                            : AppColor.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

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
          Text(
            "${ref.watchTr('filtering')}:",
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColor.primary),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text("$selectedFilter: ${_searchController.text}",
                style: const TextStyle(fontSize: 10)),
            backgroundColor: AppColor.primary.withOpacity(0.1),
            deleteIcon:
                const Icon(Icons.close, size: 12, color: AppColor.primary),
            onDeleted: () {
              setState(() {
                selectedFilter = null;
                _searchController.clear();
                UniversalFilterDialog.clearCache(FilterModule.repair);
              });
              ref
                  .read(repairListProvider.notifier)
                  .changeTab(_tabs[_tabController.index].key);
            },
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
            side: BorderSide.none,
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                selectedFilter = null;
                _searchController.clear();
                UniversalFilterDialog.clearCache(FilterModule.repair);
              });
              ref
                  .read(repairListProvider.notifier)
                  .changeTab(_tabs[_tabController.index].key);
            },
            child: Text(ref.watchTr('reset_btn'),
                style: const TextStyle(fontSize: 11, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSortMenu() {
    showSortDrawer(
      context: context,
      ref: ref,
      config: SortDrawerConfig(
        title: ref.watchTr('sort_repairs'),
        subtitle: ref.watchTr('choose_order'),
        fields: [],
        initialAscending: isAscending,
        onApply: (_, ascending) {
          final sortOrder = ascending ? 'asc' : 'desc';
          final tab = _tabs[_tabController.index].key;
          ref.read(repairListProvider.notifier).fetchRepairs(
              customUrl: 'api/common/repairs?tab=$tab&sort=$sortOrder');
          setState(() => isAscending = ascending);
        },
        onClear: () {
          ref
              .read(repairListProvider.notifier)
              .changeTab(_tabs[_tabController.index].key);
          setState(() => isAscending = true);
        },
      ),
    );
  }

  Widget _buildSelectAllBar(RepairListState state) {
    if (state.repairs.isEmpty) return const SizedBox.shrink();

    bool isAllSelected =
        state.repairs.every((r) => selectedIds.contains(r.id.toString()));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isAllSelected) {
              selectedIds.clear();
            } else {
              for (var r in state.repairs) {
                selectedIds.add(r.id.toString());
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
                  value: isAllSelected,
                  activeColor: AppColor.primary,
                  side: const BorderSide(color: AppColor.black, width: 1.5),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        for (var r in state.repairs) {
                          selectedIds.add(r.id.toString());
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
              isAllSelected ? "Deselect All" : "Select All Items",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColor.black,
                  fontSize: 14),
            ),
            const Spacer(),
            if (selectedIds.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${selectedIds.length} Selected",
                  style: const TextStyle(
                      color: AppColor.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              _buildBulkActions(),
            ],
          ],
        ),
      ),
    );
  }

  void _printTable() async {
    if (selectedIds.isEmpty) {
      Get.snackbar("Info", "Please select items to print");
      return;
    }

    final ids = selectedIds.join(',');
    final endpoint = "api/common/repairs/generate-pdf?ids=$ids";

    await ref.read(pdfDownloadProvider.notifier).downloadPDF(
          endpoint: endpoint,
          fileName: "Repairs_${DateTime.now().millisecondsSinceEpoch}.pdf",
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

    setState(() => _isBulkSharing = true);

    try {
      final currentState = ref.read(repairListProvider);
      final selectedRepairs = currentState.repairs
          .where((r) => selectedIds.contains(r.id.toString()))
          .toList();

      final List<ShareCardItem> shareItems = [];
      for (final repair in selectedRepairs) {
        final imageUrl = repair.imageProofUrl;
        if (imageUrl == null || imageUrl.isEmpty) continue;

        shareItems.add(ShareCardItem(
          imageUrl: imageUrl,
          title: repair.productName ?? 'Repair Order',
          category: repair.productName,
          weight: repair.weight,
          narration: repair.repairDetails,
          workOrderNumber:
              repair.orderNumber ?? repair.orderNo ?? repair.id?.toString(),
        ));
      }

      if (shareItems.isEmpty) {
        Toaster.showError('No items with images to share.');
        return;
      }

      await ShareCardService.shareMultiple(context, shareItems);
    } catch (e) {
      Toaster.showError('Share failed: $e');
    } finally {
      if (mounted) setState(() => _isBulkSharing = false);
    }
  }

  void _shareRepair(RepairOrder repair) {
    ShareCardService.share(
      context,
      ShareCardItem(
        imageUrl: repair.imageProofUrl,
        title: repair.productName ?? 'Repair Order',
        category: repair.productName,
        weight: repair.weight,
        narration: repair.repairDetails,
        workOrderNumber:
            repair.orderNumber ?? repair.orderNo ?? repair.id?.toString(),
      ),
    );
  }

  Widget _buildBulkActions() {
    if (selectedIds.isEmpty) return const SizedBox.shrink();

    final currentTabKey = _tabs[_tabController.index].key.toLowerCase();
    final isSuperAdmin = role == 'super_admin' || role == 'admin';
    final isCraftsman = role == 'craftsman' || role == 'craftsman_staff';

    // Show for super admin on 'new' or 'pending' or 'received' tab
    final bool isSuperAdminPending = isSuperAdmin &&
        (currentTabKey == 'new' || currentTabKey == 'pending' || currentTabKey == 'received');
    // Show for craftsman on 'assigned' tab
    final bool isCraftsmanAssigned = isCraftsman && currentTabKey == 'assigned';

    if (!isSuperAdminPending && !isCraftsmanAssigned) return const SizedBox.shrink();

    final state = ref.read(repairListProvider);
    final selectedRepairs = state.repairs
        .where((r) => selectedIds.contains(r.id.toString()))
        .toList();

    if (selectedRepairs.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 28,
          child: FormFeildCommonButton(
            text: "Reject",
            backgroundColor: AppColor.error,
            onPressed: _handleBulkReject,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 28,
          child: FormFeildCommonButton(
            text: "Accept",
            backgroundColor: Colors.green,
            onPressed: _handleBulkAccept,
          ),
        ),
      ],
    );
  }

  void _handleBulkAccept() {
    final count = selectedIds.length;
    Get.dialog(
      AlertDialog(
        title: const Text("Accept Selected Repairs"),
        content: Text(
          "Are you sure you want to accept the $count selected repair order(s)?",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final notifier = ref.read(repairListProvider.notifier);
              final idsToProcess = List<String>.from(selectedIds);
              for (final id in idsToProcess) {
                await notifier.acceptRepair(id);
              }
              setState(() => selectedIds.clear());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Confirm Accept"),
          ),
        ],
      ),
    );
  }

  void _handleSingleAccept(RepairOrder repair) {
    final id = repair.id?.toString();
    if (id == null) return;
    Get.dialog(
      AlertDialog(
        title: Text("Accept Repair #$id"),
        content: Text("Are you sure you want to accept repair order #$id?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await ref.read(repairListProvider.notifier).acceptRepair(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text("Confirm Accept"),
          ),
        ],
      ),
    );
  }

  void _handleSingleApprove(RepairOrder repair) {
    final id = repair.id?.toString();
    if (id == null) return;
    final TextEditingController itemSentByController =
        TextEditingController(text: repair.itemSentBy ?? '');

    Get.dialog(
      AlertDialog(
        title: Text("Approve Repair #$id"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Item Sent By"),
            const SizedBox(height: 8),
            TextField(
              controller: itemSentByController,
              decoration: const InputDecoration(
                hintText: "Enter item sent by",
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await ref.read(repairListProvider.notifier).approveRepair(
                    id,
                    itemSentBy: itemSentByController.text.trim(),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text("Approve"),
          ),
        ],
      ),
    );
  }

  void _handleSingleCraftsmanComplete(RepairOrder repair) {
    final id = repair.id?.toString();
    if (id == null) return;
    RepairCompletionDialog.show(
      context: context,
      repairId: id,
      type: RepairCompletionType.craftsman,
      initialItemCollectedBy: repair.itemCollectedBy,
      initialItemReturnedBy: repair.itemReturnedBy,
      onComplete: ({
        required itemCollectedBy,
        required itemReturnedBy,
        voucherImage,
        completionProofImage,
      }) async {
        return await ref.read(repairListProvider.notifier).completeRepair(
              id,
              itemCollectedBy: itemCollectedBy,
              itemReturnedBy: itemReturnedBy,
              craftsmanVoucherImage: voucherImage,
              craftsmanCompletionProofImage: completionProofImage,
            );
      },
    );
  }

  void _handleSingleBuyerAccept(RepairOrder repair) {
    final id = repair.id?.toString();
    if (id == null) return;
    final TextEditingController itemAcceptedByController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text("Accept Repair #$id"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Item Accepted By *"),
            const SizedBox(height: 8),
            TextField(
              controller: itemAcceptedByController,
              decoration: const InputDecoration(
                hintText: "Enter item accepted by",
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final acceptedBy = itemAcceptedByController.text.trim();
              if (acceptedBy.isEmpty) {
                Toaster.showError("Please enter Item Accepted By");
                return;
              }
              Get.back();
              await ref.read(repairListProvider.notifier).buyerAcceptRepair(
                    id,
                    itemAcceptedBy: acceptedBy,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text("Confirm Accept"),
          ),
        ],
      ),
    );
  }

  void _handleSingleBuyerReject(RepairOrder repair) {
    final id = repair.id?.toString();
    if (id == null) return;
    final TextEditingController reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text("Reject Repair #$id"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter rejection reason for repair order #$id:"),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "Enter rejection reason *",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                Toaster.showError("Please enter a rejection reason");
                return;
              }
              Get.back();
              await ref.read(repairListProvider.notifier).buyerRejectRepair(id, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              foregroundColor: Colors.white,
            ),
            child: const Text("Confirm Reject"),
          ),
        ],
      ),
    );
  }

  void _handleSingleBuyerComplete(RepairOrder repair) {
    final id = repair.id?.toString();
    if (id == null) return;
    RepairCompletionDialog.show(
      context: context,
      repairId: id,
      type: RepairCompletionType.buyer,
      initialItemCollectedBy: repair.itemCollectedBy,
      initialItemReturnedBy: repair.itemReturnedBy,
      onComplete: ({
        required itemCollectedBy,
        required itemReturnedBy,
        voucherImage,
        completionProofImage,
      }) async {
        return await ref.read(repairListProvider.notifier).buyerCompleteRepair(
              id,
              itemCollectedBy: itemCollectedBy,
              itemReturnedBy: itemReturnedBy,
              buyerVoucherImage: voucherImage,
              buyerCompletionProofImage: completionProofImage,
            );
      },
    );
  }

  void _handleSingleReject(RepairOrder repair) {
    final id = repair.id?.toString();
    if (id == null) return;
    final TextEditingController reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text("Reject Repair #$id"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter rejection reason for repair order #$id:"),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "Enter rejection reason *",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                Toaster.showError("Please enter a rejection reason");
                return;
              }
              Get.back();
              await ref.read(repairListProvider.notifier).rejectRepair(id, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              foregroundColor: Colors.white,
            ),
            child: const Text("Confirm Reject"),
          ),
        ],
      ),
    );
  }

  void _handleSingleAllocate(RepairOrder repair) {
    final id = repair.id?.toString();
    if (id == null) return;
    AllocateRepairDialog.show(
      context: context,
      repairId: id,
      initialCraftsmanCode: repair.allocatedCraftsmanCode ?? repair.craftsmanCode,
      initialItemSentBy: repair.itemSentBy,
      initialNotes: repair.notes ?? repair.allocationNotes,
      onAllocate: ({required craftsmanCode, itemSentBy, notes}) async {
        return await ref.read(repairListProvider.notifier).allocateRepair(
          id,
          craftsmanCode: craftsmanCode,
          itemSentBy: itemSentBy,
          notes: notes,
        );
      },
    );
  }

  void _handleBulkReject() {
    final count = selectedIds.length;
    final TextEditingController reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text("Reject Selected Repairs"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Rejecting $count selected repair order(s)."),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "Enter rejection reason *",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                Toaster.showError("Please enter a rejection reason");
                return;
              }
              Get.back();
              final notifier = ref.read(repairListProvider.notifier);
              final idsToProcess = List<String>.from(selectedIds);
              for (final id in idsToProcess) {
                await notifier.rejectRepair(id, reason);
              }
              setState(() => selectedIds.clear());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Confirm Reject"),
          ),
        ],
      ),
    );
  }
}
