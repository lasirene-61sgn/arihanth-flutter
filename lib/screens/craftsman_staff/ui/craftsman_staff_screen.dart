import 'dart:io';

import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/craftsman_staff/model/craftsman_staff_model.dart';
import 'package:arianth/screens/craftsman_staff/riverpod/craftsman_staff_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/resuable_responsive_desktop_header.dart';
import 'package:arianth/services/widget/reusable_file_picker.dart';
import 'package:arianth/services/widget/reusable_sort.dart';
import 'package:arianth/services/widget/reusable_table_view.dart';
import 'package:arianth/screens/craftsman_staff/widgets/craftsman_staff_card.dart';
import 'package:arianth/services/widget/enterprise_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/localization/language_selector.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'package:arianth/services/widget/pagination_controls.dart';
import '../../../services/widget/form_field_common_button.dart';
import '../../../services/widget/reusable_bottom_nav_bar.dart';
import '../../../services/common_notifiers/pdf_download_notifier.dart';
import '../../../services/widget/custom_msg.dart';
import '../../products/riverpod/products_notifier.dart';

class CraftsmanStaffScreen extends ConsumerStatefulWidget {
  const CraftsmanStaffScreen({super.key});

  @override
  ConsumerState<CraftsmanStaffScreen> createState() => _CraftsmanStaffScreenState();
}

class _CraftsmanStaffScreenState extends ConsumerState<CraftsmanStaffScreen> {
   Set<String> selectedIds = {};
   bool searchToggle = false;
   final TextEditingController _searchController = TextEditingController();
   String? role;
   @override
   void initState() {
     super.initState();
     role = SharedPreferencesHelper().getString("role");
    Future.microtask(() {
      ref.read(craftsmanStaffProvider.notifier).fetchCraftsmanStaff(urls: "api/common/craftsman-staff");
      ref.read(productListProvider.notifier).fetchBPCodes();
      ref.read(productListProvider.notifier).fetchCraftBPCodes();
    });
  }


  bool get isMobile => MediaQuery.of(context).size.width < 600;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(craftsmanStaffProvider);
    final pdfState = ref.watch(pdfDownloadProvider);

    return Stack(
      children: [
        Scaffold(
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

        // Dynamic Title Area
        title: !searchToggle
            ? Text(
          ref.watchTr('CraftsmanStaff'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
            : EnterpriseSearchBar(
          controller: _searchController,
          hintText: ref.watchTr('Search by Name, Code or Email...'),
          onChanged: (value) {
            ref.read(craftsmanStaffProvider.notifier).fetchCraftsmanStaff(
                urls: "api/common/craftsman-staff?search=$value");
          },
          onCancel: () {
            setState(() {
              _searchController.clear();
              searchToggle = false;
            });
            ref.read(craftsmanStaffProvider.notifier).fetchCraftsmanStaff();
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
              label: 'CraftsmanStaff',
              onNext: () => ref.read(craftsmanStaffProvider.notifier).goToNextPage(),
              onPrevious: () => ref.read(craftsmanStaffProvider.notifier).goToPreviousPage(),
              isFirstPage: state.previousUrl == null,
              isLastPage: state.nextUrl == null,
              isLoading: state.isLoading,
            ),
        ],
      ),

      bottomNavigationBar: ERPBottomNavigationBar(
        actions: [
          // 1. LEFT: Export
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
            label: ref.watchTr('create'),
            icon: Icons.person_add_alt_1,
            color: AppColor.primary, // Primary action color
            isFloatingCenter: true, // ⭐️ Primary Action
            onPressed: () => Get.toNamed(AppRoutes.craftsmanStaffAdd),
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
            color: selectedIds.isNotEmpty ? AppColor.indigo : Colors.black,
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
        title: ref.watchTr('sort_craftsman_staff'),
        subtitle: ref.watchTr('choose_order'),
        fields: [], // No fields needed for unified sort
        initialAscending: isAscending,
        onApply: (_, ascending) {
          final sortOrder = ascending ? 'asc' : 'desc';
          ref.read(craftsmanStaffProvider.notifier).fetchCraftsmanStaff(urls: "api/common/craftsman-staff?sort=$sortOrder");
          setState(() {
            isAscending = ascending;
          });
        },
        onClear: () {
          ref.read(craftsmanStaffProvider.notifier).fetchCraftsmanStaff();
          setState(() {
            isAscending = true;
          });
        },
      ),
    );
  }

  Widget _buildSelectAllBar(state) {
    if (state.craftsman_staff.isEmpty) return const SizedBox.shrink();

    bool isAllSelectedOnPage = state.craftsman_staff.isNotEmpty &&
        state.craftsman_staff.every((d) => selectedIds.contains(d.id.toString()));

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
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        for (var d in state.craftsman_staff) {
                          selectedIds.add(d.id.toString());
                        }
                      } else {
                        for (var d in state.craftsman_staff) {
                          selectedIds.remove(d.id.toString());
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
              isAllSelectedOnPage ? ref.watchTr('Deselect All') : ref.watchTr('Select All'),
              style: const TextStyle(color: AppColor.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            if (selectedIds.isNotEmpty)
              Text(
                '${selectedIds.length} ${ref.watchTr('Selected')}',
                style: const TextStyle(color: AppColor.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

   Widget _buildHeaderDesktop() {
     final hasSelection = selectedIds.isNotEmpty;
     final singleSelection = selectedIds.length == 1;

     return Column(
       children: [
         if(!isMobile) Container(
           width: double.infinity,
           height: 50,
           padding: EdgeInsets.symmetric(vertical: 10,horizontal: 50),
           decoration: BoxDecoration(
             color: AppColor.silver.withOpacity(0.1),
             border: const Border(
               left: BorderSide(
                 color: AppColor.white,
                 width: 1,
               ),
             ),
           ),
           child: Text(ref.watchTr("CraftsmanStaff"), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.white)),

         ),
         ResponsiveDesktopHeader(
           title: ref.watchTr('CraftsmanStaff'),
           backgroundColor: AppColor.white,
           showBorder: true,
           showShadow: false,
           actions: [
             ActionButtonConfig(
               label: ref.watchTr('Add New'),
               icon: Icons.add,
               color: AppColor.primary,
               onPressed: () {
                 Get.toNamed(AppRoutes.craftsmanStaffAdd);

               },
             ),
             ActionButtonConfig(
               label: ref.watchTr('View'),
               icon: Icons.visibility,
               color: AppColor.primary,
               enabled: singleSelection,
               // onPressed: singleSelection
               //     ? () async {
               //   await ref.read(craftsmanStaffProvider.notifier).craftsman_staffDetails(selectedIds.first, context);
               //   if (mounted) {
               //     context.push('${RouteNames.craftsman_staff}/view',
               //         extra: {"screenName": "CraftsmanStaff"});
               //   }
               // }
               //     : null,
             ),
             if(role != "Admin")  ActionButtonConfig(
               label: ref.watchTr('Edit'),
               icon: Icons.edit,
               color: AppColor.primary,
               enabled: singleSelection,
               // onPressed: singleSelection
               //     ? () async {
               //   await ref.read(craftsmanStaffProvider.notifier).craftsman_staffDetails(selectedIds.first, context);
               //   if (mounted) {
               //     context.push('${RouteNames.craftsman_staff}/add',
               //         extra: {"screenName": "CraftsmanStaff", "type": "Edit"});
               //   }
               // }
               //     : null,
             ),

             ActionButtonConfig(
               label: ref.watchTr('Print'),
               icon: Icons.print,
               color: Colors.indigo,
               onPressed: ()=>_printTable(),
             ),
             // ActionButtonConfig(
             //   label: 'Share',
             //   icon: Icons.share,
             //   color: Colors.green,
             //   enabled: singleSelection,
             // ),
           ],
         ),
       ],
     );
   }


   void _printTable() async {
     if (selectedIds.isEmpty) {
       Get.snackbar(ref.read(localeProvider.notifier).translate("Info"), ref.read(localeProvider.notifier).translate("Please select items to print"));
       return;
     }

     final ids = selectedIds.join(',');
     final endpoint = "api/common/craftsman-staff/generate-pdf?ids=$ids";

     await ref.read(pdfDownloadProvider.notifier).downloadPDF(
       endpoint: endpoint,
       fileName: "CraftsmanStaff_${DateTime.now().millisecondsSinceEpoch}.pdf",
     );

     final finalState = ref.read(pdfDownloadProvider);
     if (finalState.error != null) {
       Toaster.showError(finalState.error!);
     } else if (finalState.filePath != null) {
       Toaster.showSuccess(ref.read(localeProvider.notifier).translate("PDF Downloaded successfully"));
     }
   }
   // Make sure you have imported your KycDocument file at the top of this file!
// import 'package:arianth/services/widget/reusable_file_picker.dart';

  Widget _buildPreTable() {
    final state = ref.watch(craftsmanStaffProvider);

    if (state.isLoading && state.craftsman_staff.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.craftsman_staff.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColor.textHint.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              ref.watchTr('No craftsman_staff found'),
              style: const TextStyle(color: AppColor.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), // Space for bottom nav
      itemCount: state.craftsman_staff.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final craftsman_staff = state.craftsman_staff[index];
        final id = craftsman_staff.id.toString();
        final isSelected = selectedIds.contains(id);

        return CraftsmanStaffCard(
          craftsman_staff: craftsman_staff,
          isSelected: isSelected,
          onSelectionChanged: (checked) {
            setState(() {
              if (checked == true) {
                selectedIds.add(id);
              } else {
                selectedIds.remove(id);
              }
            });
          },
          onTap: () async {
            await ref.read(craftsmanStaffProvider.notifier).craftsman_staffDetails(id);
            Get.toNamed(AppRoutes.craftsmanStaffView);
          },
          onEdit: () {
            Get.toNamed(AppRoutes.craftsmanStaffAdd, arguments: id);
          },
        );
      },
    );
  }
}