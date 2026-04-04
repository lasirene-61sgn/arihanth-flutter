import 'dart:io';

import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/user/model/user_model.dart';
import 'package:arianth/screens/user/riverpod/user_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/resuable_responsive_desktop_header.dart';
import 'package:arianth/services/widget/reusable_file_picker.dart';
import 'package:arianth/services/widget/reusable_sort.dart';
import 'package:arianth/services/widget/reusable_table_view.dart';
import 'package:arianth/screens/user/widgets/user_card.dart';
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

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
   Set<String> selectedIds = {};
   bool searchToggle = false;
   final TextEditingController _searchController = TextEditingController();
   String? role;
   @override
   void initState() {
     super.initState();
     role = SharedPreferencesHelper().getString("role");
    Future.microtask(() {
      ref.read(userProvider.notifier).fetchUsers(urls: "api/common/users");
      ref.read(productListProvider.notifier).fetchBPCodes();
      ref.read(productListProvider.notifier).fetchCraftBPCodes();
    });
  }


  bool get isMobile => MediaQuery.of(context).size.width < 600;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProvider);
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
          ref.watchTr('Users'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
            : EnterpriseSearchBar(
          controller: _searchController,
          hintText: 'Search by Name, Code or Email...',
          onChanged: (value) {
            ref.read(userProvider.notifier).fetchUsers(
                urls: "api/common/users?search=$value");
          },
          onCancel: () {
            setState(() {
              _searchController.clear();
              searchToggle = false;
            });
            ref.read(userProvider.notifier).fetchUsers();
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
              label: 'User',
              onNext: () => ref.read(userProvider.notifier).goToNextPage(),
              onPrevious: () => ref.read(userProvider.notifier).goToPreviousPage(),
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
            onPressed: () => Get.toNamed(AppRoutes.usersAdd),
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
        title: ref.watchTr('sort_users'),
        subtitle: ref.watchTr('choose_order'),
        fields: [], // No fields needed for unified sort
        initialAscending: isAscending,
        onApply: (_, ascending) {
          final sortOrder = ascending ? 'asc' : 'desc';
          ref.read(userProvider.notifier).fetchUsers(urls: "api/common/users?sort=$sortOrder");
          setState(() {
            isAscending = ascending;
          });
        },
        onClear: () {
          ref.read(userProvider.notifier).fetchUsers();
          setState(() {
            isAscending = true;
          });
        },
      ),
    );
  }

  Widget _buildSelectAllBar(state) {
    if (state.users.isEmpty) return const SizedBox.shrink();

    bool isAllSelectedOnPage = state.users.isNotEmpty &&
        state.users.every((d) => selectedIds.contains(d.id.toString()));

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
                      for (var d in state.users) {
                        selectedIds.add(d.id.toString());
                      }
                    } else {
                      for (var d in state.users) {
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
           child: const Text("Users", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.white)),

         ),
         ResponsiveDesktopHeader(
           title: 'Users',
           backgroundColor: AppColor.white,
           showBorder: true,
           showShadow: false,
           actions: [
             ActionButtonConfig(
               label: 'Add New',
               icon: Icons.add,
               color: AppColor.primary,
               onPressed: () {
                 Get.toNamed(AppRoutes.usersAdd);

               },
             ),
             ActionButtonConfig(
               label: 'View',
               icon: Icons.visibility,
               color: AppColor.primary,
               enabled: singleSelection,
               // onPressed: singleSelection
               //     ? () async {
               //   await ref.read(userProvider.notifier).userDetails(selectedIds.first, context);
               //   if (mounted) {
               //     context.push('${RouteNames.users}/view',
               //         extra: {"screenName": "Users"});
               //   }
               // }
               //     : null,
             ),
             if(role != "Admin")  ActionButtonConfig(
               label: 'Edit',
               icon: Icons.edit,
               color: AppColor.primary,
               enabled: singleSelection,
               // onPressed: singleSelection
               //     ? () async {
               //   await ref.read(userProvider.notifier).userDetails(selectedIds.first, context);
               //   if (mounted) {
               //     context.push('${RouteNames.users}/add',
               //         extra: {"screenName": "Users", "type": "Edit"});
               //   }
               // }
               //     : null,
             ),

             ActionButtonConfig(
               label: 'Print',
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
       Get.snackbar("Info", "Please select items to print");
       return;
     }

     final ids = selectedIds.join(',');
     final endpoint = "api/common/users/generate-pdf?ids=$ids";

     await ref.read(pdfDownloadProvider.notifier).downloadPDF(
       endpoint: endpoint,
       fileName: "Users_${DateTime.now().millisecondsSinceEpoch}.pdf",
     );

     final finalState = ref.read(pdfDownloadProvider);
     if (finalState.error != null) {
       Toaster.showError(finalState.error!);
     } else if (finalState.filePath != null) {
       Toaster.showSuccess("PDF Downloaded successfully");
     }
   }
   // Make sure you have imported your KycDocument file at the top of this file!
// import 'package:arianth/services/widget/reusable_file_picker.dart';

  Widget _buildPreTable() {
    final state = ref.watch(userProvider);

    if (state.isLoading && state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColor.textHint.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No users found',
              style: TextStyle(color: AppColor.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), // Space for bottom nav
      itemCount: state.users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = state.users[index];
        final id = user.id.toString();
        final isSelected = selectedIds.contains(id);

        return UserCard(
          user: user,
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
            await ref.read(userProvider.notifier).userDetails(id);
            Get.toNamed(AppRoutes.usersView);
          },
          onEdit: () {
            Get.toNamed(AppRoutes.usersAdd, arguments: id);
          },
        );
      },
    );
  }
}