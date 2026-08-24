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

# Let's insert it right after `class _PurchaseOrderScreenState extends ConsumerState<PurchaseOrderScreen> {`
import re
content = content.replace("class _PurchaseOrderScreenState extends ConsumerState<PurchaseOrderScreen> {", "class _PurchaseOrderScreenState extends ConsumerState<PurchaseOrderScreen> {\n" + get_tab_value_code)

with open("lib/screens/purchase_order/ui/purchase_order_screen.dart", "w") as f:
    f.write(content)
