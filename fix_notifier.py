import os

path = "lib/screens/craftsman_staff/riverpod/craftsman_staff_notifier.dart"

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

old_func = """  Future<void> saveCraftsmanStaff(
      Map<String, dynamic> map, {
        String? url,
        String? method,
      }) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      // 1. Execute request based on method passed from UI
      final response = method == "POST"
          ? await ApiClient().post(endpoint: url ?? "api/common/craftsman-staff", body: map)
          : await ApiClient().put(endpoint: url ?? "api/common/craftsman-staff", body: map);"""

new_func = """  Future<void> saveCraftsmanStaff(
      Map<String, dynamic> map, {
        String? url,
        String? method,
        Map<String, dynamic>? files,
      }) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      // 1. Execute request based on method passed from UI
      dynamic response;
      if (files != null && files.isNotEmpty) {
        response = await ApiClient().requestWithFiles(
          endpoint: url ?? "api/common/craftsman-staff",
          fields: map,
          files: files,
          method: method ?? "POST",
        );
      } else {
        response = method == "POST"
            ? await ApiClient().post(endpoint: url ?? "api/common/craftsman-staff", body: map)
            : await ApiClient().put(endpoint: url ?? "api/common/craftsman-staff", body: map);
      }"""

content = content.replace(old_func, new_func)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("Done fixing notifier.")
