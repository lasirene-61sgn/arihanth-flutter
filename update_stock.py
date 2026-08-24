import re

with open("lib/screens/live_stock_order/ui/live_stock_order.dart", "r") as f:
    content = f.read()

# 1. Add selectedFilter and selectedSort
content = content.replace("  final TextEditingController _searchController = TextEditingController();",
                          "  final TextEditingController _searchController = TextEditingController();\n  String? selectedFilter;\n  String? selectedSort;")

# 2. Insert _buildActiveFilterRibbon before _showFilterDialog (there is _showFilterDialog around line 180 or so)
ribbon_code = """
  Widget _buildActiveFilterRibbon() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.divider)),
      ),
      child: Row(
        children: [
          Text("${ref.watchTr('filtering')}:", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColor.primary)),
          const SizedBox(width: 8),
          Chip(
            label: Text("$selectedFilter: ${_searchController.text}", style:  const TextStyle(fontSize: 10)),
            backgroundColor: AppColor.primary.withOpacity(0.1),
            deleteIcon: const Icon(Icons.close, size: 12, color: AppColor.primary),
            onDeleted: () {
              setState(() {
                selectedFilter = null;
                _searchController.clear();
              });
              String url = "api/common/live-stock-orders?tab=${statusToTab[_activeStatus] ?? 'new-orders'}";
              ref.read(liveStockOrderNotifierProvider.notifier).fetchLiveStockOrders(customUrl: url);
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            side: BorderSide.none,
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                selectedFilter = null;
                _searchController.clear();
              });
              String url = "api/common/live-stock-orders?tab=${statusToTab[_activeStatus] ?? 'new-orders'}";
              ref.read(liveStockOrderNotifierProvider.notifier).fetchLiveStockOrders(customUrl: url);
            },
            child: Text(ref.watchTr('reset_btn'), style: const TextStyle(fontSize: 11, color: Colors.red)),
          )
        ],
      ),
    );
  }
"""
# find where to insert it. We can insert it before Widget build or something.
# We'll just append it to the class before `Widget build`
content = content.replace("  @override\n  Widget build(BuildContext context) {",
                          ribbon_code + "\n  @override\n  Widget build(BuildContext context) {")

# 3. Add ribbon inside Column children
content = content.replace(
    "_buildSelectAllBar(state),",
    "if (selectedFilter != null) _buildActiveFilterRibbon(),\n          _buildSelectAllBar(state),"
)

# 4. Update the NavActionItem logic in ERPBottomNavigationBar
nav_action_search = """          NavActionItem(
            label: ref.watchTr('search'),
            icon: Icons.search,
            color: AppColor.primary,
            onPressed: () {
              setState(() {
                searchToggle = true;
              });
            },
          ),"""

nav_action_reset_and_search = """          if (selectedFilter != null || selectedSort != null)
            NavActionItem(
              label: ref.watchTr('reset'),
              icon: Icons.refresh,
              color: Colors.red,
              onPressed: () {
                _searchController.clear();
                String url = "api/common/live-stock-orders?tab=${statusToTab[_activeStatus] ?? 'new-orders'}";
                ref.read(liveStockOrderNotifierProvider.notifier).fetchLiveStockOrders(customUrl: url);
                setState(() {
                  selectedFilter = null;
                  selectedSort = null;
                });
              },
            )
          else
            NavActionItem(
              label: ref.watchTr('search'),
              icon: Icons.search,
              color: AppColor.primary,
              onPressed: () {
                setState(() {
                  searchToggle = true;
                });
              },
            ),"""

content = content.replace(nav_action_search, nav_action_reset_and_search)

# 5. Filter nav item label
nav_filter_old = "label: ref.watchTr('filter')"
nav_filter_new = "label: selectedFilter == null ? ref.watchTr('filter') : ref.watchTr('filtered')"
content = content.replace(nav_filter_old, nav_filter_new, 1)

# Ensure filter selection updates selectedFilter
content = re.sub(r'onApply: \(\s*url\s*\)\s*\{', r'onApply: (url) {\n                 setState(() { selectedFilter = ref.watchTr("filtered"); });', content)

with open("lib/screens/live_stock_order/ui/live_stock_order.dart", "w") as f:
    f.write(content)

