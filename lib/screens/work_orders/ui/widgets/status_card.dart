import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/work_orders/riverpod/work_orders_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkOrderStatusCards extends ConsumerStatefulWidget {
  final ValueChanged<String> onStatusChanged;
  const WorkOrderStatusCards({super.key, required this.onStatusChanged});

  @override
  ConsumerState<WorkOrderStatusCards> createState() => _WorkOrderStatusCardsState();
}

class _WorkOrderStatusCardsState extends ConsumerState<WorkOrderStatusCards>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? role;

  // Optimized Status List based on Admin Role
  final List<String> _baseStatuses = [
    'All',
    'New',
    'Allocated',
    'In Process',
    'For Approval',
    'Completed',
    'Overdue',
    'Rejected',
  ];

  List<String> _visibleStatuses = [];

  // Mapping strictly to api/super-admin URLs
  final Map<String, String> adminUrls = {
    'All': 'api/common/work-orders?tab=all-orders',
    'New': 'api/common/work-orders?tab=new-orders',
    'Allocated': 'api/common/work-orders?tab=allocated-orders',
    'In Process': 'api/common/work-orders?tab=in-process-orders',
    'For Approval': 'api/common/work-orders?tab=for-approval-orders',
    'Completed': 'api/common/work-orders?tab=completed-orders',
    'Rejected': 'api/common/work-orders?tab=rejected-orders',
    'Overdue': 'api/common/work-orders?tab=overdue-orders',
  };

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role") ?? '';

    final r = role?.toLowerCase();
    if (r == 'buyer' || r == 'key_user' || r == 'user') {
      _visibleStatuses = ['New', 'Allocated', 'In Process', 'Completed', 'Rejected', 'All'];
    } else {
      _visibleStatuses = _baseStatuses.where((status) {
        if (r == 'craftsman') {
          return status != 'New' && status != 'For Approval';
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
    final url = adminUrls[status] ?? adminUrls['All']!;
    ref.read(workOrderListProvider.notifier).fetchWorkOrders(urls: url);
    widget.onStatusChanged(status);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workOrderListProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), width: 0.5)),
      ),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
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
                          ? AppColor.textWhite.withValues(alpha: 0.2)
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
  int _getCountForStatus(String status, WorkOrderListState state) {
    switch (status) {
      case 'All':
        return state.totalCount;
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
      case 'Overdue':
        return state.overdueOrders; // Correctly mapped to the new state field
      default:
        return 0;
    }
  }
}