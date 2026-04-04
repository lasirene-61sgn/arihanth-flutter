import 'dart:async';
import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/products/model/sub_category_model.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/screens/purchase_order/model/purchase_orders_model.dart';
import 'package:arianth/screens/purchase_order/riverpod/purchase_orders_notifier.dart';
import 'package:arianth/screens/purchase_order/ui/widgets/po_item_card.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:arianth/services/widget/form_field_common_button.dart';
import 'package:arianth/services/widget/reuseable_dropdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/image_picker/image_picker_helper.dart';

import '../../products/model/category_model.dart' show Category;

class PurchaseOrderForm extends ConsumerStatefulWidget {
  final void Function(Map<String, dynamic> data)? onSubmit;
  final String? purchaseId;

  const PurchaseOrderForm({super.key, this.onSubmit, this.purchaseId});

  @override
  ConsumerState<PurchaseOrderForm> createState() => _PurchaseOrderFormState();
}

class _PurchaseOrderFormState extends ConsumerState<PurchaseOrderForm> {
  final TextEditingController _noteController = TextEditingController();
  DateTime? _dueDate;
  String? _selectedBpCode;
  final List<Map<String, dynamic>> _items = [];
  Timer? _designCodeDebounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(purchaseOrderListProvider.notifier).resetCurrentOrder();
      if (widget.purchaseId != null && widget.purchaseId != "null") {
        await autoFill();
      } else {
        _handleAddItem(); // Add initial empty item
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _designCodeDebounce?.cancel();
    for (final item in _items) {
      _disposeItemControllers(item);
    }
    super.dispose();
  }

  void _disposeItemControllers(Map<String, dynamic> item) {
    for (final subItem in item['subItems']) {
      (subItem['gramsCtrl'] as TextEditingController).dispose();
      (subItem['qtyCtrl'] as TextEditingController).dispose();
      (subItem['totalWeightCtrl'] as TextEditingController).dispose();
    }
    (item['totalWeightCtrl'] as TextEditingController).dispose();
    (item['notesCtrl'] as TextEditingController).dispose();
    if (item['designCtrl'] is TextEditingController) {
      (item['designCtrl'] as TextEditingController).dispose();
    }
  }

  void _handleRemoveMainItem(int index) {
    setState(() {
      final item = _items[index];
      _disposeItemControllers(item);
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final purchaseState = ref.watch(purchaseOrderListProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          ref.watchTr(widget.purchaseId != null ? 'edit_purchase_order' : 'create_purchase_order'),
          style: const TextStyle(color: AppColor.textWhite),
        ),
        backgroundColor: AppColor.appBarBackground,
        foregroundColor: AppColor.textWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColor.textWhite, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildTopFields(isMobile),
            const SizedBox(height: 16),
            ..._items.asMap().entries.map((e) {
              final index = e.key;
              final item = e.value;
              return POItemRow(
                index: index,
                itemData: item,
                isMobile: isMobile,
                categoryDropdown: _buildCategoryDropdown(item),
                subCategoryDropdown: _buildSubCategoryDropdown(item),
                designField: _buildDesignField(item),
                imageWidget: _buildImagePickerWidget(index),
                onAddSubItem: () => _handleAddSubItem(index),
                onRemoveSubItem: (subIdx) => _handleRemoveSubItem(index, subIdx),
                onRemoveMainItem: () => _handleRemoveMainItem(index),
                onRecalc: () => _recalcTotalWeight(index),
              );
            }).toList(),
            const SizedBox(height: 16),
            SafeArea(bottom: true, child: _buildFooterButtons(purchaseState)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopFields(bool isMobile) {
    final labelStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: AppColor.textPrimary,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            _labelWithWidget("Due Date", _buildDateSelector(), labelStyle),
            const SizedBox(height: 12),
            _labelWithWidget("General Notes", _buildGeneralNoteField(), labelStyle),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _labelWithWidget("Due Date", _buildDateSelector(), labelStyle)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _labelWithWidget("General Notes", _buildGeneralNoteField(), labelStyle)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _labelWithWidget(String label, Widget widget, TextStyle style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: style),
        const SizedBox(height: 6),
        widget,
      ],
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _dueDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2101),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColor.primary,
                  onPrimary: AppColor.textWhite,
                  surface: AppColor.background,
                  onSurface: AppColor.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) setState(() => _dueDate = picked);
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColor.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColor.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _dueDate == null ? 'Select Date' : DateFormat('dd-MM-yyyy').format(_dueDate!),
              style: const TextStyle(fontSize: 13, color: AppColor.textPrimary),
            ),
            const Icon(Icons.calendar_month, size: 18, color: AppColor.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralNoteField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColor.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColor.divider),
      ),
      child: TextField(
        controller: _noteController,
        style: const TextStyle(fontSize: 13, color: AppColor.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Enter internal notes...',
          hintStyle: TextStyle(color: AppColor.textHint),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(Map<String, dynamic> item) {
    final productState = ref.watch(productListProvider);
    final categories = productState.categories ?? [];
    final categoryList = categories
        .where((cat) => cat.name.trim().isNotEmpty)
        .map((cat) => cat.name.trim())
        .toSet()
        .toList();

    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.divider),
        borderRadius: BorderRadius.circular(6),
        color: AppColor.surface,
      ),
      child: WebSearchableDropdown<String>(
        items: categoryList,
        itemLabel: (v) => v,
        selectedValue: item['category'],
        hintText: 'Category',
        allowNew: false,
        onChanged: (v) {
          setState(() {
            item['category'] = v ?? '';
            // Fetch subcategories
            final selectedCat = categories.firstWhere((cat) => cat.name.trim() == (v ?? '').trim(), orElse: () => Category(id: 0, name: ''));
            if (selectedCat.id != 0) {
              item['categoryId'] = selectedCat.id;
              ref.read(productListProvider.notifier).fetchSubCategories(
                url: "api/common/products/subcategories/?category_id=${selectedCat.id}",
              ).then((list) {
                setState(() {
                  item['localSubCategories'] = list;
                });
              });
            } else {
              item['categoryId'] = null;
              setState(() {
                item['localSubCategories'] = <SubCategory>[];
              });
            }
          });
        },
      ),
    );
  }

  Widget _buildSubCategoryDropdown(Map<String, dynamic> item) {
    final List<SubCategory> allSubCategories = (item['localSubCategories'] as List<SubCategory>?) ?? [];
    final String selectedCategory = item['category'] ?? '';

    final filteredSubCategoryList = allSubCategories
        .where((sc) =>
            sc.name.trim().isNotEmpty &&
            (selectedCategory.isEmpty ||
                sc.categoryName == selectedCategory ||
                (sc.categoryName?.isEmpty ?? true)))
        .map((sc) => sc.name.trim())
        .toSet()
        .toList();

    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.divider),
        borderRadius: BorderRadius.circular(6),
        color: AppColor.surface,
      ),
      child: WebSearchableDropdown<String>(
        items: filteredSubCategoryList,
        itemLabel: (v) => v,
        selectedValue: item['subcategory'],
        hintText: 'Sub Category',
        allowNew: false,
        onChanged: (v) {
          setState(() {
            item['subcategory'] = v ?? '';
            final selectedSub = allSubCategories.firstWhere((sc) => sc.name.trim() == (v ?? '').trim(),);
            item['subCategoryId'] = selectedSub.id;
            // CRITICAL: We update the .text of the existing controller.
            // DO NOT replace the controller object with a String, or the app will crash!
            if (item['designCtrl'] is TextEditingController) {
              final ctrl = item['designCtrl'] as TextEditingController;
              ctrl.text = selectedSub.designCode?.toString() ?? '';
              // Also trigger the image fetch for this design code
              _onDesignCodeChanged(item, ctrl.text);
            }
          });
        },
      ),
    );
  }

  Widget _buildDesignField(Map<String, dynamic> item) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.divider),
        borderRadius: BorderRadius.circular(6),
        color: AppColor.surface,
      ),
      child: TextField(
        controller: item['designCtrl'],
        onChanged: (value) => _onDesignCodeChanged(item, value),
        textAlignVertical: TextAlignVertical.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: 'Design Code',
          hintStyle: TextStyle(color: AppColor.textHint, fontSize: 12),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: const TextStyle(fontSize: 12, color: AppColor.textPrimary),
      ),
    );
  }

  void _onDesignCodeChanged(Map<String, dynamic> item, String value) {
    if (_designCodeDebounce?.isActive ?? false) _designCodeDebounce!.cancel();

    _designCodeDebounce = Timer(const Duration(milliseconds: 600), () async {
      final code = value.trim();
      if (code.isEmpty) {
        setState(() {
          item['serverImage'] = null;
          item['productId'] = '';
        });
        return;
      }

      final productData = await ref.read(productListProvider.notifier).fetchProductByCode(code);
      if (productData != null) {
        setState(() {
          final productState = ref.read(productListProvider);

          if (productData.productCategoryId != null) {
            // item['productId'] = productData.id;
            item['categoryId'] = productData.productCategoryId;
            final cat = productState.categories.firstWhere((c) => c.id == productData.productCategoryId, orElse: () => Category(id: 0, name: ''));
            if (cat.id != 0) {
              item['category'] = cat.name;
            }

            // SET THE FETCHED IMAGE
            item['serverImage'] = productData.productImageUrl;
            // IMPORTANT: use productData.id (the integer) instead of productCode
            item['productId'] = productData.id;

            ref.read(productListProvider.notifier).fetchSubCategories(
              url: "api/common/products/subcategories/?category_id=${productData.productCategoryId}",
            ).then((list) async {
               // After subcategories are loaded, try to find subcategory name
               setState(() {
                 item['localSubCategories'] = list;
               });
               if (productData.subcategoryId != null) {
                 final subCat = list.firstWhere((sc) => sc.id == productData.subcategoryId, orElse: () => SubCategory(id: 0, name: '', categoryName: '', designCode: ''));
                  setState(() {
                    if(subCat.id != 0) {
                      item['subCategoryId'] = subCat.id;
                      item['subcategory']= subCat.name;
                    }
                  });

                                }

            });
          }
        });
      }
    });
  }

  Widget _buildImagePickerWidget(int index) {
    final item = _items[index];
    final List<PlatformFile> files = item['selectedFiles'] ?? [];
    final serverImage = item['serverImage'] as String?;

    return InkWell(
      onTap: () => _pickImage(index),
      child: Container(
        height: 85,
        width: 85,
        decoration: BoxDecoration(
          border: Border.all(color: AppColor.divider),
          borderRadius: BorderRadius.circular(8),
          color: AppColor.surface,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (files.isNotEmpty && files.first.bytes != null)
                Image.memory(
                  files.first.bytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              else if (serverImage != null && serverImage.isNotEmpty)
                Image.network(
                  serverImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey, size: 20),
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined, color: AppColor.textHint, size: 24),
                    const SizedBox(height: 4),
                    Text('Images', style: TextStyle(fontSize: 10, color: AppColor.textSecondary)),
                  ],
                ),

              // Multiple images badge
              if (files.length > 1)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${files.length - 1}',
                      style: const TextStyle(fontSize: 10, color: AppColor.textWhite, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(int index) async {
    final result = await ImagePickerHelper.pickImages(context, allowMultiple: true);

    if (result.isNotEmpty) {
      setState(() {
        _items[index]['selectedFiles'] = result;
      });
    }
  }

  Future<void> autoFill() async {
    final id = widget.purchaseId!;
    await ref.read(purchaseOrderListProvider.notifier).purchaseOrderDetail(id);
    final order = ref.read(purchaseOrderListProvider).purchaseOrderDetail;

    if (order != null) {
      // 1. Prepare non-async data
      DateTime? dueDate;
      if (order.dueDate != null) {
        try {
          dueDate = DateTime.parse(order.dueDate!);
        } catch (_) {}
      }

      final List<Map<String, dynamic>> preparedItems = [];
      
      // 2. Perform async work outside of setState
      if (order.items != null) {
        for (final poItem in order.items!) {
          final catId = int.tryParse(poItem.category ?? '');
          List<SubCategory> localSubCats = [];
          if (catId != null) {
            localSubCats = await ref.read(productListProvider.notifier).fetchSubCategories(
              url: "api/common/products/subcategories/?category_id=$catId",
            );
          }

          final Map<String, dynamic> itemMap = {
            'productId': poItem.productId,
            'category': poItem.categoryName ?? '',
            'categoryId': catId,
            'subcategory': poItem.subcategoryName ?? '',
            'subCategoryId': int.tryParse(poItem.subcategory ?? ''),
            'localSubCategories': localSubCats,
            'designCtrl': TextEditingController(text: poItem.designText),
            'notesCtrl': TextEditingController(text: poItem.itemNotes ?? ''),
            'totalWeightCtrl': TextEditingController(text: poItem.total?.toString() ?? '0.00'),
            'subItems': [],
            'selectedFiles': <PlatformFile>[],
            'serverImage': poItem.imageUrl,
          };

          final grams = poItem.grams ?? [];
          final qtys = poItem.quantity ?? [];
          final count = grams.length > qtys.length ? grams.length : qtys.length;

          if (count == 0) {
            itemMap['subItems'].add({
              'gramsCtrl': TextEditingController(),
              'qtyCtrl': TextEditingController(),
              'totalWeightCtrl': TextEditingController(text: '0'),
            });
          } else {
            for (int i = 0; i < count; i++) {
              final g = i < grams.length ? grams[i].toString() : '';
              final q = i < qtys.length ? qtys[i].toString() : '';
              final gVal = double.tryParse(g) ?? 0;
              final qVal = int.tryParse(q) ?? 0;

              itemMap['subItems'].add({
                'gramsCtrl': TextEditingController(text: g),
                'qtyCtrl': TextEditingController(text: q),
                'totalWeightCtrl': TextEditingController(text: (gVal * qVal).toStringAsFixed(2)),
              });
            }
          }
          preparedItems.add(itemMap);
        }
      }

      // 3. Update state synchronously
      setState(() {
        _dueDate = dueDate;
        _noteController.text = order.notes ?? '';
        _items.clear();
        _items.addAll(preparedItems);
        
        if (_items.isEmpty) {
          _handleAddItem();
        }
      });
    }
  }

  void _recalcTotalWeight(int itemIndex) {
    final item = _items[itemIndex];
    double grandTotal = 0.0;
    for (final subItem in item['subItems']) {
      final g = double.tryParse(subItem['gramsCtrl'].text) ?? 0;
      final q = int.tryParse(subItem['qtyCtrl'].text) ?? 0;
      final subTotal = g * q;
      subItem['totalWeightCtrl'].text = subTotal.toStringAsFixed(2);
      grandTotal += subTotal;
    }
    item['totalWeightCtrl'].text = grandTotal.toStringAsFixed(2);
  }

  void _handleAddItem() {
    setState(() {
      _items.add({
        'productId': '',
        'category': '',
        'categoryId': null,
        'subcategory': '',
        'subCategoryId': null,
        'localSubCategories': <SubCategory>[],
        'serverImage': null,
        'designCtrl': TextEditingController(),
        'subItems': [
          {
            'gramsCtrl': TextEditingController(),
            'qtyCtrl': TextEditingController(),
            'totalWeightCtrl': TextEditingController(text: '0'),
          }
        ],
        'totalWeightCtrl': TextEditingController(text: '0.00'),
        'notesCtrl': TextEditingController(),
        'selectedFiles': <PlatformFile>[],
      });
    });
  }

  void _handleAddSubItem(int itemIndex) {
    if (itemIndex < 0 || itemIndex >= _items.length) return;
    setState(() {
      final item = _items[itemIndex];
      item['subItems'].add({
        'gramsCtrl': TextEditingController(),
        'qtyCtrl': TextEditingController(),
        'totalWeightCtrl': TextEditingController(text: '0'),
      });
      _recalcTotalWeight(itemIndex);
    });
  }

  void _handleRemoveSubItem(int itemIndex, int subIndex) {
    if (itemIndex < 0 || itemIndex >= _items.length) return;
    final item = _items[itemIndex];
    if (subIndex < 0 || subIndex >= item['subItems'].length) return;
    setState(() {
      final subItem = item['subItems'][subIndex];
      (subItem['gramsCtrl'] as TextEditingController).dispose();
      (subItem['qtyCtrl'] as TextEditingController).dispose();
      (subItem['totalWeightCtrl'] as TextEditingController).dispose();
      item['subItems'].removeAt(subIndex);
      _recalcTotalWeight(itemIndex);
    });
  }

  Widget _buildFooterButtons(dynamic purchaseState) {
    return Row(
      children: [
        FormFeildCommonButton(
          text: 'Add Item',
          textColor: AppColor.textPrimary,
          backgroundColor: AppColor.surface,
          onPressed: _handleAddItem,
        ),
        const Spacer(),
        FormFeildCommonButton(
          text: purchaseState.isSavingPO ? 'Wait...' : (widget.purchaseId == null ? "Create" : "Update"),
          textColor: AppColor.textWhite,
          backgroundColor: AppColor.primary,
          onPressed: purchaseState.isSavingPO ? null : _handleCreate,
        ),
      ],
    );
  }

  Future<void> _handleCreate() async {
    if (_items.isEmpty) {
      Toaster.showError('Please add at least one item.');
      return;
    }

    final pOrder = PurchaseOrder(
      dueDate: _dueDate != null ? DateFormat('dd-MM-yyyy').format(_dueDate!) : null,
      notes: _noteController.text,
      items: _items.map((item) {
        final List<String> gramsList = [];
        final List<String> quantityList = [];
        double totalWeight = 0.0;

        for (final sub in item['subItems']) {
          final g = (sub['gramsCtrl'] as TextEditingController).text;
          final q = (sub['qtyCtrl'] as TextEditingController).text;
          if (g.isNotEmpty && q.isNotEmpty) {
            gramsList.add(g);
            quantityList.add(q);
            totalWeight += (double.tryParse(g) ?? 0) * (int.tryParse(q) ?? 0);
          }
        }


        return PurchaseItem(
          productId: item['productId']?.toString(),
          category: (item['categoryId'] ?? '').toString(),
          subcategory: (item['subCategoryId'] ?? '').toString(),
          categoryName: (item['category'] ?? '').toString(),
          subcategoryName: (item['subcategory'] ?? '').toString(),
          itemNotes: (item['notesCtrl'] as TextEditingController).text,
          grams: gramsList,
          quantity: quantityList,
          total: totalWeight,
          designCode: (item['designCtrl'] as TextEditingController).text,
        );
      }).toList(),
    );

    final Map<String, dynamic> payload = pOrder.toJson();

    final Map<String, dynamic> files = {};
    for (int i = 0; i < _items.length; i++) {
        final List<PlatformFile> itemFiles = _items[i]['selectedFiles'] ?? [];
        if (itemFiles.isNotEmpty) {
            files["items[$i][image]"] = itemFiles.first;
        }
    }

    final notifier = ref.read(purchaseOrderListProvider.notifier);
    final response = await notifier.createPurchaseOrder(
      context: context,
      payload: payload,
      id: widget.purchaseId,
      files: files,
    );

    if (response != null && response["status"] == 1) {
      Toaster.showSuccess('Purchase Order ${widget.purchaseId != null ? "updated" : "created"} successfully');
      Get.back();
    } else {
      // Handle nested validation errors if present
      String? displayError;
      if (response != null && response["message"] is Map) {
        final msgMap = response["message"];
        if (msgMap["errors"] is Map && (msgMap["errors"] as Map).isNotEmpty) {
           final firstError = (msgMap["errors"] as Map).values.first;
           displayError = firstError is List ? firstError.first.toString() : firstError.toString();
        } else {
           displayError = msgMap["message"]?.toString();
        }
      }

      Toaster.showError(displayError ?? response?["message"]?.toString() ?? 'Failed to save purchase order');
    }
  }
}
