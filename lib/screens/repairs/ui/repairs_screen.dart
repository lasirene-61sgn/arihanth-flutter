import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/screens/repairs/model/repair_model.dart';
import 'package:arianth/services/widget/no_data_widget.dart';
import 'package:arianth/screens/repairs/riverpod/repairs_notifier.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
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

class RepairsScreen extends ConsumerStatefulWidget {
  const RepairsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RepairsScreen> createState() => _RepairsScreenState();
}

class _RepairsScreenState extends ConsumerState<RepairsScreen> {
  String? role;
  Set<String> selectedIds = {};
  bool searchToggle = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role")?.toLowerCase() ?? '';
    
    Future.microtask(() {
      ref.read(repairListProvider.notifier).fetchRepairs();
      ref.read(productListProvider.notifier).fetchBPCodes();
    });
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
          ref.watchTr('repairs') ?? 'Sample/Repair', // Assuming translation exists
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          )
        ) : EnterpriseSearchBar(
          controller: _searchController,
          hintText: 'Search sample/repairs...',
          onChanged: (value) {
            ref.read(repairListProvider.notifier).fetchRepairs(
                customUrl: "api/common/repairs?search=$value");
          },
          onCancel: () {
            setState(() {
              _searchController.clear();
              searchToggle = false;
            });
            ref.read(repairListProvider.notifier).fetchRepairs();
          },
        ),

      ),
      body: Column(
        children: [
          _buildSelectAllBar(state),
          Expanded(
            child: state.isLoading && !state.isLoaded
                ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
                : state.repairs.isEmpty
                    ? const NoDataWidget(
                        title: "No Repairs Found",
                        subtitle: "Your repair list is currently empty. Try searching or adjusting your filters.",
                        icon: Icons.build_circle_outlined,
                      )
                    : ListView.builder(
                        itemCount: state.repairs.length,
                        itemBuilder: (context, index) {
                          final repair = state.repairs[index];
                          return RepairListCard(
                            repair: repair,
                            role: role,
                            isSelected: selectedIds.contains(repair.id.toString()),
                            onSelectionChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedIds.add(repair.id.toString());
                                } else {
                                  selectedIds.remove(repair.id.toString());
                                }
                              });
                            },
                            onEdit: () => Get.toNamed(AppRoutes.repairsAdd, arguments: repair.id.toString()),
                            onShare: () => _shareRepair(repair),
                            onTap: () {
                              // Navigate to details screen, pass ID
                              Get.toNamed(AppRoutes.repairsDetails, arguments: repair.id.toString());
                            },
                          );
                        },
                      ),
          ),
          
          // Pagination
          if (state.nextUrl != null || state.previousUrl != null)
            PaginationControls(
              count: state.count ?? 0,
              label: 'Ripair',
              onNext: () => ref.read(repairListProvider.notifier).goToNextPage(),
              onPrevious: () => ref.read(repairListProvider.notifier).goToPreviousPage(),
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
            onPressed: () {
               UniversalFilterDialog.show(
                 context, 
                 ref, 
                 module: FilterModule.repair,
                 role: role,
                 onApply: (url) {
                   ref.read(repairListProvider.notifier).fetchRepairs(customUrl: url);
                 },
               );
            },
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
          if (role == 'buyer' || role == 'admin' || role == 'super_admin')
          NavActionItem(
            label: ref.watchTr('create') ?? 'Create',
            icon: Icons.add,
            color: AppColor.primary,
            isFloatingCenter: true,
            onPressed: () {
              Get.toNamed(AppRoutes.repairsAdd);
            },
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

  bool isAscending = true;
  void _showSortMenu() {
    showSortDrawer(
      context: context,
      ref: ref,
      config: SortDrawerConfig(
        title: ref.watchTr('sort_repairs'),
        subtitle: ref.watchTr('choose_order'),
        fields: [], // No fields needed for unified sort
        initialAscending: isAscending,
        onApply: (_, ascending) {
          final sortOrder = ascending ? 'asc' : 'desc';
          ref.read(repairListProvider.notifier).fetchRepairs(customUrl: 'api/common/repairs?sort=$sortOrder');
          setState(() {
            isAscending = ascending;
          });
        },
        onClear: () {
          ref.read(repairListProvider.notifier).fetchRepairs(customUrl: 'api/common/repairs?sort=desc');
          setState(() {
            isAscending = true;
          });
        },
      ),
    );
  }



  Widget _buildSelectAllBar(RepairListState state) {
    if (state.repairs.isEmpty) return const SizedBox.shrink();

    bool isAllSelected = state.repairs.every((r) => selectedIds.contains(r.id.toString()));

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
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColor.black, fontSize: 14),
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
                  style: const TextStyle(color: AppColor.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
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

  void _shareRepair(RepairOrder repair) {
    final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(role?.toLowerCase());
    final bool isSample = repair.repair?.toLowerCase() == 'sample';

    ShareCardService.share(
      context,
      ShareCardItem(
        imageUrl: repair.imageProofUrl,
        title: repair.productName ?? 'Repair Order',
        category: repair.productName,
        weight: repair.weight,
        narration: isSample ? repair.sampleDetails : repair.repairDetails,
        workOrderNumber: repair.orderNo?.toString() ?? repair.id?.toString(),
      ),
    );
  }
}
