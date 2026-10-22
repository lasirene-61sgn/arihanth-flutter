import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/screens/repairs/model/repair_model.dart';
import 'package:arianth/services/widget/no_data_widget.dart';
import 'package:arianth/screens/repairs/riverpod/repairs_notifier.dart';
import 'package:arianth/services/common_notifiers/pdf_download_notifier.dart';
import 'package:arianth/services/widget/custom_msg.dart';
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
    _tabController.addListener(_onTabChanged);

    Future.microtask(() {
      ref.read(repairListProvider.notifier).fetchRepairs();
      ref.read(productListProvider.notifier).fetchBPCodes();
    });
  }

  /// Returns the tab list appropriate for the current [role].
  List<_TabDef> _roleTabs() {
    if (role == 'buyer' || role == 'key_user' || role == 'user') {
      return [
        const _TabDef(key: 'all',       label: 'All'),
        const _TabDef(key: 'approval',  label: 'Approval'),
        const _TabDef(key: 'completed', label: 'Completed'),
      ];
    } else if (role == 'craftsman' || role == 'craftsman_staff') {
      return [
        const _TabDef(key: 'all',       label: 'All'),
        const _TabDef(key: 'assigned',  label: 'Assigned'),
        const _TabDef(key: 'completed', label: 'Completed'),
      ];
    } else {
      // super_admin, admin and any other role
      return [
        const _TabDef(key: 'all',       label: 'All'),
        const _TabDef(key: 'received',  label: 'Received'),
        const _TabDef(key: 'allocated', label: 'Allocated'),
        const _TabDef(key: 'completed', label: 'Completed'),
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
                child: state.isLoading && !state.isLoaded
                    ? const Center(
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
                              return RepairListCard(
                                repair: repair,
                                role: role,
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
                                onEdit: () => Get.toNamed(
                                    AppRoutes.repairsAdd,
                                    arguments: repair.id.toString()),
                                onShare: () => _shareRepair(repair),
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

    // Check if role is super_admin and active tab is received
    if (role != 'super_admin' && role != 'admin') return const SizedBox.shrink();

    final currentTabKey = _tabs[_tabController.index].key.toLowerCase();
    if (currentTabKey != 'received') return const SizedBox.shrink();

    final state = ref.read(repairListProvider);
    final selectedRepairs = state.repairs
        .where((r) => selectedIds.contains(r.id.toString()))
        .toList();

    if (selectedRepairs.isEmpty) return const SizedBox.shrink();

    // Show operation ONLY when selected items are strictly pending
    final bool allPending = selectedRepairs.every(
        (r) => (r.status ?? '').toLowerCase() == 'pending');
    if (!allPending) return const SizedBox.shrink();

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
