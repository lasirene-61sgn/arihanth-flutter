with open("lib/screens/purchase_order/ui/purchase_order_screen.dart", "r") as f:
    content = f.read()

get_tab_value_code = """
  String _getTabValue() {
    final Map<String, String> statusToTab = {
      'All': 'all',
      'New': 'created',
      'Allocated': 'allocated',
      'Rejected': 'rejected',
      'In Process': 'in_process',
      'For Approval': 'for_approval',
      'Completed': 'completed',
      'Closed': 'closed'
    };
    return statusToTab[_activeStatus] ?? 'created';
  }
"""

# Insert _getTabValue() right after void initState() { ... }
# we'll look for `    super.dispose();\n  }` which is the end of dispose method
import re
content = re.sub(r'(    super\.dispose\(\);\n  \})', r'\1\n' + get_tab_value_code, content)

with open("lib/screens/purchase_order/ui/purchase_order_screen.dart", "w") as f:
    f.write(content)
