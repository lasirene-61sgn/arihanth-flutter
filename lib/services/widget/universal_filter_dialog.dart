import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../screens/products/model/bp_buyer_model.dart';
import '../../screens/products/model/category_model.dart';

enum FilterModule { workOrder, product, design, catalogue, purchaseOrder, repair, buyer, craftsman, keyUser, stockOrder }


class FilterData {
  String code;
  String name;
  String weight;
  String businessName;
  String city;
  String userCode;
  String emailId;
  String mobileNo;
  String fullName;
  BpBuyerModel? selectedBpModel;
  BpBuyerModel? selectedCraftsmanModel;
  String? selectedCategory;
  String? selectedSubcategory;
  DateTime? fromDate;
  DateTime? toDate;

  FilterData({
    this.code = '',
    this.name = '',
    this.weight = '',
    this.businessName = '',
    this.city = '',
    this.userCode = '',
    this.emailId = '',
    this.mobileNo = '',
    this.fullName = '',
    this.selectedBpModel,
    this.selectedCraftsmanModel,
    this.selectedCategory,
    this.selectedSubcategory,
    this.fromDate,
    this.toDate,
  });
}


class UniversalFilterDialog extends ConsumerStatefulWidget {
  final FilterModule module;
  final String? activeStatus; // For Work Orders / POs
  final String? role;
  final Function(String url) onApply;

  const UniversalFilterDialog({
    super.key,
    required this.module,
    this.activeStatus,
    this.role,
    required this.onApply,
  });


  static final Map<FilterModule, FilterData> filterCache = {};

  static void clearCache(FilterModule module) {
    filterCache.remove(module);
  }

  static Future<void> show(
    BuildContext context, 
    WidgetRef ref, {
    required FilterModule module,
    String? activeStatus,
    String? role,
    required Function(String url) onApply,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filter',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        );
      },
      pageBuilder: (context, _, __) => UniversalFilterDialog(
        module: module,
        activeStatus: activeStatus,
        role: role,
        onApply: onApply,
      ),
    );
  }

  @override
  ConsumerState<UniversalFilterDialog> createState() => _UniversalFilterDialogState();
}

class _UniversalFilterDialogState extends ConsumerState<UniversalFilterDialog> {
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _businessNameCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _userCodeCtrl = TextEditingController();
  final TextEditingController _emailIdCtrl = TextEditingController();
  final TextEditingController _mobileNoCtrl = TextEditingController();
  final TextEditingController _fullNameCtrl = TextEditingController();

  BpBuyerModel? _selectedBpModel;
  BpBuyerModel? _selectedCraftsmanModel;
  String? _selectedCategory;
  String? _selectedSubcategory;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void dispose() {
    // Save to cache before disposing
    UniversalFilterDialog.filterCache[widget.module] = FilterData(
      code: _codeCtrl.text,
      name: _nameCtrl.text,
      weight: _weightCtrl.text,
      businessName: _businessNameCtrl.text,
      city: _cityCtrl.text,
      userCode: _userCodeCtrl.text,
      emailId: _emailIdCtrl.text,
      mobileNo: _mobileNoCtrl.text,
      fullName: _fullNameCtrl.text,
      selectedBpModel: _selectedBpModel,
      selectedCraftsmanModel: _selectedCraftsmanModel,
      selectedCategory: _selectedCategory,
      selectedSubcategory: _selectedSubcategory,
      fromDate: _fromDate,
      toDate: _toDate,
    );

    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _businessNameCtrl.dispose();
    _cityCtrl.dispose();
    _userCodeCtrl.dispose();
    _emailIdCtrl.dispose();
    _mobileNoCtrl.dispose();
    _fullNameCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    // Load from cache
    if (UniversalFilterDialog.filterCache.containsKey(widget.module)) {
      final cache = UniversalFilterDialog.filterCache[widget.module]!;
      _codeCtrl.text = cache.code;
      _nameCtrl.text = cache.name;
      _weightCtrl.text = cache.weight;
      _businessNameCtrl.text = cache.businessName;
      _cityCtrl.text = cache.city;
      _userCodeCtrl.text = cache.userCode;
      _emailIdCtrl.text = cache.emailId;
      _mobileNoCtrl.text = cache.mobileNo;
      _fullNameCtrl.text = cache.fullName;
      _selectedBpModel = cache.selectedBpModel;
      _selectedCraftsmanModel = cache.selectedCraftsmanModel;
      _selectedCategory = cache.selectedCategory;
      _selectedSubcategory = cache.selectedSubcategory;
      _fromDate = cache.fromDate;
      _toDate = cache.toDate;
    }

    Future.microtask(() {
      final notifier = ref.read(productListProvider.notifier);
      final state = ref.read(productListProvider);
      
      if (state.categories.isEmpty) notifier.fetchCategories();
      if (state.bpBuyerList.isEmpty) notifier.fetchBPCodes();
      if (state.bpCraftsmanList.isEmpty) notifier.fetchCraftBPCodes();
    });
  }

  void _resetFilters() {
    UniversalFilterDialog.clearCache(widget.module);
    setState(() {
      _codeCtrl.clear();
      _nameCtrl.clear();
      _weightCtrl.clear();
      _businessNameCtrl.clear();
      _cityCtrl.clear();
      _userCodeCtrl.clear();
      _emailIdCtrl.clear();
      _mobileNoCtrl.clear();
      _fullNameCtrl.clear();
      _selectedBpModel = null;
      _selectedCraftsmanModel = null;
      _selectedCategory = null;
      _selectedSubcategory = null;
      _fromDate = null;
      _toDate = null;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final Map<String, String> queryParams = {};
    
    // Module specific base path and params
    String basePath = "";
    switch (widget.module) {
      case FilterModule.workOrder:
        basePath = "api/common/work-orders";
        if (widget.activeStatus != null) {
          final Map<String, String> statusToTab = {
            'All': 'all-orders',
            'New': 'new-orders',
            'Allocated': 'allocated-orders',
            'In Process': 'in-process-orders',
            'For Approval': 'for-approval-orders',
            'Completed': 'completed-orders',
            'Rejected': 'rejected-orders',
            'Overdue': 'overdue-orders',
          };
          queryParams['tab'] = statusToTab[widget.activeStatus] ?? 'all-orders';
        }
        if (_codeCtrl.text.isNotEmpty) queryParams['product_code'] = _codeCtrl.text.trim();
        break;
      case FilterModule.product:
        basePath = "api/common/products";
        if (_codeCtrl.text.isNotEmpty) queryParams['product_code'] = _codeCtrl.text.trim();
        if (_nameCtrl.text.isNotEmpty) queryParams['product_name'] = _nameCtrl.text.trim();
        break;
      case FilterModule.design:
        basePath = "api/common/designs";
        if (widget.role?.toLowerCase() == 'super_admin') {
          // Super admins can filter by any tab
          if (widget.activeStatus != null) {
            final statusToTab = {
              'All': 'all',
              'Pending': 'pending',
              'Accepted': 'accepted',
              'Rejected': 'rejected',
            };
            queryParams['tab'] = statusToTab[widget.activeStatus] ?? 'all';
          }
        } else {
          // All other roles are restricted to accepted designs only
          queryParams['tab'] = 'accepted';
        }
        if (_codeCtrl.text.isNotEmpty) queryParams['design_code'] = _codeCtrl.text.trim();
        if (_nameCtrl.text.isNotEmpty) queryParams['design_name'] = _nameCtrl.text.trim();
        break;
      case FilterModule.catalogue:
        basePath = "api/common/catalogue";
        if (_codeCtrl.text.isNotEmpty) queryParams['product_code'] = _codeCtrl.text.trim();
        break;
      case FilterModule.purchaseOrder:
        basePath = "api/common/purchase-orders";
        if (widget.activeStatus != null) {
          final Map<String, String> statusToTab = {
            'All': 'all',
            'New': 'created',
            'Allocated': 'allocated',
            'In Process': 'in_process',
            'For Approval': 'for_approval',
            'Completed': 'completed',
            'Rejected': 'rejected',
          };
          queryParams['tab'] = statusToTab[widget.activeStatus] ?? 'all';
        }
        if (_codeCtrl.text.isNotEmpty) queryParams['search'] = _codeCtrl.text.trim();
        break;
      case FilterModule.repair:
        basePath = "api/common/repairs";
        if (_codeCtrl.text.isNotEmpty) queryParams['product_code'] = _codeCtrl.text.trim();
        if (_nameCtrl.text.isNotEmpty) queryParams['product_name'] = _nameCtrl.text.trim();
        if (_weightCtrl.text.isNotEmpty) queryParams['weight'] = _weightCtrl.text.trim();
        break;
      case FilterModule.buyer:
        basePath = "api/super-admin/buyers";
        if (_selectedBpModel != null) queryParams['bp_code'] = _selectedBpModel!.bpCode!;
        if (_businessNameCtrl.text.isNotEmpty) queryParams['business_name'] = _businessNameCtrl.text.trim();
        if (_cityCtrl.text.isNotEmpty) queryParams['city'] = _cityCtrl.text.trim();
        break;
      case FilterModule.craftsman:
        basePath = "api/super-admin/craftsmen";
        if (_selectedCraftsmanModel != null) queryParams['craftsman_code'] = _selectedCraftsmanModel!.bpCode!;
        if (_businessNameCtrl.text.isNotEmpty) queryParams['business_name'] = _businessNameCtrl.text.trim();
        if (_cityCtrl.text.isNotEmpty) queryParams['city'] = _cityCtrl.text.trim();
        break;
      case FilterModule.keyUser:
        basePath = "api/common/key-users";
        if (_selectedBpModel != null) queryParams['bp_code'] = _selectedBpModel!.bpCode!;
        if (_userCodeCtrl.text.isNotEmpty) queryParams['user_code'] = _userCodeCtrl.text.trim();
        if (_emailIdCtrl.text.isNotEmpty) queryParams['email_id'] = _emailIdCtrl.text.trim();
        if (_mobileNoCtrl.text.isNotEmpty) queryParams['mobile_no'] = _mobileNoCtrl.text.trim();
        if (_fullNameCtrl.text.isNotEmpty) queryParams['full_name'] = _fullNameCtrl.text.trim();
        break;
      case FilterModule.stockOrder:
        basePath = "api/common/stock-orders";
        if (_codeCtrl.text.isNotEmpty) queryParams['search'] = _codeCtrl.text.trim();
        break;
    }
    // Common query params (only for modules that use them)
    if (widget.module != FilterModule.buyer && 
        widget.module != FilterModule.craftsman && 
        widget.module != FilterModule.keyUser) {
      // For Purchase Orders, we block buyer code but allow craftsman code
      if (widget.module != FilterModule.purchaseOrder) {
        if (_selectedBpModel != null) queryParams['bp_code'] = _selectedBpModel!.bpCode ?? '';
      }
      if (_selectedCraftsmanModel != null) queryParams['craftsman_code'] = _selectedCraftsmanModel!.bpCode ?? '';
    }
    if (_selectedCategory != null) queryParams['category_name'] = _selectedCategory!;
    if (_selectedSubcategory != null) queryParams['subcategory'] = _selectedSubcategory!;
    if (_fromDate != null) queryParams['from_date'] = DateFormat('dd-MM-yyyy').format(_fromDate!);
    if (_toDate != null) queryParams['to_date'] = DateFormat('dd-MM-yyyy').format(_toDate!);

    final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final url = "$basePath${queryString.isNotEmpty ? '?' : ''}$queryString";
    
    widget.onApply(url);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productListProvider);
    final isSuperAdmin = widget.role?.toLowerCase() == 'super_admin';
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: isMobile ? MediaQuery.of(context).size.width * 0.85 : 400,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: AppColor.background,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (isSuperAdmin) ...[
                      if (widget.module != FilterModule.craftsman && widget.module != FilterModule.purchaseOrder) ...[
                        _buildBpDropdown(
                          label: 'Buyer Code',
                          value: _selectedBpModel,
                          items: productState.bpBuyerList,
                          onChanged: (v) => setState(() => _selectedBpModel = v),
                          icon: Icons.business_center_outlined,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (widget.module == FilterModule.workOrder || 
                          widget.module == FilterModule.purchaseOrder ||
                          widget.module == FilterModule.repair ||
                          widget.module == FilterModule.craftsman ||
                          widget.module == FilterModule.catalogue ||  
                          widget.module == FilterModule.product ||
                          widget.module == FilterModule.design ||
                          widget.module == FilterModule.stockOrder) ...[
                        _buildBpDropdown(
                          label: 'Craftsman Code',
                          value: _selectedCraftsmanModel,
                          items: productState.bpCraftsmanList,
                          onChanged: (v) => setState(() => _selectedCraftsmanModel = v),
                          icon: Icons.person_search_outlined,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                   
                    if (widget.module == FilterModule.product || 
                        widget.module == FilterModule.design ||
                        widget.module == FilterModule.repair) ...[
                      _buildTextField(
                        label: widget.module == FilterModule.repair ? 'Product Name' : (widget.module == FilterModule.product ? 'Product Name' : 'Design Name'),
                        controller: _nameCtrl,
                        hint: 'Enter name',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 16),
                    ],
                   
                    if (widget.module != FilterModule.repair && 
                        widget.module != FilterModule.buyer && 
                        widget.module != FilterModule.craftsman && 
                        widget.module != FilterModule.keyUser) ...[
                      _buildTextField(
                        label: _getCodeLabel(),
                        controller: _codeCtrl,
                        hint: 'Enter code',
                        icon: Icons.qr_code_outlined,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (widget.module == FilterModule.buyer || widget.module == FilterModule.craftsman) ...[
                      _buildTextField(
                        label: 'Business Name',
                        controller: _businessNameCtrl,
                        hint: 'Enter business name',
                        icon: Icons.business_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'City',
                        controller: _cityCtrl,
                        hint: 'Enter city',
                        icon: Icons.location_city_outlined,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (widget.module == FilterModule.keyUser) ...[
                      _buildTextField(
                        label: 'Full Name',
                        controller: _fullNameCtrl,
                        hint: 'Enter full name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'User Code',
                        controller: _userCodeCtrl,
                        hint: 'Enter user code',
                        icon: Icons.tag_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Email ID',
                        controller: _emailIdCtrl,
                        hint: 'Enter email',
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Mobile No',
                        controller: _mobileNoCtrl,
                        hint: 'Enter mobile',
                        icon: Icons.phone_android_outlined,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (widget.module == FilterModule.repair) ...[
                      _buildTextField(
                        label: 'Weight',
                        controller: _weightCtrl,
                        hint: 'Enter weight',
                        icon: Icons.scale_outlined,
                      ),
                      const SizedBox(height: 16),
                    ],
                  
                    if (widget.module != FilterModule.repair && 
                        widget.module != FilterModule.buyer && 
                        widget.module != FilterModule.craftsman && 
                        widget.module != FilterModule.keyUser &&
                        widget.module != FilterModule.stockOrder) ...[
                      _buildDropdown(
                        label: 'Category',
                        value: _selectedCategory,
                        items: productState.categories.map((e) => e.name ?? '').toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedCategory = v;
                            _selectedSubcategory = null;
                          });
                          if (v != null) {
                            final selectedCat = productState.categories.firstWhere(
                              (cat) => cat.name.trim() == v.trim(),
                              orElse: () => Category(id: 0, name: ''),
                            );
                            if (selectedCat.id != 0) {
                              ref.read(productListProvider.notifier).fetchSubCategories(
                                url: "api/common/products/subcategories/?category_id=${selectedCat.id}",
                              );
                            }
                          }
                        },
                        icon: Icons.category_outlined,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDropdown(
                        label: 'Subcategory',
                        value: _selectedSubcategory,
                        items: productState.subCategories.map((sc) => sc.name ?? '').toList(),
                        onChanged: (v) => setState(() => _selectedSubcategory = v),
                        icon: Icons.layers_outlined,
                        enabled: _selectedCategory != null && !productState.isLoadingSubCategories,
                        hint: productState.isLoadingSubCategories ? 'Loading...' : 'Select Subcategory',
                      ),
                    ],
                   
                    if ((widget.module == FilterModule.workOrder || 
                         widget.module == FilterModule.purchaseOrder || 
                         widget.module == FilterModule.repair) && 
                         widget.module != FilterModule.repair &&
                         widget.module != FilterModule.buyer &&
                         widget.module != FilterModule.craftsman &&
                         widget.module != FilterModule.keyUser) ...[
                      const SizedBox(height: 24),
                     const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColor.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePicker(
                              label: 'From',
                              value: _fromDate,
                              onPick: (date) => setState(() => _fromDate = date),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDatePicker(
                              label: 'To',
                              value: _toDate,
                              onPick: (date) => setState(() => _toDate = date),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  String _getCodeLabel() {
    switch (widget.module) {
      case FilterModule.workOrder: return 'Product Code';
      case FilterModule.product: return 'Product Code';
      case FilterModule.design: return 'Design Code';
      case FilterModule.catalogue: return 'Product Code';
      case FilterModule.purchaseOrder: return 'Order Number';
      case FilterModule.repair: return 'Repair ID';
      case FilterModule.buyer: return ''; // Should not be reached
      case FilterModule.craftsman: return ''; // Should not be reached
      case FilterModule.keyUser: return ''; // Should not be reached
      case FilterModule.stockOrder: return 'Order Number';
    }
  }

  Widget _buildHeader() {
    String title = "Filter";
    switch (widget.module) {
      case FilterModule.workOrder: title = ref.watchTr('filter_wo'); break;
      case FilterModule.product: title = ref.watchTr('filter_products'); break;
      case FilterModule.design: title = ref.watchTr('filter_designs'); break;
      case FilterModule.catalogue: title = ref.watchTr('filter_designs'); break; // Catalogue uses filter_designs tr
      case FilterModule.purchaseOrder: title = ref.watchTr('filter_po'); break;
      case FilterModule.repair: title = "Filter Repairs"; break; // Fallback if no tr
      case FilterModule.buyer: title = "Filter Buyers"; break;
      case FilterModule.craftsman: title = "Filter Craftsmen"; break;
      case FilterModule.keyUser: title = "Filter Key Users"; break;
      case FilterModule.stockOrder: title = "Filter Stock Orders"; break;
    }
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 15, left: 20, right: 10),
      decoration: BoxDecoration(
        color: AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt_outlined, color: AppColor.primary, size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                   Text(ref.watchTr('narrow_down'), style: const TextStyle(fontSize: 12, color: AppColor.textSecondary)),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required String hint, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColor.textSecondary)),
        const SizedBox(height: 6),
        CustomInputField(
          labelText: null,
          controller: controller,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20, color: AppColor.primary),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    bool enabled = true,
    String? hint,
  }) {
    final uniqueItems = items.where((e) => e.isNotEmpty).toSet().toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: enabled ? AppColor.textSecondary : AppColor.textHint)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: uniqueItems.contains(value) ? value : null,
          items: uniqueItems.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            prefixIcon: Icon(icon, size: 20, color: enabled ? AppColor.primary : AppColor.textHint),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColor.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColor.primary)),
            filled: !enabled,
            fillColor: Colors.grey.shade100,
          ),
          hint: Text(hint ?? 'Select $label', style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  // Dedicated dropdown for BpBuyerModel — shows "code - businessName"
  Widget _buildBpDropdown({
    required String label,
    required BpBuyerModel? value,
    required List<BpBuyerModel> items,
    required ValueChanged<BpBuyerModel?> onChanged,
    required IconData icon,
  }) {
    final uniqueItems = items.where((e) => (e.bpCode ?? '').isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColor.textSecondary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<BpBuyerModel>(
          value: uniqueItems.contains(value) ? value : null,
          isExpanded: true,
          items: uniqueItems.map((e) {
            final displayText = (e.businessName != null && e.businessName!.isNotEmpty)
                ? '${e.bpCode} - ${e.businessName}'
                : (e.bpCode ?? '');
            return DropdownMenuItem<BpBuyerModel>(
              value: e,
              child: Text(displayText, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            prefixIcon: Icon(icon, size: 20, color: AppColor.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColor.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColor.primary)),
          ),
          hint: Text('Select $label', style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildDatePicker({required String label, required DateTime? value, required ValueChanged<DateTime> onPick}) {
    final dateStr = value != null ? DateFormat('dd-MM-yyyy').format(value) : 'dd-mm-yyyy';
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: AppColor.primary),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onPick(picked);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColor.textSecondary)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColor.divider),
              borderRadius: BorderRadius.circular(8),
              color: AppColor.surface,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColor.primary),
                const SizedBox(width: 8),
                Text(dateStr, style: TextStyle(fontSize: 12, color: value != null ? AppColor.textPrimary : AppColor.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 15, 20, MediaQuery.of(context).padding.bottom + 15),
      decoration: BoxDecoration(
        color: AppColor.surface,
        border: Border(top: BorderSide(color: AppColor.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Reset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
