import 'package:arianth/screens/buyer/model/buyer_model.dart';
import 'package:arianth/screens/buyer/riverpod/buyer_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:arianth/services/widget/form_field_common_button.dart';
import 'package:arianth/services/widget/pagination_controls.dart';
import 'package:arianth/services/widget/reusable_fillter_dialog.dart';
import 'package:arianth/services/widget/reusable_sort.dart';
import 'package:arianth/services/widget/reusable_table_view.dart';
import 'package:flutter/material.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/localization/language_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../../app_color/app_color.dart';
import '../../../services/widget/reusable_bottom_nav_bar.dart';
import '../widgets/buyer_card.dart';
import 'package:arianth/services/widget/enterprise_search_bar.dart';
import 'package:arianth/services/widget/universal_filter_dialog.dart';
import 'package:arianth/services/common_notifiers/pdf_download_notifier.dart';
import 'package:arianth/services/widget/custom_msg.dart';

class BuyerScreen extends ConsumerStatefulWidget {
  const BuyerScreen({super.key});

  @override
  ConsumerState<BuyerScreen> createState() => _BuyerScreenState();
}

class _BuyerScreenState extends ConsumerState<BuyerScreen> {
  Set<String> selectedIds = {};
  String? selectedFilter;
  String? selectedSort;
  bool isAscending = true;
  bool searchToggle = false;
  final TextEditingController _searchController = TextEditingController();

  String? role;

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role");
    Future.microtask(() async {
      await ref.read(buyerListProvider.notifier).fetchBuyers();
    });
  }

  bool get isMobile => MediaQuery.of(context).size.width < 600;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(buyerListProvider);
    final pdfState = ref.watch(pdfDownloadProvider);
    return Stack(
      children: [
        Scaffold(
      backgroundColor: AppColor.background, // Brighter, modern ERP background
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
        title: !searchToggle
            ? Text(
          ref.watchTr('buyers'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
            : EnterpriseSearchBar(
          controller: _searchController,
          hintText: 'Search buyers...',
          onChanged: (value) {
            final searchUrl = "/api/super-admin/buyers?search=$value";
            ref.read(buyerListProvider.notifier).fetchBuyers(url: searchUrl);
          },
          onCancel: () {
            setState(() {
              _searchController.clear();
              searchToggle = false;
            });
            ref.read(buyerListProvider.notifier).fetchBuyers();
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
              // 🟢 Enterprise Filter Ribbon: Shows what is currently being filtered
              if (selectedFilter != null) _buildActiveFilterRibbon(),

              // 🟢 Select All Bar
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
              label: 'Buyer',
              onNext: () => ref.read(buyerListProvider.notifier).goToNextPage(),
              onPrevious: () => ref.read(buyerListProvider.notifier).goToPreviousPage(),
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
            icon: Icons.filter_alt, // ERP-style icon
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
            label: ref.watchTr('add_new'),
            icon: Icons.add,
            color: AppColor.primary,
            isFloatingCenter: true,
            onPressed: () => Get.toNamed(AppRoutes.buyersAdd),
          ),
          NavActionItem(
            label: ref.watchTr('print'),
            icon: Icons.print,
            color: selectedIds.isNotEmpty ? AppColor.primary : Colors.black,
            onPressed: _printTable,
          ),
          if (selectedFilter != null || selectedSort != null)
            NavActionItem(
              label: ref.watchTr('reset'),
              icon: Icons.refresh,
              color: Colors.red,
              onPressed: () {
                _searchController.clear();
                ref.read(buyerListProvider.notifier).fetchBuyers();
                setState(() {
                  selectedFilter = null;
                  selectedSort = null;
                });
                UniversalFilterDialog.clearCache(FilterModule.buyer);
              },
            )
          else
            NavActionItem(
              label: ref.watchTr('sort'),
              icon: Icons.sort_by_alpha,
              color: AppColor.primary,
              onPressed: _showSortMenu,
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
            label: Text("$selectedFilter: ${_searchController.text}", style:  TextStyle(fontSize: 10)),
            backgroundColor: AppColor.primary.withOpacity(0.1),
            deleteIcon: const Icon(Icons.close, size: 12, color: AppColor.primary),
            onDeleted: () {
              setState(() {
                selectedFilter = null;
                _searchController.clear();
                UniversalFilterDialog.clearCache(FilterModule.buyer);
              });
              ref.read(buyerListProvider.notifier).fetchBuyers();
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
                UniversalFilterDialog.clearCache(FilterModule.buyer);
              });
              ref.read(buyerListProvider.notifier).fetchBuyers();
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
      module: FilterModule.buyer,
      role: role,
      onApply: (url) {
        setState(() {
          selectedFilter = ref.watchTr('filtered');
        });
        ref.read(buyerListProvider.notifier).fetchBuyers(url: url);
      },
    );
  }

  void _showSortMenu() {
    showSortDrawer(
      context: context,
      ref: ref,
      config: SortDrawerConfig(
        title: ref.watchTr('sort_buyers'),
        subtitle: ref.watchTr('choose_sort'),
        fields: [
          SortField(
            label: ref.watchTr('buyer_code'),
            key: 'bp_code',
            icon: Icons.tag_rounded,
            sub: ref.watchTr('sort_by_bp'),
          ),
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
        onApply: (_, ascending) {
          final sortOrder = ascending ? 'asc' : 'desc';
          ref.read(buyerListProvider.notifier).fetchBuyers(url: "api/super-admin/buyers?sort=$sortOrder");
          setState(() {
            isAscending = ascending;
          });
        },
        onClear: () {
          ref.read(buyerListProvider.notifier).fetchBuyers();
          setState(() {
            isAscending = true;
          });
        },
      ),
    );
  }



  Widget _buildSelectAllBar(state) {
    if (state.buyers.isEmpty) return const SizedBox.shrink();

    bool isAllSelectedOnPage = state.buyers.isNotEmpty &&
        state.buyers.every((b) => selectedIds.contains(b.id.toString()));

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
              width: 30,
              height: 30,
              child: Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: isAllSelectedOnPage,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        for (var b in state.buyers) {
                          selectedIds.add(b.id.toString());
                        }
                      } else {
                        for (var b in state.buyers) {
                          selectedIds.remove(b.id.toString());
                        }
                      }
                    });
                  },
                  activeColor: AppColor.primary,
                  checkColor: AppColor.textWhite,
                  side: const BorderSide(color: AppColor.black, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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

  Widget _buildPreTable() {
    final state = ref.watch(buyerListProvider);
    if (state.isLoading && state.buyers.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColor.primary));
    }
    if (state.buyers.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.buyers.length,
      itemBuilder: (context, index) {
        final buyer = state.buyers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: BuyerCard(
            buyer: buyer,
            isSelected: selectedIds.contains(buyer.id.toString()),
            onSelectionChanged: (value) {
              setState(() {
                if (value == true) {
                  selectedIds.add(buyer.id.toString());
                } else {
                  selectedIds.remove(buyer.id.toString());
                }
              });
            },
            onEdit: () => Get.toNamed(AppRoutes.buyersAdd, arguments: buyer.id.toString()),
            onDetail: () => Get.toNamed(AppRoutes.buyersDetails, arguments: buyer.id.toString()),
          ),
        );
      },
    );
  }



  void _printTable() async {
    if (selectedIds.isEmpty) {
      Get.snackbar("Info", "Please select items to print");
      return;
    }

    final ids = selectedIds.join(',');
    final endpoint = "api/super-admin/buyers/generate-pdf?ids=$ids";

    await ref.read(pdfDownloadProvider.notifier).downloadPDF(
      endpoint: endpoint,
      fileName: "Buyers_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );

    final finalState = ref.read(pdfDownloadProvider);
    if (finalState.error != null) {
      Toaster.showError(finalState.error!);
    } else if (finalState.filePath != null) {
      Toaster.showSuccess("PDF Downloaded successfully");
    }
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const Text('No buyers found', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}