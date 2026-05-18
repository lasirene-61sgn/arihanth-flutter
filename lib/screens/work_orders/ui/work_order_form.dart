import 'dart:io';

import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/products/model/bp_buyer_model.dart';
import 'package:arianth/screens/products/model/products_model.dart';
import 'package:arianth/screens/products/model/sub_category_model.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/screens/work_orders/model/work_orders_model.dart';
import 'package:arianth/screens/work_orders/riverpod/work_orders_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:arianth/services/widget/reuseable_dropdown.dart';
import 'package:arianth/screens/work_orders/ui/widgets/work_order_dropdown_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:arianth/screens/products/widgets/add_category_dialog.dart';
import 'package:arianth/screens/products/widgets/add_sub_category_dialog.dart';
import 'package:arianth/screens/products/model/category_model.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/image_picker/image_picker_helper.dart';

class WorkOrderForm extends ConsumerStatefulWidget {
  final String? id;

  const WorkOrderForm({super.key, this.id});

  @override
  ConsumerState<WorkOrderForm> createState() => _WorkOrderFormState();
}

class _WorkOrderFormState extends ConsumerState<WorkOrderForm> {
  // ---------- Controllers ----------
  final TextEditingController _customerNameCtrl = TextEditingController();
  final TextEditingController _referenceNoCtrl = TextEditingController();
  final TextEditingController _quantityCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _craftsmanNoteCtrl = TextEditingController();
  final TextEditingController _sizeCtrl = TextEditingController();
  final TextEditingController _lengthCtrl = TextEditingController();
  final TextEditingController _productCodeCtrl = TextEditingController();
  final TextEditingController _weightFromCtrl = TextEditingController();
  final TextEditingController _weightToCtrl = TextEditingController();
  final TextEditingController _customerDateCtrl = TextEditingController();
  final TextEditingController _craftsmanDateCtrl = TextEditingController();
  bool _showKycErrors = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
// Change this line

  // ---------- State ----------
  DateTime? _customerDueDate;
  DateTime? _craftsmanDueDate;
// PlatformFile? _productImage;
  List<PlatformFile> _selectedImages = [];
  String? _selectedBpCode;
  String? _selectedProductName;

  // ---------- Dropdown selected values ----------
  String _selectedCategory = '';
  String _selectedType = '';
  String _selectedStone = '';
  String _selectedScrew = '';
  String _selectedHook = '';
  String _selectedOpenClose = '';
  String _selectedHallmark = '';
  String _selectedRodium = '';
  String _selectedEnamel = '';
  String _productCategory = '';
  String _subCategory = '';
  List<String>? _serverImageUrl;
  String? mobileNo;
  String? gstNo;

  Timer? _productCodeDebounce;

  // ---------- Helper ----------
  bool get _hasImageForValidation =>
      (_selectedImages.isNotEmpty && _selectedImages.first.bytes != null) ||
          (_serverImageUrl != null && _serverImageUrl!.isNotEmpty);

  bool get _isFormValid =>
      _formKey.currentState?.validate() == true && _hasImageForValidation;

  // Validators
  String? _customerValidator(dynamic _) =>
      _customerDueDate == null ? 'Select a date' : null;

  String? _craftsmanValidator(dynamic _) {
    if (_craftsmanDueDate == null) return 'Select a date';
    if (_customerDueDate != null &&
        _craftsmanDueDate!.isAfter(_customerDueDate!)) {
      return 'Must be on or before customer due date';
    }
    return null;
  }

  String? role;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role") ?? '';
    Future.microtask(() {
      final productNotifier = ref.read(productListProvider.notifier);
      final productState = ref.read(productListProvider);
      
      if (productState.categories.isEmpty) productNotifier.fetchCategories();
      if (productState.bpBuyerList.isEmpty) productNotifier.fetchBPCodes();

      if (widget.id != null && widget.id!.isNotEmpty && widget.id != "null") {
        _fillForm();
        ref.read(productListProvider.notifier).fetchBPCodes();
      }
    });
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _referenceNoCtrl.dispose();
    _quantityCtrl.dispose();
    _noteCtrl.dispose();
    _craftsmanNoteCtrl.dispose();
    _sizeCtrl.dispose();
    _lengthCtrl.dispose();
    _productCodeCtrl.dispose();
    _weightFromCtrl.dispose();
    _weightToCtrl.dispose();
    _customerDateCtrl.dispose();
    _craftsmanDateCtrl.dispose();
    _productCodeDebounce?.cancel();
    super.dispose();
  }

  Future<void> _fillForm() async {
    await ref
        .read(workOrderListProvider.notifier)
        .workOrderDetail(widget.id.toString(), context);
    final data = ref.read(workOrderListProvider).workOrderDetail;

    if (data == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      DateTime? serverDate;
      if (data.dueDate != null && data.dueDate!.isNotEmpty) {
        try {
          final parts = data.dueDate!.split('-');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            serverDate = DateTime(year, month, day);
          }
        } catch (e) {
          serverDate = DateTime.tryParse(data.dueDate!);
        }
      }

      DateTime? craftDate;
      if (data.craftsmanDueDate != null && data.craftsmanDueDate!.isNotEmpty) {
        try {
          final parts = data.craftsmanDueDate!.split('-');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            craftDate = DateTime(year, month, day);
          }
        } catch (e) {
          craftDate = DateTime.tryParse(data.craftsmanDueDate!);
        }
      }

      setState(() {
        _isDataLoaded = true;
        _selectedBpCode = data.bpCode ?? data.allocatedCraftsmanBpCode; 
        _customerDueDate = serverDate;
        _craftsmanDueDate = craftDate;

        _customerNameCtrl.text = data.customerName ?? '';
        _referenceNoCtrl.text = data.referenceNo ?? '';
        _quantityCtrl.text = (data.quantity ?? '').toString();
        _noteCtrl.text = data.narrationAdmin ?? '';
        _craftsmanNoteCtrl.text = data.narrationCraftsman ?? '';
        _sizeCtrl.text = data.size ?? '';
        _lengthCtrl.text = data.length ?? '';
        _productCodeCtrl.text = data.designCode ?? data.productCode ?? '';
        _weightFromCtrl.text = data.weightFrom ?? '';
        _weightToCtrl.text = data.weightTo ?? '';
        _selectedEnamel = data.enamel ?? '';
        _selectedHook = data.hook ?? '';

        _productCategory = data.productCategory ?? '';
        _subCategory = data.subcategory ?? '';
        _selectedProductName = data.productName ?? '';

        _selectedType = data.type ?? '';
        _selectedStone = data.stone ?? '';
        _selectedOpenClose = data.openClose ?? '';
        _selectedHallmark = data.hallmark ?? '';
        _selectedRodium = data.rodium ?? '';
        _selectedScrew = data.screwName ?? '';

        _serverImageUrl = data.images?.map((e) => e.toString()).toList() ?? [];
      });

      if (_selectedBpCode != null && _selectedBpCode!.isNotEmpty) {
        ref.read(productListProvider.notifier).
        fetchProductByCode(_selectedBpCode!);
      }

      if (_productCategory.isNotEmpty) {
        final state = ref.read(productListProvider);
        final categories = state.categories ?? [];
        final selectedCat = categories.firstWhere(
              (cat) => cat.name.trim() == _productCategory.trim(),
          orElse: () => Category(id: 0, name: ''),
        );
        if (selectedCat.id != 0) {
          ref.read(productListProvider.notifier).fetchSubCategories(
            url: "api/common/products/subcategories/?category_id=${selectedCat.id}",
          );
        }
      }
    });
  }



  void _onProductCodeChanged(String value) {
    if (_productCodeDebounce?.isActive ?? false) _productCodeDebounce!.cancel();

    _productCodeDebounce = Timer(const Duration(milliseconds: 600), () async {
      final code = value.trim();
      if (code.isEmpty) return;

      final BPProductData? productData = await ref
          .read(productListProvider.notifier)
          .fetchProductByCode(code);

      if (productData != null) {
        setState(() {
          // Update the fields with grabbed product data
          _selectedProductName = productData.productName ?? '';
          _productCodeCtrl.text = productData.designCode ?? code;

          _sizeCtrl.text = productData.size ?? '';
          _lengthCtrl.text = productData.length ?? '';
          _weightFromCtrl.text = productData.weightFrom ?? '';
          _weightToCtrl.text = productData.weightTo ?? '';

          _selectedType = productData.type ?? '';
          _selectedStone = productData.stone ?? '';
          _selectedHook = productData.hook ?? '';
          _selectedOpenClose = productData.openClose ?? '';
          _selectedHallmark = productData.hallmark ?? '';
          _selectedRodium = productData.rodium ?? '';
          _selectedEnamel = productData.enamel ?? '';

          // If there are images, we can prefill the _serverImageUrl
          if (productData.images != null && productData.images!.isNotEmpty) {
            _serverImageUrl = productData.images!.map((e) => e.imageUrl.toString()).toList();
          } else if (productData.productImageUrl != null && productData.productImageUrl!.isNotEmpty) {
            _serverImageUrl = [productData.productImageUrl!];
          } else {
            _serverImageUrl = [];
          }

          // Fetch Subcategories if Product Category ID matches anything
          if (productData.productCategoryId != null) {
            final state = ref.read(productListProvider);
            final categories = state.categories ?? [];
            final matchedCat = categories.firstWhere(
                  (cat) => cat.id == productData.productCategoryId,
              orElse: () => Category(id: 0, name: ''),
            );

            if (matchedCat.id != 0) {
              _productCategory = matchedCat.name;
              ref.read(productListProvider.notifier).fetchSubCategories(
                url: "api/common/products/subcategories/?category_id=${matchedCat.id}",
              ).then((_) {
                // Try to set subcategory after loading
                if (productData.subcategoryId != null) {
                  final state = ref.read(productListProvider);
                  final subs = state.subCategories ?? [];
                  final matchedSub = subs.firstWhere(
                          (sub) => sub.id == productData.subcategoryId,
                      // orElse: () => SubCategory(id: 0, name: '')
                  );
                  if (matchedSub.id != 0) {
                    setState(() => _subCategory = matchedSub.name);
                  }
                }
              });
            }
          }
        });
      }
    });
  }

  void _createWorkOrder() {
    if (!_formKey.currentState!.validate() || !_hasImageForValidation) return;

    final bpCodeClean = _selectedBpCode != null && _selectedBpCode!.contains('-')
        ? _selectedBpCode!.split('-').first.trim()
        : _selectedBpCode?.trim() ?? '';

    final customerDueDateStr = _customerDueDate != null
        ? "${_customerDueDate!.year}-${_customerDueDate!.month.toString().padLeft(2, '0')}-${_customerDueDate!.day.toString().padLeft(2, '0')}"
        : null;

    final craftsmanDueDateStr = _craftsmanDueDate != null
        ? "${_craftsmanDueDate!.year}-${_craftsmanDueDate!.month.toString().padLeft(2, '0')}-${_craftsmanDueDate!.day.toString().padLeft(2, '0')}"
        : null;

    final roleLower = role?.toLowerCase() ?? '';
    final isRestrictedRole = roleLower == "key_user" || roleLower == "user" || roleLower == "buyer";

    final workOrder = WorkOrder(
      bpCode: _selectedBpCode,
      customerName: _customerNameCtrl.text.trim(),
      referenceNo: _referenceNoCtrl.text.trim(),
      dueDate: customerDueDateStr,
      productCategory: _productCategory.isEmpty ? _selectedCategory.toString() : _productCategory.toString(),
      subcategory: _subCategory,
      quantity: _quantityCtrl.text.trim(),
      type: _selectedType,
      weightFrom: _weightFromCtrl.text.trim().isEmpty ? null : _weightFromCtrl.text.trim(),
      weightTo: _weightToCtrl.text.trim().isEmpty ? null : _weightToCtrl.text.trim(),
      openClose: _selectedOpenClose,
      hallmark: _selectedHallmark,
      rodium: _selectedRodium,
      hook: _selectedHook,
      size: _sizeCtrl.text.trim(),
      stone: _selectedStone,
      enamel: _selectedEnamel,
      screwName: _selectedScrew,
      length: _lengthCtrl.text.trim().isEmpty ? null : _lengthCtrl.text.trim(),
      designCode: _productCodeCtrl.text.trim(),
      productName: "",
      narrationAdmin: isRestrictedRole ? _noteCtrl.text.trim() : null,
      narrationCraftsman: !isRestrictedRole ? _craftsmanNoteCtrl.text.trim() : null,
      craftsmanDueDate: !isRestrictedRole ? craftsmanDueDateStr : null,
    );

    final payload = workOrder.toJson();
    // Append narration manually as it's required by the backend API 
    // but not explicitly defined as a separate mapping in the WorkOrder model
    if (roleLower != 'buyer') {
      payload["narration"] = _noteCtrl.text.trim();
    }

    final Map<String, dynamic> files = {};
    for (int i = 0; i < _selectedImages.length; i++) {
      files["product_images[$i]"] = _selectedImages[i];
    }

    ref.read(workOrderListProvider.notifier).saveWorkOrder(

      id: (widget.id != null && widget.id!.isNotEmpty && widget.id != "null")
          ? widget.id.toString()
          : null,
      url: (widget.id != null && widget.id!.isNotEmpty && widget.id != "null")
          ? "api/common/work-orders/${widget.id.toString()}"
          : "api/common/work-orders",
      context,
      payload,
      files.isNotEmpty ? files : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workOrderListProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;
    final productState = ref.watch(productListProvider);
    final product = productState.productDetail;

    final isBpCodeReadOnly = product != null &&
        (product.bpCode != null && product.bpCode!.isNotEmpty);
    final bool showInfoIcon = _hasValue(gstNo) || _hasValue(mobileNo);
    final categories = productState.categories ?? [];

    Category? selectedCategoryModel;
    try {
      if (_productCategory.isNotEmpty) {
        selectedCategoryModel = categories.firstWhere((c) => c.name == _productCategory);
      }
    } catch (_) {}

    final bool showHook = selectedCategoryModel?.hasHook == true;
    final bool showEnamel = selectedCategoryModel?.hasEnamel == true;
    final bool showRodium = selectedCategoryModel?.hasRodium == true;
    final bool showOpenClose = selectedCategoryModel?.hasOpenClose == true;
    final bool showStone = selectedCategoryModel?.hasStone == true;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColor.white),
          onPressed: () {
            Get.back();
          },
        ),
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          ref.watchTr(widget.id != null && widget.id != "null" && widget.id!.isNotEmpty
              ? 'edit_work_order'
              : 'create_work_order'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColor.white,
          ),
        ),
      ),
      body: SafeArea(
        child: MouseRegion(
          cursor: SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              color: AppColor.background,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 880,
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _imageUploader(),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Aligns labels if heights differ
                            children: [
                               // Provides consistent spacing between dropdowns
                              _buildBpCodeDropdown(isBpCodeReadOnly),
                              _buildProductCategoryDropdown(),
                              const SizedBox(width: 12), // Provides consistent spacing between dropdowns
                              _buildProductSubCategoryDropdown(),
                              const SizedBox(width: 12),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // 1. Core Identifiers Group
                          _responsiveLayout(context, [
                            _smallInput(
                              label: 'Product Code',
                              controller: _productCodeCtrl,
                              onChanged: _onProductCodeChanged,
                              isLoading: productState.isSaving,
                            ),
                            _smallInput(
                              label: 'Reference Number',
                              controller: _referenceNoCtrl,
                            ),
                            // _smallInput(
                            //   label: 'Customer Name',
                            //   controller: _customerNameCtrl,
                            //   validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                            //   suffixIcon: showInfoIcon ? Icons.info_outline : null,
                            //   tooltipMessage: [
                            //     if (_hasValue(gstNo)) 'GST No: $gstNo',
                            //     if (_hasValue(mobileNo)) 'Mobile: $mobileNo',
                            //   ].join('\n'),
                            //   mobileNumber: _hasValue(mobileNo) ? mobileNo : null,
                            // ),
                            _smallInput(
                              label: 'Quantity',
                              controller: _quantityCtrl,
                              keyboard: TextInputType.number,
                              validator: (v) {
                                if (v?.trim().isEmpty ?? true) return 'Required';
                                if (int.tryParse(v!) == null) return 'Invalid number';
                                return null;
                              },
                            ),
                            WorkOrderDropdownWidget(
                              label: 'Type',
                              fieldKeyName: 'type',
                              hintText: 'Select Type',
                              items: const ['Piece', 'Pair'],
                              value: _selectedType,
                              onChanged: (v) =>
                                  setState(() => _selectedType = v!),
                            ),
                            WorkOrderDropdownWidget(
                              label: 'Screw',
                              fieldKeyName: 'screw',
                              hintText: 'Select Screw',
                              items: const ['north screw', 'south screw'],
                              value: _selectedScrew,
                              onChanged: (v) =>
                                  setState(() => _selectedScrew = v!),
                            ),
                          ]),
                          const SizedBox(height: 8),

                          // 2. Dates Group
                          _responsiveLayout(context, [
                            _dateField(
                              label: 'Customer Due Date',
                              onPick: (d) => setState(() {
                                _customerDueDate = d;
                                if (_craftsmanDueDate != null && _craftsmanDueDate!.isAfter(d)) {
                                  _craftsmanDueDate = null;
                                }
                              }),
                              value: _customerDueDate,
                              validator: _customerValidator,
                              controller: _customerDateCtrl,
                            ),

                              if(role?.toLowerCase() != "key_user" && role?.toLowerCase() != "user" && role?.toLowerCase() != "buyer")
                              _dateField(
                                label: 'Craftsman Due Date',
                                onPick: (d) =>
                                    setState(() => _craftsmanDueDate = d),
                                value: _craftsmanDueDate,
                                validator: _craftsmanValidator,
                                lastDateOverride: _customerDueDate ??
                                    DateTime.now()
                                        .add(const Duration(days: 365 * 5)),
                                controller: _craftsmanDateCtrl,
                              ),
                          ]),
                          const SizedBox(height: 8),

                          // 3. Size, Quantity & Hooks Group
                          _responsiveLayout(context, [
                            _smallInput(
                              label: 'Length',
                              controller: _lengthCtrl,
                              keyboard: TextInputType.text,
                            ),
                            if (showHook)
                              WorkOrderDropdownWidget(
                                label: 'Hook',
                                fieldKeyName: 'hook',
                                hintText: 'Select Hook',
                                items: const ['No', "Single", "Double"],
                                value: _selectedHook,
                                onChanged: (v) =>
                                    setState(() => _selectedHook = v!),
                              ),
                            _smallInput(
                              label: 'Weight From (grams)',
                              controller: _weightFromCtrl,
                              keyboard: TextInputType.number,
                              validator: (v) {
                                if (v?.trim().isEmpty ?? true) return null;
                                if (double.tryParse(v!) == null) return 'Invalid number';
                                return null;
                              },
                            ),
                            _smallInput(
                              label: 'Weight To (grams)',
                              controller: _weightToCtrl,
                              keyboard: TextInputType.number,
                              validator: (v) {
                                if (v?.trim().isEmpty ?? true) return null;
                                if (double.tryParse(v!) == null) return 'Invalid number';
                                return null;
                              },
                            ),

                          ]),
                          const SizedBox(height: 8),

                          // 4. Attributes Group (Stone, Screw, Enamel, Rodium, etc)
                          _responsiveLayout(context, [
                            if (showStone)
                              WorkOrderDropdownWidget(
                                label: 'Stone',
                                fieldKeyName: 'stone',
                                hintText: 'Select Stone',
                                items: const ['Yes', 'No'],
                                value: _selectedStone,
                                onChanged: (v) =>
                                    setState(() => _selectedStone = v!),
                              ),
                            _smallInput(
                              label: 'Size',
                              controller: _sizeCtrl,
                              keyboard: TextInputType.text,
                            ),
                            // WorkOrderDropdownWidget(
                            //   label: 'Screw',
                            //   fieldKeyName: 'screw',
                            //   items: const ['Yes', 'No'],
                            //   value: _selectedScrew,
                            //   onChanged: (v) =>
                            //       setState(() => _selectedScrew = v!),
                            // ),
                            if (showOpenClose)
                              WorkOrderDropdownWidget(
                                label: 'Open/Close',
                                fieldKeyName: 'open_close',
                                hintText: 'Select Option',
                                items: const ['Open', 'Close'],
                                value: _selectedOpenClose,
                                onChanged: (v) =>
                                    setState(() => _selectedOpenClose = v!),
                              ),
                            WorkOrderDropdownWidget(
                              label: 'Hallmark',
                              fieldKeyName: 'hallmark',
                              hintText: 'Select Hallmark',
                              items: const ['Yes', 'No'],
                              value: _selectedHallmark,
                              onChanged: (v) =>
                                  setState(() => _selectedHallmark = v!),
                            ),
                            if (showEnamel)
                              WorkOrderDropdownWidget(
                                label: 'Enamel',
                                fieldKeyName: 'enamel',
                                hintText: 'Select Enamel',
                                items: const ['Yes', 'No'],
                                value: _selectedEnamel,
                                onChanged: (v) =>
                                    setState(() => _selectedEnamel = v!),
                              ),
                            if (showRodium)
                              WorkOrderDropdownWidget(
                                label: 'Rodium',
                                fieldKeyName: 'rodium',
                                hintText: 'Select Rodium',
                                items: const ['Yes', 'No'],
                                value: _selectedRodium,
                                onChanged: (v) =>
                                    setState(() => _selectedRodium = v!),
                              ),
                          ]),
                          const SizedBox(height: 8),

                          // 5. Notes Group
                          _responsiveLayout(context, [
                            _textArea(
                              label: 'Note',
                              controller: _noteCtrl,
                            ),
                            if(role?.toLowerCase() != "key_user" && role?.toLowerCase() != "user" && role?.toLowerCase() != "buyer")
                              _textArea(
                                label: 'Craftsman Note',
                                controller: _craftsmanNoteCtrl,
                              ),
                          ]),
                          const SizedBox(height: 16),

                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CustomButton(
                                width: isMobile ? 120 : 100,
                                // height: 40,
                                text: 'Cancel',
                                onPressed: () => Get.back(),
                                backgroundColor: AppColor.warning,
                                textColor: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              CustomButton(
                                width: isMobile ? 120 : 160,
                                // height: 40,
                                text: widget.id != null ||
                                    (widget.id?.isNotEmpty == true) ||
                                    widget.id == "null"
                                    ? "Update"
                                    : 'Create',
                                isLoading: state.isSaving,
                                onPressed: _isFormValid || !state.isSaving
                                    ? _createWorkOrder
                                    : null,
                                backgroundColor: AppColor.primary,
                                textColor: AppColor.textWhite,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }



  // ---------- RESPONSIVE LAYOUT HELPER ----------
  Widget _responsiveLayout(BuildContext context, List<Widget> children) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final itemsPerRow = isMobile ? 2 : 3;

    if (children.isEmpty) return const SizedBox.shrink();

    final validChildren =
    children.where((w) => w != const SizedBox.shrink()).toList();

    if (validChildren.length == 1) {
      return validChildren[0];
    }

    final List<List<Widget>> rows = [];
    for (int i = 0; i < validChildren.length; i += itemsPerRow) {
      final end = (i + itemsPerRow).clamp(0, validChildren.length);
      rows.add(validChildren.sublist(i, end));
    }

    return Column(
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _buildRow(rows[i], itemsPerRow),
        ],
      ],
    );
  }

  Widget _buildRow(List<Widget> items, int itemsPerRow) {
    return Row(
      children: [
        for (int i = 0; i < itemsPerRow; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: i < items.length ? items[i] : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          color: AppColor.textSecondary,
        ),
        const SizedBox(height: 6),
        const Text(
          'Click to upload images *',
          style: TextStyle(color: AppColor.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        const Text(
          'Supported formats: JPG, PNG',
          style: TextStyle(fontSize: 11, color: AppColor.textSecondary),
        ),
      ],
    );
  }
  Widget _imageUploader() {
    final hasNewImage = _selectedImages.isNotEmpty && _selectedImages.first.bytes != null;

    final imageExists = hasNewImage ||
        (_serverImageUrl != null && _serverImageUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Image *',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColor.textPrimary),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: imageExists ? AppColor.divider : AppColor.error.withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(8),
              color: AppColor.surface,
            ),
            child: // Inside _imageUploader's Container child:
            SizedBox(
              height: 120,
              child: _selectedImages.isEmpty && (_serverImageUrl == null || _serverImageUrl!.isEmpty)
                  ? _buildUploadPlaceholder() // Move your existing placeholder logic here
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + (_serverImageUrl?.length ?? 0) + 1,
                itemBuilder: (context, index) {
                  final int serverImagesCount = _serverImageUrl?.length ?? 0;
                  
                  if (index < serverImagesCount) {
                    // Display Server Image
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(
                                  _serverImageUrl![index].startsWith('http')
                                      ? _serverImageUrl![index]
                                      : _serverImageUrl![index],
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _serverImageUrl!.removeAt(index);
                                if (_serverImageUrl!.isEmpty) {
                                  _serverImageUrl = null;
                                }
                              }),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                    if (index < serverImagesCount + _selectedImages.length) {
                      // Display Picked File
                      final int localIndex = index - serverImagesCount;
                      final file = _selectedImages[localIndex];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: file.bytes != null ? DecorationImage(
                                  image: MemoryImage(file.bytes!),
                                  fit: BoxFit.cover,
                                ) : null,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedImages.removeAt(localIndex)),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Add More Button
                    return _buildAddMoreCard();
                  },
                ),
            ),
          ),
        ),
        if (!imageExists)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Image is required',
              style: TextStyle(color: Colors.red, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildAddMoreCard() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColor.coolLavender.withOpacity(0.5), width: 1),
          color: AppColor.surface,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColor.coolLavender, size: 24),
            SizedBox(height: 4),
            Text('Add More', style: TextStyle(fontSize: 10, color: AppColor.coolLavender)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final result = await ImagePickerHelper.pickImages(context, allowMultiple: true);

      if (result.isNotEmpty) {
        setState(() {
          final validFiles = result.where((file) {
            final fileSizeMB = (file.size / (1024 * 1024));
            return fileSizeMB <= 5.0; // Increased to 5MB to match other forms
          }).toList();

          _selectedImages.addAll(validFiles);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Widget _smallInput({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboard,
    bool? readonly,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    IconData? suffixIcon,
    String? tooltipMessage,
    String? mobileNumber,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColor.black),
        ),
        const SizedBox(height: 6),
        CustomInputField(
          labelText: null,
          isLoading: isLoading,
          controller: controller,
          keyboardType: keyboard,
          readOnly: readonly ?? false,
          validator: validator,
          style: const TextStyle(fontSize: 12, color: AppColor.textPrimary),
          maxLines: 1,
          hideCounterText: true,
          onChanged: onChanged,
          decoration: _inputDecoration().copyWith(
            hintText: 'Enter $label',
            hintStyle: const TextStyle(fontSize: 12, color: AppColor.primary),
            suffixIcon: suffixIcon == null
                ? null
                : Builder(
                    builder: (iconContext) => InkWell(
                      onTap: () {
                        _showTopTooltip(
                          iconContext,
                          tooltipMessage ?? '',
                          mobileNumber,
                        );
                      },
                      child: const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _showTopTooltip(
      BuildContext context,
      String message,
      String? mobileNumber,
      ) {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: offset.dx - 140,
        top: offset.dy - 80,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 8),
                if (mobileNumber != null && mobileNumber.isNotEmpty && !kIsWeb)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        entry.remove();
                        _makeCall(mobileNumber);
                      },
                      icon: const Icon(Icons.call,
                          size: 16, color: Colors.green),
                      label: const Text(
                        "Call",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) entry.remove();
    });
  }

  Future<void> _makeCall(String mobile) async {
    final uri = Uri.parse('tel:$mobile');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _textArea({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        CustomInputField(
          labelText: label,
          controller: controller,
          maxLines: 4,
          validator: validator,
          style: const TextStyle(fontSize: 12,color: AppColor.black),
          hideCounterText: true,
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required ValueChanged<DateTime> onPick,
    DateTime? value,
    String? Function(dynamic)? validator,
    DateTime? lastDateOverride,
    required TextEditingController controller,
  }) {
    final formattedDate = value != null
        ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
        : '';
    if (controller.text != formattedDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          controller.text = formattedDate;
        }
      });
    }

    final errorText = validator?.call(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColor.black),
        ),
        const SizedBox(height: 6),
        CustomInputField(
          labelText: null,
          controller: controller,
          readOnly: true,
          onTap: () async {
            final DateTime now = DateTime.now();
            final DateTime first = now;
            final DateTime last =
                lastDateOverride ?? now.add(const Duration(days: 365 * 5));
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: first,
              lastDate: last,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColor.primary,
                      onPrimary: AppColor.black,
                      surface: AppColor.background,
                      onSurface: AppColor.textPrimary,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColor.black,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onPick(picked);
              controller.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
            }
          },
          suffixIcon: const Icon(Icons.calendar_today, size: 16),
          hintText: 'dd/mm/yyyy',
          style: TextStyle(
            fontSize: 12,
            color: value != null ? AppColor.black : AppColor.primary,
          ),
          decoration: _inputDecoration().copyWith(
            hintText: 'dd/mm/yyyy',
            hintStyle: const TextStyle(fontSize: 12, color: AppColor.primary),
            suffixIcon: const Icon(Icons.calendar_today, size: 16, color: AppColor.primary),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 11),
            ),
          ),
      ],
    );
  }

  bool _hasValue(String? value) {
    return value != null &&
        value.trim().isNotEmpty &&
        value.toLowerCase() != 'null';
  }
  Widget _buildBpCodeDropdown(bool isReadOnly) {
    final partnerState = ref.watch(productListProvider);
    // Safely handle potential null list from provider
    final List<BpBuyerModel> partners = partnerState.bpBuyerList ?? [];

    // Filter out partners without a BP Code or Name
    final validPartners = partners.where((bp) => 
      bp.bpCode != null && bp.bpCode!.isNotEmpty &&
      bp.businessName != null && bp.businessName!.isNotEmpty
    ).toList();

    // Find the currently selected model based on _selectedBpCode string
    BpBuyerModel? selectedModel;
    if (_selectedBpCode != null && _selectedBpCode!.isNotEmpty) {
      selectedModel = validPartners.cast<BpBuyerModel?>().firstWhere(
        (bp) => bp?.bpCode == _selectedBpCode, 
        orElse: () => null
      );
    }

    return WorkOrderDropdownWidget<BpBuyerModel>(
      label: 'Customer BP Code',
      fieldKeyName: 'bp_code',
      items: validPartners,
      itemLabel: (bp) => "${bp.bpCode} - ${bp.businessName}",
      selectedItemLabel: (bp) => bp.bpCode ?? '',
      value: selectedModel,
      isSearchable: true,
      hintText: 'Select BP Code',
      readOnly: isReadOnly,
      isLoading: partnerState.isLoadingBp,
      onChanged: isReadOnly
          ? null
          : (BpBuyerModel? selectedPartner) async {
        if (selectedPartner == null) return;

        setState(() {
          _selectedBpCode = selectedPartner.bpCode;

          // 3. Update related fields safely
          mobileNo = selectedPartner.mobile ?? '';
          gstNo = selectedPartner.gstNo ?? '';

          // Logic for Customer Name based on business_name format
          String businessName = selectedPartner.businessName ?? '';
          if (businessName.isNotEmpty) {
            // Handle "SCM-Chennai" format: extract "Chennai"
            List<String> parts = businessName.split('-');
            _customerNameCtrl.text = parts.length > 1
                ? parts[1].trim()
                : businessName;
          } else {
            _customerNameCtrl.text = '';
          }
        });

        // 4. Trigger API call using the bp_code (ID-like field)
        final codeToFetch = selectedPartner.bpCode;
        if (codeToFetch != null && codeToFetch.isNotEmpty) {
          await ref
              .read(productListProvider.notifier)
              .fetchProductByCode(codeToFetch);
        }
      },
    );
  }

  Widget _buildProductCategoryDropdown() {
    final productState = ref.watch(productListProvider);
    final categories = productState.categories ?? [];

    final categoryList = categories
        .where((cat) => cat.name.trim().isNotEmpty)
        .map((cat) => cat.name.trim())
        .toSet()
        .toList();

    categoryList.insert(0, '+ Add New Category');

    return WorkOrderDropdownWidget<String>(
      label: 'Product Category',
      fieldKeyName: 'product_category',
      items: categoryList,
      value: categoryList.contains(_productCategory) ? _productCategory : null,
      isSearchable: true,
      hintText: 'Select category',
      isLoading: productState.isLoadingCategories,
      onChanged: (v) async {
        final notifier = ref.read(productListProvider.notifier);
        if (v == '+ Add New Category') {
          final result = await AddCategoryDialog.show(context, '');
          if (result != null) {
            final saved = await notifier.saveCategory(
                  result['name'],
                  hasHook: result['hasHook'],
                  hasEnamel: result['hasEnamel'],
                  hasRodium: result['hasRodium'],
                  hasOpenClose: result['hasOpenClose'],
                  hasStone: result['hasStone'],
                );

            if (saved != null) {
              if (mounted) {
                setState(() {
                  _productCategory = saved.name.trim();
                  _subCategory = '';
                });
                await notifier.fetchSubCategories(
                  url: "api/common/products/subcategories/?category_id=${saved.id}",
                );
              }
            }
          }
          return; 
        }
        
        if (v != null) {
          setState(() {
            _productCategory = v;
            _subCategory = '';
          });

          final selectedCat = categories.firstWhere(
                (cat) => cat.name.trim() == v.trim(),
            orElse: () => Category(id: 0, name: ''),
          );

          if (selectedCat.id != 0) {
            await notifier.fetchSubCategories(
              url: "api/common/products/subcategories/?category_id=${selectedCat.id}",
            );
          }
        }
      },
    );
  }

  Widget _buildProductSubCategoryDropdown() {
    final productState = ref.watch(productListProvider);
    final subCategories = productState.subCategories;

    final subCategoryList = subCategories
        .map((sc) => sc.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    if (_productCategory.isNotEmpty) {
      subCategoryList.insert(0, '+ Add New Sub Category');
    }

    return WorkOrderDropdownWidget<String>(
      label: 'Sub Category',
      fieldKeyName: 'sub_category',
      items: subCategoryList,
      value: subCategoryList.contains(_subCategory) ? _subCategory : null,
      isSearchable: true,
      isLoading: productState.isLoadingSubCategories,
      hintText: _productCategory.isEmpty
          ? 'Select Category First'
          : 'Select sub category',
      onChanged: (v) async {
        if (v == '+ Add New Sub Category') {
          final newValue = await AddSubCategoryDialog.show(context, '');
          if (newValue != null && newValue.trim().isNotEmpty) {
            final categories = productState.categories;
            final selectedCat = categories.firstWhere(
                (cat) => cat.name.trim() == _productCategory.trim(),
                orElse: () => Category(id: 0, name: ''),
            );

            final saved = await ref
                .read(productListProvider.notifier)
                .saveSubCategory(
                  newValue.trim(),
                  category: _productCategory,
                  categoryId: selectedCat.id != 0 ? selectedCat.id : null,
                );
                
            if (saved != null) {
              if (mounted) {
                setState(() => _subCategory = newValue.trim());
              }
            }
          }
          return;
        }
        if (v != null) {
          setState(() => _subCategory = v);
        }
      },
    );
  }


  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColor.coolLavender, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColor.coolLavender, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColor.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColor.error, width: 1.5),
      ),
      fillColor: AppColor.surface,
      filled: true,
    );
  }

}