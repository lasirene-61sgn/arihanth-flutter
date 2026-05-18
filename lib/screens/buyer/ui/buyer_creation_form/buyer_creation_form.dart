import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/buyer/model/buyer_model.dart';
import 'package:arianth/screens/buyer/riverpod/buyer_notifier.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/pincode_service/pincode_client.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:arianth/services/widget/reusable_file_picker.dart';
import 'package:arianth/services/widget/reusable_full_screen_view.dart' show FileViewerUtil;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:arianth/services/image_picker/image_picker_helper.dart';
// Ensure this import points to where you saved your CustomInputField
// import 'package:arianth/services/widget/custom_input_field.dart';

class BPCreationForm extends ConsumerStatefulWidget {
  const BPCreationForm({super.key});

  @override
  ConsumerState<BPCreationForm> createState() => _BPCreationFormState();
}

class _BPCreationFormState extends ConsumerState<BPCreationForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
   String? id;
  final _pincodeService = PincodeApiService();
  bool _isPincodeLoading = false;
  String? _pincodeError;

// Debounce timer to avoid excessive API calls
  Timer? _pincodeDebounce;
  // --- TAB 1: GENERAL INFO CONTROLLERS ---
  final _businessNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _landlineController = TextEditingController();
  final _emailController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _referredByController = TextEditingController();
  final passWord = TextEditingController();
  final confirmPassWord = TextEditingController();
  final _moreInfoController = TextEditingController();

  // --- TAB 2: ADDRESS CONTROLLERS ---
  final _doorNoController = TextEditingController();
  final _shopNoController = TextEditingController();
  final _complexNameController = TextEditingController();
  final _buildingNameController = TextEditingController();
  final _streetNameController = TextEditingController();
  final _areaController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _mapLocation = TextEditingController();
  final _locationGuideController = TextEditingController();

  // --- TAB 3: KYC CONTROLLERS ---

  final _aadharNoController = TextEditingController();
  final _aadharNameController = TextEditingController();
  final _panNumberController = TextEditingController();
  final _gstNoController = TextEditingController();
  final _bisNoController = TextEditingController();
  final _msmeNoController = TextEditingController();
  final tanNOController = TextEditingController();
  final _cinNoController = TextEditingController();

  // --- TAB 4: BANKING CONTROLLERS ---
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _ifscCodeeController = TextEditingController();
  final _branchController = TextEditingController();
  final bankCity = TextEditingController();
  final bankState = TextEditingController();
  final bankNote = TextEditingController();
  Map<String, KycDocument> _documents = {
    'gst': KycDocument(),
    'brand_img': KycDocument(),
    'pan': KycDocument(),
    'aadhar': KycDocument(),
    'tan': KycDocument(),   // Added
    'msme': KycDocument(),
    'bis': KycDocument(),
    'cin': KycDocument(),   // Added
    'bank_proof': KycDocument(),
    'shop': KycDocument(),
  };

  // permission Tap
  final List<String> _allPermissions =["product","design", "catalogue","work_order", "user_management" , "key_user", "finance", "stock_order", "meetings", "favorites"];
  List<String> _selectedPermissions = [];
  KycDocument _tempBankDoc = KycDocument();
  KycDocument _tempPanDoc = KycDocument();
  KycDocument _tempAadharDoc = KycDocument();

  List<Map<String, dynamic>> bankDetailList = [];
  List<Map<String, dynamic>> aadharDetailList = [];
  List<Map<String, dynamic>> panDetailList = [];
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Add pincode change listener with debounce
    _pincodeController.addListener(_onPincodeChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      id = Get.arguments?.toString();
      if (id != null) {
        _loadBuyerData(int.parse(id!));
      }
    });
  }

// Debounced pincode change handler
  void _onPincodeChanged() {
    final pincode = _pincodeController.text.trim();
    _pincodeDebounce?.cancel();

    // Clear error if user starts typing again
    if (pincode.length < 6 && _pincodeError != null) {
      setState(() => _pincodeError = null);
    }

    _pincodeDebounce = Timer(const Duration(milliseconds: 500), () {
      if (pincode.length == 6) {
        _fetchPincodeDetails(pincode);
      }
    });
  }
  @override
  void dispose() {
    // Clean up
    _pincodeDebounce?.cancel();
    _pincodeController.removeListener(_onPincodeChanged);

    // Dispose all controllers...
    _businessNameController.dispose();
    _contactNameController.dispose();
    // ... (all your other controllers)
    _pincodeController.dispose();
    _tabController.dispose();
    super.dispose();
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

        // --- ADD THE NEW CODE HERE ---
        setState(() {
          // 'primary.name' contains the specific City/Office name (e.g., Chidamabarapuram)
          // 'primary.districtName' contains the District (e.g., Tirunelveli)
          String cityValue = primary.name.isNotEmpty ? primary.name : primary.districtName;

          _cityController.value = TextEditingValue(
            text: cityValue,
            selection: TextSelection.collapsed(offset: cityValue.length),
          );

          _stateController.value = TextEditingValue(
            text: primary.stateName,
            selection: TextSelection.collapsed(offset: primary.stateName.length),
          );

          // Also update the area controller if you have one
          _areaController.value = TextEditingValue(
            text: primary.taluk.isNotEmpty ? primary.taluk : primary.districtName,
            selection: TextSelection.collapsed(offset: (primary.taluk.isNotEmpty ? primary.taluk : primary.districtName).length),
          );

          _isPincodeLoading = false;
        });
        // ------------------------------


      }
    } catch (e) {
      setState(() {
        _isPincodeLoading = false;
        _pincodeError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _loadBuyerData(int id) async {
    // Fetch details from notifier
    await ref.read(buyerListProvider.notifier).fetchBuyerDetail(id);

    // Get the loaded buyer from state
    final buyer = ref.read(buyerListProvider).selectedBuyer;

    if (buyer != null) {
      _populateFields(buyer);
    }
  }
  void _populateFields(Buyer buyer) {
    setState(() {
      // --- TAB 1: BASIC INFO ---
      _businessNameController.text = buyer.businessName ?? '';
      _contactNameController.text = buyer.name ?? '';
      _mobileController.text = buyer.mobile ?? '';
      _emailController.text = buyer.email ?? '';
      _businessEmailController.text = buyer.businessEmail ?? '';
      _referredByController.text = buyer.referedBy ?? '';
      _moreInfoController.text = buyer.more ?? '';

      // --- TAB 2: ADDRESS ---
      _doorNoController.text = buyer.doorNo ?? '';
      _shopNoController.text = buyer.shopNo ?? '';
      _complexNameController.text = buyer.complexName ?? '';
      _buildingNameController.text = buyer.buildingName ?? '';
      _streetNameController.text = buyer.streetName ?? '';
      _areaController.text = buyer.area ?? '';
      _cityController.text = buyer.city ?? '';
      _stateController.text = buyer.state ?? '';
      _pincodeController.text = buyer.pincode ?? '';
      _mapLocation.text = buyer.mapLocation ?? '';
      _locationGuideController.text = buyer.locationGuide ?? '';

      // --- TAB 3: KYC (Primary Documents & Text Fields) ---
      _gstNoController.text = buyer.gstNo ?? '';
      tanNOController.text = buyer.tanNo ?? '';
      _msmeNoController.text = buyer.msmeNo ?? '';
      _bisNoController.text = buyer.bisNo ?? '';
        _cinNoController.text = buyer.cinNo ?? '';
      _documents['brand_logo'] = KycDocument(networkUrl: buyer.brandAttachmentUrl);

      // Populate document map with network URLs for previewing
      _documents['gst'] = KycDocument(networkUrl: buyer.gstAttachmentUrl);
      _documents['tan'] = KycDocument(networkUrl: buyer.tanAttachmentUrl);
      _documents['msme'] = KycDocument(networkUrl: buyer.msmeAttachmentUrl);
      _documents['bis'] = KycDocument(networkUrl: buyer.bisAttachmentUrl);
      // Add these if they exist in your model:
      _documents['cin'] = KycDocument(networkUrl: buyer.cinAttachmentUrl);
      // _documents['shop'] = KycDocument(networkUrl: buyer.shopAttachmentUrl);

      // --- TAB 3: KYC (Multiple Aadhar/PAN Lists) ---
      aadharDetailList = buyer.aadharDetails.map((a) => {
        'id': a.aadharNumber,
        'name': a.aadharName,
        'doc': KycDocument(networkUrl: a.aadharImageUrl),
      }).toList();

      panDetailList = buyer.panDetails.map((p) => {
        'id': p.panNumber,
        'doc': KycDocument(networkUrl: p.panImageUrl),
      }).toList();

      // --- TAB 4: BANKING (List) ---
      // Mapping bank details if your model supports multiple banks
      if (buyer.bankDetails != null) {
        bankDetailList = buyer.bankDetails!.map((b) => {
          'bank': b.bankName,
          'acc': b.accountNo,
          'ifsc': b.ifscCode,
          'holder': b.accountName,
          'branch': b.branch,
          'city': b.bankCity,
          'state': b.bankState,
          'note': b.note,
          'doc': KycDocument(networkUrl: b.passbookUrl),
        }).toList();
      }

      // --- TAB 5: PERMISSIONS ---
      _selectedPermissions = List<String>.from(buyer.permissions);
    });
  }
  void _addBank() {
    if (_bankNameController.text.isNotEmpty && _accountNumberController.text.isNotEmpty) {
      setState(() {
        bankDetailList.add({
          'bank': _bankNameController.text,
          'acc': _accountNumberController.text,
          'ifsc': _ifscCodeeController.text, // Corrected to match your controller
          'holder': _accountHolderNameController.text,
          'branch': _branchController.text,
          'city': bankCity.text,
          'state': bankState.text,
          'note': bankNote.text,
          'doc': _tempBankDoc,
        });

        // Clear all fields after adding
        _bankNameController.clear();
        _accountNumberController.clear();
        _ifscCodeeController.clear();
        _accountHolderNameController.clear();
        _branchController.clear();
        bankCity.clear();
        bankState.clear();
        bankNote.clear();
        _tempBankDoc = KycDocument();
      });
    }
  }

  void _addPan() {
    if (_panNumberController.text.isNotEmpty) {
      setState(() {
        panDetailList.add({
          'id': _panNumberController.text,
          'doc': _tempPanDoc,
        });
        _panNumberController.clear();
        _tempPanDoc = KycDocument(); // Reset for next entry
      });
    }
  }

  void _addAadhar() {
    if (_aadharNoController.text.isNotEmpty) {
      setState(() {
        aadharDetailList.add({
          'id': _aadharNoController.text,
          'name': _aadharNameController.text,
          'doc': _tempAadharDoc,
        });
        _aadharNoController.clear();
        _aadharNameController.clear();
        _tempAadharDoc = KycDocument(); // Reset for next entry
      });
    }
  }
  // Edit Aadhar
  // Optimized Aadhar Edit
  void _editAadhar(int index) {
    // If there's already text in the fields, save it back to the list first
    if (_aadharNoController.text.isNotEmpty) {
      _addAadhar();
    }

    final item = aadharDetailList[index];
    setState(() {
      _aadharNoController.text = item['id'] ?? '';
      _aadharNameController.text = item['name'] ?? '';
      _tempAadharDoc = item['doc'] ?? KycDocument();
      aadharDetailList.removeAt(index);
    });
  }

// Optimized PAN Edit
  void _editPan(int index) {
    if (_panNumberController.text.isNotEmpty) {
      _addPan();
    }

    final item = panDetailList[index];
    setState(() {
      _panNumberController.text = item['id'] ?? '';
      _tempPanDoc = item['doc'] ?? KycDocument();
      panDetailList.removeAt(index);
    });
  }

// Optimized Bank Edit
  void _editBank(int index) {
    if (_bankNameController.text.isNotEmpty) {
      _addBank();
    }

    final item = bankDetailList[index];
    setState(() {
      _bankNameController.text = item['bank'] ?? '';
      _accountNumberController.text = item['acc'] ?? '';
      _ifscCodeeController.text = item['ifsc'] ?? '';
      _accountHolderNameController.text = item['holder'] ?? '';
      _branchController.text = item['branch'] ?? '';
      bankCity.text = item['city'] ?? '';
      bankState.text = item['state'] ?? '';
      bankNote.text = item['note'] ?? '';
      _tempBankDoc = item['doc'] ?? KycDocument();
      bankDetailList.removeAt(index);
    });
  }
  Future<void> _validateAndSubmit() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0); // Go to first tab to fix errors
      return;
    }

    // 2. Custom Validation for Lists (Aadhar & PAN)
    // Aadhar and PAN are now optional as requested.
      // 1. Prepare Basic Text Fields
      Map<String, dynamic> fields = {
        // if (id != null) "_method": "PUT",
        "business_name": _businessNameController.text,
        "name": _contactNameController.text,
        "mobile": _mobileController.text,
        "email": _emailController.text,
        "pincode": _pincodeController.text,
        "city": _cityController.text,
        "state": _stateController.text,
       if(id == null) "password": passWord.text,
        if(id == null)"password_confirmation": confirmPassWord.text,
        "area": _areaController.text,
        "gst_no": _gstNoController.text,
      };

      // 2. Add Permissions as an array
      for (int i = 0; i < _selectedPermissions.length; i++) {
        fields["permissions[$i]"] = _selectedPermissions[i];
      }

      // 3. Add Aadhar Details as arrays using index notation
      for (int i = 0; i < aadharDetailList.length; i++) {
        fields["aadhar_name[$i]"] = aadharDetailList[i]['name'];
        fields["aadhar_number[$i]"] = aadharDetailList[i]['id'];
      }

      // 4. Add PAN Details as arrays
      for (int i = 0; i < panDetailList.length; i++) {
        fields["pan_number[$i]"] = panDetailList[i]['id'];
      }

      // 5. Add Bank Details as arrays
      for (int i = 0; i < bankDetailList.length; i++) {
        fields["bank_name[$i]"] = bankDetailList[i]['bank'];
        fields["account_holder_name[$i]"] = bankDetailList[i]['holder'];
        fields["account_number[$i]"] = bankDetailList[i]['acc'];
        fields["ifsc_code[$i]"] = bankDetailList[i]['ifsc'];
        fields["branch[$i]"] = bankDetailList[i]['branch'];
        fields["bank_city[$i]"] = bankDetailList[i]['city'];
        fields["bank_state[$i]"] = bankDetailList[i]['state'];
        fields["bank_note[$i]"] = bankDetailList[i]['note'];
      }

      // 6. Prepare Files
      Map<String, dynamic> files = {};

    _documents.forEach((key, doc) {
      if (doc.platformFile != null) {
        // Mapping internal map keys to server-side payload keys
        String finalKey;
        switch (key) {
          case 'gst':
            finalKey = 'gst_attachment';
            break;
          case 'brand_img':
            finalKey = 'brand_logo';
            break;
          case 'tan':
            finalKey = 'tan_attachment';
            break;
          case 'msme':
            finalKey = 'msme_attachment';
            break;
          case 'bis':
            finalKey = 'bis_attachment';
            break;
          case 'cin':
            finalKey = 'cin_attachment';
            break;
          default:
            finalKey = key; // Keeps pan, aadhar, shop, etc., as is
        }
        files[finalKey] = doc.platformFile;
      }
    });

      // Indexed files for the lists
      for (int i = 0; i < aadharDetailList.length; i++) {
        if (aadharDetailList[i]['doc'].platformFile != null) {
          files["aadhar_image[$i]"] = aadharDetailList[i]['doc'].platformFile;
        }
      }

      for (int i = 0; i < panDetailList.length; i++) {
        if (panDetailList[i]['doc'].platformFile != null) {
          files["pan_image[$i]"] = panDetailList[i]['doc'].platformFile;
        }
      }

    for (int i = 0; i < bankDetailList.length; i++) {
      if (bankDetailList[i]['doc'].platformFile != null) {
        files["passbook_image[$i]"] = bankDetailList[i]['doc'].platformFile;
      }
    }

      // 7. Call the notifier
      await ref.read(buyerListProvider.notifier).saveBuyer(
        method:id != null ? "POST":"POST" ,
        url: id != null? "api/super-admin/buyers/$id": "api/super-admin/buyers",
        field: fields,
        files: files,
      );


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: GestureDetector(
          onTap: (){
            Get.back();
          },
            child: const Icon(Icons.arrow_back, color: AppColor.white)),
        title: const Text("Buyer Creation", style: TextStyle(color: AppColor.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: EdgeInsets.zero,
          indicatorColor: AppColor.primary,
          labelColor: AppColor.white,
          unselectedLabelColor: AppColor.black,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Basic Info"),
            Tab(text: "Address"),
            Tab(text: "KYC"),
            Tab(text: "Bank"),
            Tab(text: "Permissions"),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGeneralTab(),
                    _buildAddressTab(),
                    _buildKycTab(),
                    _buildBankTab(),
                    _buildPermissionsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // permission tap
  Widget _buildPermissionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Access Control",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.primary),
          ),
        ),
        const Text(
          "Select the screens this Buyer is allowed to access.",
          style: TextStyle(fontSize: 13, color: AppColor.textSecondary),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColor.border),
          ),
          child: Column(
            children: _allPermissions.map((perm) {
              bool isSelected = _selectedPermissions.contains(perm);
              return Column(
                children: [
                  SwitchListTile(
                    activeColor: AppColor.primary,
                    activeTrackColor: AppColor.primary.withOpacity(0.3),
                    title: Text(
                      ref.watchTr(perm).toUpperCase(), // Use translated string
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.textPrimary),
                    ),
                    value: isSelected,
                    onChanged: (bool value) {
                      setState(() {
                        if (value) {
                          _selectedPermissions.add(perm);
                        } else {
                          _selectedPermissions.remove(perm);
                        }
                      });
                    },
                  ),
                  if (perm != _allPermissions.last) const Divider(height: 1),
                ],
              );
            }).toList(),

          ),
        ),

        _buildStickyFooter(),
      ],
    );
  }
  // --- TAB BUILDERS (UI REMAINS THE SAME) ---

  Widget _buildGeneralTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _input("Business Name", _businessNameController, isReq: true),
        _input("Contact person Name", _contactNameController,isReq: true),
        _input(
          "Mobile No",
          _mobileController,
          isReq: true,
          type: TextInputType.phone,
          inputFormat: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        _input("LandLine/Centrex Number", _landlineController,  type: TextInputType.phone),
        _input("Email", _emailController, type: TextInputType.emailAddress,isReq: true),
        _input("Business Email", _businessEmailController),
        _input("Referred By", _referredByController),
        _input("PassWord", passWord,isReq: true),
        _input("Confirm PassWord", confirmPassWord,isReq: true),
        _input("Additional Info", _moreInfoController, type: TextInputType.multiline),
      ],
    );
  }

  Widget _buildAddressTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(child: _input("Door Number", _doorNoController)),
          const SizedBox(width: 10),
          Expanded(child: _input("Shop Number", _shopNoController)),
        ]),
        _input("Complex Name", _complexNameController),
        _input("Building Name", _buildingNameController),
        _input("Street Name", _streetNameController),
        _input("Area", _areaController),
        Row(
          children: [
            Expanded(
              child: CustomInputField(
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                labelText: "Pincode",
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                // maxLength: 6,
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (!RegExp(r'^\d{6}$').hasMatch(v)) return "Enter valid 6-digit pincode";
                  return null;
                },
                suffixIcon: _buildPincodeSuffix(),
                // ❌ REMOVE THIS onChanged - we already have debounced listener!
                // onChanged: (value) {
                //   if (value.length == 6) {
                //     _fetchPincodeDetails(value);
                //   }
                // },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomInputField(
                controller: _cityController,
                labelText: "District/City *",
              ),
            ),
          ],
        ),// Keep as editable fallback
        SizedBox(height: 10,),
        _input("State", _stateController),
        _input("Map Location", _mapLocation),
        _input("Location", _locationGuideController),
      ],
    );
  }
  Widget _buildPincodeSuffix() {
    if (_isPincodeLoading) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_pincodeError != null) {
      return const Icon(Icons.error_outline, color: Colors.red, size: 20);
    }

    // Only show checkmark if it's exactly 6 digits and we have data
    if (_pincodeController.text.length == 6 && _cityController.text.isNotEmpty) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }

    return const SizedBox.shrink();
  }
  Widget _buildKycTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _uploadTile("Brand Image (KYC First) *", "brand_img"),
        const Divider(height: 32),
        // --- Aadhar Section ---
        Row(
          children: [
            const Text("Aadhar Details", style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.textPrimary)),
          ],
        ),
        const SizedBox(height: 8),
        _input("Aadhar No", _aadharNoController,inputFormat: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          LengthLimitingTextInputFormatter(12),
        ]), // Removed isReq: true
        _input("Aadhar Name", _aadharNameController), // Removed isReq: true
        _uploadTile("Upload Aadhar", "temp_aadhar", customDoc: _tempAadharDoc),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _addAadhar,
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Add Aadhar"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        ...aadharDetailList.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          return _buildCardItem(
              "Aadhar: ${item['id']}",
              item['doc'],
                  () => setState(() => aadharDetailList.removeAt(idx)),
                  () => _editAadhar(idx) // <--- Add this
          );
        }),

        const Divider(height: 32),

        // --- PAN Section ---
        Row(
          children: [
            const Text("PAN Details", style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.textPrimary)),
          ],
        ),
        const SizedBox(height: 8),
        _input(
          "PAN No",
          _panNumberController,
          type: TextInputType.text,
          inputFormat: [
            LengthLimitingTextInputFormatter(10),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            UpperCaseTextFormatter(),
          ],
          validator: (v) {
            if (v != null && v.isNotEmpty && v.length != 10) {
              return "Must be 10 characters";
            }
            return null;
          },
        ),
// Removed isReq: true
        _uploadTile("Upload PAN Card", "temp_pan", customDoc: _tempPanDoc),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _addPan,
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Add PAN"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        ...panDetailList.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          return _buildCardItem(
              "PAN: ${item['id']}",
              item['doc'],
                  () => setState(() => panDetailList.removeAt(idx)),
                  () => _editPan(idx) // <--- Add this
          );
        }),
        const Divider(height: 32),

        // --- Other Primary Documents ---
        const SizedBox(height: 16),
        _input(
          "GST No ",
          _gstNoController,
          isReq: true,
          type: TextInputType.text,
          inputFormat: [
            LengthLimitingTextInputFormatter(15),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            UpperCaseTextFormatter(),
          ],
          validator: (v) {
            if (v == null || v.isEmpty) {
              return "GST No is required";
            }

            final gstRegex = RegExp(
              r'^[0-3][0-9][A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
            );

            if (!gstRegex.hasMatch(v)) {
              return "Enter valid GST number";
            }

            return null;
          },
        ),
        _uploadTile("GST Document", "gst"),
        _input("TAN Number", tanNOController),
        _uploadTile("Upload TAN Document", "tan"),
        _input("MSME No", _msmeNoController),
        _uploadTile("MSME Certificate", "msme"),
        _input("BIS No", _bisNoController),
        _uploadTile("BIS Document", "bis"),
        _input("CIN No", _cinNoController),
        _uploadTile("CIN Document", "cin"),
      ],
    );
  }

  Widget _buildCardItem(String title, KycDocument doc, VoidCallback onDelete, VoidCallback onEdit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.border),
      ),
      child: ListTile(
        leading: _buildFilePreview(doc),
        title: Text(title, style: const TextStyle(fontSize: 14, color: AppColor.textPrimary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // EDIT BUTTON
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColor.primary, size: 20),
              onPressed: onEdit,
            ),
            // DELETE BUTTON
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
  // --- TAB 3: KYC (Updated with Lists) ---
  Widget _buildBankTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Bank Identity ---
        _input("Bank Name", _bankNameController),
        _input("Account Number", _accountNumberController, type: TextInputType.number),
        _input("Account Holder Name", _accountHolderNameController),

        // --- Branch & Security ---
        Row(
          children: [
            Expanded(child: _input("IFSC Code", _ifscCodeeController)), // Note: using your variable _ifscCodeeController
            const SizedBox(width: 10),
            Expanded(child: _input("Branch", _branchController)),
          ],
        ),

        // --- Location ---
        Row(
          children: [
            Expanded(child: _input("Bank City", bankCity)),
            const SizedBox(width: 10),
            Expanded(child: _input("Bank State", bankState)),
          ],
        ),

        // --- Notes & Verification ---
        _input("Bank Note", bankNote, type: TextInputType.multiline),

        // --- Proof Upload ---
        _uploadTile("Bank Proof (Passbook/Cheque)", "temp_bank", customDoc: _tempBankDoc),

        const SizedBox(height: 10),

        // --- Action Button ---
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _addBank,
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Add Bank to List"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: AppColor.textWhite,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),

        const Divider(height: 40),

        // Inside your ListView/Tab
        ...bankDetailList.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          return _buildCardItem(
            "${item['bank']} (${item['acc']})",
            item['doc'],
                () => setState(() => bankDetailList.removeAt(idx)), // Delete only
                () => _editBank(idx), // Edit logic
          );
        }),
        ],

    );
  }


  Widget _input(String label, TextEditingController controller, {
    bool isReq = false,
    List<TextInputFormatter>? inputFormat,
    String? Function(String?)? validator,
    TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16), // Slightly increased padding for the shadow
      child: CustomInputField(
        controller: controller,
        keyboardType: type,
        inputFormatters: inputFormat,
        labelText: isReq ? "$label *" : label,
        maxLines: type == TextInputType.multiline ? 3 : 1,
        validator: (v) {
          if (isReq && (v == null || v.isEmpty)) return "Required";
          if (validator != null) return validator(v);
          return null;
        },
      ),
    );
  }

  Widget _uploadTile(String title, String docKey, {KycDocument? customDoc}) {
    final doc = customDoc ?? _documents[docKey];
    final bool hasFile = doc != null && (!doc.isEmpty || doc.networkUrl != null);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: hasFile ? Colors.green.withOpacity(0.1) : AppColor.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasFile ? Colors.green.withOpacity(0.3) : AppColor.border,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: _buildFilePreview(doc!),
        title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
        subtitle: hasFile
            ? Text(
          doc.fileName ?? (doc.networkUrl != null ? "View Online" : "File attached"),
          style: const TextStyle(fontSize: 10, color: Colors.green),
        )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasFile)
              IconButton(
                onPressed: () => FileViewerUtil.showFullScreenImage(context, doc, title),
                icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
              ),
              Text(
                hasFile ? "Change" : "Upload",
                style: const TextStyle(
                  color: AppColor.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        onTap: () => _pickFile(docKey),
      ),
    );
  }
  // 🔹 Helper to wrap image previews in a rounded box
  Widget _imageBox(Widget child) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColor.border),
        color: AppColor.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }

// 🔹 Helper to show a PDF icon when a PDF is selected
  Widget _pdfPreview() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.red.shade50,
      ),
      child: const Icon(Icons.picture_as_pdf, size: 24, color: Colors.red),
    );
  }

  Widget _emptyPreview() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.border),
        borderRadius: BorderRadius.circular(8),
        color: AppColor.surface,
      ),
      child: const Icon(Icons.insert_drive_file, size: 28, color: AppColor.textSecondary),
    );
  }
  Widget _buildFilePreview(KycDocument doc) {
    if (doc.isEmpty && doc.networkUrl == null) {
      return _emptyPreview();
    }

    // Get extension from platformFile or networkUrl
    String ext = doc.platformFile?.extension?.toLowerCase() ??
        doc.networkUrl?.split('.').last.toLowerCase() ?? "";

    if (ext == "pdf") return _pdfPreview();

    // Web Preview
    if (kIsWeb && doc.bytes != null) {
      return _imageBox(Image.memory(
        doc.bytes!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ));
    }

    // Mobile/Desktop Preview
    if (!kIsWeb && doc.file != null && doc.file!.existsSync()) {
      return _imageBox(Image.file(
        doc.file!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ));
    }

    // Network URL Preview
    if (doc.networkUrl != null && doc.networkUrl!.isNotEmpty) {
      return _imageBox(Image.network(
        doc.networkUrl!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _emptyPreview(),
      ));
    }

    return _emptyPreview();
  }

  Widget _buildStickyFooter() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: CustomButton(
          text: id != null ? "UPDATE" : "BP CREATION",
          isLoading: ref.watch(buyerListProvider).isSaving,
          iconData: Icons.check_circle,
          iconRight: true,
          backgroundColor: AppColor.primary,
          textColor: AppColor.textWhite,
          onPressed: ref.watch(buyerListProvider).isSaving ? null : _validateAndSubmit,
        ),
      ),
    );
  }
  // Inside _BPCreationFormState


// Reusable File Picker
  Future<void> _pickFile(String docKey) async {
    final result = await ImagePickerHelper.pickImages(context, allowMultiple: false);

    if (result.isNotEmpty) {
      _handlePickedFile(docKey, result.first);
    }
  }

// Reusable File Handler
  void _handlePickedFile(String docKey, PlatformFile? platformFile) {
    setState(() {
      // 1. Determine which document object we are actually updating
      KycDocument? doc;

      if (docKey == 'temp_bank') {
        doc = _tempBankDoc;
      } else if (docKey == 'temp_pan') {
        doc = _tempPanDoc;
      } else if (docKey == 'temp_aadhar') {
        doc = _tempAadharDoc;
      } else {
        doc = _documents[docKey];
      }

      // 2. Safety check: if doc is still null, initialize it in the map
      if (doc == null) {
        _documents[docKey] = KycDocument();
        doc = _documents[docKey];
      }

      // 3. Handle the null case for platformFile (if user canceled)
      if (platformFile == null) {
        doc!.networkUrl = doc.networkUrl; // keep existing or reset
        return;
      }

      // 4. Update the document properties
      doc!.networkUrl = null;
      doc.platformFile = platformFile;

      if (kIsWeb) {
        doc.bytes = platformFile.bytes;
        doc.file = null;
      } else {
        if (platformFile.path != null) {
          final file = File(platformFile.path!);
          if (file.existsSync()) {
            doc.file = file;
            doc.bytes = null;
          }
        }
      }
    });
  }
}
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}