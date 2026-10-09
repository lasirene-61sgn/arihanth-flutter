import 'package:arianth/screens/reports/model/report_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arianth/screens/reports/riverpod/report_notifier.dart';
import 'package:arianth/app_color/app_color.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';

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
    _pageController = PageController(initialPage: _currentIndex);
    Future.microtask(() => ref.read(reportProvider.notifier).fetchReportDetails());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatTabName(String type) {
    return type.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final currentTabType = _orderedTabs.isNotEmpty && _currentIndex < _orderedTabs.length 
        ? _orderedTabs[_currentIndex] 
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
    final GlobalKey key;
    if (tabType == 'top_picks_craftsman') key = _topPicksCraftsmanKey;
    else if (tabType == 'top_picks_client') key = _topPicksClientKey;
    else if (tabType == 'craftsman_favorites') key = _craftsmanFavoritesKey;
    else if (tabType == 'buyer_favorites') key = _buyerFavoritesKey;
    else return;
    
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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
          subject: _formatTabName(tabType),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing table: $e')));
      }
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
                final item = _orderedTabs.removeAt(oldIndex);
                _orderedTabs.insert(newIndex, item);
                
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
            children: _orderedTabs.map((type) {
              final isSelected = _orderedTabs.indexOf(type) == _currentIndex;
              return GestureDetector(
                key: ValueKey(type),
                onTap: () {
                  final index = _orderedTabs.indexOf(type);
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
            children: _orderedTabs.map((type) {
              return _buildTabContent(type, state.reportData!);
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

  Widget _buildTopPicksCraftsman(ReportModel data, {bool isRotated = false}) {
    final topPicks = data.topPicksCraftsman;
    if (topPicks.isEmpty) return const Center(child: Text("No Craftsman Data"));
    
    final headers = ['Code', 'Name', 'Allocated', 'In Process', 'Completed', 'Total Wt', 'WA Wt', 'PO Wt', 'Overdue', 'New Orders'];
    final columnWidths = [100.0, 150.0, 100.0, 110.0, 110.0, 100.0, 100.0, 100.0, 100.0, 120.0];

    return _buildCustomTable(
      repaintKey: isRotated ? null : _topPicksCraftsmanKey,
      headers: headers,
      columnWidths: columnWidths,
      itemCount: topPicks.length,
      onReorder: (oldIndex, newIndex) {
        ref.read(reportProvider.notifier).reorderTopPicksCraftsman(oldIndex, newIndex);
      },
      rowBuilder: (context, index) {
        final craftsman = topPicks[index];
        final isOverdue = craftsman.overdue > 0;
        final cellValues = [
          craftsman.code,
          craftsman.name,
          craftsman.allocated.toString(),
          craftsman.inProcess.toString(),
          craftsman.completed.toString(),
          craftsman.totalWeight.toString(),
          craftsman.waTotalWeight.toString(),
          craftsman.poTotalWeight.toString(),
          craftsman.overdue.toString(),
          craftsman.wo?.newOrders?.count.toString() ?? '0',
        ];
        
        final textColors = List<Color>.filled(10, AppColor.textPrimary);
        final textWeights = List<FontWeight>.filled(10, FontWeight.normal);
        if (isOverdue) {
          textColors[8] = Colors.red;
          textWeights[8] = FontWeight.bold;
        }

        return InkWell(
          onTap: () {
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
                  'Completed': wo?.completed?.orders ?? [],
                },
                'Purchase Orders (PO)': {
                  'New': po?.newOrders?.orders ?? [],
                  'Allocated': po?.allocated?.orders ?? [],
                  'In Process': po?.inProcess?.orders ?? [],
                  'For Approval': po?.forApproval?.orders ?? [],
                  'Overdue': po?.overdue?.orders ?? [],
                  'Completed': po?.completed?.orders ?? [],
                }
              },
            });
          },
          child: _buildRowCells(cellValues, columnWidths, textColors: textColors, textWeights: textWeights),
        );
      },
    );
  }

  Widget _buildTopPicksClient(ReportModel data, {bool isRotated = false}) {
    final topPicks = data.topPicksClient;
    if (topPicks.isEmpty) return const Center(child: Text("No Client Data"));
    
    final headers = ['Name', 'Orders', 'New Orders', 'In Process', 'For Approval', 'Overdue', 'Completed', 'Rejected'];
    final columnWidths = [150.0, 100.0, 120.0, 110.0, 120.0, 100.0, 110.0, 100.0];

    return _buildCustomTable(
      repaintKey: isRotated ? null : _topPicksClientKey,
      headers: headers,
      columnWidths: columnWidths,
      itemCount: topPicks.length,
      onReorder: (oldIndex, newIndex) {
        ref.read(reportProvider.notifier).reorderTopPicksClient(oldIndex, newIndex);
      },
      rowBuilder: (context, index) {
        final client = topPicks[index];
        final isOverdue = (client.overdue?.count ?? 0) > 0;
        final cellValues = [
          client.name,
          client.orders.toString(),
          client.newOrders?.count.toString() ?? '0',
          client.inProcess?.count.toString() ?? '0',
          client.forApproval?.count.toString() ?? '0',
          client.overdue?.count.toString() ?? '0',
          client.completed?.count.toString() ?? '0',
          client.rejected?.count.toString() ?? '0',
        ];
        
        final textColors = List<Color>.filled(8, AppColor.textPrimary);
        final textWeights = List<FontWeight>.filled(8, FontWeight.normal);
        if (isOverdue) {
          textColors[5] = Colors.red;
          textWeights[5] = FontWeight.bold;
        }

        return InkWell(
          onTap: () {
            Get.toNamed(AppRoutes.reportOrders, arguments: {
              'title': '${client.name} Orders',
              'tabData': {
                 'New': client.newOrders?.orders ?? [],
                 'In Process': client.inProcess?.orders ?? [],
                 'For Approval': client.forApproval?.orders ?? [],
                 'Overdue': client.overdue?.orders ?? [],
                 'Completed': client.completed?.orders ?? [],
                 'Rejected': client.rejected?.orders ?? [],
              },
            });
          },
          child: _buildRowCells(cellValues, columnWidths, textColors: textColors, textWeights: textWeights),
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
  }) {
    final totalWidth = columnWidths.fold<double>(0, (a, b) => a + b);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: repaintKey == null ? _buildTableContent(totalWidth, headers, columnWidths, itemCount, onReorder, rowBuilder) : RepaintBoundary(
        key: repaintKey,
        child: _buildTableContent(totalWidth, headers, columnWidths, itemCount, onReorder, rowBuilder),
      ),
    );
  }

  Widget _buildTableContent(double totalWidth, List<String> headers, List<double> columnWidths, int itemCount, void Function(int, int) onReorder, Widget Function(BuildContext, int) rowBuilder) {
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
                color: AppColor.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              ),
              child: Row(
                children: List.generate(headers.length, (index) {
                  final isLast = index == headers.length - 1;
                  final content = Container(
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
                  return isLast ? Expanded(child: content) : content;
                }),
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
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

  Widget _buildRowCells(List<String> cellValues, List<double> columnWidths, {List<Color>? textColors, List<FontWeight>? textWeights}) {
    return Row(
      children: List.generate(cellValues.length, (index) {
        final isLast = index == cellValues.length - 1;
        Widget cellText = Text(
          cellValues[index],
          style: TextStyle(
            color: textColors != null && textColors.length > index ? textColors[index] : AppColor.textPrimary,
            fontWeight: textWeights != null && textWeights.length > index ? textWeights[index] : FontWeight.normal,
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
          child: cellText,
        );
        return isLast ? Expanded(child: content) : content;
      }),
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

  Widget _buildCraftsmanFavorites(ReportModel data, {bool isRotated = false}) {
    var favorites = data.craftsmanFavorites.cast<Favorite>().where((fav) {
      int total = 0;
      fav.categories.forEach((k, v) => total += v.products.length);
      return total > 0;
    }).toList();
    if (favorites.isEmpty) return const Center(child: Text("No Craftsman Favorites Data"));
    return _buildFavoritesTable(favorites, 'craftsman_favorites', isRotated ? null : _craftsmanFavoritesKey);
  }

  Widget _buildBuyerFavorites(ReportModel data, {bool isRotated = false}) {
    var favorites = data.buyerFavorites.cast<Favorite>().where((fav) {
      int total = 0;
      fav.categories.forEach((k, v) => total += v.products.length);
      return total > 0;
    }).toList();
    if (favorites.isEmpty) return const Center(child: Text("No Buyer Favorites Data"));
    return _buildFavoritesTable(favorites, 'buyer_favorites', isRotated ? null : _buyerFavoritesKey);
  }

  Widget _buildFavoritesTable(List<Favorite> favorites, String type, GlobalKey? repaintKey) {
    final headers = ['Code', 'Name', 'Total Products'];
    final columnWidths = [120.0, 200.0, 150.0];

    return _buildCustomTable(
      repaintKey: repaintKey,
      headers: headers,
      columnWidths: columnWidths,
      itemCount: favorites.length,
      onReorder: (oldIndex, newIndex) {
        // Reordering not implemented for favorites here
      },
      rowBuilder: (context, index) {
        final fav = favorites[index];
        int totalProducts = 0;
        fav.categories.forEach((key, value) {
          totalProducts += value.products.length;
        });
        
        final cellValues = [
          fav.code,
          fav.name,
          totalProducts.toString(),
        ];
        
        return InkWell(
          onTap: () {
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
          },
          child: _buildRowCells(cellValues, columnWidths),
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

