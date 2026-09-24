import os

path = "lib/screens/craftsman_staff/ui/craftsman_staff_form_screen.dart"

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# Add _staffCodeController
if "final _staffCodeController =" not in content:
    content = content.replace("final _nameController = TextEditingController();", "final _staffCodeController = TextEditingController();\n  final _nameController = TextEditingController();")

    # Dispose it
    old_disp = "_nameController.dispose();"
    new_disp = "_staffCodeController.dispose();\n    _nameController.dispose();"
    content = content.replace(old_disp, new_disp)

    # Populate it
    old_pop = "_nameController.text = detail.name ?? '';"
    new_pop = "_staffCodeController.text = detail.staffCode ?? '';\n        _nameController.text = detail.name ?? '';"
    content = content.replace(old_pop, new_pop)

    # Submit it
    old_post = '      "name": _nameController.text.trim(),'
    new_post = '      "staff_code": _staffCodeController.text.trim(),\n      "name": _nameController.text.trim(),'
    content = content.replace(old_post, new_post)

    # Add UI field
    old_ui = '_input("Full Name", _nameController, isReq: true),'
    new_ui = '_input("Staff Code", _staffCodeController, isReq: true),\n            _input("Full Name", _nameController, isReq: true),'
    content = content.replace(old_ui, new_ui)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("Done fixing staff code.")
