import 'package:arianth/screens/business_partner_list/model/business_partner_list_model.dart';
import 'package:arianth/screens/business_partner_list/riverpod/business_partner_list_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:arianth/screens/business_partner_list/widgets/partner_card.dart';
import 'package:arianth/services/widget/pagination_controls.dart';
import 'package:arianth/services/widget/enterprise_search_bar.dart';

import '../../../app_color/app_color.dart';
import '../../../services/localization/language_selector.dart';
import '../../../services/widget/reusable_fillter_dialog.dart';
import '../../../services/widget/reusable_sort.dart';

class BusinessPartnersScreen extends ConsumerStatefulWidget {
  const BusinessPartnersScreen({super.key});

  @override
  ConsumerState<BusinessPartnersScreen> createState() =>
      _BusinessPartnersScreenState();
}

class _BusinessPartnersScreenState
    extends ConsumerState<BusinessPartnersScreen> with SingleTickerProviderStateMixin {
  Set<String> selectedIds = {};
  String? selectedFilter;
  String? selectedSort;
  bool isAscending = true;
  bool _actionsVisible = true;

  String? role;
  late final TabController _tabController;

  static const _tabs = [
    {'label': 'Buyers', 'value': 0},
    {'label': 'Craftsmen', 'value': 1},
  ];

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role");
    
    // Read the initially selected tab from the state
    final int initialTab = ref.read(businessPartnerListProvider).selectedTab;
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: initialTab);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      ref.read(businessPartnerListProvider.notifier).changeTab(_tabController.index);
    });

    Future.microtask(() async {
      await ref
          .read(businessPartnerListProvider.notifier)
          .fetchBusinessPartners();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get isMobile => MediaQuery.of(context).size.width < 600;


  bool searchToggle = false;
  final TextEditingController _searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(businessPartnerListProvider);
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColor.white),
          onPressed: () {
            // This opens the drawer in MainLayout
            Scaffold.of(context).openDrawer();
          },
        ),
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        title: !searchToggle
            ? Text(
          ref.watchTr('partners'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColor.white,
          ),
        )
            : EnterpriseSearchBar(
          controller: _searchController,
          hintText: 'Quick search...',
          onChanged: (value) {
            ref.read(businessPartnerListProvider.notifier).filterBusinessPartners('All', value);
          },
          onCancel: () {
            setState(() {
              _searchController.clear();
              searchToggle = false;
            });
            ref.read(businessPartnerListProvider.notifier).filterBusinessPartners('All', '');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: AppColor.white),
            onPressed: () => LanguageSelector.show(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          if (selectedFilter != null) _buildActiveFilterRibbon(),
          Flexible(
            fit: FlexFit.loose,
            child: _buildPreTable(),
          ),
          if (state.nextUrl != null || state.previousUrl != null)
            PaginationControls(
              count: state.count,
              label: 'Total BPs',
              onNext: () => ref.read(businessPartnerListProvider.notifier).goToNextPage(),
              onPrevious: () => ref.read(businessPartnerListProvider.notifier).goToPreviousPage(),
              isFirstPage: state.previousUrl == null,
              isLastPage: state.nextUrl == null,
              isLoading: state.isLoading,
            ),
        ],
      ),
      // bottomNavigationBar: ERPBottomNavigationBar(
      //   actions: [
      //     NavActionItem(
      //       label: selectedFilter == null ? ref.watchTr('filter') : ref.watchTr('filtered'),
      //       icon: Icons.filter_alt, // ERP-style icon
      //       color: Colors.orange,
      //       onPressed: _showFilterDialog,
      //     ),
      //     NavActionItem(
      //       label: ref.watchTr('export'),
      //       icon: Icons.download,
      //       color: Colors.teal,
      //       onPressed: _exportToExcel,
      //     ),
      //     NavActionItem(
      //       label: ref.watchTr('print'),
      //       icon: Icons.print,
      //       color: Colors.blueGrey,
      //       onPressed: _printTable,
      //     ),
      //     if (selectedFilter != null || selectedSort != null)
      //       NavActionItem(
      //         label: ref.watchTr('reset'),
      //         icon: Icons.refresh,
      //         color: Colors.red,
      //         onPressed: () {
      //           _searchController.clear();
      //           ref.read(businessPartnerListProvider.notifier).fetchBusinessPartners();
      //           setState(() {
      //             selectedFilter = null;
      //             selectedSort = null;
      //           });
      //         },
      //       )
      //     else
      //       NavActionItem(
      //         label: ref.watchTr('sort'),
      //         icon: Icons.sort_by_alpha,
      //         color: Colors.purple,
      //         onPressed: _showSortMenu,
      //       ),
      //   ],
      // ),
    );
  }


  void _printTable() async {
    final state = ref.read(businessPartnerListProvider);

    List<BusinessPartner> productsToPrint;

    if (selectedIds.isNotEmpty) {
      // Print only selected products
      productsToPrint = state.businessPartners
          .where((product) => selectedIds.contains(product.id.toString()))
          .toList();
    } else {
      // Print all visible products
      productsToPrint = state.businessPartners;
    }

    // If somehow empty (edge case), just do nothing silently
    if (productsToPrint.isEmpty) {
      return;
    }
    //
    // await ref.read(printServiceProvider).generateAndPrintPdf(
    //   title: "Business Partner",
    //   data: productsToPrint,
    //   context: context,
    // );
  }
  Widget _buildHeaderDesktop() {
    final hasSelection = selectedIds.isNotEmpty;
    final singleSelection = selectedIds.length == 1;


    return Column(
      children: [
        if(!isMobile) Container(
          width: double.infinity,
          height: 50,
          padding: EdgeInsets.symmetric(vertical: 10,horizontal: 50),
          decoration: BoxDecoration(
            color: AppColor.appBarBackground,
            border: Border(
              left: BorderSide(
                color: AppColor.divider,
                width: 1,
              ),
            ),
          ),
          child: Text("Business Partner",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: AppColor.textPrimary),),

        ),
      ],
    );
  }


  Widget _buildActiveFilterRibbon() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.divider)),
      ),
      child: Row(
        children: [
          const Text("Filtering:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColor.primary)),
          const SizedBox(width: 8),
          Chip(
            label: Text("$selectedFilter: ${_searchController.text}", style: const TextStyle(fontSize: 10)),
            backgroundColor: const Color(0xFFEEF2FF),
            deleteIcon: const Icon(Icons.close, size: 12, color: Colors.indigo),
            onDeleted: () {
              setState(() {
                selectedFilter = null;
                _searchController.clear();
              });
              ref.read(businessPartnerListProvider.notifier).fetchBusinessPartners();
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            side: BorderSide.none,
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                selectedFilter = null;
                _searchController.clear();
              });
              ref.read(businessPartnerListProvider.notifier).fetchBusinessPartners();
            },
            child: const Text("Clear", style: TextStyle(fontSize: 11, color: Colors.red)),
          )
        ],
      ),
    );
  }
  void _showFilterDialog() {
    showFilterDrawer(
      context: context,
      ref: ref,
      config: FilterDrawerConfig(
        title: ref.watchTr('filter_partners'),
        subtitle: ref.watchTr('narrow_down'),
        fields: [
          FilterField(label: ref.watchTr('bp_code'),    key: 'bp_code',    icon: Icons.tag_rounded),
          FilterField(label: ref.watchTr('buyer_name'), key: 'name',       icon: Icons.person_outline_rounded),
          FilterField(label: ref.watchTr('mobile'),     key: 'mobile',     icon: Icons.phone_outlined),
          FilterField(label: ref.watchTr('email'),      key: 'email',      icon: Icons.mail_outline_rounded),
          FilterField(label: ref.watchTr('status'),     key: 'kyc_status', icon: Icons.verified_outlined),
        ],
        initialField: selectedFilter != null
            ? FilterField(label: selectedFilter!, key: '', icon: Icons.tune_rounded)
            : null,
        initialValue: _searchController.text,
        onApply: (field, value) {
          setState(() {
            selectedFilter = field.label;
            _searchController.text = value;
          });
          final url = "/api/super-admin/buyers?${field.key}=$value";
          ref.read(businessPartnerListProvider.notifier).fetchBusinessPartners(url: url);
        },
        onClear: () {
          setState(() {
            selectedFilter = null;
            _searchController.clear();
          });
          ref.read(businessPartnerListProvider.notifier).fetchBusinessPartners();
        },
      ),
    );
  }
  void _showSortMenu() {
    showSortDrawer(
      context: context,
      ref: ref,
      config: SortDrawerConfig(
        title: ref.watchTr('sort_partners'),
        subtitle: ref.watchTr('choose_sort'),
        fields: [
          SortField(
            label: ref.watchTr('buyer_code'),
            key: 'bp_code',
            icon: Icons.tag_rounded,
            sub: ref.watchTr('sort_by_bp'),
          ),
          SortField(
            label: ref.watchTr('buyer_name'),
            key: 'name',
            icon: Icons.sort_by_alpha_rounded,
            sub: ref.watchTr('sort_by_alpha'),
          ),
          SortField(
            label: ref.watchTr('mobile'),
            key: 'mobile',
            icon: Icons.phone_outlined,
            sub: ref.watchTr('sort_by'),
          ),
        ],
        initialField: selectedSort,
        initialAscending: isAscending,
        onApply: (field, ascending) {
          ref.read(businessPartnerListProvider.notifier).sortBusinessPartners(field.label);
          setState(() {
            selectedSort = field.label;
            isAscending = ascending;
          });
        },
        onClear: () {
          ref.read(businessPartnerListProvider.notifier).fetchBusinessPartners();
          setState(() {
            selectedSort = null;
            isAscending = true;
          });
        },
      ),
    );
  }

  Widget _buildPreTable() {
    final state = ref.watch(businessPartnerListProvider);

    if (state.isLoading && state.businessPartners.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.businessPartners.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), // Space for pagination
      itemCount: state.businessPartners.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final partner = state.businessPartners[index];
        final id = partner.id.toString();
        final isSelected = selectedIds.contains(id);

        return PartnerCard(
          partner: partner,
          isSelected: isSelected,
          onSelectionChanged: (checked) {
            setState(() {
              if (checked == true) {
                selectedIds.add(id);
              } else {
                selectedIds.remove(id);
              }
            });
          },
          onTap: () {
            if (partner.role?.toLowerCase() == 'buyer') {
              Get.toNamed(AppRoutes.buyersDetails, arguments: id);
            } else if (partner.role?.toLowerCase() == 'craftsman') {
              Get.toNamed(AppRoutes.craftsmanView, arguments: id);
            }
          },
          onEdit: () {
            if (partner.role?.toLowerCase() == 'buyer') {
              Get.toNamed(AppRoutes.buyersAdd, arguments: id);
            } else if (partner.role?.toLowerCase() == 'craftsman') {
              Get.toNamed(AppRoutes.craftsmanAdd, arguments: id);
            }
          },

        );
      },
    );
  }

  Widget _buildTabs() {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.divider)),
      ),
      child: Center(
        child: Container(
          height: 40,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColor.background,
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
            tabs: _tabs.map((t) => Tab(text: ref.watchTr((t['label'] as String).toLowerCase()))).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No business partners found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start adding business partners to see them here',
            style: TextStyle(fontSize: 15, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}