import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:arianth/services/widget/enterprise_search_bar.dart';
import 'package:arianth/services/image_picker/image_picker_helper.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';
import 'package:arianth/app_color/app_color.dart';
import 'dart:convert';
import 'package:arianth/services/localization/app_localization.dart';
import '../riverpod/global_search_notifier.dart';
import '../model/gobal_search_model.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  PlatformFile? _selectedImage;
  
  int _currentIndex = 0;
  List<String> _orderedTabs = [];
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onScrollThresholdReached() {
    final searchState = ref.read(globalSearchProvider);
    if (!searchState.isLoading && !searchState.isFetchingMore && searchState.nextUrl != null) {
      final notifier = ref.read(globalSearchProvider.notifier);
      if (_selectedImage != null) {
        notifier.performImageSearch(_selectedImage!, isNext: true);
      } else if (_searchController.text.isNotEmpty) {
        notifier.performTextSearch(_searchController.text, isNext: true);
      }
    }
  }

  void _performSearch() {
    final notifier = ref.read(globalSearchProvider.notifier);
    
    if (_selectedImage != null) {
      notifier.performImageSearch(_selectedImage!);
    } else if (_searchController.text.isNotEmpty) {
      notifier.performTextSearch(_searchController.text);
    } else {
      notifier.clearSearch();
    }
  }

  Future<void> _pickImage() async {
    final images = await ImagePickerHelper.pickImages(context, allowMultiple: false);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImage = images.first;
      });
      _performSearch();
    }
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    FullScreenImageViewer.show(context, imageUrl);
  }

  List<String> _getItemImages(GlobalSearchModel item) {
    if (item.items == null) return [];
    final List<String> images = [];
    for (var prod in item.items!) {
      if (prod['image'] != null && prod['image'].toString().isNotEmpty) {
        images.add(prod['image'].toString());
      }
    }
    return images;
  }

  Widget _buildResultItem(GlobalSearchModel item) {
    final List<String> itemImages = _getItemImages(item);
    
    final leading = itemImages.isNotEmpty
        ? AutoSlidingImages(imageUrls: itemImages)
        : item.imageUrl != null 
            ? GestureDetector(
                onTap: () => _showFullImage(context, item.imageUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.imageUrl!, 
                    width: 50, 
                    height: 50, 
                    fit: BoxFit.cover, 
                    errorBuilder: (_,__,___) => const Icon(Icons.image_not_supported, color: AppColor.textHint),
                  ),
                ),
              )
            : const Icon(Icons.search, size: 40, color: AppColor.primary);

    final title = Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold));
    final subtitle = Text(
      '${item.type.replaceAll('_', ' ').toUpperCase()}${item.status != null ? ' • ${item.status}' : ''}${item.subtitle.isNotEmpty ? '\n${item.subtitle}' : ''}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12),
    );

    if (item.type == 'purchase_orders' && item.items != null && item.items!.isNotEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        color: AppColor.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColor.border),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: leading,
            title: title,
            subtitle: subtitle,
            children: item.items!.map((productItem) {
              return Padding(
                padding: const EdgeInsets.only(left: 70, right: 16, bottom: 12),
                child: Row(
                  children: [
                    if (productItem['image'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          productItem['image'], 
                          width: 40, 
                          height: 40, 
                          fit: BoxFit.cover, 
                          errorBuilder: (_,__,___) => const Icon(Icons.image_not_supported, size: 20)
                        ),
                      )
                    else
                      Container(
                        width: 40, 
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.inventory_2_outlined, size: 20, color: AppColor.textHint),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ref.watchTr('Design')}: ${productItem['design_code'] ?? 'N/A'}', 
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ref.watchTr('Qty')}: ${(productItem['quantity'] is List ? (productItem['quantity'] as List).first : productItem['quantity']) ?? '1'} • ${ref.watchTr('Total')}: ${productItem['total'] ?? ''}', 
                            style: const TextStyle(fontSize: 12, color: AppColor.textHint)
                          ),
                        ],
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: AppColor.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColor.border),
      ),
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  Widget _buildResultList(String type, GlobalSearchState searchState) {
    final filteredResults = searchState.searchResults.where((e) => e.type == type).toList();

    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColor.primary));
    }

    if (filteredResults.isEmpty) {
      return Center(
        child: Text(
          '${ref.watchTr('No')} ${ref.watchTr(type.replaceAll('_', ' '))} ${ref.watchTr('found')}',
          style: const TextStyle(color: AppColor.textHint),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
          _onScrollThresholdReached();
        }
        return false;
      },
      child: ListView.builder(
        itemCount: filteredResults.length + (searchState.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredResults.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator(color: AppColor.primary)),
            );
          }
          return _buildResultItem(filteredResults[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(globalSearchProvider);
    
    ref.listen<GlobalSearchState>(globalSearchProvider, (previous, next) {
      final availableTypes = next.searchResults.map((e) => e.type).toSet().toList();
      bool changed = false;
      
      for (var type in availableTypes) {
        if (!_orderedTabs.contains(type)) {
          _orderedTabs.add(type);
          changed = true;
        }
      }
      
      final toRemove = _orderedTabs.where((t) => !availableTypes.contains(t)).toList();
      if (toRemove.isNotEmpty) {
         for (var t in toRemove) {
           _orderedTabs.remove(t);
         }
         changed = true;
      }
      
      if (changed) {
        if (_currentIndex >= _orderedTabs.length && _orderedTabs.isNotEmpty) {
          _currentIndex = _orderedTabs.length - 1;
        } else if (_orderedTabs.isEmpty) {
          _currentIndex = 0;
        }
        setState(() {});
      }
    });

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1.0, color: Colors.white24),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(
          ref.watchTr('Global Search'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: EnterpriseSearchBar(
                    controller: _searchController,
                    hintText: ref.watchTr('Search anywhere...'),
                    onChanged: (value) {
                      _performSearch();
                    },
                    onCancel: () {
                      _searchController.clear();
                      _performSearch();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColor.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColor.border),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: AppColor.primary, size: 20),
                  ),
                ),
              ],
            ),
          ),
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Stack(
                  children: [
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColor.border),
                        image: DecorationImage(
                          image: FileImage(File(_selectedImage!.path!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                          });
                          _performSearch();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (searchState.isLoading && searchState.searchResults.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppColor.primary)))
          else if (searchState.searchResults.isEmpty)
            Expanded(child: Center(child: Text(ref.watchTr('No results found'), style: const TextStyle(color: AppColor.textHint))))
          else
            Expanded(
              child: Column(
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
                        final tabName = type.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
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
                              ref.watchTr(tabName),
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
                        return _buildResultList(type, searchState);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AutoSlidingImages extends StatefulWidget {
  final List<String> imageUrls;
  const AutoSlidingImages({super.key, required this.imageUrls});

  @override
  State<AutoSlidingImages> createState() => _AutoSlidingImagesState();
}

class _AutoSlidingImagesState extends State<AutoSlidingImages> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    if (widget.imageUrls.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.imageUrls.length;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(AutoSlidingImages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls.length != widget.imageUrls.length) {
      _timer?.cancel();
      _currentIndex = 0;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: () => FullScreenImageViewer.show(context, widget.imageUrls[_currentIndex]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Image.network(
            widget.imageUrls[_currentIndex],
            key: ValueKey(widget.imageUrls[_currentIndex]),
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_,__,___) => const Icon(Icons.image_not_supported, color: AppColor.textHint),
          ),
        ),
      ),
    );
  }
}

