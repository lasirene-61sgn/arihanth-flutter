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

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    title = args['title'] ?? 'Orders';
    
    if (args['nestedTabData'] != null) {
      isNested = true;
      final rawNested = Map<String, Map<String, List<Order>>>.from(args['nestedTabData']);
      for (var entry in rawNested.entries) {
        var subData = entry.value;
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareToWhatsApp() async {
    final GlobalKey? key = _tableKeys[_currentIndex];
    final boundary = key?.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot capture table.')));
      return;
    }
    
    try {
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

  Widget _buildTable(List<Order> orders, {bool isRotated = false, GlobalKey? repaintKey}) {
    final allHeaders = ['Number', 'Qty', 'Weight', 'BP Code', 'Business Name', 'Due Date', 'Craftsman Code', 'Craftsman Name', 'Overdue Days'];
    final allColumnWidths = [100.0, 80.0, 80.0, 100.0, 150.0, 120.0, 150.0, 150.0, 120.0];
    final copyableColumns = {'Number', 'BP Code', 'Business Name', 'Craftsman Code', 'Craftsman Name'};

    final isColumnEmpty = List.generate(allHeaders.length, (colIndex) {
      if (orders.isEmpty) return false;
      return orders.every((o) {
        String val = '';
        if (colIndex == 0) val = o.number;
        if (colIndex == 1) val = o.qty;
        if (colIndex == 2) val = o.weight.toString();
        if (colIndex == 3) val = o.bpCode;
        if (colIndex == 4) val = o.businessName;
        if (colIndex == 5) val = o.dueDate;
        if (colIndex == 6) val = o.craftsmanCode;
        if (colIndex == 7) val = o.craftsmanName;
        if (colIndex == 8) val = o.overdueDays.toString();
        return val.trim().isEmpty || val.trim().toUpperCase() == 'N/A' || val.trim() == 'NULL' || val.trim() == '-';
      });
    });

    final headers = <String>[];
    final columnWidths = <double>[];
    final activeColumnIndices = <int>[];

    for (int i = 0; i < allHeaders.length; i++) {
      if (!isColumnEmpty[i]) {
        headers.add(allHeaders[i]);
        columnWidths.add(allColumnWidths[i]);
        activeColumnIndices.add(i);
      }
    }

    final totalWidth = columnWidths.fold<double>(0, (a, b) => a + b);

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
                children: List.generate(headers.length, (index) {
                  final isLast = index == headers.length - 1;
                  final cellContent = Container(
                    width: isLast ? null : columnWidths[index],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                  return isLast ? Expanded(child: cellContent) : cellContent;
                }),
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
            Expanded(
              child: orders.isEmpty ? const Center(child: Text("No orders available")) : ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final o = orders[index];
                  final allCellValues = [
                    o.number,
                    o.qty,
                    o.weight.toString(),
                    o.bpCode,
                    o.businessName,
                    o.dueDate,
                    o.craftsmanCode,
                    o.craftsmanName,
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

                        final headerName = headers[colIndex];
                        final cellVal = cellValues[colIndex];
                        final isCopyable = copyableColumns.contains(headerName) && cellVal.isNotEmpty && cellVal.toUpperCase() != 'N/A';

                        if (isCopyable) {
                          cellText = InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: cellVal));
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied $cellVal to clipboard')));
                            },
                            child: cellText,
                          );
                        }

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
                },
              ),
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: isRotated || repaintKey == null ? content : RepaintBoundary(
        key: repaintKey,
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasTabs = tabNames.length > 1;
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
      body: hasTabs || isNested ? Column(
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
      ) : _buildTable(tabData[tabNames.first] ?? [], repaintKey: _tableKeys[0]),
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
