import 'package:arianth/screens/catelogue/widget/catalogue_card.dart';
import 'package:arianth/screens/catelogue/widget/catelogue_card_view.dart';
import 'package:arianth/screens/catelogue/riverpod/catalogue_notifier.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../../app_color/app_color.dart';

class CatalogueGridScreen extends ConsumerStatefulWidget {
  final Set<String> selectedIds;
  final Function(String, bool) onSelectionChanged;

  const CatalogueGridScreen({
    super.key,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<CatalogueGridScreen> createState() => _CatalogueGridScreenState();
}

class _CatalogueGridScreenState extends ConsumerState<CatalogueGridScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(catalogueProvider.notifier).fetchCatalogues();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogueProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColor.primary));
    }

    if (state.catalogues.isEmpty) {
      return const Center(child: Text("No catalogues found", style: TextStyle(color: AppColor.textPrimary)));
    }

    // Grid Configuration
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
      itemCount: state.catalogues.length,
      itemBuilder: (context, index) {
        final item = state.catalogues[index];
        return CatalogueGridCard(
          item: item,
          isSelected: widget.selectedIds.contains(item.id.toString()),
          onSelectionChanged: (selected) {
            widget.onSelectionChanged(item.id.toString(), selected ?? false);
          },
          onTap: () {
            Get.toNamed(AppRoutes.catalogueDetails, arguments: item.id?.toString());
          },
        );
      },
    );
  }
}
