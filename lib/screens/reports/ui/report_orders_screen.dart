import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/reports/model/report_model.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';

class ReportOrdersScreen extends StatefulWidget {
  const ReportOrdersScreen({super.key});

  @override
  State<ReportOrdersScreen> createState() => _ReportOrdersScreenState();
}

class _ReportOrdersScreenState extends State<ReportOrdersScreen> {
  late String title;
  late Map<String, List<Order>> tabData;
  late List<String> tabNames;
  
  bool isNested = false;
  Map<String, Map<String, List<Order>>> nestedTabData = {};
  List<String> topTabNames = [];
  int _topIndex = 0;
  
  final Map<int, GlobalKey> _tableKeys = {};
  int _currentIndex = 0;
  late PageController _pageController;
  List<String> _hiddenFields = [];
  final Map<int, Set<int>> _selectedOrdersByTab = {};

  String get role => (SharedPreferencesHelper().getString("role") ?? '').trim().toLowerCase();
  bool get isSuperAdmin => role == 'super_admin';
  bool get isCraftsmanUser => role == 'craftsman' || role == 'craftsman_staff';
  bool get isBuyerUser => role == 'buyer' || role == 'key_user' || role == 'user';

  List<String> get _allOrderFields => [
    'Number',
    'Qty',
    'Weight',
    if (!isCraftsmanUser) 'BP Code',
    if (!isCraftsmanUser) 'Business Name',
    'Due Date',
    if (!isCraftsmanUser && !isBuyerUser) 'Craftsman Code',
    if (!isCraftsmanUser && !isBuyerUser) 'Craftsman Name',
    'Overdue Days',
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomPreferences();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    title = args['title'] ?? 'Orders';

    if (args['nestedTabData'] != null) {
      isNested = true;
      final rawNested = Map<String, Map<String, List<Order>>>.from(args['nestedTabData']);
      for (var entry in rawNested.entries) {
        var subData = Map<String, List<Order>>.from(entry.value);
        if (!isSuperAdmin) {
          subData.remove('Completed');
        }
        subData.removeWhere((k, v) => v.isEmpty);
        if (subData.isNotEmpty) {
          nestedTabData[entry.key] = subData;
        }
      }
      
      if (nestedTabData.isEmpty) {
        nestedTabData = {'Orders': {'Orders': <Order>[]}};
      }
      
      topTabNames = nestedTabData.keys.toList();
      _topIndex = 0;
      tabData = nestedTabData[topTabNames[_topIndex]]!;
    } else if (args['tabData'] != null) {
      tabData = Map<String, List<Order>>.from(args['tabData']);
      if (!isSuperAdmin) {
        tabData.remove('Completed');
      }
      tabData.removeWhere((key, value) => value.isEmpty);
      if (tabData.isEmpty) {
        tabData = {'Orders': <Order>[]};
      }
    } else {
      List<Order> woOrders = args['woOrders'] ?? <Order>[];
      List<Order>? poOrders = args['poOrders'];
      if (poOrders != null && poOrders.isNotEmpty) {
        tabData = {
          if (woOrders.isNotEmpty) 'Work Orders (WO)': woOrders,
          'Purchase Orders (PO)': poOrders,
        };
      } else {
        tabData = {
          'Orders': woOrders,
        };
      }
      if (tabData.isEmpty) {
        tabData = {'Orders': <Order>[]};
      }
    }
    
    tabNames = tabData.keys.toList();
    for (int i = 0; i < tabNames.length; i++) {
      _tableKeys[i] = GlobalKey();
    }
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _loadCustomPreferences() {
    final hiddenFieldsStr = SharedPreferencesHelper().getString('reports_orders_fields_hidden');
    if (hiddenFieldsStr != null && hiddenFieldsStr.isNotEmpty) {
      try {
        _hiddenFields = List<String>.from(jsonDecode(hiddenFieldsStr));
      } catch (_) {
        _hiddenFields = [];
      }
    }
  }

  void _saveCustomPreferences() {
    SharedPreferencesHelper().setString('reports_orders_fields_hidden', jsonEncode(_hiddenFields));
  }

  void _showColumnSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.view_column_outlined, color: AppColor.primary, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Customize Order Fields',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColor.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Select which columns you want to view in this table',
                        style: TextStyle(fontSize: 13, color: AppColor.textHint),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _allOrderFields.length,
                          itemBuilder: (context, index) {
                            final field = _allOrderFields[index];
                            final isVisible = !_hiddenFields.contains(field);
                            final visibleCount = _allOrderFields.length - _hiddenFields.length;

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
                                      if (value) {
                                        _hiddenFields.remove(field);
                                      } else {
                                        if (!_hiddenFields.contains(field)) {
                                          _hiddenFields.add(field);
                                        }
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareToWhatsApp() async {
    final currentOrders = tabData[tabNames.length > _currentIndex ? tabNames[_currentIndex] : tabNames.first] ?? [];
    if (currentOrders.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No orders to share.')));
      return;
    }

    final selected = _selectedOrdersByTab[_currentIndex];
    final ordersToShare = (selected != null && selected.isNotEmpty)
        ? [for (int i = 0; i < currentOrders.length; i++) if (selected.contains(i)) currentOrders[i]]
        : currentOrders;

    OverlayEntry? entry;
    final shareKey = GlobalKey();

    try {
      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -99999,
          top: -99999,
          child: Material(
            color: Colors.transparent,
            child: _buildTable(ordersToShare, forSharing: true, repaintKey: shareKey),
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
          subject: title,
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

  void _showRotatedTable(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: AppColor.background,
          body: SafeArea(
            child: RotatedBox(
              quarterTurns: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 48.0),
                      child: _buildTable(
                        tabData[tabNames[_currentIndex]] ?? [],
                        isRotated: true,
                      ),
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
        ),
      ),
    );
  }

  Widget _buildTable(List<Order> orders, {bool isRotated = false, GlobalKey? repaintKey, bool forSharing = false}) {
    // In orders table:
    // - If craftsman is logged in, hide Buyer info (BP Code / Business Name) AND hide Craftsman columns (it's already their orders screen)
    // - If buyer is logged in, hide Craftsman info AND hide Buyer columns
    // - Only admin / super_admin sees BP Code and Craftsman Code
    final bool showBpInfo = !isCraftsmanUser && !isBuyerUser && !forSharing;
    final bool showCraftsmanInfo = !isCraftsmanUser && !isBuyerUser && !forSharing;

    final allHeaders = [
      'Number',
      'Qty',
      'Weight',
      if (showBpInfo) 'BP Code',
      if (showBpInfo) 'Business Name',
      'Due Date',
      if (showCraftsmanInfo) 'Craftsman Code',
      if (showCraftsmanInfo) 'Craftsman Name',
      'Overdue Days',
    ];
    final allColumnWidths = [
      100.0,
      80.0,
      80.0,
      if (showBpInfo) 100.0,
      if (showBpInfo) 150.0,
      120.0,
      if (showCraftsmanInfo) 150.0,
      if (showCraftsmanInfo) 150.0,
      120.0,
    ];

    final isColumnEmpty = List.generate(allHeaders.length, (colIndex) {
      if (orders.isEmpty) return false;
      return orders.every((o) {
        String val = '';
        final header = allHeaders[colIndex];
        if (header == 'Number') val = o.number;
        if (header == 'Qty') val = o.qty;
        if (header == 'Weight') val = o.weight == 0 ? '' : o.weight.toString();
        if (header == 'BP Code') val = o.bpCode;
        if (header == 'Business Name') val = o.businessName;
        if (header == 'Due Date') val = o.dueDate;
        if (header == 'Craftsman Code') val = o.craftsmanCode;
        if (header == 'Craftsman Name') val = o.craftsmanName;
        if (header == 'Overdue Days') val = o.overdueDays.toString();
        return val.trim().isEmpty || val.trim().toUpperCase() == 'N/A' || val.trim() == 'NULL' || val.trim() == '-';
      });
    });

    final headers = <String>[];
    final columnWidths = <double>[];
    final activeColumnIndices = <int>[];

    for (int i = 0; i < allHeaders.length; i++) {
      if (!isColumnEmpty[i] && (!_hiddenFields.contains(allHeaders[i]) || headers.isEmpty)) {
        headers.add(allHeaders[i]);
        columnWidths.add(allColumnWidths[i]);
        activeColumnIndices.add(i);
      }
    }

    final totalWidth = columnWidths.fold<double>(0, (a, b) => a + b) + (!forSharing ? 48.0 : 0.0);

    final selectedIndices = _selectedOrdersByTab[_currentIndex] ?? <int>{};
    final bool allSelected = orders.isNotEmpty && selectedIndices.length == orders.length;

    Widget content = Container(
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
                color: AppColor.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  if (!forSharing)
                    Container(
                      width: 48,
                      alignment: Alignment.center,
                      child: Checkbox(
                        value: allSelected,
                        activeColor: AppColor.primary,
                        tristate: selectedIndices.isNotEmpty && !allSelected,
                        onChanged: (bool? val) {
                          setState(() {
                            if (allSelected) {
                              _selectedOrdersByTab[_currentIndex] = <int>{};
                            } else {
                              _selectedOrdersByTab[_currentIndex] = Set<int>.from(List.generate(orders.length, (i) => i));
                            }
                          });
                        },
                      ),
                    ),
                  ...List.generate(headers.length, (index) {
                    final isLast = index == headers.length - 1;
                    final cellContent = Container(
                      width: isLast ? null : columnWidths[index],
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: isLast ? Colors.transparent : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        headers[index],
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                    return isLast ? Expanded(child: cellContent) : cellContent;
                  }),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
            if (forSharing)
              Column(
                children: orders.map((o) {
                  final allCellValues = [
                    o.number,
                    o.qty,
                    o.weight.toString(),
                    if (showBpInfo) o.bpCode,
                    if (showBpInfo) o.businessName,
                    o.dueDate,
                    if (showCraftsmanInfo) o.craftsmanCode,
                    if (showCraftsmanInfo) o.craftsmanName,
                    o.overdueDays.toString(),
                  ];
                  
                  final cellValues = activeColumnIndices.map((i) => allCellValues[i]).toList();
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColor.surface,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    child: Row(
                      children: List.generate(cellValues.length, (colIndex) {
                        final isLast = colIndex == cellValues.length - 1;
                        Widget cellText = Text(
                          cellValues[colIndex],
                          style: const TextStyle(
                            color: AppColor.textPrimary,
                          ),
                        );

                        final cellContent = Container(
                          width: isLast ? null : columnWidths[colIndex],
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
                        return isLast ? Expanded(child: cellContent) : cellContent;
                      }),
                    ),
                  );
                }).toList(),
              )
            else
              Expanded(
                child: orders.isEmpty ? const Center(child: Text("No orders available")) : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final o = orders[index];
                    final isChecked = selectedIndices.contains(index);
                    final allCellValues = [
                      o.number,
                      o.qty,
                      o.weight.toString(),
                      if (showBpInfo) o.bpCode,
                      if (showBpInfo) o.businessName,
                      o.dueDate,
                      if (showCraftsmanInfo) o.craftsmanCode,
                      if (showCraftsmanInfo) o.craftsmanName,
                      o.overdueDays.toString(),
                    ];
                    
                    final cellValues = activeColumnIndices.map((i) => allCellValues[i]).toList();
                    return Container(
                      decoration: BoxDecoration(
                        color: isChecked ? AppColor.primary.withOpacity(0.04) : AppColor.surface,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            alignment: Alignment.center,
                            child: Checkbox(
                              value: isChecked,
                              activeColor: AppColor.primary,
                              onChanged: (bool? val) {
                                setState(() {
                                  _selectedOrdersByTab.putIfAbsent(_currentIndex, () => <int>{});
                                  if (val == true) {
                                    _selectedOrdersByTab[_currentIndex]!.add(index);
                                  } else {
                                    _selectedOrdersByTab[_currentIndex]!.remove(index);
                                  }
                                });
                              },
                            ),
                          ),
                          ...List.generate(cellValues.length, (colIndex) {
                            final isLast = colIndex == cellValues.length - 1;
                            Widget cellText = Text(
                              cellValues[colIndex],
                              style: const TextStyle(
                                color: AppColor.textPrimary,
                              ),
                            );

                            final cellContent = Container(
                              width: isLast ? null : columnWidths[colIndex],
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
                            return isLast ? Expanded(child: cellContent) : cellContent;
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );

    if (forSharing) {
      return repaintKey == null
          ? content
          : RepaintBoundary(
              key: repaintKey,
              child: content,
            );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: isRotated || repaintKey == null
          ? content
          : RepaintBoundary(
              key: repaintKey,
              child: content,
            ),
    );
  }

  Widget _buildBody(bool hasTabs) {
    return hasTabs || isNested ? Column(
      children: [
        if (isNested && topTabNames.length > 1)
          Container(
            height: 48,
            color: AppColor.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(topTabNames.length, (index) {
                  return _buildTopTabItem(topTabNames[index], index);
                }),
              ),
            ),
          ),
        if (tabNames.length > 1)
          SizedBox(
            height: 48,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(tabNames.length, (index) {
                  return _buildTabItem(tabNames[index], index);
                }),
              ),
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
            children: List.generate(tabNames.length, (index) {
              return _buildTable(tabData[tabNames[index]] ?? [], repaintKey: _tableKeys[index]);
            }),
          ),
        ),
      ],
    ) : _buildTable(tabData[tabNames.first] ?? [], repaintKey: _tableKeys[0]);
  }

  @override
  Widget build(BuildContext context) {
    final hasTabs = tabNames.length > 1;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: _buildActions(),
      ),
      body: _buildBody(hasTabs),
    );
  }

  Widget _buildTopTabItem(String text, int index) {
    final isSelected = _topIndex == index;
    return GestureDetector(
      onTap: () {
        if (_topIndex == index) return;
        setState(() {
          _topIndex = index;
          tabData = nestedTabData[topTabNames[_topIndex]]!;
          tabNames = tabData.keys.toList();
          _currentIndex = 0;
          _pageController.jumpToPage(0);
          
          _tableKeys.clear();
          for (int i = 0; i < tabNames.length; i++) {
            _tableKeys[i] = GlobalKey();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primary.withOpacity(0.05) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColor.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? AppColor.primary : AppColor.textHint,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(String text, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
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
          text,
          style: TextStyle(
            color: isSelected ? AppColor.primary : AppColor.textHint,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions() {
    bool hasAnyOrders = tabData.values.any((list) => list.isNotEmpty);
    return [
          if (hasAnyOrders)
            IconButton(
              icon: const Icon(Icons.view_column_outlined),
              tooltip: 'Customize Columns',
              onPressed: _showColumnSelectionSheet,
            ),
          if (hasAnyOrders)
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
              onPressed: _shareToWhatsApp,
            ),
          if (hasAnyOrders)
            IconButton(
              icon: const Icon(Icons.screen_rotation),
              tooltip: 'Rotate Table',
              onPressed: () => _showRotatedTable(context),
            ),
    ];
  }
}
