import os

path = "lib/screens/craftsman_staff/widgets/craftsman_staff_card.dart"

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("profilePicture", "image")
content = content.replace("fullName", "name")
content = content.replace("craftsman_staffCode", "staffCode")
content = content.replace("craftsman_staff.bpCode", "craftsman_staff.craftsman?.craftmanCode")
content = content.replace("craftsman_staff.bpName", "craftsman_staff.craftsman?.businessName")
content = content.replace("emailId", "email")

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("Done fixing card.")
