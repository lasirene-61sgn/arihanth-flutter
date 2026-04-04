import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/dashboard_screen/riverpod/dashboard_notifier.dart';
import 'package:arianth/screens/kyc_pending/riverpod/kyc_pending_notifier.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/screens/kyc_pending/widgets/kyc_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KycPendingScreen extends ConsumerStatefulWidget {
  const KycPendingScreen({super.key});

  @override
  ConsumerState<KycPendingScreen> createState() => _KycPendingScreenState();
}

class _KycPendingScreenState extends ConsumerState<KycPendingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(kycPendingProvider.notifier).fetchKycPending();
      ref.read(dashboardProvider.notifier).fetchDashBoard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycPendingProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColor.appBarBackground,
        surfaceTintColor: AppColor.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColor.white, size: 22),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(
          ref.watchTr('kyc_verification'),
          style: const TextStyle(
              color: AppColor.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: -0.5
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(height: 1.0, color: AppColor.divider),
        ),
      ),
      body: Column(
        children: [
          _buildSegmentedTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListView(state.pendingBuyers, isBuyer: true),
                _buildListView(state.pendingCraftsmen, isBuyer: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. CLEAN SEGMENTED TAB BAR ---
  Widget _buildSegmentedTabs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppColor.background,
      child: Center(
        child: Container(
          height: 42,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColor.divider,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColor.border),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColor.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColor.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorPadding: EdgeInsets.zero,
            labelColor: AppColor.textWhite,
            unselectedLabelColor: AppColor.textSecondary,
            dividerColor: AppColor.transparent,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5
            ),
            unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12
            ),
            tabs: const [
              Tab(text: "PENDING BUYERS"),
              Tab(text: "CRAFTSMEN"),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. CUSTOM ERP LIST VIEW (NO TABLE) ---
  Widget _buildListView(List<dynamic> items, {required bool isBuyer}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppColor.textHint.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              "No pending requests found", 
              style: TextStyle(color: AppColor.textHint, fontSize: 14)
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return KycCard(
          item: item,
          isBuyer: isBuyer,
          onTap: () {
             // Handle Detail View
          },
        );
      },
    );
  }
}
