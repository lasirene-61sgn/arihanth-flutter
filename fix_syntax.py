import re

path = "lib/screens/craftsman_staff/ui/craftsman_staff_form_screen.dart"

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# First, remove all _buildPermissionsSection definitions
content = re.sub(r'  Widget _buildPermissionsSection\(\) \{[\s\S]*?\}', '', content)
content = re.sub(r'    Widget _buildPermissionsSection\(\) \{[\s\S]*?\}', '', content)

# Now fix missing brackets. 
# We know _buildCraftsmanDropdown ends with:
#       ),
#     );
#   }
content = content.replace("      ),\n    );\n  Widget _input", "      ),\n    );\n  }\n\n  Widget _input")

# And _input ends with:
#       ),
#     );
#   }
# }
content = content.replace("      ),\n    );\n}\n", "      ),\n    );\n  }\n}\n")
content = content.replace("      ),\n    );\n}", "      ),\n    );\n  }\n}")

# Re-append _buildPermissionsSection properly at the end of the class
perms_code = """

  Widget _buildPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Permissions", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: _allPermissions.map((perm) {
              bool isSelected = _selectedPermissions.contains(perm);
              return CheckboxListTile(
                title: Text(perm),
                value: isSelected,
                dense: true,
                onChanged: (bool? val) {
                  setState(() {
                    if (val == true) {
                      _selectedPermissions.add(perm);
                    } else {
                      _selectedPermissions.remove(perm);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}"""
content = re.sub(r'\}\s*$', perms_code, content)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("Done fixing syntax.")
