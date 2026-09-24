import os

path = "lib/screens/craftsman_staff/ui/craftsman_staff_form_screen.dart"

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# Add permissions state and list
if "List<String> _selectedPermissions =" not in content:
    content = content.replace("final _pincodeService = PincodeApiService();", """final _pincodeService = PincodeApiService();
  List<String> _selectedPermissions = [];
  final List<String> _allPermissions = [
    "wo_view", "wo_accept", "wo_reject", 
    "po_view", "po_accept", "po_reject", 
    "repair_view", "repair_accept", "repair_reject", 
    "product_view", "product_create", 
    "design_view", "catalogue_view"
  ];""")

    # _populateFields update
    old_pop = "_staffCodeController.text = detail.staffCode ?? '';"
    new_pop = "_staffCodeController.text = detail.staffCode ?? '';\n        _selectedPermissions = List<String>.from(detail.permissions);\n        if (detail.passwordPlain != null) {\n          _passwordController.text = detail.passwordPlain!;\n          _confirmPasswordController.text = detail.passwordPlain!;\n        }"
    content = content.replace(old_pop, new_pop)

    # postData update for permissions
    old_post = """    final files = <String, dynamic>{};"""
    new_post = """    for (int i = 0; i < _selectedPermissions.length; i++) {
      postData["permissions[$i]"] = _selectedPermissions[i];
    }
    
    final files = <String, dynamic>{};"""
    content = content.replace(old_post, new_post)

    # Remove password condition
    old_pass = """            if (_craftsman_staffId == null) ...[
              _input("Password", _passwordController,
                  isReq: true, obscure: true),
              _input("Confirm Password", _confirmPasswordController,
                  isReq: true, obscure: true),
            ],"""
    new_pass = """            _input("Password", _passwordController, isReq: _craftsman_staffId == null, obscure: false),
            _input("Confirm Password", _confirmPasswordController, isReq: _craftsman_staffId == null, obscure: false),"""
    content = content.replace(old_pass, new_pass)

    # Add permissions UI inside build
    # I'll put it right before the Submit button
    old_submit = """            SafeArea(
              child: CustomButton(
                text: "Submit","""
    new_submit = """            _buildPermissionsSection(),
            const SizedBox(height: 20),
            SafeArea(
              child: CustomButton(
                text: "Submit","""
    content = content.replace(old_submit, new_submit)

    # Add _buildPermissionsSection method
    perms_method = """  Widget _buildPermissionsSection() {
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
    content = content.replace("}\n", perms_method)
    
    # Just to clean up in case I replaced the last bracket wrongly
    # I'll use a more precise replacement for the class end
    content = content.replace("}\n  Widget _buildPermissionsSection() {", "  Widget _buildPermissionsSection() {")
    content = content.replace("}\n}", "}")
    
with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("Done updating form.")
