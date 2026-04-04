import 'package:arianth/screens/designs/model/designs_model.dart';
import 'package:arianth/screens/designs/riverpod/designs_notifier.dart';
import 'package:arianth/screens/designs/widgets/design_aprove_dialog.dart';
import 'package:arianth/screens/designs/widgets/design_card.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/services/common_notifiers/pdf_download_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:arianth/services/widget/resuable_responsive_desktop_header.dart';
import 'package:arianth/services/widget/reusable_table_image_cell.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:arianth/screens/designs/widgets/design_grid_card.dart';
import 'package:arianth/services/widget/pagination_controls.dart';
import 'package:arianth/services/widget/universal_filter_dialog.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';

import '../../../app_color/app_color.dart';
import '../../../services/responsive/responsive_helper.dart';
import '../../../services/localization/app_localization.dart';
import '../../../services/localization/language_selector.dart';
import '../../../services/widget/form_field_common_button.dart';
import '../../../services/widget/reusable_bottom_nav_bar.dart';
import '../../../services/widget/reusable_fillter_dialog.dart';
import '../../../services/widget/reusable_share_card.dart';
import '../../../services/widget/reusable_sort.dart';
import '../../../services/widget/reusable_table_image_cell.dart';
import '../../../services/widget/enterprise_search_bar.dart';

class DesignsScreen extends ConsumerStatefulWidget {
  const DesignsScreen({super.key});

  @override
  ConsumerState<DesignsScreen> createState() => _DesignsScreenState();
}

class _DesignsScreenState extends ConsumerState<DesignsScreen>
    with SingleTickerProviderStateMixin {
  String selectedType = '';
  Set<String> selectedIds = {};
  String? selectedFilter;
  String? selectedSort;
  String? role;
  bool isAscending = true;
  bool isGridMode = false;
  bool _isBulkSharing = false;

  late final TabController _tabController;
  // tab = '' means All (no ?tab= param)
  static const _tabs = [
    {'label': 'All',      'value': 'all'},
    {'label': 'Pending',  'value': 'pending'},
    {'label': 'Accepted', 'value': 'accepted'},
    {'label': 'Rejected', 'value': 'rejected'},
  ];

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role");
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      final tabValue = _tabs[_tabController.index]['value']!;
      final url = tabValue.isEmpty
          ? 'api/common/designs?tab=all'
          : 'api/common/designs?tab=$tabValue';
      ref.read(designsProvider.notifier).fetchDesigns(url: url);
    });
    Future.microtask(() {
      if (role == 'super_admin') {
        ref.read(designsProvider.notifier).fetchDesigns(url: "api/common/designs?tab=all");
      } else {
        ref.read(designsProvider.notifier).fetchDesigns(url: 'api/common/designs?tab=accepted');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get isMobile => MediaQuery.of(context).size.width < 600;

  bool searchToggle = false;
  final TextEditingController _searchController = TextEditingController();
  String _getTabValue() {
    if (role == 'super_admin') {
      return _tabs[_tabController.index]['value']!;
    }
    return 'accepted';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(designsProvider);
    final notifier = ref.read(designsProvider.notifier);
    return Scaffold(
      backgroundColor: AppColor.background,
        appBar: AppBar(
          backgroundColor: AppColor.appBarBackground,
          elevation: 0,
          surfaceTintColor: AppColor.transparent,
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

          // 2. Inset Enterprise Search Logic
          title: !searchToggle
              ? Text(
            ref.watchTr('designs'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          )
              : EnterpriseSearchBar(
            controller: _searchController,
            hintText: 'Search designs...',
            onChanged: (value) {
              final tabValue = _getTabValue();
              final url = "api/common/designs?tab=$tabValue&design_code=$value";
              ref.read(designsProvider.notifier).fetchDesigns(url: url);
            },
            onCancel: () {
              setState(() {
                _searchController.clear();
                searchToggle = false;
              });
              final tabValue = _getTabValue();
              final url = "api/common/designs?tab=$tabValue";
              ref.read(designsProvider.notifier).fetchDesigns(url: url);
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
          if (role == 'super_admin')
            IconButton(
              icon: Icon(isGridMode ? Icons.view_list : Icons.grid_view, color: Colors.white),
              onPressed: () => setState(() => isGridMode = !isGridMode),
            ),
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () => LanguageSelector.show(context, ref),
          ),
          ],
        ),
      body: Column(
        children: [
          // ── Tab Bar (WorkOrder style) ──
          if (role == 'super_admin')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColor.background,
              border: Border(bottom: BorderSide(color: AppColor.divider, width: 0.5)),
            ),
            child: Container(
              height: 40,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColor.divider,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: AppColor.transparent,
                indicator: BoxDecoration(
                  color: AppColor.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorPadding: const EdgeInsets.all(2),
                labelColor: AppColor.textWhite,
                unselectedLabelColor: AppColor.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: _tabs.map((t) => Tab(text: t['label'])).toList(),
              ),
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              children: [
                _buildSelectAllBar(state),
                const SizedBox(height: 8),
                Expanded(child: _buildPreTable()),
              ],
            ),
          ),
          if (state.nextUrl != null || state.previousUrl != null)
            PaginationControls(
              count: state.count,
              label: 'Designs',
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

          NavActionItem(
            label: ref.watchTr('sort'),
            icon: Icons.sort_by_alpha,
            color: AppColor.primary,
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
    );
  }



  void _showFilterDialog() {
    UniversalFilterDialog.show(
      context,
      ref,
      module: FilterModule.design,
      activeStatus: role == 'super_admin' ? _tabs[_tabController.index]['label'] : 'Accepted',
      role: role,
      onApply: (url) {
        ref.read(designsProvider.notifier).fetchDesigns(url: url);
      },
    );
  }
  void _showSortMenu() {
    showSortDrawer(
      context: context,
      ref: ref,
      config: SortDrawerConfig(
        title: ref.watchTr('sort_designs'),
        subtitle: ref.watchTr('choose_sort'),
        fields: [
          if (role == 'super_admin') ...[
            SortField(
              label: ref.watchTr('buyer_code'),
              key: 'bp_code',
              icon: Icons.tag_rounded,
              sub: ref.watchTr('sort_by_bp'),
            ),
            SortField(
              label: ref.watchTr('craftsman_code'),
              key: 'bp_code',
              icon: Icons.tag_rounded,
              sub: ref.watchTr('sort_by_bp'),
            ),
          ],
          SortField(
            label: ref.watchTr('buyer_name'),
            key: 'name',
            icon: Icons.sort_by_alpha_rounded,
            sub: ref.watchTr('sort_by_alpha'),
          ),
          SortField(
            label: ref.watchTr('mobile'),
            key: 'mobile',
            icon: Icons.phone_outlined,
            sub: ref.watchTr('sort_by'),
          ),
        ],
        initialField: selectedSort,
        initialAscending: isAscending,
        onApply: (field, ascending) {
           final sortOrder = ascending ? 'asc' : 'desc';
           final tab = _getTabValue();
          ref.read(designsProvider.notifier).fetchDesigns(url: "api/common/designs?tab=$tab&sort=$sortOrder&sort_by=${field.key}");
          setState(() {
            selectedSort = field.label;
            isAscending = ascending;
          });
        },
        onClear: () {
          ref.read(designsProvider.notifier).fetchDesigns();
          setState(() {
            selectedSort = null;
            isAscending = true;
          });
        },
      ),
    );
  }



  void _printTable() async {
    if (selectedIds.isEmpty) {
      Get.snackbar("Info", "Please select items to print");
      return;
    }

    final ids = selectedIds.join(',');
    final tab = _getTabValue();
    final endpoint = "api/common/designs/generate-pdf?ids=$ids&tab=$tab";

    await ref.read(pdfDownloadProvider.notifier).downloadPDF(
      endpoint: endpoint,
      fileName: "Designs_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );

    final finalState = ref.read(pdfDownloadProvider);
    if (finalState.error != null) {
      Toaster.showError(finalState.error!);
    } else if (finalState.filePath != null) {
      Toaster.showSuccess("PDF Downloaded successfully");
    }
  }

  Widget _buildSelectAllBar(state) {
    if (state.designs.isEmpty) return const SizedBox.shrink();

    bool isAllSelectedOnPage = state.designs.isNotEmpty &&
        state.designs.every((d) => selectedIds.contains(d.id.toString()));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColor.divider),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isAllSelectedOnPage,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      for (var d in state.designs) {
                        selectedIds.add(d.id.toString());
                      }
                    } else {
                      for (var d in state.designs) {
                        selectedIds.remove(d.id.toString());
                      }
                    }
                  });
                },
                activeColor: AppColor.primary,
                   checkColor: AppColor.textWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isAllSelectedOnPage ? 'Deselect All' : 'Select All',
              style: const TextStyle(color: AppColor.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            if (selectedIds.isNotEmpty)
              Text(
                '${selectedIds.length} Selected',
                style: const TextStyle(color: AppColor.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreTable() {
    final state = ref.watch(designsProvider);
    if (state.isLoading && state.designs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.designs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColor.textHint),
            const SizedBox(height: 16),
            const Text('No designs found', style: TextStyle(color: AppColor.textSecondary)),
          ],
        ),
      );
    }

    // Role-based Layout Selection
    if (role != 'super_admin' || isGridMode) {
      final screenWidth = MediaQuery.of(context).size.width;
      int crossAxisCount = screenWidth < 600 ? 2 : screenWidth < 1000 ? 3 : 5;
      double childAspectRatio = 0.8;

      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: state.designs.length,
        itemBuilder: (context, index) {
          final design = state.designs[index];
          return DesignGridCard(
            item: design,
            onTap: () => Get.toNamed(AppRoutes.designsDetails, arguments: design.id.toString()),
            onApprove: role == 'super_admin' ? () {
              DesignAproveDialog.show(context, ref, design.id.toString());
            } : null,
            isApproving: state.savingDesignId == design.id.toString(),
          );
        },
      );
    }

    // Default List View for Super Admin
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: state.designs.length,
      itemBuilder: (context, index) {
        final design = state.designs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: DesignCard(
            design: design,
            role: role,
            isSelected: selectedIds.contains(design.id.toString()),
            onSelectionChanged: (value) {
              setState(() {
                if (value == true) {
                  selectedIds.add(design.id.toString());
                } else {
                  selectedIds.remove(design.id.toString());
                }
              });
            },
            onEdit: () => Get.toNamed(AppRoutes.designsDetails, arguments: design.id.toString()),
            onShare: () async {
              final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(role?.toLowerCase());
              await ShareCardService.share(
                context,
                ShareCardItem(
                  imageUrl: design.imageUrl,
                  title: design.designName,
                  bpCode: restricted ? null : design.bpCode,
                  productCode: restricted ? null : design.designCode,
                  category: design.category,
                  refNo: restricted ? null : design.designCode,
                  isLocked: (design.isLocked == 1 && role?.toLowerCase() != 'super_admin'),
                  showWatermark: (design.isLocked == 1 && role?.toLowerCase() != 'super_admin'),
                ),
              );
            },
            onApprove: () {
              DesignAproveDialog.show(context, ref, design.id.toString());
            },
            isApproving: state.savingDesignId == design.id.toString(),
          ),
        );
      },
    );
  }

  Future<void> _shareSelected() async {
    if (selectedIds.isEmpty) return;

    setState(() {
      _isBulkSharing = true;
    });

    try {
      final state = ref.read(designsProvider);
      final List<ShareCardItem> shareItems = state.designs
          .where((item) => selectedIds.contains(item.id.toString()))
          .map((design) {
        final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(role?.toLowerCase());

        return ShareCardItem(
          imageUrl: design.imageUrl,
          title: design.designName,
          bpCode: restricted ? null : design.bpCode,
          productCode: restricted ? null : design.designCode,
          category: design.category,
          refNo: restricted ? null : design.designCode,
          isLocked: (design.isLocked == 1 && role?.toLowerCase() != 'super_admin'),
          showWatermark: (design.isLocked == 1 && role?.toLowerCase() != 'super_admin'),
        );
      }).toList();

      if (shareItems.isEmpty) {
        Toaster.showError("No selected items found on current page");
        return;
      }

      await ShareCardService.shareMultiple(context, shareItems);
    } catch (e) {
      debugPrint('Designs bulk share error: $e');
      Toaster.showError("Failed to share selected designs");
    } finally {
      if (mounted) {
        setState(() {
          _isBulkSharing = false;
        });
      }
    }
  }

}