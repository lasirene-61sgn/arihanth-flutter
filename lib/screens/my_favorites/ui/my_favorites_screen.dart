import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/designs/widgets/design_grid_card.dart';
import 'package:arianth/screens/my_favorites/riverpod/favorites_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/enterprise_search_bar.dart';
import 'package:arianth/services/widget/pagination_controls.dart';
import 'package:arianth/services/widget/reusable_bottom_nav_bar.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:arianth/services/localization/app_localization.dart';

class MyFavoritesScreen extends ConsumerStatefulWidget {
  const MyFavoritesScreen({super.key});

  @override
  ConsumerState<MyFavoritesScreen> createState() => _MyFavoritesScreenState();
}

class _MyFavoritesScreenState extends ConsumerState<MyFavoritesScreen> {
  bool searchToggle = false;
  final TextEditingController _searchController = TextEditingController();
  String? role;

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role");
    Future.microtask(() {
      ref.read(favoritesProvider.notifier).fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoritesProvider);
    final notifier = ref.read(favoritesProvider.notifier);

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title:
        // !searchToggle
        //     ?
        const Text(
                'My Favorites',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            // : EnterpriseSearchBar(
            //     controller: _searchController,
            //     hintText: 'Search favorites...',
            //     onChanged: (value) => notifier.filterFavorites(value),
            //     onCancel: () {
            //       setState(() {
            //         _searchController.clear();
            //         searchToggle = false;
            //       });
            //       notifier.fetchFavorites();
            //     },
            //   ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.search, color: Colors.white),
        //     onPressed: () => setState(() => searchToggle = true),
        //   ),
        // ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading && state.favorites.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.favorites.isEmpty
                    ? const Center(child: Text('No favorites found', style: TextStyle(color: AppColor.textSecondary)))
                    : _buildGridView(state),
          ),
          if (state.nextUrl != null || state.previousUrl != null)
            PaginationControls(
              count: state.count,
              label: 'Favorites',
              onNext: notifier.goToNextPage,
              onPrevious: notifier.goToPreviousPage,
              isFirstPage: state.previousUrl == null,
              isLastPage: state.nextUrl == null,
              isLoading: state.isLoading,
            ),
        ],
      ),
    );
  }

  Widget _buildGridView(FavoriteListState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth < 600 ? 2 : screenWidth < 1000 ? 3 : 5;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: state.favorites.length,
      itemBuilder: (context, index) {
        final design = state.favorites[index];
        return DesignGridCard(
          item: design,
          onTap: () => Get.toNamed(AppRoutes.designsDetails, arguments: design.id.toString()),
          isFavorite: true, // Always true on this screen
          onFavoriteToggle: () {
            if (design.id != null) {
              ref.read(favoritesProvider.notifier).toggleFavorite(design.id!);
            }
          },
        );
      },
    );
  }
}
