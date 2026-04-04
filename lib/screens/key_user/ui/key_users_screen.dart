import 'dart:io';

import 'package:arianth/screens/dashboard_screen/riverpod/dashboard_notifier.dart';
import 'package:arianth/screens/key_user/model/key_user_model.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/pagination_controls.dart';
import 'package:arianth/services/widget/resuable_responsive_desktop_header.dart';
import 'package:arianth/services/widget/reusable_table_view.dart';
import 'package:arianth/screens/key_user/widgets/key_user_card.dart';
import 'package:arianth/services/widget/enterprise_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../../app_color/app_color.dart';
import '../../../services/widget/form_field_common_button.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/localization/language_selector.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';
import '../../../services/widget/reusable_sort.dart';
import '../riverpod/key_user_notifier.dart';
import '../../../services/common_notifiers/pdf_download_notifier.dart';
import '../../../services/widget/custom_msg.dart';
import 'package:arianth/services/widget/universal_filter_dialog.dart';
import '../../../services/widget/reusable_bottom_nav_bar.dart';

class KeyUsersScreen extends ConsumerStatefulWidget {
  const KeyUsersScreen({super.key});

  @override
  ConsumerState<KeyUsersScreen> createState() => _KeyUsersScreenState();
}

class _KeyUsersScreenState extends ConsumerState<KeyUsersScreen> {
   Set<String> selectedIds = {};
  DateTime? _selectedDate;
  String? selectedFilter;
  final _formKey = GlobalKey<FormState>();


   String? role;
   @override
   void initState() {
     super.initState();
     role = SharedPreferencesHelper().getString("role");
    Future.microtask(() {
      ref.read(keyUserProvider.notifier).fetchKeyUsers(url: "api/common/key-users?sort=desc");
      ref.read(productListProvider.notifier).fetchBPCodes();
    });
  }

  void _showFilterDialog() {
    UniversalFilterDialog.show(
      context,
      ref,
      module: FilterModule.keyUser,
      role: role,
      onApply: (url) {
        setState(() {
          selectedFilter = ref.watchTr('filtered');
        });
        ref.read(keyUserProvider.notifier).fetchKeyUsers(url: url);
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
            label: const Text("Active Filters", style: TextStyle(fontSize: 10)),
            backgroundColor: AppColor.primary.withOpacity(0.1),
            deleteIcon: const Icon(Icons.close, size: 12, color: AppColor.primary),
            onDeleted: () {
              setState(() {
                selectedFilter = null;
                _searchController.clear();
              });
              ref.read(keyUserProvider.notifier).fetchKeyUsers();
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
              ref.read(keyUserProvider.notifier).fetchKeyUsers();
            },
            child: Text(ref.watchTr('reset_btn'), style: const TextStyle(fontSize: 11, color: Colors.red)),
          )
        ],
      ),
    );
  }
   bool get isMobile => MediaQuery.of(context).size.width < 600;
   bool searchToggle = false;
   final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(keyUserProvider);
    final notifier = ref.read(keyUserProvider.notifier);
    final pdfState = ref.watch(pdfDownloadProvider);

    return Stack(
      children: [
        Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColor.appBarBackground,
        surfaceTintColor: Colors.transparent, // Prevents color change on scroll
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

        // Enterprise Search Bar Logic
        title: !searchToggle
            ? Text(
          ref.watchTr('key_users'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        )
            : EnterpriseSearchBar(
          controller: _searchController,
          hintText: 'Search Key Users...',
          onChanged: (value) {
            ref.read(keyUserProvider.notifier).fetchKeyUsers(
                url: "api/common/key-users?search=$value");
          },
          onCancel: () {
            setState(() {
              _searchController.clear();
              searchToggle = false;
            });
            ref.read(keyUserProvider.notifier).fetchKeyUsers();
          },
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () => LanguageSelector.show(context, ref),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            if (selectedFilter != null) _buildActiveFilterRibbon(),
            _buildSelectAllBar(state),
            const SizedBox(height: 8),
            Flexible(
              fit: FlexFit.loose,
              child: _buildPreTable(),
            ),
            if (state.nextUrl != null || state.previousUrl != null)
              PaginationControls(
                count: state.count,
                label: 'KeyUsers',
                onNext: notifier.goToNextPage,
                onPrevious: notifier.goToPreviousPage,
                isFirstPage: state.previousUrl == null,
                isLastPage: state.nextUrl == null,
                isLoading: state.isLoading,
              ),
          ],
        ),
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
             color: AppColor.primary,
             isFloatingCenter: true,
             onPressed: () => Get.toNamed(AppRoutes.keyUsersAdd),
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
        title: ref.watchTr('sort_keyusers'),
        subtitle: ref.watchTr('choose_order'),
        fields: [], // No fields needed for unified sort
        initialAscending: isAscending,
        onApply: (_, ascending) {
          final sortOrder = ascending ? 'asc' : 'desc';
          ref.read(keyUserProvider.notifier).fetchKeyUsers(url: "api/common/key-users?sort=$sortOrder");
          setState(() {
            isAscending = ascending;
          });
        },
        onClear: () {
          ref.read(keyUserProvider.notifier).fetchKeyUsers();
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
    final endpoint = "api/common/key-users/generate-pdf?ids=$ids";

    await ref.read(pdfDownloadProvider.notifier).downloadPDF(
      endpoint: endpoint,
      fileName: "KeyUsers_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );

    final finalState = ref.read(pdfDownloadProvider);
    if (finalState.error != null) {
      Toaster.showError(finalState.error!);
    } else if (finalState.filePath != null) {
      Toaster.showSuccess("PDF Downloaded successfully");
    }
  }



  Widget _buildSelectAllBar(state) {
    if (state.keyUsers.isEmpty) return const SizedBox.shrink();

    bool isAllSelectedOnPage = state.keyUsers.isNotEmpty &&
        state.keyUsers.every((d) => selectedIds.contains(d.id.toString()));

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
                      for (var d in state.keyUsers) {
                        selectedIds.add(d.id.toString());
                      }
                    } else {
                      for (var d in state.keyUsers) {
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
    final state = ref.watch(keyUserProvider);

    if (state.isLoading && state.keyUsers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.keyUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_pin_outlined, size: 64, color: AppColor.textHint.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No key users found',
              style: TextStyle(color: AppColor.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120), // Space for pagination/FAB
      itemCount: state.keyUsers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final keyUser = state.keyUsers[index];
        final id = keyUser.id.toString();
        final isSelected = selectedIds.contains(id);

        return KeyUserCard(
          keyUser: keyUser,
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
            await ref.read(keyUserProvider.notifier).keyUserDetails(id);
            Get.toNamed(AppRoutes.keyUsersView);
          },
          onEdit: () {
            Get.toNamed(AppRoutes.keyUsersAdd, arguments: {
              'id': id,
            });
          },
        );
      },
    );
  }

}