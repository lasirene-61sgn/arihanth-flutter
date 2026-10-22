import 'package:arianth/screens/reports/model/report_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arianth/screens/reports/riverpod/report_notifier.dart';
import 'package:arianth/app_color/app_color.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';

class Reports extends ConsumerStatefulWidget {
  const Reports({super.key});

  @override
  ConsumerState<Reports> createState() => _ReportsState();
}

class _ReportsState extends ConsumerState<Reports> {
  final GlobalKey _topPicksCraftsmanKey = GlobalKey();
  final GlobalKey _topPicksClientKey = GlobalKey();
  final GlobalKey _craftsmanFavoritesKey = GlobalKey();
  final GlobalKey _buyerFavoritesKey = GlobalKey();
  int _currentIndex = 0;
  List<String> _hiddenTabs = [];
  Map<String, List<String>> _hiddenTableFields = {};
  final Map<String, Set<int>> _selectedIndicesByTab = {};
  List<String> _orderedTabs = [
    'top_picks_craftsman',
    'top_picks_client',
    'overall_designs',
    'craftsman_favorites',
    'buyer_favorites'
  ];
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _loadCustomPreferences();
    _pageController = PageController(initialPage: _currentIndex);
    Future.microtask(() => ref.read(reportProvider.notifier).fetchReportDetails());
  }

  void _loadCustomPreferences() {
    final savedOrderStr = SharedPreferencesHelper().getString('reports_tab_order');
    if (savedOrderStr != null && savedOrderStr.isNotEmpty) {
      try {
        final List<String> savedOrder = List<String>.from(jsonDecode(savedOrderStr));
        for (var tab in _orderedTabs) {
          if (!savedOrder.contains(tab)) {
            savedOrder.add(tab);
          }
        }
        _orderedTabs = savedOrder;
      } catch (_) {}
    }

    final hiddenTabsStr = SharedPreferencesHelper().getString('reports_tab_hidden');
    if (hiddenTabsStr != null && hiddenTabsStr.isNotEmpty) {
      try {
        _hiddenTabs = List<String>.from(jsonDecode(hiddenTabsStr));
      } catch (_) {
        _hiddenTabs = [];
      }
    }

    final hiddenFieldsStr = SharedPreferencesHelper().getString('reports_table_fields_hidden');
    if (hiddenFieldsStr != null && hiddenFieldsStr.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(hiddenFieldsStr);
        _hiddenTableFields = decoded.map((key, val) => MapEntry(key, List<String>.from(val)));
      } catch (_) {
        _hiddenTableFields = {};
      }
    }
  }

  void _saveCustomPreferences() {
    SharedPreferencesHelper().setString('reports_tab_order', jsonEncode(_orderedTabs));
    SharedPreferencesHelper().setString('reports_tab_hidden', jsonEncode(_hiddenTabs));
    SharedPreferencesHelper().setString('reports_table_fields_hidden', jsonEncode(_hiddenTableFields));
  }

  List<String> _getHiddenFieldsFor(String tableKey) {
    return _hiddenTableFields[tableKey] ?? [];
  }

  void _toggleTableField(String tableKey, String fieldName, bool visible) {
    final list = List<String>.from(_hiddenTableFields[tableKey] ?? []);
    if (visible) {
      list.remove(fieldName);
    } else {
      if (!list.contains(fieldName)) {
        list.add(fieldName);
      }
    }
    _hiddenTableFields[tableKey] = list;
    _saveCustomPreferences();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatTabName(String type) {
    final role = SharedPreferencesHelper().getString("role")?.toLowerCase() ?? '';
    final isNonAdmin = ['craftsman', 'buyer', 'user', 'craftsman_staff'].contains(role);

    if (isNonAdmin) {
      if (type == 'top_picks_craftsman' || type == 'top_picks_client') {
        return 'Top Picks';
      }
      if (type == 'craftsman_favorites' || type == 'buyer_favorites') {
        return 'Favorites';
      }
      if (type == 'overall_designs') {
        return 'Designs';
      }
    }

    return type.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  bool _isTabNotEmpty(String tabKey, ReportModel? data) {
    if (data == null) return false;
    switch (tabKey) {
      case 'top_picks_craftsman':
        return data.topPicksCraftsman.isNotEmpty;
      case 'top_picks_client':
        return data.topPicksClient.isNotEmpty;
      case 'overall_designs':
        return data.overallDesigns.isNotEmpty;
      case 'craftsman_favorites':
        return data.craftsmanFavorites.any((fav) {
          int total = 0;
          fav.categories.forEach((k, v) => total += v.products.length);
          return total > 0;
        });
      case 'buyer_favorites':
        return data.buyerFavorites.any((fav) {
          int total = 0;
          fav.categories.forEach((k, v) => total += v.products.length);
          return total > 0;
        });
      default:
        return false;
    }
  }

  List<String> _getAvailableTabs(ReportModel? data) {
    if (data == null) return [];
    final role = SharedPreferencesHelper().getString("role")?.toLowerCase() ?? '';
    final isCraftsmanUser = role == 'craftsman' || role == 'craftsman_staff';
    final isBuyerUser = role == 'buyer' || role == 'key_user' || role == 'user';

    return _orderedTabs.where((type) {
      if (_hiddenTabs.contains(type)) return false;
      // If craftsman is logged in, do not show buyer/client info
      if (isCraftsmanUser && (type == 'top_picks_client' || type == 'buyer_favorites')) {
        return false;
      }
      // If buyer is logged in, do not show craftsman info
      if (isBuyerUser && (type == 'top_picks_craftsman' || type == 'craftsman_favorites')) {
        return false;
      }
      return _isTabNotEmpty(type, data);
    }).toList();
  }

  List<String> _getAllFieldsForTable(String tableKey) {
    final role = SharedPreferencesHelper().getString("role")?.toLowerCase() ?? '';
    final isSuperAdmin = role == 'super_admin';

    switch (tableKey) {
      case 'top_picks_craftsman':
        return [
          'Code',
          'Name',
          'Allocated',
          'In Process',
          if (isSuperAdmin) 'Completed',
          'Total Wt',
          'WA Wt',
          'PO Wt',
          'Overdue',
          'New Orders',
        ];
      case 'top_picks_client':
        return [
          'Name',
          'Orders',
          'New Orders',
          'In Process',
          'For Approval',
          'Overdue',
          if (isSuperAdmin) 'Completed',
          'Rejected',
        ];
      case 'craftsman_favorites':
      case 'buyer_favorites':
        return ['Code', 'Name', 'Total Products'];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final availableTabs = _getAvailableTabs(reportState.reportData);
    final currentTabType = availableTabs.isNotEmpty && _currentIndex < availableTabs.length 
        ? availableTabs[_currentIndex] 
        : '';
    final isTable = currentTabType == 'top_picks_craftsman' || currentTabType == 'top_picks_client' || currentTabType == 'craftsman_favorites' || currentTabType == 'buyer_favorites';

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text("Reports"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          if (isTable)
            IconButton(
              icon: const Icon(Icons.view_column_outlined),
              tooltip: 'Customize Table Fields',
              onPressed: () => _showManageTableFieldsBottomSheet(currentTabType),
            ),
          IconButton(
            icon: const Icon(Icons.dashboard_customize_outlined),
            tooltip: 'Customize Reports & Fields',
            onPressed: () => _showManageReportsBottomSheet(reportState.reportData, currentTabType),
          ),
          if (isTable && reportState.reportData != null)
            IconButton(
              icon: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/image/whatsapp.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              tooltip: 'Share to WhatsApp',
              onPressed: () => _shareToWhatsApp(currentTabType),
            ),
          if (isTable && reportState.reportData != null)
            IconButton(
              icon: const Icon(Icons.screen_rotation),
              tooltip: 'Rotate Table',
              onPressed: () => _showRotatedTable(context, currentTabType),
            ),
        ],
      ),
      body: _buildBody(reportState),
    );
  }

  Future<void> _shareToWhatsApp(String tabType) async {
    final state = ref.read(reportProvider);
    if (state.reportData == null) return;
    final data = state.reportData!;

    OverlayEntry? entry;
    final shareKey = GlobalKey();

    final selected = _selectedIndicesByTab[tabType];
    final selectedIndices = (selected != null && selected.isNotEmpty) ? selected.toList() : null;

    Widget shareWidget;
    if (tabType == 'top_picks_craftsman') {
      shareWidget = _buildTopPicksCraftsman(data, forSharing: true, repaintKey: shareKey, filterIndices: selectedIndices);
    } else if (tabType == 'top_picks_client') {
      shareWidget = _buildTopPicksClient(data, forSharing: true, repaintKey: shareKey, filterIndices: selectedIndices);
    } else if (tabType == 'craftsman_favorites') {
      shareWidget = _buildCraftsmanFavorites(data, forSharing: true, repaintKey: shareKey, filterIndices: selectedIndices);
    } else if (tabType == 'buyer_favorites') {
      shareWidget = _buildBuyerFavorites(data, forSharing: true, repaintKey: shareKey, filterIndices: selectedIndices);
    } else {
      return;
    }

    try {
      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -99999,
          top: -99999,
          child: Material(
            color: Colors.transparent,
            child: shareWidget,
          ),
        ),
      );
      Overlay.of(context).insert(entry);

      await Future.delayed(const Duration(milliseconds: 250));

      final boundary = shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot capture table.')));
        return;
      }

      final ui.Image img = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Failed to convert image to bytes");

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(filePath).writeAsBytes(byteData.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'image/png')],
          subject: _formatTabName(tabType),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing table: $e')));
      }
    } finally {
      entry?.remove();
    }
  }

  void _showRotatedTable(BuildContext context, String tabType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(reportProvider);
            if (state.reportData == null) return const Scaffold();
            return Scaffold(
              backgroundColor: AppColor.background,
              body: SafeArea(
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 48.0),
                          child: tabType == 'top_picks_craftsman' 
                              ? _buildTopPicksCraftsman(state.reportData!, isRotated: true)
                              : tabType == 'top_picks_client'
                                  ? _buildTopPicksClient(state.reportData!, isRotated: true)
                                  : tabType == 'craftsman_favorites'
                                      ? _buildCraftsmanFavorites(state.reportData!, isRotated: true)
                                      : _buildBuyerFavorites(state.reportData!, isRotated: true),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 30),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showManageTableFieldsBottomSheet(String tableKey) {
    final allFields = _getAllFieldsForTable(tableKey);
    if (allFields.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final hidden = _getHiddenFieldsFor(tableKey);
            return Container(
              decoration: const BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.6,
                maxChildSize: 0.85,
                minChildSize: 0.35,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.view_column_outlined, color: AppColor.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatTabName(tableKey)} Fields',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColor.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Select which table columns you want to view',
                        style: TextStyle(fontSize: 13, color: AppColor.textHint),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: allFields.length,
                          itemBuilder: (context, index) {
                            final field = allFields[index];
                            final isVisible = !hidden.contains(field);
                            final visibleCount = allFields.length - hidden.length;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Card(
                                elevation: 0,
                                color: AppColor.background,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: AppColor.divider.withValues(alpha: 0.5)),
                                ),
                                child: SwitchListTile(
                                  title: Text(field, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  value: isVisible,
                                  activeColor: AppColor.primary,
                                  onChanged: (bool value) {
                                    if (!value && visibleCount <= 1) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('At least one column must remain visible')),
                                      );
                                      return;
                                    }
                                    setSheetState(() {
                                      _toggleTableField(tableKey, field, value);
                                    });
                                    setState(() {});
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showManageReportsBottomSheet(ReportModel? data, String currentTabType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColor.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (context, scrollController) {
                return StatefulBuilder(
                  builder: (context, setSheetState) {
                    final role = SharedPreferencesHelper().getString("role")?.toLowerCase() ?? '';
                    final isCraftsmanUser = role == 'craftsman' || role == 'craftsman_staff';
                    final isBuyerUser = role == 'buyer' || role == 'key_user' || role == 'user';

                    final nonEmptyTabs = _orderedTabs.where((tabKey) {
                      if (isCraftsmanUser && (tabKey == 'top_picks_client' || tabKey == 'buyer_favorites')) {
                        return false;
                      }
                      if (isBuyerUser && (tabKey == 'top_picks_craftsman' || tabKey == 'craftsman_favorites')) {
                        return false;
                      }
                      return _isTabNotEmpty(tabKey, data);
                    }).toList();
                    final currentTableFields = _getAllFieldsForTable(currentTabType);
                    final hiddenFields = _getHiddenFieldsFor(currentTabType);

                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const TabBar(
                          labelColor: AppColor.primary,
                          unselectedLabelColor: AppColor.textHint,
                          indicatorColor: AppColor.primary,
                          tabs: [
                            Tab(icon: Icon(Icons.tab), text: "Report Tabs"),
                            Tab(icon: Icon(Icons.view_column), text: "Table Fields"),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Tab 1: Categories/Tabs
                              nonEmptyTabs.isEmpty
                                  ? const Center(child: Text("No report categories available"))
                                  : ListView.builder(
                                      controller: scrollController,
                                      itemCount: nonEmptyTabs.length,
                                      itemBuilder: (context, index) {
                                        final tabKey = nonEmptyTabs[index];
                                        final isHidden = _hiddenTabs.contains(tabKey);
                                        final title = _formatTabName(tabKey);

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                          child: Card(
                                            elevation: 0,
                                            color: AppColor.background,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              side: BorderSide(color: AppColor.divider.withValues(alpha: 0.5)),
                                            ),
                                            child: SwitchListTile(
                                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              value: !isHidden,
                                              activeColor: AppColor.primary,
                                              onChanged: (bool value) {
                                                setSheetState(() {
                                                  if (value) {
                                                    _hiddenTabs.remove(tabKey);
                                                  } else {
                                                    _hiddenTabs.add(tabKey);
                                                  }
                                                });
                                                _saveCustomPreferences();
                                                setState(() {});
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                              // Tab 2: Table Fields for Current Table
                              currentTableFields.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(24.0),
                                        child: Text(
                                          "No table columns customizable for the currently selected report tab.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: AppColor.textHint),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: currentTableFields.length,
                                      itemBuilder: (context, index) {
                                        final field = currentTableFields[index];
                                        final isVisible = !hiddenFields.contains(field);
                                        final visibleCount = currentTableFields.length - hiddenFields.length;

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                          child: Card(
                                            elevation: 0,
                                            color: AppColor.background,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              side: BorderSide(color: AppColor.divider.withValues(alpha: 0.5)),
                                            ),
                                            child: SwitchListTile(
                                              title: Text(field, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              value: isVisible,
                                              activeColor: AppColor.primary,
                                              onChanged: (bool value) {
                                                if (!value && visibleCount <= 1) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('At least one column must remain visible')),
                                                  );
                                                  return;
                                                }
                                                setSheetState(() {
                                                  _toggleTableField(currentTabType, field, value);
                                                });
                                                setState(() {});
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(ReportState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColor.primary));
    }
    
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(state.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(reportProvider.notifier).fetchReportDetails(),
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    if (state.reportData == null) {
      return const Center(child: Text("No report data available"));
    }

    final data = state.reportData!;
    final availableTabs = _getAvailableTabs(data);

    if (availableTabs.isEmpty) {
      return const Center(child: Text("No report data available"));
    }

    if (_currentIndex >= availableTabs.length) {
      _currentIndex = 0;
    }

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ReorderableListView(
            scrollDirection: Axis.horizontal,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = availableTabs.removeAt(oldIndex);
                availableTabs.insert(newIndex, item);

                // Update _orderedTabs ordering
                _orderedTabs.remove(item);
                final insertAt = newIndex < availableTabs.length - 1
                    ? _orderedTabs.indexOf(availableTabs[newIndex + 1])
                    : _orderedTabs.length;
                _orderedTabs.insert(insertAt.clamp(0, _orderedTabs.length), item);
                
                _saveCustomPreferences();
                if (_currentIndex == oldIndex) {
                  _currentIndex = newIndex;
                } else if (_currentIndex > oldIndex && _currentIndex <= newIndex) {
                  _currentIndex--;
                } else if (_currentIndex < oldIndex && _currentIndex >= newIndex) {
                  _currentIndex++;
                }
                _pageController.jumpToPage(_currentIndex);
              });
            },
            children: availableTabs.map((type) {
              final isSelected = availableTabs.indexOf(type) == _currentIndex;
              return GestureDetector(
                key: ValueKey(type),
                onTap: () {
                  final index = availableTabs.indexOf(type);
                  setState(() => _currentIndex = index);
                  _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? AppColor.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    _formatTabName(type),
                    style: TextStyle(
                      color: isSelected ? AppColor.primary : AppColor.textHint,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: availableTabs.map((type) {
              return _buildTabContent(type, data);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(String type, ReportModel data) {
    switch (type) {
      case 'top_picks_craftsman':
        return _buildTopPicksCraftsman(data);
      case 'top_picks_client':
        return _buildTopPicksClient(data);
      case 'overall_designs':
        return _buildOverallDesigns(data);
      case 'craftsman_favorites':
        return _buildCraftsmanFavorites(data);
      case 'buyer_favorites':
        return _buildBuyerFavorites(data);
      default:
        return Center(child: Text("Unknown tab: $type"));
    }
  }

  Widget _buildTopPicksCraftsman(ReportModel data, {bool isRotated = false, bool forSharing = false, GlobalKey? repaintKey, List<int>? filterIndices}) {
    var topPicks = data.topPicksCraftsman;
    if (filterIndices != null && filterIndices.isNotEmpty) {
      topPicks = [
        for (int i in filterIndices)
          if (i >= 0 && i < topPicks.length) topPicks[i]
      ];
    }
    final role = SharedPreferencesHelper().getString("role")?.toLowerCase() ?? '';
    final isSuperAdmin = role == 'super_admin';
    final isCraftsmanUser = role == 'craftsman' || role == 'craftsman_staff';
    final hiddenFields = _getHiddenFieldsFor('top_picks_craftsman');

    final bool showIdentity = !forSharing || isCraftsmanUser;

    final allHeaders = [
      if (showIdentity) 'Code',
      if (showIdentity) 'Name',
      'Allocated',
      'In Process',
      if (isSuperAdmin) 'Completed',
      'Total Wt',
      'WA Wt',
      'PO Wt',
      'Overdue',
      'New Orders',
    ];
    final allColumnWidths = [
      if (showIdentity) 110.0,
      if (showIdentity) 160.0,
      120.0, // Allocated
      120.0, // In Process
      if (isSuperAdmin) 120.0, // Completed
      110.0, // Total Wt
      110.0, // WA Wt
      110.0, // PO Wt
      110.0, // Overdue
      130.0, // New Orders
    ];

    final isColumnEmpty = List.generate(allHeaders.length, (colIndex) {
      return topPicks.every((c) {
        String val = '';
        final header = allHeaders[colIndex];
        if (header == 'Code') val = c.code;
        if (header == 'Name') val = c.name;
        if (header == 'Allocated') val = c.allocated.toString();
        if (header == 'In Process') val = c.inProcess.toString();
        if (header == 'Completed') val = c.completed.toString();
        if (header == 'Total Wt') val = c.totalWeight == 0 ? '' : c.totalWeight.toString();
        if (header == 'WA Wt') val = c.waTotalWeight == 0 ? '' : c.waTotalWeight.toString();
        if (header == 'PO Wt') val = c.poTotalWeight == 0 ? '' : c.poTotalWeight.toString();
        if (header == 'Overdue') val = c.overdue.toString();
        if (header == 'New Orders') val = c.wo?.newOrders?.count.toString() ?? '0';
        return val.trim().isEmpty || val.trim().toUpperCase() == 'N/A' || val.trim() == 'NULL' || val.trim() == '-';
      });
    });

    final headers = <String>[];
    final columnWidths = <double>[];
    final activeColumnIndices = <int>[];

    for (int i = 0; i < allHeaders.length; i++) {
      if (!isColumnEmpty[i] && (!hiddenFields.contains(allHeaders[i]) || headers.isEmpty)) {
        headers.add(allHeaders[i]);
        columnWidths.add(allColumnWidths[i]);
        activeColumnIndices.add(i);
      }
    }

    final tableKey = 'top_picks_craftsman';
    final selectedIndices = _selectedIndicesByTab[tableKey] ?? <int>{};

    return _buildCustomTable(
      repaintKey: isRotated ? null : (repaintKey ?? _topPicksCraftsmanKey),
      headers: headers,
      columnWidths: columnWidths,
      itemCount: topPicks.length,
      isShareMode: forSharing,
      tableKey: forSharing ? null : tableKey,
      showActionColumn: !forSharing,
      onReorder: (oldIndex, newIndex) {
        ref.read(reportProvider.notifier).reorderTopPicksCraftsman(oldIndex, newIndex);
      },
      rowBuilder: (context, index) {
        final craftsman = topPicks[index];
        final isOverdue = craftsman.overdue > 0;
        final allCellValues = [
          if (showIdentity) craftsman.code,
          if (showIdentity) craftsman.name,
          craftsman.allocated.toString(),
          craftsman.inProcess.toString(),
          if (isSuperAdmin) craftsman.completed.toString(),
          craftsman.totalWeight.toString(),
          craftsman.waTotalWeight.toString(),
          craftsman.poTotalWeight.toString(),
          craftsman.overdue.toString(),
          craftsman.wo?.newOrders?.count.toString() ?? '0',
        ];

        final cellValues = activeColumnIndices.map((i) => allCellValues[i]).toList();
        
        final overdueIndex = headers.indexOf('Overdue');
        final textColors = List<Color>.filled(headers.length, AppColor.textPrimary);
        final textWeights = List<FontWeight>.filled(headers.length, FontWeight.normal);
        if (isOverdue && overdueIndex != -1) {
          textColors[overdueIndex] = Colors.red;
          textWeights[overdueIndex] = FontWeight.bold;
        }

        void openDetails() {
          final wo = craftsman.wo;
          final po = craftsman.po;
          Get.toNamed(AppRoutes.reportOrders, arguments: {
            'title': '${craftsman.name} Orders',
            'nestedTabData': {
              'Work Orders (WO)': {
                'New': wo?.newOrders?.orders ?? [],
                'Allocated': wo?.allocated?.orders ?? [],
                'In Process': wo?.inProcess?.orders ?? [],
                'For Approval': wo?.forApproval?.orders ?? [],
                'Overdue': wo?.overdue?.orders ?? [],
                if (isSuperAdmin) 'Completed': wo?.completed?.orders ?? [],
              },
              'Purchase Orders (PO)': {
                'New': po?.newOrders?.orders ?? [],
                'Allocated': po?.allocated?.orders ?? [],
                'In Process': po?.inProcess?.orders ?? [],
                'For Approval': po?.forApproval?.orders ?? [],
                'Overdue': po?.overdue?.orders ?? [],
                if (isSuperAdmin) 'Completed': wo?.completed?.orders ?? [],
              }
            },
          });
        }

        return _buildRowCells(
          cellValues,
          columnWidths,
          textColors: textColors,
          textWeights: textWeights,
          showCheckbox: !forSharing,
          isSelected: selectedIndices.contains(index),
          onSelectChanged: (val) {
            setState(() {
              if (val == true) {
                (_selectedIndicesByTab[tableKey] ??= <int>{}).add(index);
              } else {
                _selectedIndicesByTab[tableKey]?.remove(index);
              }
            });
          },
          showViewButton: !forSharing,
          onViewPressed: openDetails,
        );
      },
    );
  }

  Widget _buildTopPicksClient(ReportModel data, {bool isRotated = false, bool forSharing = false, GlobalKey? repaintKey, List<int>? filterIndices}) {
    var topPicks = data.topPicksClient;
    if (filterIndices != null && filterIndices.isNotEmpty) {
      topPicks = [
        for (int i in filterIndices)
          if (i >= 0 && i < topPicks.length) topPicks[i]
      ];
    }
    if (topPicks.isEmpty) return const Center(child: Text("No Client Data"));
    
    final role = SharedPreferencesHelper().getString("role")?.toLowerCase() ?? '';
    final isSuperAdmin = role == 'super_admin';
    final isBuyerUser = role == 'buyer' || role == 'key_user' || role == 'user';
    final hiddenFields = _getHiddenFieldsFor('top_picks_client');

    final bool showIdentity = !forSharing || isBuyerUser;

    final allHeaders = [
      if (showIdentity) 'Name',
      'Orders',
      'New Orders',
      'In Process',
      'For Approval',
      'Overdue',
      if (isSuperAdmin) 'Completed',
      'Rejected',
    ];
    final allColumnWidths = [
      if (showIdentity) 160.0,
      110.0, // Orders
      130.0, // New Orders
      120.0, // In Process
      130.0, // For Approval
      110.0, // Overdue
      if (isSuperAdmin) 120.0, // Completed
      110.0, // Rejected
    ];

    final headers = <String>[];
    final columnWidths = <double>[];
    final activeColumnIndices = <int>[];

    for (int i = 0; i < allHeaders.length; i++) {
      if (!hiddenFields.contains(allHeaders[i]) || headers.isEmpty) {
        headers.add(allHeaders[i]);
        columnWidths.add(allColumnWidths[i]);
        activeColumnIndices.add(i);
      }
    }

    final tableKey = 'top_picks_client';
    final selectedIndices = _selectedIndicesByTab[tableKey] ?? <int>{};

    return _buildCustomTable(
      repaintKey: isRotated ? null : (repaintKey ?? _topPicksClientKey),
      headers: headers,
      columnWidths: columnWidths,
      itemCount: topPicks.length,
      isShareMode: forSharing,
      tableKey: forSharing ? null : tableKey,
      showActionColumn: !forSharing,
      onReorder: (oldIndex, newIndex) {
        ref.read(reportProvider.notifier).reorderTopPicksClient(oldIndex, newIndex);
      },
      rowBuilder: (context, index) {
        final client = topPicks[index];
        final isOverdue = (client.overdue?.count ?? 0) > 0;
        final allCellValues = [
          if (showIdentity) client.name,
          client.orders.toString(),
          client.newOrders?.count.toString() ?? '0',
          client.inProcess?.count.toString() ?? '0',
          client.forApproval?.count.toString() ?? '0',
          client.overdue?.count.toString() ?? '0',
          if (isSuperAdmin) client.completed?.count.toString() ?? '0',
          client.rejected?.count.toString() ?? '0',
        ];

        final cellValues = activeColumnIndices.map((i) => allCellValues[i]).toList();
        
        final overdueIndex = headers.indexOf('Overdue');
        final textColors = List<Color>.filled(headers.length, AppColor.textPrimary);
        final textWeights = List<FontWeight>.filled(headers.length, FontWeight.normal);
        if (isOverdue && overdueIndex != -1) {
          textColors[overdueIndex] = Colors.red;
          textWeights[overdueIndex] = FontWeight.bold;
        }

        void openDetails() {
          Get.toNamed(AppRoutes.reportOrders, arguments: {
            'title': '${client.name} Orders',
            'tabData': {
               'New': client.newOrders?.orders ?? [],
               'In Process': client.inProcess?.orders ?? [],
               'For Approval': client.forApproval?.orders ?? [],
               'Overdue': client.overdue?.orders ?? [],
               if (isSuperAdmin) 'Completed': client.completed?.orders ?? [],
               'Rejected': client.rejected?.orders ?? [],
            },
          });
        }

        return _buildRowCells(
          cellValues,
          columnWidths,
          textColors: textColors,
          textWeights: textWeights,
          showCheckbox: !forSharing,
          isSelected: selectedIndices.contains(index),
          onSelectChanged: (val) {
            setState(() {
              if (val == true) {
                (_selectedIndicesByTab[tableKey] ??= <int>{}).add(index);
              } else {
                _selectedIndicesByTab[tableKey]?.remove(index);
              }
            });
          },
          showViewButton: !forSharing,
          onViewPressed: openDetails,
        );
      },
    );
  }

  Widget _buildCustomTable({
    required GlobalKey? repaintKey,
    required List<String> headers,
    required List<double> columnWidths,
    required int itemCount,
    required Widget Function(BuildContext, int) rowBuilder,
    required void Function(int, int) onReorder,
    bool isShareMode = false,
    String? tableKey,
    bool showActionColumn = false,
  }) {
    final hasPrefixCol = !isShareMode && tableKey != null;
    final prefixColWidth = showActionColumn ? 110.0 : 48.0;

    final finalHeaders = [
      if (hasPrefixCol) '',
      ...headers,
    ];
    final finalColumnWidths = [
      if (hasPrefixCol) prefixColWidth,
      ...columnWidths,
    ];
    final totalWidth = finalColumnWidths.fold<double>(0, (a, b) => a + b);

    final content = _buildTableContent(
      totalWidth,
      finalHeaders,
      finalColumnWidths,
      itemCount,
      onReorder,
      rowBuilder,
      isShareMode: isShareMode,
      tableKey: tableKey,
      showActionColumn: showActionColumn,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: repaintKey == null
          ? content
          : RepaintBoundary(
              key: repaintKey,
              child: content,
            ),
    );
  }

  Widget _buildTableContent(
    double totalWidth,
    List<String> headers,
    List<double> columnWidths,
    int itemCount,
    void Function(int, int) onReorder,
    Widget Function(BuildContext, int) rowBuilder, {
    bool isShareMode = false,
    String? tableKey,
    bool showActionColumn = false,
  }) {
    final selectedSet = tableKey != null ? (_selectedIndicesByTab[tableKey] ?? <int>{}) : <int>{};
    final isAllSelected = itemCount > 0 && selectedSet.length == itemCount;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: totalWidth,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              ),
              child: Row(
                children: List.generate(headers.length, (index) {
                  final isLast = index == headers.length - 1;
                  final isCheckboxCol = !isShareMode && tableKey != null && index == 0;

                  Widget headerWidget;
                  if (isCheckboxCol) {
                    headerWidget = SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: isAllSelected,
                        activeColor: AppColor.primary,
                        tristate: selectedSet.isNotEmpty && !isAllSelected,
                        onChanged: (val) {
                          setState(() {
                            if (isAllSelected) {
                              _selectedIndicesByTab[tableKey]?.clear();
                            } else {
                              _selectedIndicesByTab[tableKey] = Set.from(List.generate(itemCount, (i) => i));
                            }
                          });
                        },
                      ),
                    );
                  } else {
                    headerWidget = Text(
                      headers[index],
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  }

                  final content = Container(
                    width: isLast ? null : columnWidths[index],
                    padding: EdgeInsets.symmetric(horizontal: isCheckboxCol ? 8 : 12, vertical: 12),
                    alignment: isCheckboxCol ? Alignment.center : Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: isLast ? Colors.transparent : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: headerWidget,
                  );
                  return isLast ? Expanded(child: content) : content;
                }),
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
            if (isShareMode)
              Column(
                children: List.generate(itemCount, (index) {
                  return Container(
                    key: ValueKey('share_row_$index'),
                    decoration: BoxDecoration(
                      color: AppColor.surface,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    child: rowBuilder(context, index),
                  );
                }),
              )
            else
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: itemCount,
                  onReorder: onReorder,
                  itemBuilder: (context, index) {
                    return Container(
                      key: ValueKey('row_$index'),
                      decoration: BoxDecoration(
                        color: AppColor.surface,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                      ),
                      child: rowBuilder(context, index),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowCells(
    List<String> cellValues,
    List<double> columnWidths, {
    List<Color>? textColors,
    List<FontWeight>? textWeights,
    bool isSelected = false,
    ValueChanged<bool?>? onSelectChanged,
    VoidCallback? onViewPressed,
    bool showCheckbox = false,
    bool showViewButton = false,
  }) {
    final prefixWidth = showViewButton ? 110.0 : 48.0;

    return Row(
      children: [
        if (showCheckbox)
          Container(
            width: prefixWidth,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isSelected,
                    activeColor: AppColor.primary,
                    onChanged: onSelectChanged,
                  ),
                ),
                if (showViewButton) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 26,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      onPressed: onViewPressed,
                      child: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ...List.generate(cellValues.length, (index) {
          final isFirstTextCol = index == 0;
          final currentWidth = index < columnWidths.length ? columnWidths[index] : null;
          final isLast = index == cellValues.length - 1;

          Widget cellText = Text(
            cellValues[index],
            style: TextStyle(
              color: isFirstTextCol && showViewButton
                  ? AppColor.primary
                  : (textColors != null && textColors.length > index ? textColors[index] : AppColor.textPrimary),
              fontWeight: isFirstTextCol && showViewButton
                  ? FontWeight.bold
                  : (textWeights != null && textWeights.length > index ? textWeights[index] : FontWeight.normal),
              decoration: isFirstTextCol && showViewButton ? TextDecoration.underline : TextDecoration.none,
              decorationColor: AppColor.primary,
            ),
          );

          if (cellValues[index].trim().isNotEmpty && cellValues[index].trim().toUpperCase() != 'N/A') {
            cellText = InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: cellValues[index]));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied ${cellValues[index]} to clipboard')));
              },
              child: cellText,
            );
          }

          final content = Container(
            width: isLast ? null : currentWidth,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: isLast ? Colors.transparent : Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: cellText,
          );
          return isLast ? Expanded(child: content) : content;
        }),
      ],
    );
  }

  Widget _buildOverallDesigns(ReportModel data) {
    final designs = data.overallDesigns;
    if (designs.isEmpty) return const Center(child: Text("No Overall Designs Data"));
    
    // We can use a ListView for designs
    return ListView.builder(
      itemCount: designs.length,
      itemBuilder: (context, index) {
        final category = designs[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          color: AppColor.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColor.border),
          ),
          child: ExpansionTile(
            title: Text(category.category, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Count: ${category.count}'),
            children: category.products.map((product) {
              return ListTile(
                leading: product.imageUrl != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(product.imageUrl!, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image_not_supported)),
                      )
                    : const Icon(Icons.inventory_2_outlined),
                title: Text('${product.designCode} - ${product.name}'),
                subtitle: Text('Weight: ${product.weightFrom} - ${product.weightTo}'),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCraftsmanFavorites(ReportModel data, {bool isRotated = false, bool forSharing = false, GlobalKey? repaintKey, List<int>? filterIndices}) {
    var favorites = data.craftsmanFavorites.cast<Favorite>().where((fav) {
      int total = 0;
      fav.categories.forEach((k, v) => total += v.products.length);
      return total > 0;
    }).toList();
    if (favorites.isEmpty) return const Center(child: Text("No Craftsman Favorites Data"));
    return _buildFavoritesTable(favorites, 'craftsman_favorites', isRotated ? null : (repaintKey ?? _craftsmanFavoritesKey), forSharing: forSharing, filterIndices: filterIndices);
  }

  Widget _buildBuyerFavorites(ReportModel data, {bool isRotated = false, bool forSharing = false, GlobalKey? repaintKey, List<int>? filterIndices}) {
    var favorites = data.buyerFavorites.cast<Favorite>().where((fav) {
      int total = 0;
      fav.categories.forEach((k, v) => total += v.products.length);
      return total > 0;
    }).toList();
    if (favorites.isEmpty) return const Center(child: Text("No Buyer Favorites Data"));
    return _buildFavoritesTable(favorites, 'buyer_favorites', isRotated ? null : (repaintKey ?? _buyerFavoritesKey), forSharing: forSharing, filterIndices: filterIndices);
  }

  Widget _buildFavoritesTable(List<Favorite> favorites, String type, GlobalKey? repaintKey, {bool forSharing = false, List<int>? filterIndices}) {
    var displayedFavs = favorites;
    if (filterIndices != null && filterIndices.isNotEmpty) {
      displayedFavs = [
        for (int i in filterIndices)
          if (i >= 0 && i < favorites.length) favorites[i]
      ];
    }
    final hiddenFields = _getHiddenFieldsFor(type);
    final role = SharedPreferencesHelper().getString("role")?.toLowerCase() ?? '';
    final isCraftsmanUser = role == 'craftsman' || role == 'craftsman_staff';
    final isBuyerUser = role == 'buyer' || role == 'key_user' || role == 'user';
    final bool showIdentity = !forSharing || (type == 'craftsman_favorites' && isCraftsmanUser) || (type == 'buyer_favorites' && isBuyerUser);

    final allHeaders = [
      if (showIdentity) 'Code',
      if (showIdentity) 'Name',
      'Total Products',
    ];
    final allColumnWidths = [
      if (showIdentity) 120.0,
      if (showIdentity) 200.0,
      150.0,
    ];

    final headers = <String>[];
    final columnWidths = <double>[];
    final activeColumnIndices = <int>[];

    for (int i = 0; i < allHeaders.length; i++) {
      if (!hiddenFields.contains(allHeaders[i]) || headers.isEmpty) {
        headers.add(allHeaders[i]);
        columnWidths.add(allColumnWidths[i]);
        activeColumnIndices.add(i);
      }
    }

    final selectedIndices = _selectedIndicesByTab[type] ?? <int>{};

    return _buildCustomTable(
      repaintKey: repaintKey,
      headers: headers,
      columnWidths: columnWidths,
      itemCount: displayedFavs.length,
      isShareMode: forSharing,
      tableKey: forSharing ? null : type,
      showActionColumn: !forSharing,
      onReorder: (oldIndex, newIndex) {
        // Reordering not implemented for favorites here
      },
      rowBuilder: (context, index) {
        final fav = displayedFavs[index];
        int totalProducts = 0;
        fav.categories.forEach((key, value) {
          totalProducts += value.products.length;
        });
        
        final allCellValues = [
          if (showIdentity) fav.code,
          if (showIdentity) fav.name,
          totalProducts.toString(),
        ];
        
        final cellValues = activeColumnIndices.map((i) => allCellValues[i]).toList();

        void openDetails() {
          Map<String, List<Product>> tabData = {};
          fav.categories.forEach((key, value) {
            if (value.products.isNotEmpty) {
              tabData[key] = value.products;
            }
          });
          Get.toNamed(AppRoutes.reportProducts, arguments: {
            'title': '${fav.name} Favorites',
            'tabData': tabData,
          });
        }

        return _buildRowCells(
          cellValues,
          columnWidths,
          showCheckbox: !forSharing,
          isSelected: selectedIndices.contains(index),
          onSelectChanged: (val) {
            setState(() {
              if (val == true) {
                (_selectedIndicesByTab[type] ??= <int>{}).add(index);
              } else {
                _selectedIndicesByTab[type]?.remove(index);
              }
            });
          },
          showViewButton: !forSharing,
          onViewPressed: openDetails,
        );
      },
    );
  }

  List<Order> _getAllCraftsmanWoOrders(TopPicksCraftsman craftsman) {
    List<Order> allOrders = [];
    if (craftsman.wo != null) {
      allOrders.addAll(craftsman.wo!.newOrders?.orders ?? []);
      allOrders.addAll(craftsman.wo!.allocated?.orders ?? []);
      allOrders.addAll(craftsman.wo!.inProcess?.orders ?? []);
      allOrders.addAll(craftsman.wo!.completed?.orders ?? []);
      allOrders.addAll(craftsman.wo!.overdue?.orders ?? []);
      allOrders.addAll(craftsman.wo!.forApproval?.orders ?? []);
    }
    return allOrders;
  }

  List<Order> _getAllCraftsmanPoOrders(TopPicksCraftsman craftsman) {
    List<Order> allOrders = [];
    if (craftsman.po != null) {
      allOrders.addAll(craftsman.po!.newOrders?.orders ?? []);
      allOrders.addAll(craftsman.po!.allocated?.orders ?? []);
      allOrders.addAll(craftsman.po!.inProcess?.orders ?? []);
      allOrders.addAll(craftsman.po!.completed?.orders ?? []);
      allOrders.addAll(craftsman.po!.overdue?.orders ?? []);
      allOrders.addAll(craftsman.po!.forApproval?.orders ?? []);
    }
    return allOrders;
  }
}

