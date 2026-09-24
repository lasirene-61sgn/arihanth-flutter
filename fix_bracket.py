import os

path = "lib/screens/craftsman_staff/ui/craftsman_staff_form_screen.dart"

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("    );\n\n  Widget _buildFilePicker", "    );\n  }\n\n  Widget _buildFilePicker")

with open(path, "w", encoding="utf-8") as f:
    f.write(content)
