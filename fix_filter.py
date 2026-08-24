import re

with open("lib/services/widget/universal_filter_dialog.dart", "r") as f:
    content = f.read()

# 1. Add FilterData class and static cache to UniversalFilterDialog
filter_data_class = """
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
"""

content = content.replace("enum FilterModule { workOrder, product, design, catalogue, purchaseOrder, repair, buyer, craftsman, keyUser, stockOrder }",
                          "enum FilterModule { workOrder, product, design, catalogue, purchaseOrder, repair, buyer, craftsman, keyUser, stockOrder }\n\n" + filter_data_class)

static_cache_code = """
  static final Map<FilterModule, FilterData> filterCache = {};

  static void clearCache(FilterModule module) {
    filterCache.remove(module);
  }
"""
content = content.replace("  static Future<void> show(", static_cache_code + "\n  static Future<void> show(")

# 2. Update initState to load from cache
init_state_start = "  void initState() {"
init_state_end = "    });\n  }"
new_init_state = """  void initState() {
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
  }"""
content = re.sub(r'  void initState\(\) \{[\s\S]*?    \}\);\n  \}', new_init_state, content)

# 3. Update dispose to save to cache
new_dispose = """  void dispose() {
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
  }"""
content = re.sub(r'  void dispose\(\) \{[\s\S]*?    super\.dispose\(\);\n  \}', new_dispose, content)

# 4. Update _resetFilters to clear cache
content = content.replace("  void _resetFilters() {\n    setState(() {", 
                          "  void _resetFilters() {\n    UniversalFilterDialog.clearCache(widget.module);\n    setState(() {")


with open("lib/services/widget/universal_filter_dialog.dart", "w") as f:
    f.write(content)

