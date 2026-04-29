// product_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:arianth/screens/dashboard_screen/riverpod/dashboard_notifier.dart';
import 'package:arianth/screens/products/model/products_model.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/common_notifiers/pdf_download_notifier.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:arianth/services/localization/language_selector.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:arianth/services/widget/resuable_responsive_desktop_header.dart';
import 'package:arianth/services/widget/reusable_table_view.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/pagination_controls.dart';
import 'package:arianth/services/widget/universal_filter_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

import '../../../app_color/app_color.dart';
import '../../../services/widget/form_field_common_button.dart';
import '../../../services/widget/reusable_bottom_nav_bar.dart';
import '../../../services/widget/reusable_fillter_dialog.dart';
import '../../../services/widget/reusable_sort.dart';
import '../../../services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/reusable_full_screen_view.dart';
import 'package:arianth/services/widget/reusable_file_picker.dart';
import 'package:arianth/services/widget/enterprise_search_bar.dart';
import '../widgets/product_card.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Set<String> selectedIds = {};
  String? selectedFilter;
  String? selectedSort;
  String? role;
  bool isAscending = true;
  bool _isBulkSharing = false;
  Set<String> visibleActions = {
    'add',
    'edit',
    'view',
    'filter',
    'sort',
    'export',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role");
    Future.microtask(() async {
      final productNotifier = ref.read(productListProvider.notifier);
      final futures = <Future>[];
      futures.add(productNotifier.fetchProducts());
      futures.add(productNotifier.fetchCategories());
      futures.add(productNotifier.fetchBPCodes());
      futures.add(productNotifier.fetchCraftBPCodes());
      await Future.wait(futures);
    });

  }


  bool get isMobile => MediaQuery.of(context).size.width < 600;
  bool searchToggle = false;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider);
    final notifier = ref.read(productListProvider.notifier);
    final pdfState = ref.watch(pdfDownloadProvider);


    return Stack(
      children: [
        Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent, // Prevents tint color on scroll
        scrolledUnderElevation: 0,            // Keeps the appbar flat
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(height: 1.0, color: Colors.white24),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),

        // ✅ Toggle between Title and Enterprise Search Bar
        title: !searchToggle
            ? Text(
          ref.watchTr('products'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
            : EnterpriseSearchBar(
          controller: _searchController,
          hintText: 'Search product by name, code or category...',
          onChanged: (value) {
            ref.read(productListProvider.notifier).fetchProducts(
                url: "api/common/products?search=$value");
          },
          onCancel: () {
            setState(() {
              _searchController.clear();
              searchToggle = false;
            });
            ref.read(productListProvider.notifier).fetchProducts();
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
          // if (role == 'super_admin')
            IconButton(
              icon: const Icon(Icons.upload_file, color: Colors.white),
              tooltip: 'Bulk Upload',
              onPressed: _showBulkUploadDialog,
            ),
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () => LanguageSelector.show(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSelectAllBar(state),
          const SizedBox(height: 8),
          Flexible(
            fit: FlexFit.tight, // Changed to tight to take up remaining space properly
            child: SafeArea(
              top: false,
              bottom: true,
              child: _buildPreTable(),
            ),
          ),
          if (state.nextUrl != null || state.previousUrl != null)
            PaginationControls(
              count: state.count,
              label: 'Products',
              onNext: notifier.goToNextPage,
              onPrevious: notifier.goToPreviousPage,
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
            label: ref.watchTr('Sort'),
            icon: Icons.sort_by_alpha,
            color: AppColor.primary,
            onPressed: _showSortMenu,
          ),
          NavActionItem(
            label: ref.watchTr('create'),
            icon: Icons.add_box,
            color: AppColor.primary,
            // isFloatingCenter: true, // ⭐ Main Action
            onPressed: () => Get.toNamed(AppRoutes.productsAdd),
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



  Widget _buildSelectAllBar(state) {
    if (state.products.isEmpty) return const SizedBox.shrink();

    bool isAllSelectedOnPage = state.products.isNotEmpty &&
        state.products.every((p) => selectedIds.contains(p.id.toString()));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColor.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColor.primary.withOpacity(0.2)),
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
                      for (var p in state.products) {
                        selectedIds.add(p.id.toString());
                      }
                    } else {
                      for (var p in state.products) {
                        selectedIds.remove(p.id.toString());
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
    final state = ref.watch(productListProvider);
    if (state.isLoading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColor.primary));
    }
    if (state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColor.coolLavender.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No products found', style: TextStyle(color: AppColor.coolLavender)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: state.products.length,
      itemBuilder: (context, index) {
        final product = state.products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ProductCard(
            product: product,
            isSelected: selectedIds.contains(product.id.toString()),
            onSelectionChanged: (value) {
              setState(() {
                if (value == true) {
                  selectedIds.add(product.id.toString());
                } else {
                  selectedIds.remove(product.id.toString());
                }
              });
            },
            onTap: () => Get.toNamed(
              AppRoutes.productsDetails,
              arguments: product.id.toString(),
            ),
            onEdit: () => Get.toNamed(
              AppRoutes.productsAdd,
              arguments: {'id': product.id.toString()},
            ),
            onShare: () async {
              final String? imageUrl = product.images != null && product.images!.isNotEmpty
                  ? product.images!.first.imageUrl
                  : (product.productImage != null && product.productImage!.isNotEmpty)
                      ? product.productImage!.startsWith('http')
                          ? product.productImage
                          : '${ApiClient.baseUrl}storage/${product.productImage}'
                      : null;

              final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(SharedPreferencesHelper().getString("role")?.toLowerCase());
              await ShareCardService.share(
                context,
                ShareCardItem(
                  imageUrl: imageUrl,
                  title: product.productName,
                  bpCode: restricted ? null : product.bpCode,
                  productCode: product.productCode,
                  category: product.category?.name,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _shareSelected() async {
    if (selectedIds.isEmpty) return;

    setState(() {
      _isBulkSharing = true;
    });

    try {
      final state = ref.read(productListProvider);
      final List<ShareCardItem> shareItems = state.products
          .where((item) => selectedIds.contains(item.id.toString()))
          .map((product) {
        final String? imageUrl = product.images != null && product.images!.isNotEmpty
            ? product.images!.first.imageUrl
            : (product.productImage != null && product.productImage!.isNotEmpty)
                ? product.productImage!.startsWith('http')
                    ? product.productImage
                    : '${ApiClient.baseUrl}storage/${product.productImage}'
                : null;

        final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(SharedPreferencesHelper().getString("role")?.toLowerCase());

        return ShareCardItem(
          imageUrl: imageUrl,
          title: product.productName,
          bpCode: restricted ? null : product.bpCode,
          productCode: product.productCode,
          category: product.category?.name,
        );
      }).toList();

      if (shareItems.isEmpty) {
        Toaster.showError("No selected items found on current page");
        return;
      }

      await ShareCardService.shareMultiple(context, shareItems);
    } catch (e) {
      debugPrint('Products bulk share error: $e');
      Toaster.showError("Failed to share selected products");
    } finally {
      if (mounted) {
        setState(() {
          _isBulkSharing = false;
        });
      }
    }
  }

  void _showFilterDialog() {
    UniversalFilterDialog.show(
      context,
      ref,
      module: FilterModule.product,
      role: SharedPreferencesHelper().getString("role"),
      onApply: (url) {
        ref.read(productListProvider.notifier).fetchProducts(url: url);
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
            key: 'product_name',
            icon: Icons.sort_by_alpha_rounded,
            sub: ref.watchTr('sort_by_alpha'),
          ),
          SortField(
            label: ref.watchTr('product_code'),
            key: 'product_code',
            icon: Icons.tag_rounded,
            sub: ref.watchTr('sort_by_code'),
          ),
        ],
        initialField: selectedSort,
        initialAscending: isAscending,
        onApply: (field, ascending) {
          final sortOrder = ascending ? 'asc' : 'desc';
          ref.read(productListProvider.notifier).fetchProducts(url: "api/common/products?sort=$sortOrder");
          setState(() {
            selectedSort = field.label;
            isAscending = ascending;
          });
        },
        onClear: () {
          ref.read(productListProvider.notifier).fetchProducts();
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
    final endpoint = "api/common/products/generate-pdf?ids=$ids";

    await ref.read(pdfDownloadProvider.notifier).downloadPDF(
      endpoint: endpoint,
      fileName: "Products_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );

    final finalState = ref.read(pdfDownloadProvider);
    if (finalState.error != null) {
      Toaster.showError(finalState.error!);
    } else if (finalState.filePath != null) {
      Toaster.showSuccess("PDF Downloaded successfully");
    }
  }

  void _showBulkUploadDialog() {
    PlatformFile? pickedFile;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColor.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.upload_file, color: AppColor.primary, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Bulk Upload Products',
                    style: TextStyle(color: AppColor.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a .zip file containing product data to upload in bulk.',
                    style: TextStyle(color: AppColor.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: isUploading
                        ? null
                        : () async {
                            final result = await FilePicker.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['zip'],
                            );
                            if (result != null && result.files.isNotEmpty) {
                              setDialogState(() {
                                pickedFile = result.files.first;
                              });
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColor.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: pickedFile != null ? AppColor.primary : AppColor.divider,
                          width: pickedFile != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            pickedFile != null ? Icons.folder_zip : Icons.attach_file,
                            color: pickedFile != null ? AppColor.primary : AppColor.textHint,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              pickedFile?.name ?? 'Tap to select .zip file',
                              style: TextStyle(
                                color: pickedFile != null ? AppColor.textPrimary : AppColor.textHint,
                                fontSize: 14,
                                fontWeight: pickedFile != null ? FontWeight.w500 : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (pickedFile != null && !isUploading)
                            GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  pickedFile = null;
                                });
                              },
                              child: const Icon(Icons.close, color: AppColor.textHint, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (pickedFile != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Size: ${(pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(color: AppColor.textSecondary, fontSize: 11),
                    ),
                  ],
                  if (isUploading) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(color: AppColor.primary),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Uploading... Please wait',
                        style: TextStyle(color: AppColor.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isUploading ? AppColor.textHint : AppColor.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: (pickedFile == null || isUploading)
                      ? null
                      : () async {
                          setDialogState(() => isUploading = true);
                          final success = await ref
                              .read(productListProvider.notifier)
                              .bulkUploadProducts(pickedFile!);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
