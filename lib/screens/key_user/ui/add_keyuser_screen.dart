import 'dart:async';
import 'dart:io';
import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/business_partner_list/riverpod/business_partner_list_notifier.dart';
import 'package:arianth/screens/dashboard_screen/riverpod/dashboard_notifier.dart';
import 'package:arianth/screens/products/model/bp_buyer_model.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/screens/work_orders/ui/widgets/work_order_dropdown_widget.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/pincode_service/pincode_client.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:arianth/services/widget/form_field_common_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/image_picker/image_picker_helper.dart';
import '../riverpod/key_user_notifier.dart';

class KeyUserDocument {
  final Uint8List? bytes;
  final File? file;
  final String? networkUrl;
  KeyUserDocument({this.bytes, this.file, this.networkUrl});
}

class KeyUserFormScreen extends ConsumerStatefulWidget {
  final String? id; // "Edit" or "View"
  const KeyUserFormScreen({super.key, this.id});

  @override
  ConsumerState<KeyUserFormScreen> createState() => _KeyUserFormScreenState();
}

class _KeyUserFormScreenState extends ConsumerState<KeyUserFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _aadharController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _dobController = TextEditingController();
  String? role;
  // Address & Status Logic
  final _pincodeService = PincodeApiService();
  bool _isPincodeLoading = false;
  Timer? _pincodeDebounce;
  String _selectedStatusLabel = "Active";
  final List<String> _statusOptions = ["Active", "Inactive"];

  // Image & Selection State
  DateTime? _selectedDate;
  PlatformFile? _aadharFile;
  PlatformFile? _photoFile;
  String? _aadharUrl;
  String? _photoUrl;
  String? _selectedBpCode;
  bool _readOnly = false;

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role");
    _pincodeController.addListener(_onPincodeChanged);
    Future.microtask(() {
      if (widget.id != null) _fillForm(widget.id);
    });
  }

  @override
  void dispose() {
    _pincodeDebounce?.cancel();
    _pincodeController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _aadharController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _onPincodeChanged() {
    if (_pincodeController.text.length == 6) {
      _pincodeDebounce?.cancel();
      _pincodeDebounce = Timer(const Duration(milliseconds: 500), () => _fetchPincode(_pincodeController.text));
    }
  }

  Future<void> _fetchPincode(String pin) async {
    setState(() => _isPincodeLoading = true);
    try {
      final res = await _pincodeService.fetchByPincode(pin);
      if (res.isNotEmpty) {
        setState(() {
          _cityController.text = res.first.name;
          _stateController.text = res.first.stateName;
          _countryController.text = "India";
        });
      }
    } finally {
      setState(() => _isPincodeLoading = false);
    }
  }
  void _fillForm(String? id) async{
    await ref.read(keyUserProvider.notifier).keyUserDetails(id.toString());
    final data = ref.read(keyUserProvider).keyUserDetail;

    // Safety check: Don't try to fill if data is null
    if (data == null) return;

    // 2. Populate the form
    setState(() {
      // Text Fields
      _nameController.text = data.fullName ?? '';
      _mobileController.text = data.mobileNo ?? '';
      _emailController.text = data.emailId ?? '';
      _aadharController.text = data.aadharNumber ?? '';
      _pincodeController.text = data.pinCode ?? ''; // Matches 'pinCode' from your model
      _cityController.text = data.city ?? '';
      _stateController.text = data.state ?? '';
      _countryController.text = data.country ?? 'India';

      // Dropdowns
      _selectedBpCode = data.bpCode;

      // Status handling
      if (data.status != null && data.status!.toString().isNotEmpty) {
        final s = data.status!.toString().toLowerCase();
        if (s == "1" || s == "active" || s == "true") {
          _selectedStatusLabel = "Active";
        } else {
          _selectedStatusLabel = "Inactive";
        }
      }

      // Network Images
      _aadharUrl = data.aadharPhoto;
      _photoUrl = data.profilePicture;

      // Date parsing for DOB
      if (data.dob != null && data.dob!.isNotEmpty) {
        _selectedDate = DateTime.tryParse(data.dob!);
        if (_selectedDate != null) {
          _dobController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final bool isEdit = widget.id != null;

    // 1. Prepare the standard text payload
    final Map<String, dynamic> payload = {
      if (_selectedBpCode != null) "bp_code": _selectedBpCode,
      "full_name": _nameController.text.trim(),
      "email_id": _emailController.text.trim(),
      "mobile_no": _mobileController.text.trim(),
      "aadhar_number": _aadharController.text.trim(),
      "pincode": _pincodeController.text.trim(),
      "city": _cityController.text.trim(),
      "state": _stateController.text.trim(),
      "country": _countryController.text.trim(),
      "status": _selectedStatusLabel == "Active" ? 1 : 0,
    };

    if (_selectedDate != null) {
      payload["dob"] = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }

    // Only send the password if the user actually typed one
    // (Crucial for Edit mode so you don't overwrite their existing password with blanks)
    if (_passwordController.text.isNotEmpty) {
      payload["password"] = _passwordController.text;
      payload["password_confirmation"] = _passwordController.text;
    }

    // 2. Prepare the Files map (Just like product_form.dart)
    final Map<String, dynamic> files = {};
    if (_photoFile != null) {
      files["profile_picture"] = _photoFile;
    }
    if (_aadharFile != null) {
      files["aadhar_photo"] = _aadharFile;
    }

    // 3. Determine URL & Method
    // Note: When sending files (multipart/form-data) to update an existing record in Laravel/PHP APIs,
    // you typically must send a POST request with an injected `_method: PUT` parameter.
    final String endpoint = isEdit
        ? "api/common/key-users/${widget.id}"
        : "api/common/key-users";

    if (isEdit) {
      payload["_method"] = "POST"; // Force Laravel to treat this POST as a PUT
    }

    // 4. Call the Notifier
    await ref.read(keyUserProvider.notifier).saveKeyUser(
      "POST", // Always use POST when uploading files via multipart
      files,
      payload,
      id: isEdit ? widget.id : null,
      url: endpoint,
    );

    // 5. Refresh lists and navigate back
    ref.read(keyUserProvider.notifier).fetchKeyUsers(); // Refresh the table
    ref.read(dashboardProvider.notifier).fetchDashBoard(); // Refresh dashboard counts
// Close the form screen
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(keyUserProvider);
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColor.primary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColor.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          ref.watchTr(widget.id == null ? "add_key_user" : "edit_key_user"),
          style: const TextStyle(
            color: AppColor.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildBpCodeDropdown(),
              const SizedBox(height: 15),
              _input("Full Name *", _nameController, isReq: true),
              _input("Email *", _emailController, isReq: true),
              Row(children: [
                Expanded(
                  child: _input(
                    "Mobile *",
                    _mobileController,
                    isReq: true,
                    inputFormat: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')), // Blocks spaces, letters, and symbols
                      LengthLimitingTextInputFormatter(10), // Stops the user from typing more than 10 digits
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Expanded(child: _datePicker()),
              ]),
              Row(children: [
                Expanded(child: _input("Aadhar", _aadharController, isReq: false,
                  inputFormat: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    LengthLimitingTextInputFormatter(12),
                  ],
                )),
                const SizedBox(width: 10),
                if(widget.id == null)Expanded(child: _input("Password *", _passwordController, isReq: true )),
              ]),
              _input("Pincode", _pincodeController,
                  isReq: false, suffix: _isPincodeLoading ? const CircularProgressIndicator() : null,
                inputFormat: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              Row(children: [
                Expanded(child: _input("City", _cityController, isReq: false)),
                const SizedBox(width: 10),
                Expanded(child: _input("State", _stateController, isReq: false)),
              ]),
              _input("Country", _countryController),

              _buildStatusDropdown(),
              const SizedBox(height: 10),

              _buildImageSection("Aadhar Photo", isAadhar: true),
              _buildImageSection("Profile Photo", isAadhar: false),

              const SizedBox(height: 30),
              if (!_readOnly) SafeArea(
                child: FormFeildCommonButton(
                  text: state.isSaving ? "Saving..." : "Submit",
                  onPressed: state.isSaving ? null : _submit,
                  backgroundColor: AppColor.primary,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets ---
  Widget _input(String label, TextEditingController controller, {int? length, bool isReq = false, Widget? suffix,List<TextInputFormatter>? inputFormat}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomInputField(
        inputFormatters: inputFormat,
        controller: controller, labelText: label, maxLength: length, readOnly: _readOnly,
        suffixIcon: suffix,
        validator: (v) => (isReq && (v == null || v.isEmpty)) ? "Required" : null,
      ),
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
      onChanged: (BpBuyerModel? selectedPartner) {
        if (selectedPartner == null) return;
        setState(() {
          _selectedBpCode = selectedPartner.bpCode!;
        });
      },
    );
  }

  Widget _datePicker() {
    return CustomInputField(
      labelText: "DOB",
      readOnly: true,
      controller: _dobController,
      onTap: _readOnly ? null : () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColor.primary,
                  onPrimary: AppColor.textWhite,
                  surface: AppColor.background,
                  onSurface: AppColor.textPrimary,
                ),
                dialogBackgroundColor: AppColor.background,
              ),
              child: child!,
            );
          },
        );
        if (d != null) {
          setState(() {
            _selectedDate = d;
            _dobController.text = DateFormat('yyyy-MM-dd').format(d);
          });
        }
      },
    );
  }

  Widget _buildImageSection(String label, {required bool isAadhar}) {
    final hasImg = isAadhar ? (_aadharFile != null || _aadharUrl != null) : (_photoFile != null || _photoUrl != null);
    return ListTile(
      title: Text(label, style: const TextStyle(color: AppColor.textPrimary, fontSize: 12)),
      trailing: IconButton(icon: Icon(hasImg ? Icons.check_circle : Icons.upload, color: AppColor.primary), onPressed: () => _pickFile(isAadhar)),
    );
  }

  Widget _buildStatusDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _selectedStatusLabel,
        dropdownColor: AppColor.surface,
        items: _statusOptions.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: const TextStyle(color: AppColor.textPrimary)),
          );
        }).toList(),
        onChanged: _readOnly ? null : (v) {
          if (v != null) setState(() => _selectedStatusLabel = v);
        },
        decoration: const InputDecoration(
          labelText: "Status *",
          labelStyle: TextStyle(color: AppColor.textPrimary),
        ),
      ),
    );
  }

  Future<void> _pickFile(bool isAadhar) async {
    final result = await ImagePickerHelper.pickImages(context, allowMultiple: false);
    if (result.isNotEmpty) {
      setState(() {
        if (isAadhar) {
          _aadharFile = result.first;
          _aadharUrl = null;
        } else {
          _photoFile = result.first;
          _photoUrl = null;
        }
      });
    }
  }
}