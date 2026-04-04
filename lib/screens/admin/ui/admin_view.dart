import 'package:arianth/screens/admin/model/admin_model.dart';
import 'package:arianth/screens/admin/riverpod/admin_notifier.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/resuable_responsive_desktop_header.dart';
import 'package:arianth/services/widget/reusable_table_view.dart';
import 'package:arianth/screens/admin/widgets/admin_card.dart';
import 'package:flutter/material.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/localization/language_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';

import '../../../app_color/app_color.dart';
import '../../../services/widget/form_field_common_button.dart';
import '../../../services/widget/reusable_bottom_nav_bar.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
   Set<String> selectedIds = {};

  // 🔹 Mobile actions visibility
  Set<String> visibleActions = {
    'add',
    'edit',
    'view',
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminProvider.notifier).fetchAdmins();
    });
  }

  bool get isMobile => MediaQuery.of(context).size.width < 600;
   bool searchToggle = false;
   final TextEditingController _searchController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        surfaceTintColor: AppColor.transparent, // Prevents color change on scroll
        scrolledUnderElevation: 0,            // Keeps it flat while scrolling
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

        // 🟢 Toggle between Title and Enterprise Search Bar
        title: !searchToggle
            ? Text(
          ref.watchTr('Admins'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
            : Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColor.surface, // Subtle grey-blue background
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColor.border),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(
              color: AppColor.textPrimary,
              fontSize: 14,
              height: 1.4, // Vertical alignment fix
            ),
            decoration: InputDecoration(
              hintText: 'Search admin by name or code...',
              hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: IconButton(
                icon: const Icon(Icons.cancel, size: 18, color: AppColor.textHint),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    searchToggle = false;
                    // Reset search logic here
                    // ref.read(adminProvider.notifier).fetchAdmins();
                  });
                },
              ),
            ),
            onChanged: (value) {
              // Call your search logic here
              // ref.read(adminProvider.notifier).searchAdmin(value);
            },
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () => LanguageSelector.show(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
            // _buildHeaderDesktop(),

          Flexible(
            fit: FlexFit.loose,
            child: SafeArea(top:false,child: _buildPreTable()),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: (){

          Get.toNamed(AppRoutes.addAdmin);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColor.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColor.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add, 
                color: AppColor.textWhite,
                size: 30,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
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
         if(!isMobile)Container(
           width: double.infinity,
           height: 50,
           padding: EdgeInsets.symmetric(vertical: 10,horizontal: 50),
           decoration: BoxDecoration(
             color: AppColor.divider,
             border: const Border(
               left: BorderSide(
                 color: AppColor.textPrimary,
                 width: 1,
               ),
             ),
           ),
           child: const Text("Admin",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: AppColor.textPrimary),),

         ),
         ResponsiveDesktopHeader(
           title: 'Admin',
           backgroundColor: AppColor.surface,
           showBorder: true,
           showShadow: false,
           actions: [
             ActionButtonConfig(
               label: 'Add New',
               icon: Icons.add,
               color: AppColor.primary,
               onPressed: () {
                Get.toNamed(AppRoutes.addAdmin);
               },
             ),
             ActionButtonConfig(
               label: 'View',
               icon: Icons.visibility,
               color: AppColor.primary,
               enabled: singleSelection,
               // onPressed: singleSelection
               //     ? () async {
               //   if (mounted) {
               //     context.push('${RouteNames.admin}/view', extra: {"adminId": selectedIds.first.toString()});
               //   }
               // }
               //     : null,
             ),
             ActionButtonConfig(
               label: 'Edit',
               icon: Icons.edit,
               color: AppColor.primary,
               enabled: singleSelection,
               onPressed: singleSelection
                   ? () async {
                 Get.toNamed(AppRoutes.addAdmin,arguments: selectedIds.first);
               }
                   : null,
             ),
           ],
         ),
       ],
     );
   }

  Widget _buildPreTable() {
    final state = ref.watch(adminProvider);

    if (state.isLoading && state.admins.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.admins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings_outlined, size: 64, color: AppColor.textHint.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No admins found',
              style: TextStyle(color: AppColor.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), // Space for FAB
      itemCount: state.admins.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final admin = state.admins[index];
        final id = admin.id.toString();
        final isSelected = selectedIds.contains(id);

        return AdminCard(
          admin: admin,
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
          onTap: () {
            Get.toNamed(AppRoutes.adminView, arguments: id);
          },
          onEdit: () {
            Get.toNamed(AppRoutes.addAdmin, arguments: id);
          },
        );
      },
    );
  }

}
