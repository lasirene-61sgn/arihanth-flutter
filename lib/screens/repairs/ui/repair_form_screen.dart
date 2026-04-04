import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/products/model/bp_buyer_model.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/screens/repairs/model/repair_model.dart';
import 'package:arianth/screens/repairs/riverpod/repairs_notifier.dart';
import 'package:arianth/screens/work_orders/ui/widgets/work_order_dropdown_widget.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:arianth/services/widget/form_field_common_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arianth/services/image_picker/image_picker_helper.dart';
import 'package:get/get.dart';

class RepairFormScreen extends ConsumerStatefulWidget {
  final String? repairId;
  const RepairFormScreen({Key? key, this.repairId}) : super(key: key);

  @override
  ConsumerState<RepairFormScreen> createState() => _RepairFormScreenState();
}

class _RepairFormScreenState extends ConsumerState<RepairFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repairDetailsController = TextEditingController();
  final TextEditingController _sampleDetailsController = TextEditingController();
  final TextEditingController _itemGivenToController = TextEditingController();
  final TextEditingController _orderNoController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String? _selectedRepairType = 'Sample';
  String? _selectedBpCode;
  String? _role;
  PlatformFile? _selectedImage;
  String? _serverImageUrl;

  @override
  void initState() {
    super.initState();
    _role = SharedPreferencesHelper().getString("role");
    
    if (widget.repairId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRepairDetails();
      });
    }
  }

  Future<void> _loadRepairDetails() async {
    await ref.read(repairListProvider.notifier).fetchRepairDetail(widget.repairId!);
    final state = ref.read(repairListProvider);
    if (state.repairDetail != null) {
      _populateFromRepair(state.repairDetail!);
    }
  }

  void _populateFromRepair(RepairOrder repair) {
    _productNameController.text = repair.productName ?? '';
    _weightController.text = repair.weight ?? '';
    _repairDetailsController.text = repair.repairDetails ?? '';
    _sampleDetailsController.text = repair.sampleDetails ?? '';
    _itemGivenToController.text = repair.itemGivenTo ?? '';
    _selectedBpCode = repair.buyer?.bpCode;
    _selectedRepairType = repair.repair ?? 'Repair';
    _orderNoController.text = repair.orderNo ?? '';
    _refController.text = repair.ref ?? '';
    _notesController.text = repair.notes ?? '';
    _serverImageUrl = repair.imageProofUrl;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _weightController.dispose();
    _repairDetailsController.dispose();
    _sampleDetailsController.dispose();
    _itemGivenToController.dispose();
    _orderNoController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await ImagePickerHelper.pickImages(context, allowMultiple: false);

      if (result.isNotEmpty) {
        final file = result.first;
        if ((file.size / (1024 * 1024)) <= 5) {
          setState(() {
            _selectedImage = file;
          });
        } else {
          Get.snackbar("Error", "Image size should be less than 5MB");
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Error picking image: $e");
    }
  }

  Future<void> _submitForm() async {
    Map<String, dynamic> payload = {
      'product_name': _productNameController.text.trim(),
      'weight': _weightController.text.trim(),
      'repair_details': _repairDetailsController.text.trim(),
      'sample_details': _sampleDetailsController.text.trim(),
      'item_given_to': _itemGivenToController.text.trim(),
      'bp_code': _selectedBpCode ?? '',
      'order_no': _orderNoController.text.trim(),
      'repair': _selectedRepairType,
      'ref': _refController.text.trim(),
      'notes': _notesController.text.trim(),
    };

    if (widget.repairId == null) {
      await ref.read(repairListProvider.notifier).createRepair(
        payload,
        imageFile: _selectedImage,
      );
    } else {
      await ref.read(repairListProvider.notifier).updateRepair(
        widget.repairId!,
        payload,
        imageFile: _selectedImage,
      );
    }
  }

  bool _isMobileLayout(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  Widget _buildResponsiveFormRow(List<Widget> children, bool isMobile) {
    if (!isMobile) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((child) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: child,
          ),
        )).toList(),
      );
    }
    return Column(
      children: children.map((child) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: child,
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repairListProvider);
    final isMobile = _isMobileLayout(context);
    final isEditing = widget.repairId != null;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Sample' : 'New Sample',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColor.white, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColor.white, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: state.isLoading && isEditing && _productNameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildImageSection(),
                    const SizedBox(height: 24),
                    
                    _buildResponsiveFormRow([
                      _buildBpCodeDropdown(),
                      _buildInputField('Product Name', _productNameController, hint: 'Enter product name'),
                    ], isMobile),
                    
                    if (!isMobile) const SizedBox(height: 16),
                    
                    _buildResponsiveFormRow([
                      _buildInputField('Weight (gm)', _weightController, hint: 'Enter weight', keyboardType: TextInputType.number),
                      _buildInputField('Item Given To', _itemGivenToController, hint: 'Enter name'),
                    ], isMobile),

                    if (!isMobile) const SizedBox(height: 16),

                    _buildResponsiveFormRow([
                      _buildInputField('Repair Details', _repairDetailsController, hint: 'Enter repair details', maxLines: 3),
                      _buildInputField('Sample Details', _sampleDetailsController, hint: 'Enter sample details', maxLines: 3),
                    ], isMobile),

                    if (!isMobile) const SizedBox(height: 16),

                    _buildResponsiveFormRow([
                      _buildInputField('Order No', _orderNoController, hint: 'Enter order number'),
                      _buildRepairTypeDropdown(),
                    ], isMobile),

                    if (!isMobile) const SizedBox(height: 16),

                    _buildResponsiveFormRow([
                      _buildInputField('Reference', _refController, hint: 'Enter reference'),
                      if (_role?.toLowerCase() == 'super_admin')
                        _buildInputField('Notes', _notesController, hint: 'Enter notes', maxLines: 2)
                      else
                        const SizedBox.shrink(),
                    ], isMobile),
                    
                    const SizedBox(height: 40),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FormFeildCommonButton(
                          text: "Cancel",
                          textColor: CupertinoColors.systemGrey2,
                          onPressed: () => Get.back(),
                        ),
                        const SizedBox(width: 16),
                        FormFeildCommonButton(
                          text: state.isLoading ? "Wait..." : (isEditing ? 'Update' : 'Create'),
                          onPressed: state.isLoading ? null : _submitForm,
                          textColor: AppColor.textWhite,
                          backgroundColor: AppColor.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? hint, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.black)),
        const SizedBox(height: 8),
        CustomInputField(
          labelText: '',
          hintText: hint ?? 'Enter $label',
          hintStyle: const TextStyle(fontSize: 12, color: AppColor.primary),
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
        ),
      ],
    );
  }

  Widget _buildBpCodeDropdown() {
    final productState = ref.watch(productListProvider);
    // Determine which list to use based on role, matching product_form.dart logic
    final partners = _role == "craftsman" ? productState.bpCraftsmanList : productState.bpBuyerList;

    final validPartners = partners.where((bp) => 
      bp.bpCode != null && bp.bpCode!.isNotEmpty &&
      bp.businessName != null && bp.businessName!.isNotEmpty
    ).toList();

    BpBuyerModel? selectedModel;
    if (_selectedBpCode != null && _selectedBpCode!.isNotEmpty) {
      try {
        selectedModel = validPartners.firstWhere(
          (bp) => bp.bpCode == _selectedBpCode,
        );
      } catch (_) {}
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
      onChanged: (BpBuyerModel? selectedPartner) {
        if (selectedPartner == null) return;
        setState(() {
          _selectedBpCode = selectedPartner.bpCode;
        });
      },
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Image Proof', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.black)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: AppColor.border),
              borderRadius: BorderRadius.circular(8),
              color: AppColor.surface,
            ),
            child: _selectedImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_selectedImage!.bytes!, width: 150, height: 150, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImage = null),
                          child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                : _serverImageUrl != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(_serverImageUrl!, width: 150, height: 150, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _serverImageUrl = null),
                              child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: AppColor.textSecondary, size: 32),
                          SizedBox(height: 8),
                          Text('Upload Image', style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
                        ],
                      ),
          ),
        ),
      ],
    );
  }
  Widget _buildRepairTypeDropdown() {
    return WorkOrderDropdownWidget<String>(
      label: 'Repair Type',
      fieldKeyName: 'repair',
      hintText: 'Select Type',
      items: const ['Sample', 'Repair'],
      value: _selectedRepairType,
      onChanged: (v) => setState(() => _selectedRepairType = v),
    );
  }
}
