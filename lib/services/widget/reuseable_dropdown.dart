import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:flutter/material.dart';

class WebSearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemLabel;
  final String Function(T)? selectedItemLabel; // ✅ NEW: format selected text differently
  final T? selectedValue;
  final ValueChanged<T?>? onChanged; // ✅ Made optional
  final String hintText;
  final bool enabled; // ✅ Added enabled flag
  final bool readOnly; // 🛠️ NEW: Optional readOnly flag
  final bool allowNew; // ✅ new flag
  final Future<T?> Function(String)? onNewItemAdded; // ✅ callback

  const WebSearchableDropdown({
    super.key,
    required this.items,
    required this.itemLabel,
    this.selectedItemLabel, // ✅ NEW
    this.onChanged, // ✅ Optional now
    this.selectedValue,
    this.hintText = 'Select option',
    this.enabled = true, // ✅ Default enabled
    this.readOnly = false, // 🛠️ NEW: Default to false
    this.allowNew = false, // default off
    this.onNewItemAdded,
    this.validator,
  });

  final String? Function(T?)? validator;

  @override
  State<WebSearchableDropdown<T>> createState() =>
      _WebSearchableDropdownState<T>();
}

class _WebSearchableDropdownState<T> extends State<WebSearchableDropdown<T>> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<T> _filteredItems = [];
  T? _selectedValue;
  bool _isOpen = false;

  bool _showNewInput = false;
  final TextEditingController _newInputCtrl = TextEditingController();
  bool _isAdding = false; // ✅ Local loading state for Add button

  @override
  void initState() {
    super.initState();
    _updateItemsAndValue(); // ✅ Initial update

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _closeDropdown();
      }
    });

    _controller.addListener(() {
      if (_isOpen) _filter(_controller.text);
    });
  }

  @override
  void didUpdateWidget(covariant WebSearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateItemsAndValue(deferController: true); // ✅ Deferred updating controller
    if (_isOpen) {
      // ✅ Schedule refresh after build to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshOverlay();
        }
      });
    }
  }

  void _updateItemsAndValue({bool deferController = false}) {
    _filteredItems = widget.items;
    if (_selectedValue != widget.selectedValue) {
      _selectedValue = widget.selectedValue;
      
      final newText = _selectedValue != null
          ? (widget.selectedItemLabel != null
              ? widget.selectedItemLabel!(_selectedValue as T)
              : widget.itemLabel(_selectedValue as T))
          : '';

      if (deferController) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _controller.text = newText;
          }
        });
      } else {
        _controller.text = newText;
      }
    }
  }

  void _filter(String query) {
    final lower = query.toLowerCase().trim();
    setState(() {
      if (lower.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) =>
            widget.itemLabel(item).toLowerCase().contains(lower))
            .toList();
      }
    });
    _refreshOverlay();
  }

  void _toggleDropdown() {
    // 🛠️ Check readOnly: Cannot interact if disabled OR readOnly
    if (!widget.enabled || widget.readOnly) return;

    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    // 🛠️ Check readOnly: Cannot open if disabled OR readOnly
    if (_isOpen || !widget.enabled || widget.readOnly) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
    _showNewInput = false;
    _isAdding = false; // ✅ Reset loading
    if (_selectedValue != null) {
      _controller.text = widget.selectedItemLabel != null
            ? widget.selectedItemLabel!(_selectedValue as T)
            : widget.itemLabel(_selectedValue as T);
    } else {
      _controller.clear();
    }
  }

  void _refreshOverlay() {
    if (_isOpen) {
      _overlayEntry?.remove();
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final canInteract = widget.enabled && !widget.readOnly;

    return OverlayEntry(
      builder: (context) => Positioned(
        // Positioned must be at the root of the Overlay builder
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            color: AppColor.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.allowNew && !_showNewInput && canInteract)
                    Container(
                      // Removed the internal Positioned that was here
                      color: AppColor.divider.withOpacity(0.5),
                      child: ListTile(
                        dense: true,
                        trailing: const Icon(Icons.add_circle_outline,
                            color: AppColor.primary),
                        title: const Text('Add new',
                            style: TextStyle(color: AppColor.textPrimary)),
                        onTap: () {
                          setState(() => _showNewInput = true);
                          _refreshOverlay();
                        },
                      ),
                    ),
                  if (_showNewInput && canInteract)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newInputCtrl,
                              style: const TextStyle(color: AppColor.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'Enter new option',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.all(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isAdding || !canInteract
                                ? null
                                : () async {
                              final newText = _newInputCtrl.text.trim();
                              if (newText.isEmpty) return;
                              setState(() => _isAdding = true);
                              try {
                                if (widget.onNewItemAdded != null) {
                                  final newItem = await widget.onNewItemAdded!(newText);
                                  if (newItem != null && mounted) {
                                    setState(() {
                                      _selectedValue = newItem;
                                      _controller.text = widget.itemLabel(newItem);
                                    });
                                    widget.onChanged?.call(newItem);
                                  }
                                }
                              } finally {
                                if (mounted) setState(() => _isAdding = false);
                                _newInputCtrl.clear();
                                _showNewInput = false;
                                _closeDropdown();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              foregroundColor: AppColor.textWhite,
                            ),
                            child: _isAdding
                                ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.textWhite),
                            )
                                : const Text('Add'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _filteredItems.isEmpty
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No results found', style: TextStyle(color: Colors.grey)),
                    )
                        : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = item == _selectedValue;
                        return InkWell(
                          onTap: canInteract ? () {
                            setState(() {
                              _selectedValue = item;
                              _controller.text = widget.selectedItemLabel != null
                                  ? widget.selectedItemLabel!(item)
                                  : widget.itemLabel(item);
                            });
                            widget.onChanged?.call(item);
                            _closeDropdown();
                          } : null,
                          child: Container(
                            color: isSelected ? AppColor.primary.withOpacity(0.1) : Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            child: Text(
                              widget.itemLabel(item),
                              style: TextStyle(
                                color: isSelected ? AppColor.primary : AppColor.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
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

  @override
  Widget build(BuildContext context) {
    // 🛠️ The field is readOnly if it's disabled (!widget.enabled) OR if readOnly is explicitly set.
    final textFieldReadOnly = !widget.enabled || widget.readOnly;
    // 🛠️ The field is interactable (can open dropdown) if it's enabled AND not readOnly.
    final canInteract = widget.enabled && !widget.readOnly;

    return CompositedTransformTarget(
      link: _layerLink,
      child: CustomInputField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled, // ✅ Wire enabled
        readOnly: textFieldReadOnly, // 🛠️ Use combined readOnly logic
        validator: (v) => widget.validator?.call(widget.selectedValue),
        onTap: canInteract ? _toggleDropdown : null, // 🛠️ Use combined interactable logic
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: AppColor.primary, fontSize: 12),
          // 🛠️ Only show interactive icon if enabled AND not readOnly
          suffixIcon: canInteract
              ? InkWell(
            onTap: _toggleDropdown,
            child: Icon(
              _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColor.textSecondary,
              size: 18,
            ),
          )
              : const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColor.divider, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColor.divider, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          isDense: true,
          filled: false, // To avoid extra background fill
        ),
        style: TextStyle(
          fontSize: 12,
          color: widget.selectedValue == null ? AppColor.primary : AppColor.black,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _controller.dispose();
    _focusNode.dispose();
    _newInputCtrl.dispose();
    super.dispose();
  }
}