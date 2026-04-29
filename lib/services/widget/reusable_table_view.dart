import 'package:flutter/material.dart';
import 'package:arianth/app_color/app_color.dart'; // 👈 Import brand colors

// 👇 Adjust these imports based on your exact folder structure
import 'package:arianth/services/widget/reusable_file_picker.dart';
import 'reusable_full_screen_view.dart';

/// ⚙️ Configuration for table columns
class TableColumnConfig {
  final String header;
  final int flex;
  final bool isSticky;
  final Widget Function(dynamic item)? cellBuilder;
  final String Function(dynamic item)? valueGetter;
  final double? width;

  // 👇 Added property for default image handling
  final KycDocument? Function(dynamic item)? imageDocGetter;

  const TableColumnConfig({
    required this.header,
    this.flex = 1,
    this.isSticky = false,
    this.cellBuilder,
    this.valueGetter,
    this.width,
    this.imageDocGetter,
  });
}

/// 📊 Reusable Data Table Widget with responsive grid/table support
class ReusableDataTable<T> extends StatefulWidget {
  final List<T> items;
  final List<TableColumnConfig> columns;
  final bool enableSelection;
  final Set<String> selectedIds;
  final Function(Set<String>)? onSelectionChanged;
  final String Function(T item) getItemId;
  final bool stickyCheckbox;
  final bool stickyFirstColumn;
  final bool isLoading;
  final String? error;
  final Widget? emptyStateWidget;
  final Widget? loadingWidget;
  final Color? headerColor;
  final Color? selectedRowColor;
  final Color? rowHoverColor;
  final double borderRadius;
  final double elevation;
  final Function(T item)? onRowTap;
  final double minTableWidth;
  final double rowHeight;
  final double headerHeight;
  final Color? Function(T item)? rowColorGetter;

  const ReusableDataTable({
    Key? key,
    required this.items,
    required this.columns,
    required this.getItemId,
    this.enableSelection = true,
    this.selectedIds = const {},
    this.onSelectionChanged,
    this.stickyCheckbox = false,
    this.stickyFirstColumn = false,
    this.isLoading = false,
    this.error,
    this.emptyStateWidget,
    this.loadingWidget,
    this.headerColor,
    this.selectedRowColor,
    this.rowHoverColor,
    this.borderRadius = 12,
    this.elevation = 0,
    this.onRowTap,
    this.minTableWidth = 1400,
    this.rowHeight = 64,
    this.headerHeight = 56,
    this.rowColorGetter,
  }) : super(key: key);

  @override
  State<ReusableDataTable<T>> createState() => _ReusableDataTableState<T>();
}

class _ReusableDataTableState<T> extends State<ReusableDataTable<T>> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _stickyVerticalController = ScrollController();
  String? _hoveredRowId;

  @override
  void initState() {
    super.initState();
    _verticalController.addListener(_syncVerticalScroll);
    _stickyVerticalController.addListener(_syncVerticalScroll);
    _horizontalController.addListener(_syncHorizontalScroll);
    _headerHorizontalController.addListener(_syncHorizontalScroll);
  }

  void _syncVerticalScroll() {
    if (_verticalController.hasClients &&
        _stickyVerticalController.hasClients) {
      if (_verticalController.position.isScrollingNotifier.value) {
        if (_verticalController.offset != _stickyVerticalController.offset) {
          _stickyVerticalController.jumpTo(_verticalController.offset);
        }
      } else if (_stickyVerticalController.position.isScrollingNotifier.value) {
        if (_stickyVerticalController.offset != _verticalController.offset) {
          _verticalController.jumpTo(_stickyVerticalController.offset);
        }
      }
    }
  }

  void _syncHorizontalScroll() {
    if (_horizontalController.hasClients &&
        _headerHorizontalController.hasClients) {
      if (_horizontalController.offset != _headerHorizontalController.offset) {
        if (_horizontalController.position.isScrollingNotifier.value) {
          _headerHorizontalController.jumpTo(_horizontalController.offset);
        } else if (_headerHorizontalController
            .position
            .isScrollingNotifier
            .value) {
          _horizontalController.jumpTo(_headerHorizontalController.offset);
        }
      }
    }
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    _stickyVerticalController.dispose();
    _headerHorizontalController.dispose();
    super.dispose();
  }

  // ============== View Getters =============
  // ⭐️ UPDATED: Card view threshold increased to 950px
  bool get _isMobileLayout {
    return MediaQuery.of(context).size.width < 950;
  }

  bool get _isCompactView {
    return MediaQuery.of(context).size.width < 1200;
  }

  // =========================================

  // --- Selection Helper Methods ---
  bool _getSelectAllValue() {
    if (widget.items.isEmpty) return false;
    return widget.items.every(
          (item) => widget.selectedIds.contains(widget.getItemId(item)),
    );
  }

  void _handleSelectAll(bool value) {
    if (widget.onSelectionChanged == null) return;
    if (value) {
      final allIds = widget.items.map(widget.getItemId).toSet();
      widget.onSelectionChanged!(allIds);
    } else {
      widget.onSelectionChanged!({});
    }
  }

  void _handleRowCheckbox(String id, bool value) {
    if (widget.onSelectionChanged == null) return;
    final newSelection = Set<String>.from(widget.selectedIds);
    if (value) {
      newSelection.add(id);
    } else {
      newSelection.remove(id);
    }
    widget.onSelectionChanged!(newSelection);
  }

  void _handleRowTap(T item) {
    final id = widget.getItemId(item);
    if (widget.enableSelection && widget.onSelectionChanged != null) {
      final newSelection = Set<String>.from(widget.selectedIds);
      if (newSelection.contains(id)) {
        newSelection.remove(id);
      } else {
        newSelection.add(id);
      }
      widget.onSelectionChanged!(newSelection);
    }
    widget.onRowTap?.call(item);
  }

  // --- Column & Width Calculations ---
  List<TableColumnConfig> get _stickyColumns {
    final sticky = <TableColumnConfig>[];
    for (var col in widget.columns) {
      if (col.isSticky) {
        sticky.add(col);
      }
    }
    if (widget.stickyFirstColumn &&
        widget.columns.isNotEmpty &&
        !widget.columns.first.isSticky) {
      if (!sticky.contains(widget.columns.first)) {
        sticky.insert(0, widget.columns.first);
      }
    }
    return sticky;
  }

  List<TableColumnConfig> get _scrollableColumns {
    final stickyHeaders = _stickyColumns.map((e) => e.header).toSet();
    return widget.columns
        .where((col) => !stickyHeaders.contains(col.header))
        .toList();
  }

  double get _stickyWidth {
    double width = 0;
    if (widget.enableSelection && widget.stickyCheckbox) {
      width += _isCompactView ? 60 : 85;
    }
    for (var col in _stickyColumns) {
      width += col.width ?? (_isCompactView ? 120 : 180);
    }
    return width;
  }

  bool get _hasSticky =>
      (widget.enableSelection && widget.stickyCheckbox) ||
          _stickyColumns.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.items.isEmpty) {
      return widget.loadingWidget ??
          const Padding(
            padding: EdgeInsets.all(60),
            child: Center(child: CircularProgressIndicator()),
          );
    }

    if (widget.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: Text(
            'Error: ${widget.error}',
            style: const TextStyle(color: AppColor.error, fontSize: 15),
          ),
        ),
      );
    }

    if (widget.items.isEmpty) {
      return widget.emptyStateWidget ?? _buildDefaultEmptyState();
    }

    final content = _isMobileLayout ? _buildMobileView() : _buildTableView();

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: _isMobileLayout
            ? null
            : BoxDecoration(
          color: AppColor.transparent, // Background handled by Scaffold
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: AppColor.divider, width: 1),
        ),
        child: content,
      ),
    );
  }

  Widget _buildTableView() {
    return _hasSticky ? _buildSplitTable() : _buildFullScrollableTable();
  }

  Widget _buildFullScrollableTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = _isCompactView
            ? constraints.maxWidth
            : widget.minTableWidth;
        final headerHeight = _isCompactView ? 40 : widget.headerHeight;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: double.parse(headerHeight.toString()).toDouble(),
              decoration: BoxDecoration(
                color: widget.headerColor ?? AppColor.tableHeader,
                border: Border(
                  bottom: BorderSide(color: AppColor.divider, width: 1),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _headerHorizontalController,
                child: SizedBox(
                  width: tableWidth,
                  child: _buildHeader(includeSelection: widget.enableSelection),
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                controller: _verticalController,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _horizontalController,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: widget.items
                          .map(
                            (item) => _buildRow(
                          item,
                          includeSelection: widget.enableSelection,
                        ),
                      )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSplitTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final requiredRightWidth = widget.minTableWidth - _stickyWidth;
        final rightSideWidth =
        (requiredRightWidth > constraints.maxWidth - _stickyWidth)
            ? requiredRightWidth
            : constraints.maxWidth - _stickyWidth;
        final headerHeight = _isCompactView ? 40 : widget.headerHeight;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: _stickyWidth,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppColor.divider, width: 0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStickyHeader(),
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      controller: _stickyVerticalController,
                      child: Column(
                        children: widget.items
                            .map((item) => _buildStickyRow(item))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: double.parse(headerHeight.toString()).toDouble(),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: widget.headerColor ?? AppColor.tableHeader,
                      border: Border(
                        bottom: BorderSide(color: AppColor.divider, width: 1),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _headerHorizontalController,
                      child: SizedBox(
                        width: rightSideWidth,
                        child: _buildScrollableHeader(),
                      ),
                    ),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _horizontalController,
                        child: SizedBox(
                          width: rightSideWidth,
                          child: Column(
                            children: widget.items
                                .map((item) => _buildScrollableRow(item))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Logic: Above 500px show 2 columns, otherwise 1.
        double spacing = 12.0;
        double cardWidth = constraints.maxWidth > 500
            ? (constraints.maxWidth - spacing - 8) / 2
            : constraints.maxWidth;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Wrap(
            spacing: spacing, // Horizontal spacing between cards
            runSpacing: spacing, // Vertical spacing between rows
            children: widget.items.map((item) {
              final id = widget.getItemId(item);
              final isSelected = widget.selectedIds.contains(id);

              return SizedBox(
                width: cardWidth,
                child: _MobileItemCard<T>(
                  item: item,
                  columns: widget.columns,
                  isSelected: isSelected,
                  enableSelection: widget.enableSelection,
                  onTap: () => _handleRowTap(item),
                  onToggleSelection: (value) => _handleRowCheckbox(id, value),
                  selectedColor:
                  widget.selectedRowColor?.withOpacity(0.5) ??
                      AppColor.primary.withOpacity(0.05),
                  buildCell: _buildCell,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool includeSelection}) {
    final padding = _isCompactView ? 16.0 : 24.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Row(
        children: [
          if (includeSelection) ...[
            SizedBox(
              width: 26,
              height: 26,
              child: Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: _getSelectAllValue(),
                  onChanged: (value) => _handleSelectAll(value ?? false),
                  side: const BorderSide(color: AppColor.black, width: 1.5),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            SizedBox(width: _isCompactView ? 8 : 16),
          ],
          ...widget.columns.map(
                (col) =>
                Expanded(flex: col.flex, child: _buildHeaderCell(col.header)),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyHeader() {
    final padding = _isCompactView ? 16.0 : 24.0;
    return Container(
      decoration: BoxDecoration(
        color: widget.headerColor ?? AppColor.tableHeader,
        border: Border(
          bottom: BorderSide(color: AppColor.divider, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      height: _isCompactView ? 40 : widget.headerHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Row(
          children: [
            if (widget.enableSelection && widget.stickyCheckbox) ...[
              SizedBox(
                width: 26,
                height: 26,
                child: Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: _getSelectAllValue(),
                    onChanged: (value) => _handleSelectAll(value ?? false),
                    side: const BorderSide(color: AppColor.black, width: 1.5),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              SizedBox(width: _isCompactView ? 8 : 16),
            ],
            ..._stickyColumns.map(
                  (col) => SizedBox(
                width: col.width ?? (_isCompactView ? 120 : 180),
                child: _buildHeaderCell(col.header),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableHeader() {
    final padding = _isCompactView ? 16.0 : 24.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Row(
        children: _scrollableColumns
            .map(
              (col) =>
              Expanded(flex: col.flex, child: _buildHeaderCell(col.header)),
        )
            .toList(),
      ),
    );
  }

  Widget _buildRow(T item, {required bool includeSelection}) {
    final id = widget.getItemId(item);
    final isSelected = widget.selectedIds.contains(id);
    final isHovered = _hoveredRowId == id;
    final padding = _isCompactView ? 16.0 : 24.0;
    final rowHeight = _isCompactView ? 48.0 : widget.rowHeight;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowId = id),
      onExit: (_) => setState(() => _hoveredRowId = null),
      child: InkWell(
        onTap: () => _handleRowTap(item),
        child: Container(
          height: rowHeight,
          decoration: BoxDecoration(
            color: _getRowColor(isSelected, isHovered, item),
            border: Border(
              bottom: BorderSide(color: AppColor.divider, width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Row(
            children: [
              if (includeSelection) ...[
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (val) => _handleRowCheckbox(id, val ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                SizedBox(width: _isCompactView ? 8 : 16),
              ],
              ...widget.columns.map(
                    (col) => Expanded(flex: col.flex, child: _buildCell(item, col)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickyRow(T item) {
    final id = widget.getItemId(item);
    final isSelected = widget.selectedIds.contains(id);
    final isHovered = _hoveredRowId == id;
    final padding = _isCompactView ? 16.0 : 24.0;
    final rowHeight = _isCompactView ? 48.0 : widget.rowHeight;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowId = id),
      onExit: (_) => setState(() => _hoveredRowId = null),
      child: InkWell(
        onTap: () => _handleRowTap(item),
        child: Container(
          height: rowHeight,
          decoration: BoxDecoration(
            color: _getRowColor(isSelected, isHovered, item),
            border: Border(
              bottom: BorderSide(color: AppColor.divider, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Row(
            children: [
              if (widget.enableSelection && widget.stickyCheckbox) ...[
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (val) => _handleRowCheckbox(id, val ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                SizedBox(width: _isCompactView ? 8 : 16),
              ],
              ..._stickyColumns.map(
                    (col) => SizedBox(
                  width: col.width ?? (_isCompactView ? 120 : 180),
                  child: _buildCell(item, col),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableRow(T item) {
    final id = widget.getItemId(item);
    final isSelected = widget.selectedIds.contains(id);
    final isHovered = _hoveredRowId == id;
    final padding = _isCompactView ? 16.0 : 24.0;
    final rowHeight = _isCompactView ? 48.0 : widget.rowHeight;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowId = id),
      onExit: (_) => setState(() => _hoveredRowId = null),
      child: InkWell(
        onTap: () => _handleRowTap(item),
        child: Container(
          height: rowHeight,
          decoration: BoxDecoration(
            color: _getRowColor(isSelected, isHovered, item),
            border: Border(
              bottom: BorderSide(color: AppColor.divider, width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Row(
            children: _scrollableColumns
                .map(
                  (col) =>
                  Expanded(flex: col.flex, child: _buildCell(item, col)),
            )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColor.textPrimary,
          fontSize: _isCompactView ? 12 : 14,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCell(T item, TableColumnConfig column) {
    final fontSize = _isCompactView ? 13.0 : 14.0;

    // 🌟 1. DEFAULT IMAGE HANDLING LOGIC
    if (column.imageDocGetter != null) {
      final doc = column.imageDocGetter!(item);

      // Check if image data actually exists and is not null/empty
      final bool hasData = doc != null && (
          (doc.networkUrl != null && doc.networkUrl!.isNotEmpty) ||
              doc.file != null ||
              doc.bytes != null
      );

      Widget imageWidget;
      if (!hasData) {
        imageWidget = const Center(
          child: Icon(Icons.image_not_supported, color: AppColor.textHint, size: 20),
        );
      } else if (doc.bytes != null) {
        imageWidget = Image.memory(doc.bytes!, fit: BoxFit.cover);
      } else if (doc.file != null) {
        imageWidget = Image.file(doc.file!, fit: BoxFit.cover);
      } else {
        imageWidget = Image.network(
          doc.networkUrl!,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: AppColor.textHint, size: 20),
        );
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Only open full screen if it's not null/empty
          if (hasData) {
            FileViewerUtil.showFullScreenImage(context, doc, column.header);
          }
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 40,
            height: 40,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColor.divider),
            ),
            child: imageWidget,
          ),
        ),
      );
    }

    // 2. STANDARD TEXT/CUSTOM WIDGET HANDLING
    if (column.cellBuilder != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: column.cellBuilder!(item),
      );
    }

    if (column.valueGetter != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          column.valueGetter!(item),
          style: TextStyle(
            fontSize: fontSize,
            color: AppColor.textPrimary,
            fontWeight: FontWeight.w400,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Text('-', style: TextStyle(fontSize: fontSize)),
    );
  }

  Color _getRowColor(bool isSelected, bool isHovered, T item) {
    if (widget.rowColorGetter != null) {
      final customColor = widget.rowColorGetter!(item);
      if (customColor != null) return customColor;
    }
    if (isSelected) return widget.selectedRowColor ?? AppColor.primary.withOpacity(0.1);
    if (isHovered) return widget.rowHoverColor ?? AppColor.surface;
    return AppColor.transparent; // Allow Scaffold background
  }

  Widget _buildDefaultEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 72, color: AppColor.textHint),
          const SizedBox(height: 24),
          const Text(
            'No data found',
            style: TextStyle(
              fontSize: 20,
              color: AppColor.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'There are no items to display',
            style: TextStyle(fontSize: 15, color: AppColor.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------
// **MOBILE CARD WIDGET: REVERSED LAYOUT WITH IMAGE ON RIGHT**
// -------------------------------------------------------
class _MobileItemCard<T> extends StatelessWidget {
  final T item;
  final List<TableColumnConfig> columns;
  final bool isSelected;
  final bool enableSelection;
  final VoidCallback? onTap;
  final Function(bool)? onToggleSelection;
  final Color selectedColor;
  final Widget Function(T item, TableColumnConfig column) buildCell;

  const _MobileItemCard({
    required this.item,
    required this.columns,
    required this.isSelected,
    required this.enableSelection,
    this.onTap,
    this.onToggleSelection,
    required this.selectedColor,
    required this.buildCell,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Identify the Image Column (GST/Image or imageDocGetter)
    final imageColumn = columns.firstWhere(
          (col) =>
      col.imageDocGetter != null || // Easily identify our new image columns
          col.header.toLowerCase() == 'image' ||
          col.header.toLowerCase() == 'gst',
      orElse: () => columns.first,
    );

    // 2. Identify the Primary Text Column
    final primaryColumn = columns.firstWhere(
          (col) => col != imageColumn,
      orElse: () => columns.first,
    );

    // 3. Remaining columns for the details section
    final secondaryColumns = columns
        .where((col) => col != primaryColumn && col != imageColumn)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: isSelected 
             ? selectedColor 
             : AppColor.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColor.primary.withOpacity(0.5)
              : AppColor.divider.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP ROW: Checkbox, Name/ID, and Image on the right
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (enableSelection)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isSelected,
                          activeColor: AppColor.primary,
                             checkColor: AppColor.textWhite,
                          onChanged: (v) => onToggleSelection?.call(v ?? false),
                        ),
                      ),
                    ),
                  Expanded(child: buildCell(item, primaryColumn)),
                  const SizedBox(width: 12),
                  // The image column already handles its own container formatting now
                  // but we wrap it in a clean size box for the mobile card layout
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: buildCell(item, imageColumn),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColor.textSecondary,
                ),
              ),

              Column(
                children: [
                  ...List.generate(
                    (secondaryColumns.length / 2).ceil(), // Calculate how many rows of 2 we need
                        (rowIndex) {
                      final firstIndex = rowIndex * 2;
                      final secondIndex = firstIndex + 1;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: rowIndex == (secondaryColumns.length / 2).ceil() - 1 ? 0 : 12.0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // First item in the row
                            _buildDetailItem(secondaryColumns[firstIndex], item),

                            // Second item in the row (if exists, else empty spacer)
                            if (secondIndex < secondaryColumns.length)
                              _buildDetailItem(secondaryColumns[secondIndex], item)
                            else
                              const Expanded(child: SizedBox()),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔵 Helper for consistent detail items (Label above Value)
  Widget _buildDetailItem(TableColumnConfig col, T item) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            col.header,
            style: const TextStyle(
              color: AppColor.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          buildCell(item, col),
        ],
      ),
    );
  }
}
