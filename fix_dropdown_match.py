import os

path = "lib/screens/craftsman_staff/ui/craftsman_staff_form_screen.dart"

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# Add _selectedCraftsmanCode
if "String? _selectedCraftsmanCode;" not in content:
    content = content.replace("int? _selectedCraftsmanId;", "int? _selectedCraftsmanId;\n  String? _selectedCraftsmanCode;")

    # In _populateFields, set _selectedCraftsmanCode
    old_pop = "_selectedCraftsmanId = detail.craftsmanId;"
    new_pop = "_selectedCraftsmanId = detail.craftsmanId;\n        _selectedCraftsmanCode = detail.craftsman?.craftmanCode;"
    content = content.replace(old_pop, new_pop)

    # In _buildCraftsmanDropdown, use _selectedCraftsmanCode to find the model
    old_match = """    if (_selectedCraftsmanId != null) {
      selectedModel = validPartners.cast<BpBuyerModel?>().firstWhere(
              (bp) => bp?.id.toString() == _selectedCraftsmanId.toString(),
          orElse: () => null
      );
    }"""
    new_match = """    if (_selectedCraftsmanId != null) {
      selectedModel = validPartners.cast<BpBuyerModel?>().firstWhere(
        (bp) {
          if (_selectedCraftsmanCode != null && _selectedCraftsmanCode!.isNotEmpty) {
            return bp?.bpCode == _selectedCraftsmanCode;
          }
          return bp?.id.toString() == _selectedCraftsmanId.toString();
        },
        orElse: () => null
      );
    }"""
    content = content.replace(old_match, new_match)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("Done fixing dropdown match.")
