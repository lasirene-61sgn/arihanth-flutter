import os

path = "lib/screens/craftsman_staff/ui/craftsman_staff_form_screen.dart"

with open(path, "r", encoding="utf-8") as f:
    lines = f.readlines()

# The clean file up to the end of build method
clean_lines = lines[:347]

# Let's add the missing methods correctly:
methods_code = """  Widget _buildFilePicker(String label, PlatformFile? currentFile, Function(PlatformFile?) onFileSelected, {String? serverUrl}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.black)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            try {
              final result = await ImagePickerHelper.pickImages(context, allowMultiple: false);
              if (result.isNotEmpty) {
                final file = result.first;
                if ((file.size / (1024 * 1024)) <= 5) {
                  onFileSelected(file);
                } else {
                  Get.snackbar("Error", "Image size should be less than 5MB");
                }
              }
            } catch (e) {
              Get.snackbar("Error", "Error picking image: $e");
            }
          },
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: AppColor.border),
              borderRadius: BorderRadius.circular(8),
              color: AppColor.surface,
            ),
            child: currentFile != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (currentFile.bytes != null) ? Image.memory(currentFile.bytes!, width: 150, height: 150, fit: BoxFit.cover) : Container(color: Colors.grey),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => onFileSelected(null),
                          child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                : serverUrl != null && serverUrl.isNotEmpty
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(serverUrl, width: 150, height: 150, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: () => onFileSelected(null),
                              child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: AppColor.textSecondary, size: 32),
                          SizedBox(height: 8),
                          Text('Upload Image', style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildCraftsmanDropdown() {
    final partnerState = ref.watch(productListProvider);
    final validPartners = partnerState.bpCraftsmanList;

    BpBuyerModel? selectedModel;
    if (_selectedCraftsmanId != null) {
      selectedModel = validPartners.cast<BpBuyerModel?>().firstWhere(
        (bp) {
          bool matchByCode = false;
          if (_selectedCraftsmanCode != null && _selectedCraftsmanCode!.isNotEmpty) {
            matchByCode = bp?.bpCode == _selectedCraftsmanCode;
          }
          bool matchById = bp?.id.toString() == _selectedCraftsmanId.toString();
          return matchByCode || matchById;
        },
        orElse: () => null
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: WorkOrderDropdownWidget<BpBuyerModel>(
        label: 'Craftsman',
        fieldKeyName: 'craftsman_id',
        items: validPartners,
        itemLabel: (bp) => "${bp.bpCode} - ${bp.businessName}",
        selectedItemLabel: (bp) => "${bp.bpCode} - ${bp.businessName}",
        value: selectedModel,
        isSearchable: false,
        hintText: 'Select Craftsman',
        onChanged: (BpBuyerModel? selectedPartner) {
          if (selectedPartner == null) return;
          setState(() {
            _selectedCraftsmanId = selectedPartner.id;
          });
        },
      ),
    );
  }

  Widget _input(String label, TextEditingController controller,
      {bool isReq = false,
        bool obscure = false,
        TextInputType type = TextInputType.text,
        List<TextInputFormatter>? inputFormat,
        String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        inputFormatters: inputFormat,
        decoration: InputDecoration(
          labelText: isReq ? "$label *" : label,
        ),
        validator: (v) {
          if (isReq && (v == null || v.isEmpty)) return "Required";
          if (validator != null) return validator(v);
          return null;
        },
      ),
    );
  }

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
}
"""

with open(path, "w", encoding="utf-8") as f:
    f.writelines(clean_lines)
    f.write("\n")
    f.write(methods_code)

print("Done fixing the whole file from 348 to EOF.")
