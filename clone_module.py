import os

source_dir = "lib/screens/user"
dest_dir = "lib/screens/craftsman_staff"

# Mappings
replacements = {
    "User": "CraftsmanStaff",
    "user": "craftsman_staff",
    "Users": "CraftsmanStaff",
    "users": "craftsman_staff",
    "UserListState": "CraftsmanStaffListState",
    "UserListNotifier": "CraftsmanStaffListNotifier",
    "user_form": "craftsman_staff_form",
    "userProvider": "craftsmanStaffProvider",
    "api/common/users": "api/common/craftsman-staff",
    "api/common/user": "api/common/craftsman-staff",
    "route_name": "route_name" # just to ensure no bad replacements
}

file_rename = {
    "user_model.dart": "craftsman_staff_model.dart",
    "user_notifier.dart": "craftsman_staff_notifier.dart",
    "users_screen.dart": "craftsman_staff_screen.dart",
    "user_form_screen.dart": "craftsman_staff_form_screen.dart",
    "user_details_screen.dart": "craftsman_staff_details_screen.dart",
    "user_card.dart": "craftsman_staff_card.dart"
}

os.makedirs(dest_dir, exist_ok=True)

for root, dirs, files in os.walk(source_dir):
    for file in files:
        if not file.endswith(".dart"): continue
        
        src_path = os.path.join(root, file)
        
        rel_dir = os.path.relpath(root, source_dir)
        dest_sub_dir = os.path.join(dest_dir, rel_dir)
        os.makedirs(dest_sub_dir, exist_ok=True)
        
        dest_file_name = file_rename.get(file, file.replace("user", "craftsman_staff"))
        dest_path = os.path.join(dest_sub_dir, dest_file_name)
        
        with open(src_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        for k, v in replacements.items():
            content = content.replace(k, v)
            
        # Fix AppRoutes in the new files (from AppRoutes.users to AppRoutes.craftsmanStaff)
        content = content.replace("AppRoutes.craftsman_staffs", "AppRoutes.craftsmanStaff")
        content = content.replace("AppRoutes.craftsman_staffsAdd", "AppRoutes.craftsmanStaffAdd")
        content = content.replace("AppRoutes.craftsman_staffsView", "AppRoutes.craftsmanStaffView")
        
        with open(dest_path, "w", encoding="utf-8") as f:
            f.write(content)

print("Done cloning module.")
