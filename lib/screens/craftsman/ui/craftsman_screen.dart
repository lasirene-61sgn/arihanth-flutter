import 'dart:io';
import 'package:arianth/screens/craftsman/riverpod/craftsman_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/pagination_controls.dart';
import 'package:arianth/services/widget/reusable_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/localization/language_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../../app_color/app_color.dart';
import '../../../services/widget/reusable_fillter_dialog.dart';
import '../../../services/widget/reusable_sort.dart';
import '../widgets/craftsman_card.dart';
import 'package:arianth/services/widget/enterprise_search_bar.dart';
import 'package:arianth/services/widget/universal_filter_dialog.dart';
import 'package:arianth/services/common_notifiers/pdf_download_notifier.dart';
import 'package:arianth/services/widget/custom_msg.dart';

class CraftsmanScreen extends ConsumerStatefulWidget {
  const CraftsmanScreen({super.key});

  @override
  ConsumerState<CraftsmanScreen> createState() => _CraftsmanScreenState();
}

class _CraftsmanScreenState extends ConsumerState<CraftsmanScreen> {
  bool selectAll = false;
  Set<String> selectedIds = {};
  String? selectedFilter;
  String? selectedSort;
  bool isAscending = true;

  bool get isMobile => MediaQuery.of(context).size.width < 600;

  String? role;
  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role");
    super.initState();
    Future.microtask(() {
      ref.read(craftsmanListProvider.notifier).fetchCraftsmen();
    });
  }

  bool searchToggle = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(craftsmanListProvider);
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
          child: Divider(height: 1.0, color: AppColor.divider),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),

        // 🔵 Toggle between "CraftsMan" Title and Vertical-Centered Search Bar
        title: !searchToggle
            ? Text(
          ref.watchTr('craftsman'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
            : EnterpriseSearchBar(
          controller: _searchController,
          hintText: 'Search Craftsman, Code or Mobile...',
          onChanged: (value) {
            final searchUrl = "api/super-admin/craftsmen?search=$value";
            ref.read(craftsmanListProvider.notifier).fetchCraftsmen(url: searchUrl);
          },
          onCancel: () {
            setState(() {
              _searchController.clear();
              searchToggle = false;
            });
            ref.read(craftsmanListProvider.notifier).fetchCraftsmen();
          },
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () => LanguageSelector.show(context, ref),
          ),
        ],
      ),
        body: Stack(
          children: [
            Column(
              children: [
                if (selectedFilter != null) _buildActiveFilterRibbon(),
                // _buildHeaderDesktop(),
                _buildSelectAllBar(state),
                const SizedBox(height: 8),

                Flexible(
                  fit: FlexFit.loose,
                  child: _buildPreTable(),
                ),
                const SizedBox(height: 60), // Space for pagination
              ],
            ),
            if (state.nextUrl != null || state.previousUrl != null)
              PaginationControls(
                count: state.count,
                label: 'Craftsman',
                onNext: () => ref.read(craftsmanListProvider.notifier).goToNextPage(),
                onPrevious: () => ref.read(craftsmanListProvider.notifier).goToPreviousPage(),
                isFirstPage: state.previousUrl == null,
                isLastPage: state.nextUrl == null,
                isLoading: state.isLoading,
              ),
          ],
        ),
      bottomNavigationBar: ERPBottomNavigationBar(
        actions: [
          // 1. Filter
          NavActionItem(
            label: selectedFilter == null ? ref.watchTr('filter') : ref.watchTr('filtered'),
            icon: Icons.filter_alt,
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

          // 3. ADD NEW (Floating Center)
          NavActionItem(
            label: ref.watchTr('add_new'),
            icon: Icons.add,
            color: AppColor.primary,
            isFloatingCenter: true,
            onPressed: () => Get.toNamed(AppRoutes.craftsmanAdd),
          ),

          // 4. Print
          NavActionItem(
            label: ref.watchTr('print'),
            icon: Icons.print,
            color: selectedIds.isNotEmpty ? AppColor.primary : Colors.black,
            onPressed: _printTable,
          ),

          // 5. Reset or Sort
          // if (selectedFilter != null || selectedSort != null)
          //   NavActionItem(
          //     label: 'Reset',
          //     icon: Icons.refresh,
          //     color: Colors.red,
          //     onPressed: () {
          //       ref.read(craftsmanListProvider.notifier).fetchCraftsmen();
          //       setState(() {
          //         selectedFilter = null;
          //         selectedSort = null;
          //       });
          //     },
          //   ),
            NavActionItem(
              label: 'Sort',
              icon: Icons.sort_by_alpha,
              color: AppColor.primary,
              onPressed:()=> _showSortMenu(),
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

  Widget _buildSelectAllBar(state) {
    if (state.craftsmen.isEmpty) return const SizedBox.shrink();

    bool isAllSelectedOnPage = state.craftsmen.isNotEmpty &&
        state.craftsmen.every((c) => selectedIds.contains(c.id.toString()));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColor.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
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
                      for (var c in state.craftsmen) {
                        selectedIds.add(c.id.toString());
                      }
                    } else {
                      for (var c in state.craftsmen) {
                        selectedIds.remove(c.id.toString());
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
    final state = ref.watch(craftsmanListProvider);
    if (state.isLoading && state.craftsmen.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColor.primary));
    }
    if (state.craftsmen.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.craftsmen.length,
      itemBuilder: (context, index) {
        final craftsman = state.craftsmen[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: CraftsmanCard(
            craftsman: craftsman,
            isSelected: selectedIds.contains(craftsman.id.toString()),
            onSelectionChanged: (value) {
              setState(() {
                if (value == true) {
                  selectedIds.add(craftsman.id.toString());
                } else {
                  selectedIds.remove(craftsman.id.toString());
                }
              });
            },
            onEdit: () => Get.toNamed(AppRoutes.craftsmanAdd, arguments: craftsman.id.toString()),
            onDetail: () => Get.toNamed(AppRoutes.craftsmanView, arguments: craftsman.id.toString()),
          ),
        );
      },
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
          Text("${ref.watchTr('filtering')}:", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColor.primary)),
          const SizedBox(width: 8),
          Chip(
            label: Text("$selectedFilter: ${_searchController.text}", style: const TextStyle(fontSize: 10)),
            backgroundColor: AppColor.primary.withOpacity(0.1),
            deleteIcon: const Icon(Icons.close, size: 12, color: AppColor.primary),
            onDeleted: () {
              setState(() {
                selectedFilter = null;
                _searchController.clear();
              });
              ref.read(craftsmanListProvider.notifier).fetchCraftsmen();
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
              });
              ref.read(craftsmanListProvider.notifier).fetchCraftsmen();
            },
            child: Text(ref.watchTr('reset_btn'), style: const TextStyle(fontSize: 11, color: Colors.red)),
          )
        ],
      ),
    );
  }



  // -------------------------------------------------------------------------
  // EDIT & VIEW
  // -------------------------------------------------------------------------
  Future<void> _editCraftsman() async {
    final id = selectedIds.first;
    // await ref.read(craftsmanListProvider.notifier).craftManDetails(id, context);
    // if (mounted) {
    //   context.push(
    //     '${RouteNames.settings}/add',
    //     extra: {"screen": "CraftsMan", "type": "Edit", "id": id},
    //   );
    // }
  }

  void _showFilterDialog() {
    UniversalFilterDialog.show(
      context,
      ref,
      module: FilterModule.craftsman,
      role: role,
      onApply: (url) {
        setState(() {
          selectedFilter = ref.watchTr('filtered');
        });
        ref.read(craftsmanListProvider.notifier).fetchCraftsmen(url: url);
      },
    );
  }
  void _showSortMenu() {
    showSortDrawer(
      context: context,
      ref: ref,
      config: SortDrawerConfig(
        title: ref.watchTr('sort_craftsmen'),
        subtitle: ref.watchTr('choose_sort'),
        fields: [
          SortField(
            label: ref.watchTr('craftsman_code'),
            key: 'bp_code',
            icon: Icons.tag_rounded,
            sub: ref.watchTr('sort_by_bp'),
          ),
          SortField(
            label: ref.watchTr('craftsman_name'),
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
        onApply: (_, ascending) {
          final sortOrder = ascending ? 'asc' : 'desc';
          ref.read(craftsmanListProvider.notifier).fetchCraftsmen(url: "api/super-admin/craftsmen?sort=$sortOrder");
          setState(() {
            isAscending = ascending;
          });
        },
        onClear: () {
          ref.read(craftsmanListProvider.notifier).fetchCraftsmen();
          setState(() {
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
    final endpoint = "api/super-admin/craftsmen/generate-pdf?ids=$ids";

    await ref.read(pdfDownloadProvider.notifier).downloadPDF(
      endpoint: endpoint,
      fileName: "Craftsmen_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );

    final finalState = ref.read(pdfDownloadProvider);
    if (finalState.error != null) {
      Toaster.showError(finalState.error!);
    } else if (finalState.filePath != null) {
      Toaster.showSuccess("PDF Downloaded successfully");
    }
  }

  Widget _buildEmptyState() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
    child: Column(
      children: [
        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 24),
        const Text(
          'No craftsmen found',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Start adding craftsmen to see them here',
          style: TextStyle(fontSize: 15, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
