import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/live_stock_order/riverpod/live_stock_order_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StockOrderStatusCards extends ConsumerStatefulWidget {
  final ValueChanged<String> onStatusChanged;
  const StockOrderStatusCards({super.key, required this.onStatusChanged});

  @override
  ConsumerState<StockOrderStatusCards> createState() => _StockOrderStatusCardsState();
}

class _StockOrderStatusCardsState extends ConsumerState<StockOrderStatusCards>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? role;

  final List<String> _baseStatuses = [
    'All',
    'New',
    'Allocated',
    'In Process',
    'For Approval',
    'Completed',
    'Rejected',
  ];

  List<String> _visibleStatuses = [];

  final Map<String, String> statusToTab = {
    'All': 'all-orders',
    'New': 'new-orders',
    'Allocated': 'allocated-orders',
    'In Process': 'in-process-orders',
    'For Approval': 'for-approval-orders',
    'Completed': 'completed-orders',
    'Rejected': 'rejected-orders',
  };

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role") ?? '';

    final r = role?.toLowerCase();
    if (r == 'buyer' || r == 'key_user' || r == 'user') {
      _visibleStatuses = ['New', 'Allocated', 'In Process', 'For Approval', 'Completed', 'Rejected', 'All'];
    } else {
      _visibleStatuses = _baseStatuses.where((status) {
        if (r == 'craftsman') {
          // Craftsman sees Allocated (as New), In Process, For Approval, Completed, Rejected, All
          return status != 'New'; 
        }
        return true;
      }).toList();
    }

    // Always move 'All' to the end for any user
    if (_visibleStatuses.contains('All')) {
      _visibleStatuses.remove('All');
      _visibleStatuses.add('All');
    }

    _tabController = TabController(length: _visibleStatuses.length, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _handleStatusChange(_visibleStatuses[_tabController.index]);
      }
    });

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_visibleStatuses.isNotEmpty) {
        _handleStatusChange(_visibleStatuses.first);
      }
    });
  }

  void _handleStatusChange(String status) {
    final tab = statusToTab[status] ?? 'all-orders';
    final url = "api/common/stock-orders?tab=$tab";
    ref.read(liveStockOrderNotifierProvider.notifier).fetchLiveStockOrders(customUrl: url);
    widget.onStatusChanged(status);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveStockOrderNotifierProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 0.5)),
      ),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
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
          tabs: _visibleStatuses.map((status) {
            int count = _getCountForStatus(status, state);
            String displayName = status;
            if (role?.toLowerCase() == 'craftsman' && status == 'Allocated') {
              displayName = 'New';
            }
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(displayName),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _tabController.index == _visibleStatuses.indexOf(status)
                          ? AppColor.textWhite.withOpacity(0.2)
                          : AppColor.divider,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        color: _tabController.index == _visibleStatuses.indexOf(status)
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

  int _getCountForStatus(String status, LiveStockOrderState state) {
    switch (status) {
      case 'All':
        return state.allOrders;
      case 'New':
        return state.newOrders;
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
      default:
        return 0;
    }
  }
}
