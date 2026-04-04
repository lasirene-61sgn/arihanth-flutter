// Updated CreateProductForm (Web-Only, Mobile Responsiveness Added)
import 'dart:io';

import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/products/model/bp_buyer_model.dart';
import 'package:arianth/screens/products/model/products_model.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:arianth/services/widget/form_field_common_button.dart';
import 'package:arianth/services/widget/reusable_file_picker.dart';


import 'package:arianth/services/widget/reuseable_dropdown.dart';
import 'package:arianth/screens/work_orders/ui/widgets/work_order_dropdown_widget.dart';
import 'package:arianth/screens/products/widgets/add_category_dialog.dart';
import 'package:arianth/screens/products/widgets/add_sub_category_dialog.dart';
import 'package:arianth/screens/products/model/category_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:arianth/services/localization/app_localization.dart';

import 'package:arianth/services/image_picker/image_picker_helper.dart';
import '../model/sub_category_model.dart';

class CreateProductForm extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onCreate;
  final String? type;
  final String? productId;
  final String? action;

  const CreateProductForm({
    super.key,
    required this.onClose,
    required this.onCreate,
    this.type,
    this.productId,
    this.action,
  });

  @override
  ConsumerState<CreateProductForm> createState() => _CreateProductFormState();
}

class _CreateProductFormState extends ConsumerState<CreateProductForm> {
  final _formKey = GlobalKey<FormState>();
  String? role;
  // Controllers
  final _quantityController = TextEditingController();
  final _weightFromController = TextEditingController();
  final _weightToController = TextEditingController();
  final _narrationCraftsmanController = TextEditingController();
  final _narrationAdminController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final _lengthController = TextEditingController();
  final _productNameController = TextEditingController();
  final _productCodeController = TextEditingController();
  final _noteController = TextEditingController();

  // Dropdown values
  String _productCategory = '';
  String _subCategory = '';
  String _type = "";
  String status = "";
  String _orderType = "";
  // String _designStatus = "";
  String _selectedBpCode = "";
  String _stone = '';
  String _enamel = '';
  String _openClose = '';
  String _hallmark = '';
  String _rodium = '';
  String _hook = '';
  int? _isLocked;

  // Multi-image state
  List<PlatformFile> _selectedImages = [];
  List<String>? _serverImageUrl;

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role");
    if (widget.productId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProductDetails();
      });
    }
  }

  Future<void> _loadProductDetails() async {
    await ref.read(productListProvider.notifier).productDetail(
        widget.productId!);

    final state = ref.read(productListProvider);
    if (state.productDetail != null) {
      final product = state.productDetail!;

      // Populate form fields
      _productCategory = product.category?.name ?? 'Bangles';
      _subCategory = product.subcategory?.name ?? '';
      _type = product.type ?? "";
      _stone = product.stone ?? '';
      _enamel = (product.enamel ?? '').toLowerCase() == '' ? '' : (product.enamel ?? '');
      _openClose = product.openClose ?? '';
      _hallmark = product.hallmark ?? '';
      _rodium = product.rodium ?? '';
      _sizeController.text = product.size ?? '';
      _lengthController.text = product.length?.toString() ?? '';
      _productNameController.text = product.productName ?? '';
      _productCodeController.text = product.productCode ?? '';
      _weightFromController.text = product.weightFrom?.toString() ?? '';
      _weightToController.text = product.weightTo?.toString() ?? '';
      _selectedBpCode = product.bpCode ?? '';
      _orderType = product.orderType ?? '';
      _isLocked = product.isLocked;

      // Handle Product Images - populate server image list
      final imageUrls = <String>[];
      if (product.images != null && product.images!.isNotEmpty) {
        for (final img in product.images!) {
          if (img.imageUrl != null && img.imageUrl!.isNotEmpty) {
            imageUrls.add(img.imageUrl!);
          }
        }
      } else if (product.productImage != null && product.productImage!.isNotEmpty) {
        imageUrls.add(product.productImage!);
      }
      if (imageUrls.isNotEmpty) {
        setState(() => _serverImageUrl = imageUrls);
      }

      setState(() {});

      // 🔥 Fetch dependent dropdown data based on loaded values
      if (_productCategory.isNotEmpty) {
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
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _weightFromController.dispose();
    _weightToController.dispose();
    _narrationCraftsmanController.dispose();
    _narrationAdminController.dispose();
    _lengthController.dispose();
    _productNameController.dispose();
    _productCodeController.dispose();
    super.dispose();
  }

  // 🖼️ Pick Files (Web Compatible)

  // 🧩 Submit and Save Product
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final state = ref.read(productListProvider);
    final categories = state.categories ?? [];
    final subCategories = state.subCategories ?? [];

    // Map names back to IDs for the model
    final selectedCat = categories.firstWhere(
      (c) => c.name.trim() == _productCategory.trim(),
      orElse: () => Category(id: 0, name: ''),
    );
    final selectedSubCat = subCategories.firstWhere(
      (sc) => sc.name.trim() == _subCategory.trim(),
        orElse: () => SubCategory(id: 0, categoryName: '', name: '', designCode: ''),
    );

    final product = Product(
      id: widget.productId != null ? int.tryParse(widget.productId ?? '') : null,
      productName: _productNameController.text.trim(),
      productCode: _productCodeController.text.trim(),
      productCategoryId: selectedCat.id != 0 ? selectedCat.id : null,
      productSubcategoryId: selectedSubCat.id != 0 ? selectedSubCat.id : null,
      type: _type,
      openClose: _openClose,
      hallmark: _hallmark,
      rodium: _rodium,
      hook: _hook,
      size: _sizeController.text.trim(),
      stone: _stone,
      enamel: _enamel,
      length: _lengthController.text.trim(),
      weightFrom: _weightFromController.text.trim(),
      weightTo: _weightToController.text.trim(),
      orderType: _orderType,
      isLocked: _isLocked,
      bpCode: (role != "Key User" && role != "User") 
          ? (_selectedBpCode.contains('-') ? _selectedBpCode.split('-').first.trim() : _selectedBpCode.trim())
          : null,
    );

    // Build indexed file map for multiple images
    final Map<String, dynamic> files = {};
    for (int i = 0; i < _selectedImages.length; i++) {
      files["images[$i]"] = _selectedImages[i];
    }
    // 🧠 Call Riverpod Notifier
    await ref.read(productListProvider.notifier).saveProduct(
      product.toJson(),
      id: widget.productId,
      files: files,
    );

  }

  Future<void> forAction(bool forAction) async {
    if (!_formKey.currentState!.validate()) return;

    final state = ref.read(productListProvider);
    final categories = state.categories ?? [];
    final subCategories = state.subCategories ?? [];

    final selectedCat = categories.firstWhere(
      (c) => c.name.trim() == _productCategory.trim(),
      orElse: () => Category(id: 0, name: ''),
    );
    final selectedSubCat = subCategories.firstWhere(
      (sc) => sc.name.trim() == _subCategory.trim(),
    );

    final product = Product(
      id: widget.productId != null ? int.tryParse(widget.productId ?? '') : null,
      productName: _productNameController.text.trim(),
      productCode: _productCodeController.text.trim(),
      productCategoryId: selectedCat.id != 0 ? selectedCat.id : null,
      productSubcategoryId: selectedSubCat.id != 0 ? selectedSubCat.id : null,
      type: _type,
      openClose: _openClose,
      hallmark: _hallmark,
      rodium: _rodium,
      hook: _hook,
      size: _sizeController.text.trim(),
      stone: _stone,
      enamel: _enamel,
      length: _lengthController.text.trim(),
      weightFrom: _weightFromController.text.trim(),
      weightTo: _weightToController.text.trim(),
      orderType: _orderType,
      isLocked: _isLocked,
      bpCode: _selectedBpCode,
    );

    // final PlatformFile? file = _pickedFiles.isNotEmpty ? _pickedFiles.first : null;
    //
    // await ref.read(productListProvider.notifier).forAction(
    //   product.toJson(),
    //   id: widget.productId != null ? widget.productId : null,
    //   file: file,
    //   reject: forAction,
    // );

    widget.onCreate();
  }


  // Helper to check for mobile layout (less than 600px)
  bool _isMobileLayout(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  // --- Web (4-Column) Layout Helper (Existing) ---
  Widget _buildFormRow(List<Widget> children) =>
      Row(children: children.map((child) => Expanded(child: Container(
          margin: const EdgeInsets.only(right: 10),
          child: child))).toList());

  // --- Mobile (2-Column) Layout Helper (NEW) ---
  Widget _buildResponsiveFormRow(List<Widget> children, bool isMobile) {
    if (!isMobile) {
      // Use the original 4-column layout for web/desktop
      return _buildFormRow(children);
    }

    // Use a 2-column layout for mobile (Wrap the children)
    return Wrap(
      spacing: 16.0, // Horizontal space between fields
      runSpacing: 16.0, // Vertical space between rows
      children: children.map((child) => SizedBox(
        width: MediaQuery.of(context).size.width - 25, // Calculate width for roughly two columns minus padding/margin
        child: child,
      )).toList(),
    );
  }
  Map<String, KycDocument> _documents = {
       'product': KycDocument(),   // Add these
  };

  // --- MAIN BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider);
    final isMobile = _isMobileLayout(context);

    final categories = state.categories ?? [];
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

    final row1Fields = [
    _buildBpCodeDropdown(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Product Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.textPrimary)),
          const SizedBox(height: 8),
          CustomInputField(
            labelText: '',
            hintText: 'Enter Product Name',
            controller: _productNameController,
            readOnly: false, ),

        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Product Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.textPrimary)),
          const SizedBox(height: 8),
          CustomInputField(
            labelText: '',
            hintText: 'Enter Product Code',
            controller: _productCodeController,
            readOnly: false,
          ),
        ],
      ),
      _buildProductCategoryDropdown(),
      _buildProductSubCategoryDropdown(),
    ];

    final row2Fields = [
      _buildDropdownField(
        'Type',
        _type,
        ['Piece', 'Pair'],
        (val) => setState(() => _type = val!),
        validator: (v) => (v == null || v.isEmpty) ? 'Type is required' : null,
      ),


      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Length', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.textPrimary)),
          const SizedBox(height: 8),
          CustomInputField(
            labelText: '',
            hintText: 'Enter Length',
            controller: _lengthController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s.-]')),
            ],
            readOnly: false,
          ),
        ],
      ),
      _buildWeightRangeField(),
    ];

    final row3Fields = [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Size', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.textPrimary)),
          const SizedBox(height: 8),
          CustomInputField(
            labelText: '',
            hintText: 'Enter Size',
            controller: _sizeController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s.-]')),
            ],
            readOnly: false,
          ),
        ],
      ),
      // _buildQuantityField(),

    ];

    final row4Fields = [
      if (showOpenClose)
          _buildDropdownField('Open/Close', _openClose, ['Open', 'Close'],
            (val) => setState(() => _openClose = val!)),
      // _buildDropdownField('HUID', _hallmark, ['Yes', 'No'],
      //     (val) => setState(() => _hallmark = val!)),
      if (showRodium)
          _buildDropdownField('Rodium', _rodium, ['Yes', 'No'],
            (val) => setState(() => _rodium = val!)),
    ];

    final row5Fields = [
      if (showHook)
          _buildDropdownField('Hook', _hook, ['Yes', 'No'],
            (val) => setState(() => _hook = val!)),
      if (showStone)
          _buildDropdownField('Stone', _stone, ['No', 'Yes'],
            (val) => setState(() => _stone = val!)),
      if (showEnamel)
          _buildDropdownField('Enamel', _enamel, ['Yes', 'No'],
            (val) => setState(() => _enamel = val!)),
    ];

    // final row6Fields = [
    //   Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       const Text('Note', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.white)),
    //       const SizedBox(height: 8),
    //       CustomInputField(
    //         labelText: '',
    //         hintText: 'Enter Note',
    //         controller: _noteController,
    //         maxLines: 2,
    //       ),
    //     ],
    //   ),
    // ];

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColor.white),
          onPressed: () {
           Get.back();
          },
        ),
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        title: Text(
          ref.watchTr(widget.productId != null ? 'edit_product' : 'create_product'), 
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColor.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(18),
          decoration: isMobile? null: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: AppColor.cardShadow, blurRadius: 8),
            ],
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SizedBox(
                  //   width: isMobile ? double.infinity : MediaQuery.sizeOf(context).width/3,
                  //   child: _buildImageUploadSection(),
                  // ),
                  _imageUploader(),
                  const SizedBox(height: 16),

                  // Responsive Form Rows
                  _buildResponsiveFormRow(row1Fields, isMobile),
                  const SizedBox(height: 24),
                  _buildResponsiveFormRow(row2Fields, isMobile),
                  const SizedBox(height: 24),
                  _buildResponsiveFormRow(row3Fields, isMobile),
                  const SizedBox(height: 24),
                  _buildResponsiveFormRow(row4Fields, isMobile),
                  const SizedBox(height: 24),
                  _buildResponsiveFormRow(row5Fields, isMobile),
                 const SizedBox(height: 24),
                // _buildResponsiveFormRow(row6Fields, isMobile),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [

                      FormFeildCommonButton(
                      text: "Cancel",
                        textColor: CupertinoColors.systemGrey2,
                        onPressed: (){
                        // context.pop();
                      },),

                        const SizedBox(width: 16),

                        FormFeildCommonButton(
                          text:state.isSaving? "Wait...": widget.productId != null ? 'Update' : 'Create',
                          onPressed:state.isSaving ? null : _submit,
                          textColor: AppColor.textWhite,
                          backgroundColor: AppColor.primary,
                        ),
                        const SizedBox(width: 16),

        ],

                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_upload_outlined, color: AppColor.textSecondary, size: 28),
        const SizedBox(height: 6),
        const Text('Click to upload images', style: TextStyle(color: AppColor.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        const Text('Supported: JPG, PNG', style: TextStyle(fontSize: 11, color: AppColor.textSecondary)),
      ],
    );
  }

  Widget _imageUploader() {
    final hasNewImage = _selectedImages.isNotEmpty && _selectedImages.first.bytes != null;
    final imageExists = hasNewImage || (_serverImageUrl != null && _serverImageUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Images',
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
                color: AppColor.border,
              ),
              borderRadius: BorderRadius.circular(8),
              color: AppColor.surface,
            ),
            child: SizedBox(
              height: 120,
              child: _selectedImages.isEmpty && (_serverImageUrl == null || _serverImageUrl!.isEmpty)
                  ? _buildUploadPlaceholder()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length + (_serverImageUrl?.length ?? 0) + 1,
                      itemBuilder: (context, index) {
                        final int serverCount = _serverImageUrl?.length ?? 0;

                        if (index < serverCount) {
                          // Server image
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(_serverImageUrl![index]),
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
                                      if (_serverImageUrl!.isEmpty) _serverImageUrl = null;
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

                        if (index < serverCount + _selectedImages.length) {
                          // Locally picked image
                          final int localIndex = index - serverCount;
                          final file = _selectedImages[localIndex];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: file.bytes != null
                                        ? DecorationImage(
                                            image: MemoryImage(file.bytes!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    color: AppColor.background,
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

                        // Add More button
                        return _buildAddMoreCard();
                      },
                    ),
            ),
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
          border: Border.all(color: AppColor.border, width: 1),
          color: AppColor.background,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColor.textSecondary, size: 24),
            SizedBox(height: 4),
            Text('Add More', style: TextStyle(fontSize: 10, color: AppColor.textSecondary)),
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
          final validFiles = result.where((f) => (f.size / (1024 * 1024)) <= 5).toList();
          _selectedImages.addAll(validFiles);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Widget _buildDropdownField(String label, String? value, List<String> items,
      void Function(String?)? onChanged,
      {String? Function(String?)? validator}) {
    return WorkOrderDropdownWidget<String>(
      label: label,
      fieldKeyName: label.toLowerCase().replaceAll(' ', '_'),
      items: items,
      value: value,
      isSearchable: false, // Standard dropdown functionality
      hintText: 'Select $label',
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quantity',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.textPrimary)),
        const SizedBox(height: 8),
        CustomInputField(
          labelText: '',
          hintText: 'Number',
          controller: _quantityController,
          keyboardType: TextInputType.number,
          readOnly: false,
        ),
      ],
    );
  }

  Widget _buildProductCategoryDropdown() {
    final productState = ref.watch(productListProvider);
    final categories = productState.categories; // Already handles null via state default []

    // Create the display list
    final categoryNames = categories
        .map((cat) => cat.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    categoryNames.insert(0, '+ Add New Category');

    return WorkOrderDropdownWidget<String>(
      label: 'Category',
      fieldKeyName: 'product_category',
      items: categoryNames,
      value: categoryNames.contains(_productCategory) ? _productCategory : null,
      isSearchable: false,
      hintText: 'Select category',
      isLoading: productState.isLoadingCategories,
      validator: (v) => (v == null || v.isEmpty || v == '+ Add New Category') ? 'Category is required' : null,
      onChanged: (v) async {
        final notifier = ref.read(productListProvider.notifier);
        
        // --- 1. HANDLE ADD NEW CATEGORY ---
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
              setState(() {
                _productCategory = saved.name.trim();
                _subCategory = '';
              });
              await notifier.fetchSubCategories(
                url: "api/common/products/subcategories/?category_id=${saved.id}",
              );
            }
          }
          return;
        }

        if (v != null) {
          setState(() {
            _productCategory = v;
            _subCategory = '';
          });

          // Find the ID matching the selected name
          final selectedCat = categories.firstWhere(
                (cat) => cat.name.trim() == v.trim(),
            orElse: () => Category(id: 0, name: ''),
          );

          if (selectedCat.id != 0) {
            // Fetch subcategories for the selected ID
            await notifier.fetchSubCategories(
              url: "api/common/products/subcategories/?category_id=${selectedCat.id}",
            );
          }
        }
      },
    );
  }
  Widget _buildBpCodeDropdown() {
    final partnerState = ref.watch(productListProvider);
    // Safely handle null list
    final partners = role == "craftsman"?
    partnerState.bpCraftsmanList:
    partnerState.bpBuyerList;

    final validPartners = partners.where((bp) => 
      bp.bpCode != null && bp.bpCode!.isNotEmpty &&
      bp.businessName != null && bp.businessName!.isNotEmpty
    ).toList();

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
      isLoading: partnerState.isLoadingBp,
      onChanged: (BpBuyerModel? selectedPartner) {
        if (selectedPartner == null) return;
        setState(() {
          _selectedBpCode = selectedPartner.bpCode!;
        });
      },
    );
  }
  Widget _buildProductSubCategoryDropdown() {
    final productState = ref.watch(productListProvider);
    final allSubCategories = productState.subCategories;

    // 1. Filter subcategories to only show those fetched for the current category
    final subCategoryList = allSubCategories
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
      isSearchable: false,
      isLoading: productState.isLoadingSubCategories,
      hintText: _productCategory.isEmpty
          ? 'Select Category first'
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

            final saved = await ref.read(productListProvider.notifier)
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

  Widget _buildWeightRangeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Weight Range (gm)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.textPrimary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CustomInputField(
                labelText: '',
                hintText: 'From',
                controller: _weightFromController,
                keyboardType: TextInputType.number,
                readOnly: false,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomInputField(
                labelText: '',
                hintText: 'To',
                controller: _weightToController,
                keyboardType: TextInputType.number,
                readOnly: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}