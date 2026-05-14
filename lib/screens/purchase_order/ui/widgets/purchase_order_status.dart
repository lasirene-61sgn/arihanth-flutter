// ui/widgets/purchase_order_status_tabs.dart

import 'package:arianth/app_color/app_color.dart'; // Ensure you have this for consistent styling
import 'package:arianth/screens/purchase_order/riverpod/purchase_orders_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PurchaseOrderStatusCards extends ConsumerStatefulWidget {
  final ValueChanged<String> onStatusChanged;

  const PurchaseOrderStatusCards({
    super.key,
    required this.onStatusChanged,
  });

  @override
  ConsumerState<PurchaseOrderStatusCards> createState() =>
      _PurchaseOrderStatusCardsState();
}

class _PurchaseOrderStatusCardsState extends ConsumerState<PurchaseOrderStatusCards>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? role;
  late List<Map<String, String>> _tabs;
  int _lastTabIndex = 0;

  final Map<String, String> normalUrls = {
    'New': 'api/common/purchase-orders?tab=created',
    'Allocated': 'api/common/purchase-orders?tab=allocated',
    'In Process': 'api/common/purchase-orders?tab=in_process',
    'For Approval': 'api/common/purchase-orders?tab=for_approval',
    'Completed': 'api/common/purchase-orders?tab=completed',
    'Rejected': 'api/common/purchase-orders?tab=rejected',
    'All': 'api/common/purchase-orders?tab=all',
  };

  List<Map<String, String>> _getTabs() {
    final isCraftsman = role?.toLowerCase() == 'craftsman';
    List<Map<String, String>> tabs = [];
    
    if (isCraftsman) {
      tabs = [
        {'label': 'New', 'value': 'Allocated'},
        {'label': 'In Process', 'value': 'In Process'},
        {'label': 'Completed', 'value': 'Completed'},
        {'label': 'Rejected', 'value': 'Rejected'},
        {'label': 'All', 'value': 'All'},
      ];
    } else {
      tabs = [
        {'label': 'New', 'value': 'New'},
        {'label': 'Allocated', 'value': 'Allocated'},
        {'label': 'In Process', 'value': 'In Process'},
        {'label': 'Completed', 'value': 'Completed'},
        {'label': 'Rejected', 'value': 'Rejected'},
        {'label': 'All', 'value': 'All'},
      ];
    }

    // Ensure 'All' is always last (though already added last above)
    final allTab = tabs.firstWhere((t) => t['label'] == 'All', orElse: () => {});
    if (allTab.isNotEmpty) {
      tabs.removeWhere((t) => t['label'] == 'All');
      tabs.add(allTab);
    }
    
    return tabs;
  }

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role") ?? '';
    _tabs = _getTabs();
    _tabController = TabController(length: _tabs.length, vsync: this);

    // Listen to tab changes
    _tabController.addListener(() {
      if (_tabController.index != _lastTabIndex) {
        setState(() {
          _lastTabIndex = _tabController.index;
        });
        _handleTabSelection(_tabs[_tabController.index]['value']!);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleTabSelection(_tabs[0]['value']!);
    });
  }

  void _handleTabSelection(String status) {
    final url = normalUrls[status] ?? normalUrls['New']!;
    ref.read(purchaseOrderListProvider.notifier).fetchPurchaseOrders(customUrl: url);
    widget.onStatusChanged(status);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColor.background,
        border: Border(bottom: BorderSide(color: AppColor.divider, width: 0.5)),
      ),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColor.surface, 
          borderRadius: BorderRadius.circular(10),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: AppColor.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          indicatorPadding: const EdgeInsets.all(2),
          labelColor: AppColor.textWhite, 
          unselectedLabelColor: AppColor.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: _tabs.map((tab) {
            final status = tab['label']!;
            final value = tab['value']!;
            final state = ref.watch(purchaseOrderListProvider);
            int count = _getCountForStatus(value, state);
            
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(status),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _tabController.index == _tabs.indexOf(tab)
                          ? AppColor.textWhite.withValues(alpha: 0.2)
                          : AppColor.divider,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        color: _tabController.index == _tabs.indexOf(tab)
                            ? AppColor.textWhite
                            : AppColor.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  int _getCountForStatus(String status, PurchaseOrderListState state) {
    switch (status) {
      case 'New':
        return state.createdOrders;
      case 'Allocated':
        return state.allocatedOrders;
      case 'In Process':
        return state.inProcessOrders;
      case 'For Approval':
        return state.forApprovalOrders;
      case 'Completed':
        return state.completedOrders;
      case 'Rejected':
        return state.rejectedOrders;
      case 'All':
        return state.totalCount;
      default:
        return 0;
    }
  }
}