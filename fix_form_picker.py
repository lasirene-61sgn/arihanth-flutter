import os

path = "lib/screens/craftsman_staff/ui/craftsman_staff_form_screen.dart"

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

bad_picker_1 = """            ReusableFilePicker(
              label: "Profile Image",
              selectedFile: _profileImage,
              onFileSelected: (file) {
                setState(() => _profileImage = file);
              },
              onClear: () {
                setState(() => _profileImage = null);
              },
            ),"""

bad_picker_2 = """            ReusableFilePicker(
              label: "Aadhar Image",
              selectedFile: _aadharImage,
              onFileSelected: (file) {
                setState(() => _aadharImage = file);
              },
              onClear: () {
                setState(() => _aadharImage = null);
              },
            ),"""

good_picker_1 = """            _buildFilePicker("Profile Image", _profileImage, (file) => setState(() => _profileImage = file)),"""
good_picker_2 = """            _buildFilePicker("Aadhar Image", _aadharImage, (file) => setState(() => _aadharImage = file)),"""

content = content.replace(bad_picker_1, good_picker_1)
content = content.replace(bad_picker_2, good_picker_2)

# Insert the _buildFilePicker method at the end of the class
picker_method = """
  Widget _buildFilePicker(String label, PlatformFile? currentFile, Function(PlatformFile?) onFileSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
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
                final result = await FilePicker.platform.pickFiles(type: FileType.image);
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
  }
}
"""

content = content.replace("}\n", picker_method)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("Done fixing form picker.")
