import 'package:arianth/services/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_color/app_color.dart';

// ── Data Models ───────────────────────────────────────────────────────────────

class FilterField {
  final String label;
  final String key;
  final IconData icon;

  const FilterField({
    required this.label,
    required this.key,
    required this.icon,
  });
}

class FilterDrawerConfig {
  final String title;
  final String subtitle;
  final List<FilterField> fields;
  final void Function(FilterField field, String value) onApply;
  final VoidCallback onClear;
  final FilterField? initialField;
  final String initialValue;

  const FilterDrawerConfig({
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.onApply,
    required this.onClear,
    this.initialField,
    this.initialValue = '',
  });
}

// ── Public Entry Point ────────────────────────────────────────────────────────

Future<void> showFilterDrawer({
  required BuildContext context,
  required WidgetRef ref,
  required FilterDrawerConfig config,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: ref.watchTr('filter'),
    barrierColor: Colors.black38,
    transitionDuration: const Duration(milliseconds: 260),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
    pageBuilder: (context, _, __) => _FilterDrawer(config: config, ref: ref),
  );
}

// ── Internal Drawer Widget ────────────────────────────────────────────────────

class _FilterDrawer extends StatefulWidget {
  final FilterDrawerConfig config;
  final WidgetRef ref;
  const _FilterDrawer({required this.config, required this.ref});

  @override
  State<_FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<_FilterDrawer> {
  FilterField? _selectedField;
  late final TextEditingController _ctrl;

  bool get isMobile => MediaQuery.of(context).size.width < 600;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.config.initialValue);

    // Match initialField by label from the full field list
    if (widget.config.initialField != null) {
      _selectedField = widget.config.fields.firstWhere(
            (f) => f.label == widget.config.initialField!.label,
        orElse: () => widget.config.fields.first,
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: isMobile ? MediaQuery.of(context).size.width * 0.82 : 340,
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppColor.background,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08), blurRadius: 32, offset: Offset(-8, 0)),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildBody()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: AppColor.background,
        border: Border(bottom: BorderSide(color: AppColor.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune_rounded,
                color: AppColor.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.config.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
                Text(
                  widget.config.subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: AppColor.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close,
                  size: 16, color: AppColor.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      children: [
        // Section label
        Text(
          widget.ref.watchTr('filter_by'),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColor.textSecondary,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),

        // Dynamic field cards
        ...widget.config.fields.map((field) {
          final isActive = _selectedField?.key == field.key;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedField = isActive ? null : field;
              if (!isActive) _ctrl.clear();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(bottom: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: isActive ? AppColor.primary.withOpacity(0.1) : AppColor.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? AppColor.primary : AppColor.border,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive ? AppColor.primary : AppColor.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                          isActive ? AppColor.primary : AppColor.border),
                    ),
                    child: Icon(field.icon,
                        size: 16,
                        color: isActive
                            ? AppColor.white
                            : AppColor.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      field.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? AppColor.primary
                            : AppColor.textPrimary,
                      ),
                    ),
                  ),
                  if (isActive)
                    const Icon(Icons.check_circle_rounded,
                        size: 18, color: AppColor.primary)
                  else
                    Icon(Icons.radio_button_unchecked,
                        size: 18, color: AppColor.border),
                ],
              ),
            ),
          );
        }),

        Divider(height: 28, color: AppColor.border),

        // Search label
        Text(
          widget.ref.watchTr('search_value'),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColor.textSecondary,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),

        // Search field
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedField != null ? AppColor.accent : AppColor.border,
              width: _selectedField != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: _ctrl,
            enabled: _selectedField != null,
            style: const TextStyle(
                color: AppColor.textPrimary, fontSize: 14),
            cursorColor: AppColor.accent,
            decoration: InputDecoration(
              hintText: _selectedField != null
                  ? '${widget.ref.watchTr('enter')} ${_selectedField!.label.toLowerCase()}…'
                  : widget.ref.watchTr('select_field_first'),
              hintStyle:
              const TextStyle(color: AppColor.textSecondary, fontSize: 13),
              border: InputBorder.none,
              prefixIcon: Icon(
                _selectedField?.icon ?? Icons.search_rounded,
                color: _selectedField != null
                    ? AppColor.accent
                    : AppColor.textSecondary,
                size: 20,
              ),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.cancel,
                    size: 16, color: AppColor.textSecondary),
                onPressed: () => setState(() => _ctrl.clear()),
              )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),

        const SizedBox(height: 20),

        // Active filter preview badge
        if (_selectedField != null && _ctrl.text.isNotEmpty)
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColor.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.preview_rounded,
                    size: 14, color: AppColor.primary),
                const SizedBox(width: 8),
                Text('${widget.ref.watchTr('preview')}: ',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColor.textSecondary,
                        fontWeight: FontWeight.w600)),
                Flexible(
                  child: Text(
                    '${_selectedField!.label} = "${_ctrl.text}"',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColor.primary,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    final canApply =
        _selectedField != null && _ctrl.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColor.background,
        border: Border(top: BorderSide(color: AppColor.border)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: AppColor.border),
            ),
            onPressed: () {
              widget.config.onClear();
              Navigator.pop(context);
            },
            child: Text(widget.ref.watchTr('reset_btn'),
                style: const TextStyle(
                    color: AppColor.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                canApply ? AppColor.primary : AppColor.surface,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: canApply
                  ? () {
                widget.config.onApply(
                    _selectedField!, _ctrl.text.trim());
                Navigator.pop(context);
              }
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, size: 16, color: AppColor.white),
                  const SizedBox(width: 8),
                  Text(widget.ref.watchTr('apply_filter'),
                      style: const TextStyle(
                          color: AppColor.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}