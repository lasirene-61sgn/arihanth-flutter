import 'dart:async';
import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/products/model/bp_buyer_model.dart';
import 'package:arianth/screens/work_orders/ui/widgets/work_order_dropdown_widget.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/pincode_service/pincode_client.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import '../riverpod/user_notifier.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  const UserFormScreen({super.key});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _userId;

  // Controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _aadharController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _pincodeController = TextEditingController();

  String? _selectedBpCode;

  final _pincodeService = PincodeApiService();
  bool _isPincodeLoading = false;
  String? _pincodeError;
  Timer? _pincodeDebounce;

  String? role;

  @override
  void initState() {
    super.initState();

    role = SharedPreferencesHelper().getString("role");

    _pincodeController.addListener(_onPincodeChanged);

    _userId = Get.arguments as String?;

    if (_userId != null) {
      Future.microtask(() async {
        await ref.read(userProvider.notifier).userDetails(_userId!);
        _populateFields();
      });
    }

    Future.microtask(
            () => ref.read(productListProvider.notifier).fetchBPCodes());
  }

  void _populateFields() {
    final detail = ref.read(userProvider).userDetail;
    if (detail != null) {
      setState(() {
        _nameController.text = detail.fullName ?? '';
        _mobileController.text = detail.mobileNo ?? '';
        _emailController.text = detail.email ?? '';
        _dobController.text = detail.dob ?? '';
        _pincodeController.text = detail.pinCode ?? '';
        _cityController.text = detail.city ?? '';
        _stateController.text = detail.state ?? '';
        _countryController.text = detail.country ?? "India";
        _aadharController.text = detail.aadharNumber ?? '';
        _selectedBpCode = detail.bpCode;
      });
    }
  }

  void _onPincodeChanged() {
    final pincode = _pincodeController.text.trim();
    _pincodeDebounce?.cancel();

    _pincodeDebounce = Timer(const Duration(milliseconds: 500), () {
      if (pincode.length == 6) _fetchPincodeDetails(pincode);
    });
  }

  Future<void> _fetchPincodeDetails(String pincode) async {
    setState(() {
      _isPincodeLoading = true;
      _pincodeError = null;
    });

    try {
      final postOffices = await _pincodeService.fetchByPincode(pincode);
      if (postOffices.isNotEmpty) {
        final primary = postOffices.first;
        setState(() {
          _cityController.text = primary.name;
          _stateController.text = primary.stateName;
          _countryController.text = "India";
          _isPincodeLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isPincodeLoading = false;
        _pincodeError = e.toString();
      });
    }
  }

  String? _selectedStatusLabel = "Active";
  int get _statusValue => _selectedStatusLabel == "Active" ? 1 : 0;

  Future<void> _submitForm() async {
    final userState = ref.read(userProvider);
    if (userState.isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedBpCode == null) {
      Toaster.showError("Please select BP Code");
      return;
    }

    final postData = {
      "full_name": _nameController.text.trim(),
      "bp_code": _selectedBpCode,
      "mobile_no": _mobileController.text.trim(),
      "email": _emailController.text.trim(),
      "pincode": _pincodeController.text.trim(),
      "city": _cityController.text.trim(),
      "state": _stateController.text.trim(),
      "country": _countryController.text.trim(),
      "password": _passwordController.text,
      "password_confirmation": _confirmPasswordController.text,
      "aadhar_number": _aadharController.text.trim(),
      "status": _selectedStatusLabel?.toLowerCase(),
    };

    await ref.read(userProvider.notifier).saveUser(
      method: "POST",
      url: _userId == null
          ? "api/common/users"
          : "api/common/users/$_userId",
      postData,
    );

    if (!ref.read(userProvider).isSaving &&
        ref.read(userProvider).error == null) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_userId == null ? "Create User" : "Edit User"),
      ),
      body: userState.isLoading && _userId != null
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _input("Full Name", _nameController, isReq: true),
            _buildBpCodeDropdown(),
            _input("Mobile Number", _mobileController, isReq: true,
                type: TextInputType.phone,inputFormat:[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ]),
            _input("Email", _emailController,
                type: TextInputType.emailAddress),

            _input(
              "Aadhar No",
              _aadharController,
              inputFormat: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              validator: (v) => (v != null &&
                  v.isNotEmpty &&
                  v.length != 12)
                  ? "Must be 12 digits"
                  : null,
            ),

            if (_userId == null) ...[
              _input("Password", _passwordController,
                  isReq: true, obscure: true),
              _input("Confirm Password", _confirmPasswordController,
                  isReq: true, obscure: true),
            ],

            _input("Pin Code", _pincodeController,
                type: TextInputType.number,
                inputFormat: [LengthLimitingTextInputFormatter(6)]),

            _input("City", _cityController),
            _input("State", _stateController, isReq: false),
            _input("Country", _countryController, isReq: false),

            DropdownButtonFormField<String>(
              value: _selectedStatusLabel,
              items: ["Active", "InActive"]
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedStatusLabel = v),
            ),

            const SizedBox(height: 20),

            SafeArea(
              child: CustomButton(
                text: "Submit",
                isLoading: userState.isSaving,
                onPressed: _submitForm,
              ),
            ),
          ],
        ),
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
  Widget _input(String label, TextEditingController controller,
      {bool isReq = false,
        bool obscure = false,
        TextInputType type = TextInputType.text,
        List<TextInputFormatter>? inputFormat,
        String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        inputFormatters: inputFormat,
        decoration: InputDecoration(
          labelText: isReq ? "$label *" : label,
        ),
        validator: (v) {
          if (isReq && (v == null || v.isEmpty)) return "Required";
          if (validator != null) return validator(v);
          return null;
        },
      ),
    );
  }
}