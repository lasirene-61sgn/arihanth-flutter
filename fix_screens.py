import re

files_and_modules = {
    "lib/screens/products/ui/products_screen.dart": "FilterModule.product",
    "lib/screens/designs/ui/designs_screen.dart": "FilterModule.design",
    "lib/screens/catelogue/ui/catelogue_main_screen.dart": "FilterModule.catalogue",
    "lib/screens/craftsman/ui/craftsman_screen.dart": "FilterModule.craftsman",
    "lib/screens/repairs/ui/repairs_screen.dart": "FilterModule.repair",
    "lib/screens/purchase_order/ui/purchase_order_screen.dart": "FilterModule.purchaseOrder",
    "lib/screens/work_orders/ui/work_orders_screen.dart": "FilterModule.workOrder",
    "lib/screens/key_user/ui/key_users_screen.dart": "FilterModule.keyUser",
    "lib/screens/live_stock_order/ui/live_stock_order.dart": "FilterModule.stockOrder",
    "lib/screens/buyer/ui/buyers_screen.dart": "FilterModule.buyer",
}

for path, module in files_and_modules.items():
    try:
        with open(path, "r") as f:
            content = f.read()

        # Add import for UniversalFilterDialog if not present
        if "UniversalFilterDialog.clearCache" not in content and "universal_filter_dialog.dart" not in content:
            # Most screens probably already import it for show(). 
            # If not, let's not worry unless it fails. 
            pass

        # 1. Update dispose()
        # Find `void dispose() {` or `@override\n  void dispose() {`
        if "void dispose() {" in content:
            dispose_injection = f"  void dispose() {{\n    UniversalFilterDialog.clearCache({module});"
            content = content.replace("  void dispose() {", dispose_injection, 1)

        # 2. Update Ribbon reset (if it exists)
        # Look for `_searchController.clear();` inside `_buildActiveFilterRibbon`
        # Actually it's easier to replace `selectedFilter = null;\n                _searchController.clear();`
        # with `selectedFilter = null;\n                _searchController.clear();\n                UniversalFilterDialog.clearCache({module});`
        # It occurs twice in ribbon (onDeleted and onPressed) and once in NavActionItem
        
        target = "selectedFilter = null;\n                _searchController.clear();"
        replacement = f"selectedFilter = null;\n                _searchController.clear();\n                UniversalFilterDialog.clearCache({module});"
        content = content.replace(target, replacement)
        
        target2 = "_searchController.clear();\n                selectedFilter = null;"
        replacement2 = f"_searchController.clear();\n                selectedFilter = null;\n                UniversalFilterDialog.clearCache({module});"
        content = content.replace(target2, replacement2)
        
        target3 = "_searchController.clear();\n                ref.read"
        # Wait, in nav bar I did `_searchController.clear();\n                String url...`
        # Or `_searchController.clear();\n                ref.read`
        # Let's just look for `_searchController.clear();` and inject before it inside the reset button.
        # But we don't want to inject on `searchToggle = false; _searchController.clear();` 
        # Actually the reset buttons set `selectedFilter = null;`
        # Let's look for `setState(() {\n                  selectedFilter = null;\n                  selectedSort = null;\n                });` in NavActionItem
        
        target4 = "                  selectedFilter = null;\n                  selectedSort = null;\n                });"
        replacement4 = f"                  selectedFilter = null;\n                  selectedSort = null;\n                }});\n                UniversalFilterDialog.clearCache({module});"
        content = content.replace(target4, replacement4)
        
        with open(path, "w") as f:
            f.write(content)
            
    except Exception as e:
        print(f"Error on {path}: {e}")

