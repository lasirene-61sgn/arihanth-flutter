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

class ReportProductsScreen extends StatefulWidget {
  const ReportProductsScreen({super.key});

  @override
  State<ReportProductsScreen> createState() => _ReportProductsScreenState();
}

class _ReportProductsScreenState extends State<ReportProductsScreen> {
  late String title;
  late Map<String, List<Product>> tabData;
  late List<String> tabNames;
  final Map<int, GlobalKey> _tableKeys = {};
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    title = args['title'] ?? 'Products';
    
    if (args['tabData'] != null) {
      tabData = Map<String, List<Product>>.from(args['tabData']);
      tabData.removeWhere((key, value) => value.isEmpty);
      
      if (tabData.isEmpty) {
        tabData = {'Products': <Product>[]};
      }
    } else {
      tabData = {'Products': <Product>[]};
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

  Widget _buildTable(List<Product> products, {bool isRotated = false, GlobalKey? repaintKey}) {
    final allHeaders = ['Image', 'Design Code', 'Name', 'Weight From', 'Weight To'];
    final allColumnWidths = [80.0, 150.0, 200.0, 120.0, 120.0];
    final copyableColumns = {'Design Code', 'Name'};

    final isColumnEmpty = List.generate(allHeaders.length, (colIndex) {
      if (products.isEmpty) return false;
      return products.every((p) {
        if (colIndex == 0) return p.imageUrl == null || p.imageUrl!.isEmpty;
        
        String val = '';
        if (colIndex == 1) val = p.designCode;
        if (colIndex == 2) val = p.name;
        if (colIndex == 3) val = p.weightFrom.toString();
        if (colIndex == 4) val = p.weightTo.toString();
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
              child: products.isEmpty ? const Center(child: Text("No products available")) : ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColor.surface,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    child: Row(
                      children: List.generate(activeColumnIndices.length, (colIndex) {
                        final isLast = colIndex == activeColumnIndices.length - 1;
                        final actualIndex = activeColumnIndices[colIndex];
                        Widget innerContent;
                        String cellValForCopy = '';
                        
                        if (actualIndex == 0) {
                          innerContent = p.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(p.imageUrl!, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image_not_supported)),
                                )
                              : const Icon(Icons.inventory_2_outlined);
                        } else {
                          String textVal = '';
                          if (actualIndex == 1) textVal = p.designCode;
                          if (actualIndex == 2) textVal = p.name;
                          if (actualIndex == 3) textVal = p.weightFrom.toString();
                          if (actualIndex == 4) textVal = p.weightTo.toString();
                          
                          cellValForCopy = textVal;
                          innerContent = Text(textVal, style: const TextStyle(color: AppColor.textPrimary));
                        }

                        final headerName = headers[colIndex];
                        final isCopyable = copyableColumns.contains(headerName) && cellValForCopy.isNotEmpty && cellValForCopy.toUpperCase() != 'N/A';

                        if (isCopyable) {
                          innerContent = InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: cellValForCopy));
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied $cellValForCopy to clipboard')));
                            },
                            child: innerContent,
                          );
                        }

                        final cellContent = Container(
                          width: isLast ? null : columnWidths[colIndex],
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: isLast ? Colors.transparent : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          child: innerContent,
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
      body: hasTabs ? Column(
        children: [
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
    bool hasAnyProducts = tabData.values.any((list) => list.isNotEmpty);
    return [
          if (hasAnyProducts)
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
          if (hasAnyProducts)
            IconButton(
              icon: const Icon(Icons.screen_rotation),
              tooltip: 'Rotate Table',
              onPressed: () => _showRotatedTable(context),
            ),
    ];
  }
}
