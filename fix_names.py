import os

source_dir = "lib/screens/craftsman_staff"

for root, dirs, files in os.walk(source_dir):
    for file in files:
        if not file.endswith(".dart"): continue
        
        src_path = os.path.join(root, file)
        
        with open(src_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        content = content.replace("craftsman_staffProvider", "craftsmanStaffProvider")
        content = content.replace("CraftsmanStaffsScreen", "CraftsmanStaffScreen")
        
        with open(src_path, "w", encoding="utf-8") as f:
            f.write(content)

print("Done fixing names.")
