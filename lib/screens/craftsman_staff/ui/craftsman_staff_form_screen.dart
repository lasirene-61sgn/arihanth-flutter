import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/products/model/bp_buyer_model.dart';
import 'package:arianth/screens/work_orders/ui/widgets/work_order_dropdown_widget.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:arianth/services/image_picker/image_picker_helper.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/services/localization/app_localization.dart';
import '../riverpod/craftsman_staff_notifier.dart';

class CraftsmanStaffFormScreen extends ConsumerStatefulWidget {
  const CraftsmanStaffFormScreen({super.key});

  @override
  ConsumerState<CraftsmanStaffFormScreen> createState() => _CraftsmanStaffFormScreenState();
}

class _CraftsmanStaffFormScreenState extends ConsumerState<CraftsmanStaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _craftsman_staffId;

  // Controllers
  final _staffCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _aadharController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int? _selectedCraftsmanId;
  String? _selectedCraftsmanCode;

  String? _selectedStatusLabel = "Active";

  PlatformFile? _profileImage;
  String? _serverProfileImage;
  PlatformFile? _aadharImage;
  String? _serverAadharImage;

  List<String> _selectedPermissions = [];
  final List<String> _allPermissions = [
    "wo_view", "wo_accept", "wo_reject", 
    "po_view", "po_accept", "po_reject", 
    "repair_view", "repair_accept", "repair_reject", 
    "product_view", "product_create", 
    "design_view", "catalogue_view"
  ];

  @override
  void initState() {
    super.initState();
    _craftsman_staffId = Get.arguments as String?;

    if (_craftsman_staffId != null) {
      Future.microtask(() async {
        await ref.read(craftsmanStaffProvider.notifier).craftsman_staffDetails(_craftsman_staffId!);
        _populateFields();
      });
    }

    Future.microtask(() => ref.read(productListProvider.notifier).fetchCraftBPCodes());
  }

  void _populateFields() {
    final detail = ref.read(craftsmanStaffProvider).craftsman_staffDetail;
    if (detail != null) {
      setState(() {
        _staffCodeController.text = detail.staffCode ?? '';
        _nameController.text = detail.name ?? '';
        _mobileController.text = detail.mobileNo ?? '';
        _emailController.text = detail.email ?? '';
        _aadharController.text = detail.aadharNumber ?? '';
        _selectedCraftsmanId = detail.craftsmanId;
        _selectedCraftsmanCode = detail.craftsman?.craftmanCode;
        _selectedStatusLabel = detail.isActive ? "Active" : "InActive";
        _serverProfileImage = detail.image;
        _serverAadharImage = detail.aadharImage;
        _selectedPermissions = List<String>.from(detail.permissions);
        if (detail.passwordPlain != null) {
          _passwordController.text = detail.passwordPlain!;
          _confirmPasswordController.text = detail.passwordPlain!;
        }
      });
    }
  }

  @override
  void dispose() {
    _staffCodeController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _aadharController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final craftsman_staffState = ref.read(craftsmanStaffProvider);
    if (craftsman_staffState.isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCraftsmanId == null) {
      Toaster.showError(ref.read(localeProvider.notifier).translate("Please select Craftsman"));
      return;
    }

    final postData = <String, dynamic>{
      "staff_code": _staffCodeController.text.trim(),
      "name": _nameController.text.trim(),
      "craftsman_id": _selectedCraftsmanCode.toString(),
      "mobile": _mobileController.text.trim(),
      "email": _emailController.text.trim(),
      "aadhar_number": _aadharController.text.trim(),
      "is_active": _selectedStatusLabel == "Active" ? "1" : "0",
    };

    if (_passwordController.text.isNotEmpty) {
      postData["password"] = _passwordController.text;
      postData["password_confirmation"] = _confirmPasswordController.text;
    }

    // for (int i = 0; i < _selectedPermissions.length; i++) {
      postData["permissions"] = _selectedPermissions;
    // }

    final files = <String, dynamic>{};
    if (_profileImage != null) {
      files["image"] = _profileImage;
    }
    if (_aadharImage != null) {
      files["aadhar_image"] = _aadharImage;
    }

    print('----- Submitting Craftsman Staff -----');
    print('Payload: $postData');
    print('Files: ${files.keys.toList()}');
    print('--------------------------------------');

    await ref.read(craftsmanStaffProvider.notifier).saveCraftsmanStaff(
      postData,
      method: "POST", 
      url: _craftsman_staffId == null
          ? "api/common/craftsman-staff"
          : "api/common/craftsman-staff/$_craftsman_staffId",
      files: files.isNotEmpty ? files : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final craftsman_staffState = ref.watch(craftsmanStaffProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_craftsman_staffId == null ? ref.watchTr("Create CraftsmanStaff") : ref.watchTr("Edit CraftsmanStaff")),
      ),
      body:  Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _input(ref.watchTr("Staff Code"), _staffCodeController, isReq: true),
            _input(ref.watchTr("Full Name"), _nameController, isReq: true),
            _buildCraftsmanDropdown(),
            _input(ref.watchTr("Mobile Number"), _mobileController, isReq: true,
                type: TextInputType.phone, inputFormat:[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ]),
            _input(ref.watchTr("Email"), _emailController,
                type: TextInputType.emailAddress),
            _input(
              ref.watchTr("Aadhar No"),
              _aadharController,
              inputFormat: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              validator: (v) => (v != null &&
                  v.isNotEmpty &&
                  v.length != 12)
                  ? ref.watchTr("Must be 12 digits")
                  : null,
            ),
            _input(ref.watchTr("Password"), _passwordController, isReq: _craftsman_staffId == null, obscure: false),
            _input(ref.watchTr("Confirm Password"), _confirmPasswordController, isReq: _craftsman_staffId == null, obscure: false),
            DropdownButtonFormField<String>(
              value: _selectedStatusLabel,
              items: ["Active", "InActive"]
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(ref.watchTr(e)),
              ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedStatusLabel = v),
            ),
            const SizedBox(height: 20),
            _buildFilePicker(ref.watchTr("Profile Image"), _profileImage, (file) { setState(() { if(file==null) _serverProfileImage=null; _profileImage = file; }); }, serverUrl: _serverProfileImage),
            const SizedBox(height: 15),
            _buildFilePicker(ref.watchTr("Aadhar Image"), _aadharImage, (file) { setState(() { if(file==null) _serverAadharImage=null; _aadharImage = file; }); }, serverUrl: _serverAadharImage),
            const SizedBox(height: 20),
            _buildPermissionsSection(),
            const SizedBox(height: 20),
            SafeArea(
              child: CustomButton(
                text: ref.watchTr("Submit"),
                isLoading: craftsman_staffState.isSaving,
                onPressed: _submitForm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker(String label, PlatformFile? currentFile, Function(PlatformFile?) onFileSelected, {String? serverUrl}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.black)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            try {
              final result = await ImagePickerHelper.pickImages(context, allowMultiple: false);
              if (result.isNotEmpty) {
                final file = result.first;
                if ((file.size / (1024 * 1024)) <= 5) {
                  onFileSelected(file);
                } else {
                  Get.snackbar(ref.read(localeProvider.notifier).translate("Error"), ref.read(localeProvider.notifier).translate("Image size should be less than 5MB"));
                }
              }
            } catch (e) {
              Get.snackbar(ref.read(localeProvider.notifier).translate("Error"), "${ref.read(localeProvider.notifier).translate("Error picking image:")} $e");
            }
          },
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: AppColor.border),
              borderRadius: BorderRadius.circular(8),
              color: AppColor.surface,
            ),
            child: currentFile != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (currentFile.bytes != null) ? Image.memory(currentFile.bytes!, width: 150, height: 150, fit: BoxFit.cover) : Container(color: Colors.grey),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => onFileSelected(null),
                          child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                : serverUrl != null && serverUrl.isNotEmpty
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(serverUrl, width: 150, height: 150, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: () => onFileSelected(null),
                              child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined, color: AppColor.textSecondary, size: 32),
                          const SizedBox(height: 8),
                          Text(ref.watchTr('Upload Image'), style: const TextStyle(fontSize: 12, color: AppColor.textSecondary)),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildCraftsmanDropdown() {
    final partnerState = ref.watch(productListProvider);
    // Safely handle null list
    final partners = partnerState.bpCraftsmanList;

    final validPartners = partners.where((bp) =>
    bp.bpCode != null && bp.bpCode!.isNotEmpty &&
        bp.businessName != null && bp.businessName!.isNotEmpty
    ).toList();

    BpBuyerModel? selectedModel;
    if (_selectedCraftsmanCode != null && _selectedCraftsmanCode!.isNotEmpty) {
      selectedModel = validPartners.cast<BpBuyerModel?>().firstWhere(
              (bp) => bp?.bpCode == _selectedCraftsmanCode,
          orElse: () => null
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: WorkOrderDropdownWidget<BpBuyerModel>(
        label: ref.watchTr('Craftsman'),
        fieldKeyName: 'craftsman_id',
        items: validPartners,
        itemLabel: (bp) => "${bp.bpCode} - ${bp.businessName}",
        selectedItemLabel: (bp) => bp.bpCode ?? '',
        value: selectedModel,
        isSearchable: true,
        hintText: ref.watchTr('Select BP Code'),
        onChanged: (BpBuyerModel? selectedPartner) {
          print("hello ${selectedPartner?.bpCode}");

          if (selectedPartner == null) return;
          setState(() {
            _selectedCraftsmanCode = selectedPartner.bpCode!;
            // _selectedCraftsmanId = selectedPartner.id!;
          });
        },
      ),
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
          if (isReq && (v == null || v.isEmpty)) return ref.watchTr("Required");
          if (validator != null) return validator(v);
          return null;
        },
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ref.watchTr("Permissions"), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: _allPermissions.map((perm) {
              bool isSelected = _selectedPermissions.contains(perm);
              return CheckboxListTile(
                title: Text(perm),
                value: isSelected,
                dense: true,
                onChanged: (bool? val) {
                  setState(() {
                    if (val == true) {
                      _selectedPermissions.add(perm);
                    } else {
                      _selectedPermissions.remove(perm);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
