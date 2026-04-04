

import 'package:arianth/services/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_color/app_color.dart';

class SortField {
  final String label;
  final String key;
  final IconData icon;
  final String sub;

  const SortField({
    required this.label,
    required this.key,
    required this.icon,
    required this.sub,
  });
}

class SortDrawerConfig {
  final String title;
  final String subtitle;
  final List<SortField> fields;
  final void Function(SortField field, bool ascending) onApply;
  final VoidCallback onClear;
  final String? initialField;
  final bool initialAscending;

  const SortDrawerConfig({
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.onApply,
    required this.onClear,
    this.initialField,
    this.initialAscending = true,
  });
}

// ── Public Entry Point ────────────────────────────────────────────────────────

Future<void> showSortDrawer({
  required BuildContext context,
  required WidgetRef ref,
  required SortDrawerConfig config,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _SortBottomSheet(config: config, ref: ref),
  );
}

// ── Internal Bottom Sheet Widget ──────────────────────────────────────────────

class _SortBottomSheet extends StatefulWidget {
  final SortDrawerConfig config;
  final WidgetRef ref;
  const _SortBottomSheet({required this.config, required this.ref});

  @override
  State<_SortBottomSheet> createState() => _SortBottomSheetState();
}

class _SortBottomSheetState extends State<_SortBottomSheet> {
  SortField? _selectedField;
  late bool _ascending;

  @override
  void initState() {
    super.initState();
    _ascending = widget.config.initialAscending;
    if (widget.config.initialField != null) {
      _selectedField = widget.config.fields.firstWhere(
        (f) => f.label == widget.config.initialField,
        // orElse: () => widget.config.fields.isNotEmpty ? widget.config.fields.first : null,
      );
    } else if (widget.config.fields.isNotEmpty) {
      _selectedField = widget.config.fields.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColor.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Graggable handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColor.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildHeader(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    _buildBody(),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sort_rounded, color: AppColor.primary, size: 20),
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
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                Text(
                  widget.ref.watchTr('choose_order'),
                  style: const TextStyle(fontSize: 12, color: AppColor.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20, color: AppColor.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // Direction toggle
        Container(
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColor.border),
          ),
          child: Column(
            children: [
              _directionTile(
                label: widget.ref.watchTr('ascending'),
                icon: Icons.arrow_upward_rounded,
                isActive: _ascending,
                onTap: () => setState(() => _ascending = true),
              ),
              Divider(height: 1, color: AppColor.border),
              _directionTile(
                label: widget.ref.watchTr('descending'),
                icon: Icons.arrow_downward_rounded,
                isActive: !_ascending,
                onTap: () => setState(() => _ascending = false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            _ascending
                ? '${widget.ref.watchTr('ascending')}: Smallest → Largest / A → Z'
                : '${widget.ref.watchTr('descending')}: Largest → Smallest / Z → A',
            style: const TextStyle(fontSize: 12, color: AppColor.textSecondary, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: AppColor.background,
        border: Border(top: BorderSide(color: AppColor.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: AppColor.border),
              ),
              onPressed: () {
                widget.config.onClear();
                Navigator.pop(context);
              },
              child: Text(widget.ref.watchTr('reset_btn'),
                  style: const TextStyle(color: AppColor.textSecondary, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (_selectedField != null) {
                  widget.config.onApply(_selectedField!, _ascending);
                }
                Navigator.pop(context);
              },
              child: Text(widget.ref.watchTr('apply_sort'),
                  style: const TextStyle(color: AppColor.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _directionTile({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? AppColor.primary.withOpacity(0.1) : AppColor.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: isActive ? AppColor.primary : AppColor.textSecondary),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? AppColor.primary : AppColor.textPrimary,
              ),
            ),
            const Spacer(),
            if (isActive)
              const Icon(Icons.check_circle_rounded, size: 20, color: AppColor.primary)
            else
              const Icon(Icons.radio_button_off_rounded, size: 20, color: AppColor.border),
          ],
        ),
      ),
    );
  }
}
