import re

with open("lib/screens/catelogue/ui/catelogue_main_screen.dart", "r") as f:
    content = f.read()

# 1. Insert _buildActiveFilterRibbon before _showFilterDialog
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
              ref.read(catalogueProvider.notifier).fetchCatalogues();
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
              ref.read(catalogueProvider.notifier).fetchCatalogues();
            },
            child: Text(ref.watchTr('reset_btn'), style: const TextStyle(fontSize: 11, color: Colors.red)),
          )
        ],
      ),
    );
  }
"""
content = re.sub(r'  void _showFilterDialog\(\) \{', ribbon_code + r'\n  void _showFilterDialog() {', content)

# 2. Add ribbon inside Column children
content = content.replace(
    "_buildSelectAllBar(state),",
    "if (selectedFilter != null) _buildActiveFilterRibbon(),\n          _buildSelectAllBar(state),"
)

# 3. Update the NavActionItem logic in ERPBottomNavigationBar
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
                ref.read(catalogueProvider.notifier).fetchCatalogues();
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

# 4. Filter nav item label
nav_filter_old = "label: ref.watchTr('filter')"
nav_filter_new = "label: selectedFilter == null ? ref.watchTr('filter') : ref.watchTr('filtered')"
content = content.replace(nav_filter_old, nav_filter_new, 1)

with open("lib/screens/catelogue/ui/catelogue_main_screen.dart", "w") as f:
    f.write(content)

