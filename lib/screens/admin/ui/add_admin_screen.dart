import 'dart:async';
import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/services/pincode_service/pincode_client.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:arianth/services/localization/app_localization.dart';
import '../riverpod/admin_notifier.dart';

class AddAdminScreen extends ConsumerStatefulWidget {
  const AddAdminScreen({super.key});

  @override
  ConsumerState<AddAdminScreen> createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends ConsumerState<AddAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _adminId;
  // Controllers
  final _categoryController = TextEditingController();
  final _nameController = TextEditingController();
  final userCode = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _aadharController = TextEditingController();
  final _aadharNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _pincodeController = TextEditingController();

  // Pincode Fetching Logic
  final _pincodeService = PincodeApiService();
  bool _isPincodeLoading = false;
  String? _pincodeError;
  Timer? _pincodeDebounce;

  // Permissions Logic
  final List<String> _availablePermissions = [
    "business_partner",
    "key_user_management",
    "user_management",
    "work_order",
    "purchase_order",
    "product",
    "design",
    "catalogue",
    "kyc_pending",
    "finance",
    "meetings"
  ];
  final List<String> _selectedPermissions = [];

  @override
  void initState() {
    super.initState();
    _pincodeController.addListener(_onPincodeChanged);

    // Get the ID from arguments
    _adminId = Get.arguments as String?;

    if (_adminId != null) {
      // If editing, fetch details and fill controllers
      Future.microtask(() async {
        await ref.read(adminProvider.notifier).adminDetails(_adminId!);
        _populateFields();
      });
    }
  }

  void _populateFields() {
    final detail = ref.read(adminProvider).adminDetail;
    if (detail != null) {
      setState(() {
        _categoryController.text = detail.category ?? '';
        _nameController.text = detail.fullName ?? '';
        userCode.text = detail.userCode ?? '';
        _mobileController.text = detail.mobileNo ?? '';
        _emailController.text = detail.emailId ?? '';
        _dobController.text = detail.dob ?? ''; // Handle format conversion if needed
        _pincodeController.text = detail.pincode ?? '';
        _cityController.text = detail.city ?? '';
        _stateController.text = detail.state ?? '';
        _countryController.text = detail.country ?? '';
        _aadharController.text = detail.aadharNumber ?? '';
        
        // Populate permissions
        _selectedPermissions.clear();
        if (detail.permissions.isNotEmpty) {
          _selectedPermissions.addAll(detail.permissions);
        }
      });
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _pincodeDebounce?.cancel();
    _pincodeController.removeListener(_onPincodeChanged);
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _onPincodeChanged() {
    final pincode = _pincodeController.text.trim();
    _pincodeDebounce?.cancel();
    if (pincode.length < 6 && _pincodeError != null) {
      setState(() => _pincodeError = null);
    }
    _pincodeDebounce = Timer(const Duration(milliseconds: 500), () {
      if (pincode.length == 6) {
        _fetchPincodeDetails(pincode);
      }
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
          _cityController.text = primary.name.isNotEmpty ? primary.name : primary.districtName;
          _stateController.text = primary.stateName;
          _countryController.text = "India";
          _isPincodeLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isPincodeLoading = false;
        _pincodeError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: AppColor.appBarBackground,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(
            Icons.arrow_back,
            color: AppColor.white,
          ),
        ),
        title: Text(
          ref.watchTr(_adminId != null ? 'edit_admin' : 'create_admin'),
          style: const TextStyle(color: AppColor.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            _input("Designation", _categoryController),
            _input("Full Name", _nameController, isReq: true),
            _input("User Code", userCode, isReq: true),
            _input(
              "Mobile Number",
              _mobileController,
              isReq: true,
              type: TextInputType.phone,
              inputFormat: [
                LengthLimitingTextInputFormatter(10),
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return "Mobile number is required";
                }

                if (v.length != 10) {
                  return "Mobile number must be 10 digits";
                }

                return null;
              },
            ),
            _input("Email ID", _emailController, isReq: true, type: TextInputType.emailAddress),

            Row(children: [
              Expanded(child: _input("DOB", _dobController, readOnly: true, onTap: _onDobTap)),
              const SizedBox(width: 10),
              Expanded(child: _input(
                "Aadhar No",
                _aadharController,
                isReq: false,
                inputFormat: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  LengthLimitingTextInputFormatter(12),
                ],
                validator: (v) => (v != null && v.isNotEmpty && v.length != 12) ? "Must be 12 digits" : null,
              )),
            ]),

            if(_adminId == null)_input("Password", _passwordController, isReq: true, ),
            if(_adminId == null)_input("Confirm Password", _confirmPasswordController, isReq: true, ),
            _input("Aadhar Name", _aadharNameController),

            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: CustomInputField(
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                labelText: "Pin Code *",
                maxLength: 6,
                suffixIcon: _buildPincodeSuffix(),
                // validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
              ),
            ),

            Row(children: [
              Expanded(child: _input("City", _cityController)),
              const SizedBox(width: 10),
              Expanded(child: _input("State", _stateController)),
            ]),

            _input("Country", _countryController,),

            const SizedBox(height: 10),
            const Text(
              "Permissions",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColor.textPrimary),
            ),
            const SizedBox(height: 12),

// Grid layout for permissions matching your image's two-column look
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,         // Two columns like the image
                childAspectRatio: 4,      // Adjust height/width ratio of the items
                crossAxisSpacing: 10,
                mainAxisSpacing: 0,
              ),
              itemCount: _availablePermissions.length,
              itemBuilder: (context, index) {
                final perm = _availablePermissions[index];
                final bool isSelected = _selectedPermissions.contains(perm);

                // Formatting: business_partner -> Business partner
                String label = perm.replaceAll('_', ' ');
                label = label[0].toUpperCase() + label.substring(1);

                return InkWell(
                  onTap: () {
                    setState(() {
                      isSelected ? _selectedPermissions.remove(perm) : _selectedPermissions.add(perm);
                    });
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: isSelected,
                              activeColor: AppColor.primary,
                           checkColor: AppColor.textWhite,
                            side: const BorderSide(color: AppColor.black, width: 1.5),
                            onChanged: (val) {
                              setState(() {
                                val! ? _selectedPermissions.add(perm) : _selectedPermissions.remove(perm);
                              });
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 13, color: AppColor.textPrimary),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 40),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: CustomButton(
                  text: _adminId != null ? "UPDATE ADMIN" : "CREATE ADMIN",
                  isLoading: adminState.isSaving, // Shows loading spinner
                  onPressed: adminState.isSaving
                      ? null // Disables click while saving
                      : _submitForm,
                  backgroundColor: adminState.isSaving
                      ? AppColor.silver 
                      : AppColor.primary,
                  textColor: AppColor.textWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPincodeSuffix() {
    if (_isPincodeLoading) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_pincodeError != null) return const Icon(Icons.error_outline, color: AppColor.error, size: 20);
    if (_pincodeController.text.length == 6 && _cityController.text.isNotEmpty) {
      return const Icon(Icons.check_circle, color: AppColor.success, size: 20);
    }
    return const SizedBox.shrink();
  }

  Widget _input(String label, TextEditingController controller, {
    bool isReq = false,
    bool readOnly = false,
    bool obscure = false,
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? inputFormat,
    String? Function(String?)? validator,
    VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: CustomInputField(
        controller: controller,
        readOnly: readOnly,
        obscureText: obscure,
        keyboardType: type,
        onTap: onTap,
        inputFormatters: inputFormat,
        labelText: isReq ? "$label *" : label,
        validator: (v) {
          if (isReq && (v == null || v.isEmpty)) return "Required";
          if (validator != null) return validator(v);
          return null;
        },
      ),
    );
  }

  Future<void> _onDobTap() async {
    final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
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
    if (picked != null) setState(() => _dobController.text = DateFormat('MM/dd/yyyy').format(picked));
  }
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // 1. Prepare the JSON Map
      final Map<String, dynamic> postData = {
        "category": _categoryController.text.trim(),
        "full_name": _nameController.text.trim(),
        "user_code": userCode.text.trim(),
        "bp_code": userCode.text.trim(),
        "mobile_no": _mobileController.text.trim(),
        "email_id": _emailController.text.trim(),
        "dob": _dobController.text.trim(),
        // Ensure format YYYY-MM-DD
        "pincode": _pincodeController.text.trim(),
        "city": _cityController.text.trim(),
        "state": _stateController.text.trim(),
        "country": _countryController.text.trim(),
        "password": _passwordController.text,
        "password_confirmation": _confirmPasswordController.text,
        "aadhar_number": _aadharController.text.trim(),
        "status": 1,
        "profile_picture": null,
        // Document upload removed as requested
        "aadhar_photo": null,
        "permissions": _selectedPermissions,
        // List of strings from the checkboxes
      };
      final String method = _adminId != null ? "POST" : "POST";
      final String url = _adminId != null ? "api/super-admin/admins/$_adminId" : "api/super-admin/admins";
      await ref.read(adminProvider.notifier).saveAdmin(postData, method: method, url: url);
    }
  }
}