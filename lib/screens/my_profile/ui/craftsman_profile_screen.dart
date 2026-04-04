import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/my_profile/model/craftsman_profile_model.dart';
import 'package:arianth/screens/my_profile/riverpod/craftsman_profile_notifier.dart';
import 'package:arianth/services/image_picker/image_picker_helper.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:arianth/services/widget/reusable_file_picker.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/widget/reusable_full_screen_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

class CraftsmanProfileScreen extends ConsumerStatefulWidget {
  const CraftsmanProfileScreen({super.key});

  @override
  ConsumerState<CraftsmanProfileScreen> createState() => _CraftsmanProfileScreenState();
}

class _CraftsmanProfileScreenState extends ConsumerState<CraftsmanProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _businessNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _landlineController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _referredByController = TextEditingController();
  final _moreInfoController = TextEditingController();

  final _doorNoController = TextEditingController();
  final _shopNoController = TextEditingController();
  final _complexNameController = TextEditingController();
  final _buildingNameController = TextEditingController();
  final _streetNameController = TextEditingController();
  final _areaController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _mapLocationController = TextEditingController();
  final _locationGuideController = TextEditingController();

  final _gstNoController = TextEditingController();
  final _aadharNoController = TextEditingController();
  final _aadharNameController = TextEditingController();
  final _panNumberController = TextEditingController();
  final _tanNOController = TextEditingController();
  final _msmeNoController = TextEditingController();
  final _bisNoController = TextEditingController();
  final _cinNoController = TextEditingController();

  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _branchController = TextEditingController();
  final _bankCity = TextEditingController();
  final _bankState = TextEditingController();
  final _bankNote = TextEditingController();

  final _workerNameController = TextEditingController();
  final _workerNumberController = TextEditingController();

  // Documents & Lists
  Map<String, KycDocument> _documents = {
    'gst': KycDocument(),
    'tan': KycDocument(),
    'msme': KycDocument(),
    'bis': KycDocument(),
    'cin': KycDocument(),
    'brand_img': KycDocument(),
    'shop': KycDocument(),
  };

  KycDocument _tempAadharDoc = KycDocument();
  KycDocument _tempPanDoc = KycDocument();
  KycDocument _tempBankDoc = KycDocument();
  KycDocument _tempWorkerDoc = KycDocument();

  List<Map<String, dynamic>> aadharDetailList = [];
  List<Map<String, dynamic>> panDetailList = [];
  List<Map<String, dynamic>> bankDetailList = [];
  List<Map<String, dynamic>> workerDetailList = [];

  bool _isInitialized = false;
  bool _fieldsPopulated = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _isInitialized = true;
    Future.microtask(() => ref.read(craftsmanProfileNotifierProvider.notifier).fetchProfile());
  }

  void _populateFields(CraftsmanProfileModel profile) {
    if (_fieldsPopulated) return;
    _fieldsPopulated = true;
    _gstNoController.text = profile.gstNo ?? '';
    _tanNOController.text = profile.tanNo ?? '';
    _msmeNoController.text = profile.msmeNo ?? '';
    _bisNoController.text = profile.bisNo ?? '';

    _businessNameController.text = profile.businessName ?? '';
    _contactNameController.text = profile.name ?? '';
    _emailController.text = profile.email ?? '';
    _mobileController.text = profile.mobile ?? '';
    _landlineController.text = profile.landline ?? '';
    _businessEmailController.text = profile.businessEmail ?? '';
    _referredByController.text = profile.referedBy ?? '';
    _moreInfoController.text = profile.moreInfo ?? '';

    _doorNoController.text = profile.doorNo ?? '';
    _shopNoController.text = profile.shopNo ?? '';
    _complexNameController.text = profile.complexName ?? '';
    _buildingNameController.text = profile.buildingName ?? '';
    _streetNameController.text = profile.streetName ?? '';
    _areaController.text = profile.area ?? '';
    _pincodeController.text = profile.pincode ?? '';
    _cityController.text = profile.city ?? '';
    _stateController.text = profile.state ?? '';
    _mapLocationController.text = profile.mapLocation ?? '';
    _locationGuideController.text = profile.locationGuide ?? '';

    _documents['gst'] = KycDocument(networkUrl: profile.gstAttachment);
    _documents['tan'] = KycDocument(networkUrl: profile.tanAttachment);
    _documents['msme'] = KycDocument(networkUrl: profile.msmeAttachment);
    _documents['bis'] = KycDocument(networkUrl: profile.bisAttachment);
    _documents['brand_img'] = KycDocument(networkUrl: profile.brandLogo);
    _documents['shop'] = KycDocument(networkUrl: profile.shopAttachment);

    aadharDetailList = profile.aadharDetails.map((a) => {
      'id': a.id, 'name': a.aadharName ?? '', 'number': a.aadharNumber ?? '', 'doc': KycDocument(networkUrl: a.aadharImageUrl),
    }).toList();

    panDetailList = profile.panDetails.map((p) => {
      'id': p.id, 'number': p.panNumber ?? '', 'doc': KycDocument(networkUrl: p.panImageUrl),
    }).toList();

    bankDetailList = profile.bankDetails.map((b) => {
      'id': b.id, 'bank_name': b.bankName ?? '', 'account_no': b.accountNo ?? '', 'ifsc_code': b.ifscCode ?? '',
      'account_name': b.accountName ?? '', 'branch': b.branch ?? '', 'bank_city': b.bankCity ?? '', 'bank_state': b.bankState ?? '',
      'doc': KycDocument(networkUrl: b.passbookUrl),
    }).toList();

    workerDetailList = profile.workers.map((w) => {
      'id': w.id, 'name': w.workerName ?? '', 'number': w.workerNumber ?? '', 'doc': KycDocument(networkUrl: w.workerImageUrl),
    }).toList();
  }

  @override
  void dispose() {
    if (_isInitialized) _tabController.dispose();
    _gstNoController.dispose(); _aadharNoController.dispose(); _aadharNameController.dispose(); _panNumberController.dispose();
    _tanNOController.dispose(); _msmeNoController.dispose(); _bisNoController.dispose(); _cinNoController.dispose();
    _bankNameController.dispose(); _accountNumberController.dispose(); _accountHolderNameController.dispose();
    _ifscCodeController.dispose(); _branchController.dispose(); _bankCity.dispose(); _bankState.dispose(); _bankNote.dispose();
    _workerNameController.dispose(); _workerNumberController.dispose(); _businessNameController.dispose(); _contactNameController.dispose();
    _mobileController.dispose(); _emailController.dispose(); _landlineController.dispose(); _businessEmailController.dispose();
    _referredByController.dispose(); _moreInfoController.dispose(); _doorNoController.dispose(); _shopNoController.dispose();
    _complexNameController.dispose(); _buildingNameController.dispose(); _streetNameController.dispose(); _areaController.dispose();
    _pincodeController.dispose(); _cityController.dispose(); _stateController.dispose(); _mapLocationController.dispose(); _locationGuideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(craftsmanProfileNotifierProvider);
    final profile = profileState.profile;

    if (profileState.isLoading && profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (profile != null) _populateFields(profile);

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.appBarBackground, elevation: 0,
        title: Text(ref.watchTr('my_profile'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: _isEditMode 
            ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => setState(() => _isEditMode = false))
            : IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () => Scaffold.of(context).openDrawer()),
        bottom: profile == null || !_isEditMode ? null : TabBar(
          controller: _tabController, isScrollable: true, tabAlignment: TabAlignment.start, indicatorColor: AppColor.primary,
          labelColor: AppColor.white, unselectedLabelColor: AppColor.black,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [ Tab(text: "General"), Tab(text: "Address"), Tab(text: "KYC"), Tab(text: "Bank"), Tab(text: "Images"), Tab(text: "Worker Details") ],
        ),
      ),
      body: profile == null 
        ? Center(child: Text(profileState.error ?? "Failed to load profile"))
        : !_isEditMode 
            ? _buildProfileSummary(profile)
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(child: TabBarView(controller: _tabController, children: [ _buildGeneralTab(), _buildAddressTab(), _buildKycTab(), _buildBankTab(), _buildImagesTab(), _buildWorkerTab() ])),
                    if (profile.isFrozen != 1) _buildSubmitButton(),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileSummary(CraftsmanProfileModel profile) {
    String profileImageUrl = profile.aadharDetails.isNotEmpty ? (profile.aadharDetails.first.aadharImageUrl ?? '') : '';
    if (profileImageUrl.isNotEmpty && !profileImageUrl.startsWith('http')) profileImageUrl = ApiClient.baseUrl + profileImageUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Center(child: CircleAvatar(radius: 60, backgroundColor: AppColor.surface, backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null, child: profileImageUrl.isEmpty ? const Icon(Icons.person, size: 60, color: AppColor.textHint) : null)),
          const SizedBox(height: 20),
          Text(profile.businessName ?? "Business Name", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColor.textPrimary)),
          Text(profile.craftmanCode ?? "", style: const TextStyle(color: AppColor.textSecondary, fontSize: 16)),
          const SizedBox(height: 30),
          _summaryItem(Icons.person, "Owner/Contact", profile.name ?? "N/A"), _summaryItem(Icons.phone, "Mobile", profile.mobile ?? "N/A"), _summaryItem(Icons.email, "Email", profile.email ?? "N/A"),
          _summaryItem(Icons.location_on, "Address", "${profile.city ?? ""}, ${profile.state ?? ""}".trim().replaceAll(RegExp(r'^, |, $'), '')),
          const SizedBox(height: 40),
          if (profile.kycStatus == "approved") _frozenInfo(),
          if (profile.kycStatus == "pending") CustomButton(text: "EDIT PROFILE", onPressed: () => setState(() => _isEditMode = true), backgroundColor: AppColor.primary, textColor: AppColor.textWhite),
        ],
      ),
    );
  }

  Widget _frozenInfo() { return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[200]!)), child: const Row(children: [ Icon(Icons.error_outline, color: Colors.red), SizedBox(width: 10), Expanded(child: Text("Your account is currently frozen. Please contact administration for any updates.", style: TextStyle(color: Colors.red))) ])); }
  Widget _summaryItem(IconData icon, String label, String value) { return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [ Icon(icon, color: AppColor.primary, size: 20), const SizedBox(width: 15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)), Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)) ]) ])); }

  Widget _buildSubmitButton() {
    final profileState = ref.watch(craftsmanProfileNotifierProvider);
    return SafeArea(child: Padding(padding: const EdgeInsets.all(16.0), child: CustomButton(text: "UPDATE PROFILE", isLoading: profileState.isSaving, onPressed: _validateAndSubmit, backgroundColor: AppColor.primary, textColor: AppColor.textWhite)));
  }

  Future<void> _validateAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    Map<String, dynamic> fields = { "business_name": _businessNameController.text, "name": _contactNameController.text, "email": _emailController.text, "mobile": _mobileController.text, "landline": _landlineController.text, "business_email": _businessEmailController.text, "refered_by": _referredByController.text, "more": _moreInfoController.text, "door_no": _doorNoController.text, "shop_no": _shopNoController.text, "complex_name": _complexNameController.text, "building_name": _buildingNameController.text, "street_name": _streetNameController.text, "area": _areaController.text, "pincode": _pincodeController.text, "city": _cityController.text, "state": _stateController.text, "map_location": _mapLocationController.text, "location_guide": _locationGuideController.text, "gst_no": _gstNoController.text, "tan_no": _tanNOController.text, "msme_no": _msmeNoController.text, "bis_no": _bisNoController.text, "cin_no": _cinNoController.text, "pan_no": _panNumberController.text, "bank_name": _bankNameController.text, "account_holder_name": _accountHolderNameController.text, "account_number": _accountNumberController.text, "ifsc_code": _ifscCodeController.text, "branch": _branchController.text, "bank_city": _bankCity.text, "bank_state": _bankState.text, "note": _bankNote.text };
    for (int i = 0; i < aadharDetailList.length; i++) { fields["aadhar_id[$i]"] = aadharDetailList[i]['id']; fields["aadhar_name[$i]"] = aadharDetailList[i]['name']; fields["aadhar_number[$i]"] = aadharDetailList[i]['number']; }
    for (int i = 0; i < panDetailList.length; i++) { fields["pan_id[$i]"] = panDetailList[i]['id']; fields["pan_number[$i]"] = panDetailList[i]['number']; }
    for (int i = 0; i < bankDetailList.length; i++) { fields["bank_id[$i]"] = bankDetailList[i]['id']; fields["bank_name[$i]"] = bankDetailList[i]['bank_name']; fields["account_number[$i]"] = bankDetailList[i]['account_no']; fields["ifsc_code[$i]"] = bankDetailList[i]['ifsc_code']; fields["account_holder_name[$i]"] = bankDetailList[i]['account_name']; fields["branch[$i]"] = bankDetailList[i]['branch']; fields["bank_city[$i]"] = bankDetailList[i]['bank_city']; fields["bank_state[$i]"] = bankDetailList[i]['bank_state']; }
    for (int i = 0; i < workerDetailList.length; i++) { fields["worker_id[$i]"] = workerDetailList[i]['id']; fields["worker_name[$i]"] = workerDetailList[i]['name']; fields["worker_number[$i]"] = workerDetailList[i]['number']; }

    Map<String, dynamic> files = {};
    _documents.forEach((key, doc) { if (doc.platformFile != null) { String finalKey = key; if (key == 'gst') finalKey = 'gst_attachment'; else if (key == 'tan') finalKey = 'tan_attachment'; else if (key == 'msme') finalKey = 'msme_attachment'; else if (key == 'bis') finalKey = 'bis_attachment'; else if (key == 'brand_img') finalKey = 'brand_logo'; files[finalKey] = doc.platformFile; } });
    for (int i = 0; i < aadharDetailList.length; i++) if (aadharDetailList[i]['doc'].platformFile != null) files["aadhar_image[$i]"] = aadharDetailList[i]['doc'].platformFile;
    for (int i = 0; i < panDetailList.length; i++) if (panDetailList[i]['doc'].platformFile != null) files["pan_image[$i]"] = panDetailList[i]['doc'].platformFile;
    for (int i = 0; i < bankDetailList.length; i++) if (bankDetailList[i]['doc'].platformFile != null) files["passbook_image[$i]"] = bankDetailList[i]['doc'].platformFile;
    for (int i = 0; i < workerDetailList.length; i++) if (workerDetailList[i]['doc'].platformFile != null) files["worker_image[$i]"] = workerDetailList[i]['doc'].platformFile;

    final success = await ref.read(craftsmanProfileNotifierProvider.notifier).updateProfile(fields: fields, files: files);
    if (success) setState(() => _isEditMode = false);
  }

  Widget _buildGeneralTab() { return ListView(padding: const EdgeInsets.all(16), children: [ _input("Business Name", _businessNameController, readOnly: true), _input("Contact Name", _contactNameController, readOnly: true), _input("Email", _emailController, readOnly: true), _input("Mobile", _mobileController, readOnly: true), _input("Landline", _landlineController), _input("Business Email", _businessEmailController), _input("Referred By", _referredByController), _input("More Info", _moreInfoController) ]); }
  Widget _buildAddressTab() { return ListView(padding: const EdgeInsets.all(16), children: [ _input("Door No", _doorNoController), _input("Shop No", _shopNoController), _input("Complex Name", _complexNameController), _input("Building Name", _buildingNameController), _input("Street Name", _streetNameController), _input("Area", _areaController), _input("Pincode", _pincodeController), _input("City", _cityController), _input("State", _stateController), _input("Map Location", _mapLocationController), _input("Location Guide", _locationGuideController) ]); }
  Widget _buildKycTab() { return ListView(padding: const EdgeInsets.all(16), children: [ _sectionHeader("GST Details"), _input("GST No (Read Only)", _gstNoController, readOnly: true), _uploadTile("GST Attachment", "gst"), const Divider(height: 32), _sectionHeader("Aadhar Details"), _input("Aadhar No", _aadharNoController), _input("Aadhar Name", _aadharNameController), _uploadTile("Upload Aadhar", "temp_aadhar", customDoc: _tempAadharDoc), Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _addAadhar, icon: const Icon(Icons.add), label: const Text("Add Aadhar"))), ...aadharDetailList.asMap().entries.map((e) => _buildCardItem("${e.value['name']} - ${e.value['number']}", e.value['doc'], () => setState(() => aadharDetailList.removeAt(e.key)))), const Divider(height: 32), _sectionHeader("PAN Details"), _input("PAN No", _panNumberController), _uploadTile("Upload PAN", "temp_pan", customDoc: _tempPanDoc), Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _addPan, icon: const Icon(Icons.add), label: const Text("Add PAN"))), ...panDetailList.asMap().entries.map((e) => _buildCardItem("PAN: ${e.value['number']}", e.value['doc'], () => setState(() => panDetailList.removeAt(e.key)))), const Divider(height: 32), _sectionHeader("Other Documents"), _input("TAN No", _tanNOController), _uploadTile("TAN Attachment", "tan"), const Divider(height: 32), _input("MSME No", _msmeNoController), _uploadTile("MSME Attachment", "msme"), const Divider(height: 32), _input("BIS No", _bisNoController), _uploadTile("BIS Attachment", "bis") ]); }
  Widget _buildBankTab() { return ListView(padding: const EdgeInsets.all(16), children: [ _sectionHeader("Banking Details"), _input("Bank Name", _bankNameController), _input("Account Number", _accountNumberController), _input("IFSC Code", _ifscCodeController), _input("Account Holder", _accountHolderNameController), _input("Branch", _branchController), _input("City", _bankCity), _input("State", _bankState), _uploadTile("Upload Bank Proof", "temp_bank", customDoc: _tempBankDoc), Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _addBank, icon: const Icon(Icons.add), label: const Text("Add Bank"))), ...bankDetailList.asMap().entries.map((e) => _buildCardItem("${e.value['bank_name']} - ${e.value['account_no']}", e.value['doc'], () => setState(() => bankDetailList.removeAt(e.key)))) ]); }
  Widget _buildWorkerTab() { return ListView(padding: const EdgeInsets.all(16), children: [ _input("Worker Name", _workerNameController), _input("Worker Number", _workerNumberController), _uploadTile("Worker Image", "temp_worker", customDoc: _tempWorkerDoc), Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _addWorker, icon: const Icon(Icons.add), label: const Text("Add Worker"))), ...workerDetailList.asMap().entries.map((e) => _buildCardItem("${e.value['name']} - ${e.value['number']}", e.value['doc'], () => setState(() => workerDetailList.removeAt(e.key)))) ]); }
  Widget _buildImagesTab() { return ListView(padding: const EdgeInsets.all(16), children: [ _uploadTile("Brand Logo/Image", "brand_img") ]); }

  Widget _input(String label, TextEditingController controller, {bool readOnly = false}) { return Padding(padding: const EdgeInsets.only(bottom: 12), child: CustomInputField(labelText: label, controller: controller, readOnly: readOnly, decoration: InputDecoration(labelText: label, filled: readOnly, fillColor: readOnly ? Colors.grey[200] : null, border: const OutlineInputBorder()))); }
  Widget _uploadTile(String title, String docKey, {KycDocument? customDoc}) { final doc = customDoc ?? _documents[docKey]; return ListTile(contentPadding: EdgeInsets.zero, title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)), subtitle: doc?.platformFile != null ? Text(doc!.platformFile!.name, style: const TextStyle(fontSize: 11)) : null, leading: _buildFilePreview(doc!), trailing: Row(mainAxisSize: MainAxisSize.min, children: [if (doc.networkUrl != null || doc.platformFile != null) IconButton(icon: const Icon(Icons.visibility, color: AppColor.primary), onPressed: () => FileViewerUtil.showFullScreenImage(context, doc, title)), IconButton(icon: const Icon(Icons.cloud_upload_outlined, color: AppColor.primary), onPressed: () => _pickFile(docKey))])); }
  Widget _buildFilePreview(KycDocument doc) { if (doc.isEmpty && doc.networkUrl == null) return _emptyPreview(); String ext = doc.platformFile?.extension?.toLowerCase() ?? doc.networkUrl?.split('.').last.toLowerCase() ?? ""; if (ext == "pdf") return _pdfPreview(); if (kIsWeb && doc.platformFile?.bytes != null) return _imageBox(Image.memory(doc.platformFile!.bytes!, width: 40, height: 40, fit: BoxFit.cover)); if (!kIsWeb && doc.platformFile?.path != null && File(doc.platformFile!.path!).existsSync()) return _imageBox(Image.file(File(doc.platformFile!.path!), width: 40, height: 40, fit: BoxFit.cover)); if (doc.networkUrl != null && doc.networkUrl!.isNotEmpty) { String fullUrl = doc.networkUrl!; if (!fullUrl.startsWith('http')) fullUrl = ApiClient.baseUrl + fullUrl; return _imageBox(Image.network(fullUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c, e, s) => _emptyPreview())); } return _emptyPreview(); }
  Widget _emptyPreview() { return Container(width: 40, height: 40, decoration: BoxDecoration(border: Border.all(color: AppColor.border), borderRadius: BorderRadius.circular(8), color: AppColor.surface), child: const Icon(Icons.insert_drive_file, size: 28, color: AppColor.textSecondary)); }
  Widget _pdfPreview() { return Container(width: 40, height: 40, decoration: BoxDecoration(border: Border.all(color: AppColor.border), borderRadius: BorderRadius.circular(8), color: Colors.red[50]), child: const Icon(Icons.picture_as_pdf, size: 24, color: Colors.red)); }
  Widget _imageBox(Widget child) { return Container(width: 40, height: 40, decoration: BoxDecoration(border: Border.all(color: AppColor.border), borderRadius: BorderRadius.circular(8)), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child)); }
  Widget _sectionHeader(String title) { return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColor.primary))); }
  Widget _buildCardItem(String title, KycDocument doc, VoidCallback onDelete) { return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(title: Text(title, style: const TextStyle(fontSize: 12)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.visibility, size: 18), onPressed: () => FileViewerUtil.showFullScreenImage(context, doc, title)), IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: onDelete)]))); }

  Future<void> _pickFile(String docKey) async {
    final result = await ImagePickerHelper.pickImages(context, allowMultiple: false);
    if (result.isNotEmpty) {
      setState(() {
        if (docKey == 'temp_aadhar') { _tempAadharDoc.networkUrl = null; _tempAadharDoc.platformFile = result.first; }
        else if (docKey == 'temp_pan') { _tempPanDoc.networkUrl = null; _tempPanDoc.platformFile = result.first; }
        else if (docKey == 'temp_bank') { _tempBankDoc.networkUrl = null; _tempBankDoc.platformFile = result.first; }
        else if (docKey == 'temp_worker') { _tempWorkerDoc.networkUrl = null; _tempWorkerDoc.platformFile = result.first; }
        else { KycDocument doc = _documents[docKey] ??= KycDocument(); doc.networkUrl = null; doc.platformFile = result.first; }
      });
    }
  }

  void _addAadhar() { if (_aadharNoController.text.isNotEmpty) { setState(() { aadharDetailList.add({'id': null, 'name': _aadharNameController.text, 'number': _aadharNoController.text, 'doc': _tempAadharDoc}); _aadharNoController.clear(); _aadharNameController.clear(); _tempAadharDoc = KycDocument(); }); } }
  void _addPan() { if (_panNumberController.text.isNotEmpty) { setState(() { panDetailList.add({'id': null, 'number': _panNumberController.text, 'doc': _tempPanDoc}); _panNumberController.clear(); _tempPanDoc = KycDocument(); }); } }
  void _addBank() { if (_accountNumberController.text.isNotEmpty) { setState(() { bankDetailList.add({'id': null, 'bank_name': _bankNameController.text, 'account_no': _accountNumberController.text, 'ifsc_code': _ifscCodeController.text, 'account_name': _accountHolderNameController.text, 'branch': _branchController.text, 'bank_city': _bankCity.text, 'bank_state': _bankState.text, 'doc': _tempBankDoc}); _bankNameController.clear(); _accountNumberController.clear(); _ifscCodeController.clear(); _accountHolderNameController.clear(); _branchController.clear(); _bankCity.clear(); _bankState.clear(); _tempBankDoc = KycDocument(); }); } }
  void _addWorker() { if (_workerNameController.text.isNotEmpty) { setState(() { workerDetailList.add({'id': null, 'name': _workerNameController.text, 'number': _workerNumberController.text, 'doc': _tempWorkerDoc}); _workerNameController.clear(); _workerNumberController.clear(); _tempWorkerDoc = KycDocument(); }); } }
}
