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
  final TextEditingController _orderNumberController = TextEditingController();
  final TextEditingController _referenceNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _itemDeliveredByController = TextEditingController();
  final TextEditingController _itemReceivedByController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedRepairOrSample = 'sample';
  int? _selectedBuyerId;
  String? _selectedBpCode;
  String? _role;
  PlatformFile? _selectedImage;
  String? _serverImageUrl;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _role = SharedPreferencesHelper().getString("role");

    // Set today's date as default
    _selectedDate = DateTime.now();
    _dateController.text = _formatDate(_selectedDate!);

    if (widget.repairId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRepairDetails();
      });
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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
    _itemDeliveredByController.text = repair.itemGivenTo ?? '';
    _itemReceivedByController.text = repair.itemReturnedBy ?? '';
    _selectedBpCode = repair.buyer?.bpCode;
    _selectedBuyerId = repair.buyerId;
    // Support both 'repair_or_sample' and legacy 'repair'
    // Normalise to lowercase to match API values ('sample' / 'repair')
    _selectedRepairOrSample = (repair.repairOrSample ?? repair.repair ?? 'sample').toLowerCase();
    // Support both 'order_number' and legacy 'order_no'
    _orderNumberController.text = repair.orderNumber ?? repair.orderNo ?? '';
    // Support both 'reference_number' and legacy 'ref'
    _referenceNumberController.text = repair.ref ?? '';
    _notesController.text = repair.notes ?? '';
    _serverImageUrl = repair.imageProofUrl;

    // Parse repair date
    final dateStr = repair.repairDate;
    if (dateStr != null && dateStr.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(dateStr);
        _dateController.text = _formatDate(_selectedDate!);
      } catch (_) {
        _dateController.text = dateStr;
      }
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _weightController.dispose();
    _repairDetailsController.dispose();
    _orderNumberController.dispose();
    _referenceNumberController.dispose();
    _notesController.dispose();
    _itemDeliveredByController.dispose();
    _itemReceivedByController.dispose();
    _dateController.dispose();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColor.primary,
              onPrimary: AppColor.white,
              surface: AppColor.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    final Map<String, dynamic> payload = {
      'date': _dateController.text.trim(),
      'product_name': _productNameController.text.trim(),
      'order_number': _orderNumberController.text.trim(),
      'repair_or_sample': _selectedRepairOrSample,
      'weight': _weightController.text.trim(),
      'repair_details': _repairDetailsController.text.trim(),
      'reference_number': _referenceNumberController.text.trim(),
      'notes': _notesController.text.trim(),
      'item_delivered_by': _itemDeliveredByController.text.trim(),
      'item_received_by': _itemReceivedByController.text.trim(),
    };

    // Send buyer_id and bp_code
    if (_selectedBuyerId != null) {
      payload['buyer_id'] = _selectedBuyerId.toString();
    }
    if (_selectedBpCode != null && _selectedBpCode!.isNotEmpty) {
      payload['bp_code'] = _selectedBpCode;
    }

    if (widget.repairId == null) {
      await ref.read(repairListProvider.notifier).createRepair(
        payload,
        imageFile: _selectedImage,
        imageFieldName: 'repair_image',
      );
    } else {
      await ref.read(repairListProvider.notifier).updateRepair(
        widget.repairId!,
        payload,
        imageFile: _selectedImage,
        imageFieldName: 'repair_image',
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
        children: children
            .map((child) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: child,
                  ),
                ))
            .toList(),
      );
    }
    return Column(
      children: children
          .map((child) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: child,
              ))
          .toList(),
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
          isEditing ? 'Edit Sample/Repair' : 'New Sample/Repair',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppColor.white, fontSize: 18),
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColor.primary))
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

                    // Date & Order Number
                    _buildResponsiveFormRow([
                      _buildDateField(),
                      _buildInputField('Order Number', _orderNumberController,
                          hint: 'Enter order number'),
                    ], isMobile),

                    if (!isMobile) const SizedBox(height: 16),

                    // Buyer & Repair or Sample type
                    _buildResponsiveFormRow([
                      _buildBpCodeDropdown(),
                      _buildRepairOrSampleDropdown(),
                    ], isMobile),

                    if (!isMobile) const SizedBox(height: 16),

                    // Product Name & Weight
                    _buildResponsiveFormRow([
                      _buildInputField('Product Name', _productNameController,
                          hint: 'Enter product name'),
                      _buildInputField('Weight (gm)', _weightController,
                          hint: 'Enter weight'),
                    ], isMobile),

                    if (!isMobile) const SizedBox(height: 16),

                    // Repair Details (full width)
                    _buildInputField(
                        'Repair Details', _repairDetailsController,
                        hint: 'Enter repair details', maxLines: 3),
                    const SizedBox(height: 16),

                    // Item Delivered By & Item Received By
                    _buildResponsiveFormRow([
                      _buildInputField(
                          'Item Delivered By', _itemDeliveredByController,
                          hint: 'Enter name'),
                      _buildInputField(
                          'Item Received By', _itemReceivedByController,
                          hint: 'Enter name'),
                    ], isMobile),

                    if (!isMobile) const SizedBox(height: 16),

                    // Reference Number & Notes
                    _buildResponsiveFormRow([
                      _buildInputField(
                          'Reference Number', _referenceNumberController,
                          hint: 'Enter reference number'),
                      _buildInputField('Notes', _notesController,
                          hint: 'Enter notes', maxLines: 2),
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
                          text: state.isLoading
                              ? "Wait..."
                              : (isEditing ? 'Update' : 'Create'),
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

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColor.black)),
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

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColor.black)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: AbsorbPointer(
            child: CustomInputField(
              labelText: '',
              hintText: 'Select date',
              hintStyle: const TextStyle(fontSize: 12, color: AppColor.primary),
              controller: _dateController,
              suffixIcon: const Icon(Icons.calendar_today,
                  size: 18, color: AppColor.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBpCodeDropdown() {
    final productState = ref.watch(productListProvider);
    final partners = _role == "craftsman"
        ? productState.bpCraftsmanList
        : productState.bpBuyerList;

    final validPartners = partners
        .where((bp) =>
            bp.bpCode != null &&
            bp.bpCode!.isNotEmpty &&
            bp.businessName != null &&
            bp.businessName!.isNotEmpty)
        .toList();

    BpBuyerModel? selectedModel;
    if (_selectedBpCode != null && _selectedBpCode!.isNotEmpty) {
      try {
        selectedModel = validPartners.firstWhere(
          (bp) => bp.bpCode == _selectedBpCode,
        );
      } catch (_) {}
    }

    return WorkOrderDropdownWidget<BpBuyerModel>(
      label: 'Customer (Buyer)',
      fieldKeyName: 'buyer_id',
      items: validPartners,
      itemLabel: (bp) => "${bp.bpCode} - ${bp.businessName}",
      selectedItemLabel: (bp) => bp.bpCode ?? '',
      value: selectedModel,
      isSearchable: true,
      hintText: 'Select Buyer',
      onChanged: (BpBuyerModel? selectedPartner) {
        if (selectedPartner == null) return;
        setState(() {
          _selectedBpCode = selectedPartner.bpCode;
          _selectedBuyerId = selectedPartner.id;
        });
      },
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Repair Image',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColor.black)),
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
                        child: Image.memory(_selectedImage!.bytes!,
                            width: 150, height: 150, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImage = null),
                          child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close,
                                  size: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                : _serverImageUrl != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(_serverImageUrl!,
                                width: 150, height: 150, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _serverImageUrl = null),
                              child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close,
                                      size: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: AppColor.textSecondary, size: 32),
                          SizedBox(height: 8),
                          Text('Upload Image',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColor.textSecondary)),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepairOrSampleDropdown() {
    return WorkOrderDropdownWidget<String>(
      label: 'Repair or Sample',
      fieldKeyName: 'repair_or_sample',
      hintText: 'Select Type',
      items: const ['sample', 'repair'],
      value: _selectedRepairOrSample,
      onChanged: (v) => setState(() => _selectedRepairOrSample = v),
    );
  }
}
