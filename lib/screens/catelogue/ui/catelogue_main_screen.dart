import 'package:arianth/screens/catelogue/riverpod/catalogue_notifier.dart';
import 'package:arianth/screens/catelogue/widget/catelogue_grid_screen.dart';
import 'package:arianth/screens/catelogue/widget/catalogue_list_view.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/localization/language_selector.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../../app_color/app_color.dart';
import '../../../services/widget/reusable_bottom_nav_bar.dart';
import '../../../services/widget/reusable_fillter_dialog.dart';
import '../../../services/widget/reusable_sort.dart';
import '../../../services/widget/enterprise_search_bar.dart';
import '../../../services/widget/universal_filter_dialog.dart';
import '../../../services/common_notifiers/pdf_download_notifier.dart';
import 'package:arianth/services/widget/pagination_controls.dart';
import '../../../services/widget/custom_msg.dart';

enum ViewMode { grid, list }

// 1. Renamed to CatalogueScreen
class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key});

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

// 2. Renamed State class
class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  String selectedType = '';
  Set<String> selectedIds = {};
  String? selectedFilter;
  String? selectedSort;
  String? role;

  bool isAscending = true;
  ViewMode viewMode = ViewMode.grid;
  bool _isBulkSharing = false;


  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role");
    Future.microtask(() async {
      ref.read(catalogueProvider.notifier).fetchCatalogues();
    });
  }

  bool get isMobile => MediaQuery.of(context).size.width < 600;
  bool searchToggle = false;
  final TextEditingController _searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogueProvider);
    final pdfState = ref.watch(pdfDownloadProvider);

    return Stack(
      children: [
        Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent, // Fix: Prevents color tint when scrolling
        scrolledUnderElevation: 0,            // Fix: Keeps it flat during scroll
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

        // Toggle logic for Enterprise Search
        title: !searchToggle
            ? Text(
          ref.watchTr('catalogue'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
            : EnterpriseSearchBar(
          controller: _searchController,
          hintText: 'Search designs in catalogue...',
          onChanged: (value) {
            ref.read(catalogueProvider.notifier).fetchCatalogues(
                url: "api/common/catalogue?search=$value");
          },
          onCancel: () {
            setState(() {
              _searchController.clear();
              searchToggle = false;
            });
            ref.read(catalogueProvider.notifier).fetchCatalogues();
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
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () => LanguageSelector.show(context, ref),
          ),
            IconButton(
              icon: Icon(viewMode == ViewMode.grid ? Icons.view_list : Icons.grid_view, color: Colors.white),
              onPressed: () {
                setState(() {
                  viewMode = viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (selectedFilter != null) _buildActiveFilterRibbon(),
          _buildSelectAllBar(state),
          const SizedBox(height: 8),
          Flexible(
            fit: FlexFit.loose,
            child: SafeArea(
              top: false,
              bottom: true,
                child: viewMode == ViewMode.grid 
                    ? CatalogueGridScreen(
                        selectedIds: selectedIds,
                        onSelectionChanged: (id, selected) {
                          setState(() {
                            if (selected) {
                              selectedIds.add(id);
                            } else {
                              selectedIds.remove(id);
                            }
                          });
                        },
                      ) 
                    : CatalogueListView(
                        selectedIds: selectedIds,
                        onSelectionChanged: (id, selected) {
                          setState(() {
                            if (selected) {
                              selectedIds.add(id);
                            } else {
                              selectedIds.remove(id);
                            }
                          });
                        },
                      )),
          ),
          if (state.nextUrl != null || state.previousUrl != null)
            PaginationControls(
              count: state.count,
              currentCount: state.catalogues.length,
              label: 'Total Catalogue',
              onNext: () => ref.read(catalogueProvider.notifier).goToNextPage(),
              onPrevious: () => ref.read(catalogueProvider.notifier).goToPreviousPage(),
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
            icon: Icons.filter_alt,
            color: AppColor.primary,
            onPressed: _showFilterDialog,
          ),
          NavActionItem(
            label: ref.watchTr('search'),
            icon: Icons.search,
            color: Colors.teal,
            onPressed: () {
              setState(() {
                searchToggle = true;
              });
            },
          ),
          // 3. Floating Center: View (Primary Action for Designs)
          // NavActionItem(
          //   label: 'WhatsApp',
          //   iconWidget: Image.asset('assets/image/whatsapp.png', width: 22, height: 22),
          //   color: const Color(0xFF25D366),
          //   isFloatingCenter: true,
          //   enabled: selectedIds.length == 1,
          //   onPressed: selectedIds.length == 1 ? () {
          //     // Your View Logic
          //   } : null,
          // ),
          // 4. Sort
          if (selectedFilter != null || selectedSort != null)
            NavActionItem(
              label: ref.watchTr('reset'),
              icon: Icons.refresh,
              color: Colors.red,
              onPressed: () {
                _searchController.clear();
                ref.read(catalogueProvider.notifier).fetchCatalogues();
                setState(() {
                  selectedFilter = null;
                  selectedSort = null;
                });
                UniversalFilterDialog.clearCache(FilterModule.catalogue);
              },
            )
          else
            NavActionItem(
              label: ref.watchTr('sort'),
              icon: Icons.sort_by_alpha,
              color: AppColor.primary,
              onPressed: _showSortMenu,
            ),

          // 5. Print
          NavActionItem(
             label: 'Print',
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

  Widget _buildSelectAllBar(state) {
    if (state.catalogues.isEmpty) return const SizedBox.shrink();

    bool isAllSelectedOnPage = state.catalogues.isNotEmpty &&
        state.catalogues.every((d) => selectedIds.contains(d.id.toString()));

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
              width: 30,
              height: 30,
              child: Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: isAllSelectedOnPage,
                  side: const BorderSide(color: AppColor.black, width: 1.5),
                  activeColor: AppColor.primary,
                  checkColor: AppColor.textWhite,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        for (var d in state.catalogues) {
                          selectedIds.add(d.id.toString());
                        }
                      } else {
                        for (var d in state.catalogues) {
                          selectedIds.remove(d.id.toString());
                        }
                      }
                    });
                  },
                ),
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
                UniversalFilterDialog.clearCache(FilterModule.catalogue);
              });
              ref.read(catalogueProvider.notifier).fetchCatalogues();
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
                UniversalFilterDialog.clearCache(FilterModule.catalogue);
              });
              ref.read(catalogueProvider.notifier).fetchCatalogues();
            },
            child: Text(ref.watchTr('reset_btn'), style: const TextStyle(fontSize: 11, color: Colors.red)),
          )
        ],
      ),
    );
  }

  void _showFilterDialog() {
    UniversalFilterDialog.show(
      context,
      ref,
      module: FilterModule.catalogue,
      role: role,
      onApply: (url) {
        ref.read(catalogueProvider.notifier).fetchCatalogues(url: url);
      },
    );
  }
  void _showSortMenu() {
    showSortDrawer(
      context: context,
      ref: ref,
      config: SortDrawerConfig(
        title: ref.watchTr('sort_products'),
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
            label: ref.watchTr('product_name'),
            key: 'Product Name',
            icon: Icons.sort_by_alpha_rounded,
            sub: ref.watchTr('sort_by_alpha'),
          ),
        ],
        initialField: selectedSort,
        initialAscending: isAscending,
        onApply: (field, ascending) {
          final sortOrder = ascending ? 'asc' : 'desc';
          ref.read(catalogueProvider.notifier).fetchCatalogues(url: "api/common/catalogue?sort=$sortOrder");
          setState(() {
            selectedSort = field.label;
            isAscending = ascending;
          });
        },
        onClear: () {
          ref.read(catalogueProvider.notifier).fetchCatalogues();
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
    final endpoint = "api/common/catalogue/generate-pdf?ids=$ids";

    await ref.read(pdfDownloadProvider.notifier).downloadPDF(
      endpoint: endpoint,
      fileName: "Catalogue_${DateTime.now().millisecondsSinceEpoch}.pdf",
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
      final state = ref.read(catalogueProvider);
      final List<ShareCardItem> shareItems = state.catalogues
          .where((item) => selectedIds.contains(item.id.toString()))
          .map((c) {
        final String? currentRole = SharedPreferencesHelper().getString("role");
        final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(currentRole?.toLowerCase());

        return ShareCardItem(
          imageUrl: c.imageUrl ?? c.productImage,
          title: c.productName,
          productCode: restricted ? null : c.productCode,
          category: c.categoryName,
          weight: c.weightFrom != null ? "${c.weightFrom} gm" : null,
          size: c.size,
          refNo: restricted ? null : c.designCode,
        );
      }).toList();

      if (shareItems.isEmpty) {
        Toaster.showError("No selected items found on current page");
        return;
      }

      await ShareCardService.shareMultiple(context, shareItems);
    } catch (e) {
      debugPrint('Catalogue bulk share error: $e');
      Toaster.showError("Failed to share selected items");
    } finally {
      if (mounted) {
        setState(() {
          _isBulkSharing = false;
        });
      }
    }
  }
}