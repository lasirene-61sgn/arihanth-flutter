import os

path = "lib/screens/craftsman_staff/ui/craftsman_staff_form_screen.dart"

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# Replace the FilePicker import with ImagePickerHelper
content = content.replace("import 'package:file_picker/file_picker.dart';", "import 'package:file_picker/file_picker.dart';\nimport 'package:arianth/services/image_picker/image_picker_helper.dart';")

# Extract the old _buildFilePicker function
old_picker = """  Widget _buildFilePicker(String label, PlatformFile? currentFile, Function(PlatformFile?) onFileSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  currentFile?.name ?? "No file chosen",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: currentFile == null ? Colors.grey : Colors.black),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final result = await FilePicker.pickFiles(type: FileType.image);
                if (result != null && result.files.isNotEmpty) {
                  onFileSelected(result.files.first);
                }
              },
              child: const Text("Browse"),
            ),
            if (currentFile != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                onPressed: () => onFileSelected(null),
              ),
            ]
          ],
        ),
      ],
    );
  }"""

new_picker = """  Widget _buildFilePicker(String label, PlatformFile? currentFile, Function(PlatformFile?) onFileSelected, {String? serverUrl}) {
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
  }"""

content = content.replace(old_picker, new_picker)

# Also need to add serverUrl properties for the fields
# In _CraftsmanStaffFormScreenState:
# String? _serverProfileImage;
# String? _serverAadharImage;
if "String? _serverProfileImage;" not in content:
    content = content.replace("PlatformFile? _profileImage;", "PlatformFile? _profileImage;\n  String? _serverProfileImage;")
    content = content.replace("PlatformFile? _aadharImage;", "PlatformFile? _aadharImage;\n  String? _serverAadharImage;")

    # In _populateFields:
    # _serverProfileImage = detail.image;
    # _serverAadharImage = detail.aadharImage;
    old_pop = "_selectedStatusLabel = detail.isActive ? \"Active\" : \"InActive\";"
    new_pop = old_pop + "\n        _serverProfileImage = detail.image;\n        _serverAadharImage = detail.aadharImage;"
    content = content.replace(old_pop, new_pop)

    # In build method for the pickers:
    old_call_1 = '_buildFilePicker("Profile Image", _profileImage, (file) => setState(() => _profileImage = file)),'
    new_call_1 = '_buildFilePicker("Profile Image", _profileImage, (file) { setState(() { if(file==null) _serverProfileImage=null; _profileImage = file; }); }, serverUrl: _serverProfileImage),'
    content = content.replace(old_call_1, new_call_1)

    old_call_2 = '_buildFilePicker("Aadhar Image", _aadharImage, (file) => setState(() => _aadharImage = file)),'
    new_call_2 = '_buildFilePicker("Aadhar Image", _aadharImage, (file) { setState(() { if(file==null) _serverAadharImage=null; _aadharImage = file; }); }, serverUrl: _serverAadharImage),'
    content = content.replace(old_call_2, new_call_2)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("Done updating picker.")
