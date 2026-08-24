import re

with open("lib/screens/repairs/ui/repairs_screen.dart", "r") as f:
    content = f.read()

# 1. Add selectedFilter and selectedSort
content = content.replace("  final TextEditingController _searchController = TextEditingController();",
                          "  final TextEditingController _searchController = TextEditingController();\n  String? selectedFilter;\n  String? selectedSort;")

# 2. Insert _buildActiveFilterRibbon before _showSortMenu or after initState
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
              ref.read(repairListProvider.notifier).fetchRepairs();
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
              ref.read(repairListProvider.notifier).fetchRepairs();
            },
            child: Text(ref.watchTr('reset_btn'), style: const TextStyle(fontSize: 11, color: Colors.red)),
          )
        ],
      ),
    );
  }
"""
content = re.sub(r'  void _showSortMenu\(\) \{', ribbon_code + r'\n  void _showSortMenu() {', content)

# 3. Add ribbon inside Column children
content = content.replace(
    "_buildSelectAllBar(state),",
    "if (selectedFilter != null) _buildActiveFilterRibbon(),\n          _buildSelectAllBar(state),"
)

# 4. Update the NavActionItem logic in ERPBottomNavigationBar
nav_action_sort = """          NavActionItem(
            label: ref.watchTr('sort'),
            icon: Icons.sort_by_alpha,
            color: AppColor.primary,
            onPressed: _showSortMenu,
          ),"""

nav_action_reset = """          if (selectedFilter != null || selectedSort != null)
            NavActionItem(
              label: ref.watchTr('reset'),
              icon: Icons.refresh,
              color: Colors.red,
              onPressed: () {
                _searchController.clear();
                ref.read(repairListProvider.notifier).fetchRepairs();
                setState(() {
                  selectedFilter = null;
                  selectedSort = null;
                });
              },
            )
          else
            NavActionItem(
              label: ref.watchTr('sort'),
              icon: Icons.sort_by_alpha,
              color: AppColor.primary,
              onPressed: _showSortMenu,
            ),"""

content = content.replace(nav_action_sort, nav_action_reset)

# 5. Filter nav item label
nav_filter_old = "label: ref.watchTr('filter')"
nav_filter_new = "label: selectedFilter == null ? ref.watchTr('filter') : ref.watchTr('filtered')"
content = content.replace(nav_filter_old, nav_filter_new, 1)

# Ensure filter selection updates selectedFilter
# ReusableFilterDialog.show( ... onApply: (url) {
content = re.sub(r'onApply: \(\s*url\s*\)\s*\{', r'onApply: (url) {\n                 setState(() { selectedFilter = ref.watchTr("filtered"); });', content)

with open("lib/screens/repairs/ui/repairs_screen.dart", "w") as f:
    f.write(content)

