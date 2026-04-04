import 'package:arianth/app_color/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinanceDashboardScreen extends ConsumerStatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  ConsumerState<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends ConsumerState<FinanceDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text(
          'Finance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColor.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColor.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),


        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(height: 1.0, color: AppColor.divider),
        ),
      ),
      // body: SingleChildScrollView(
      //   padding: const EdgeInsets.all(20),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       _buildWelcomeSection(),
      //       const SizedBox(height: 24),
      //       _buildMetricGrid(),
      //       const SizedBox(height: 24),
      //       _buildRecentTransactionsSection(),
      //       const SizedBox(height: 24),
      //       _buildRevenueChartPlaceholder(),
      //     ],
      //   ),
      // ),
      body: Center(
        child: Text("Work in Process"),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Financial Overview",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColor.primary.withValues(alpha: 0.8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Real-time business performance",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            _buildMetricCard(
              title: 'Total Revenue',
              value: '₹ 12,45,000',
              trend: '+12.5%',
              icon: Icons.account_balance_wallet_outlined,
              color: Colors.green,
            ),
            _buildMetricCard(
              title: 'Outstanding',
              value: '₹ 3,20,500',
              trend: '-4.2%',
              icon: Icons.pending_actions_outlined,
              color: Colors.orange,
            ),
            _buildMetricCard(
              title: 'Expenses',
              value: '₹ 4,12,000',
              trend: '+8.1%',
              icon: Icons.payments_outlined,
              color: Colors.red,
            ),
            _buildMetricCard(
              title: 'Net Profit',
              value: '₹ 5,12,500',
              trend: '+15.4%',
              icon: Icons.trending_up,
              color: Colors.blue,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    required Color color,
  }) {
    final isPositive = trend.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColor.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppColor.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Transactions",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                Text(
                  "View All",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColor.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => Divider(height: 1, color: AppColor.divider),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColor.background,
                  child: Icon(
                    index % 2 == 0 ? Icons.arrow_downward : Icons.arrow_upward,
                    color: index % 2 == 0 ? Colors.green : Colors.red,
                    size: 16,
                  ),
                ),
                title: Text(
                  index % 2 == 0 ? "Payment from ABC Glass" : "Vendor Payment - XYZ Kraft",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text("14 Mar 2026 • PO #9821", style: TextStyle(fontSize: 12)),
                trailing: Text(
                  index % 2 == 0 ? "+ ₹ 45,000" : "- ₹ 12,500",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: index % 2 == 0 ? Colors.green : Colors.red,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChartPlaceholder() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.divider),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: AppColor.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            const Text(
              "Revenue Statistics (Chart Placeholder)",
              style: TextStyle(color: AppColor.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
