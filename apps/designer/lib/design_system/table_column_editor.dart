import 'package:flutter/material.dart';

import 'designer_colors.dart';
import 'designer_controls.dart';
import 'designer_radius.dart';
import 'designer_spacing.dart';
import 'designer_typography.dart';

class TableColumnEditor extends StatelessWidget {
  const TableColumnEditor({
    super.key,
    required this.columns,
    this.onAdd,
    this.onUpdate,
    this.onMove,
    this.onRemove,
  });

  final List<Map<String, dynamic>> columns;
  final VoidCallback? onAdd;
  final void Function(int index, String key, dynamic value)? onUpdate;
  final void Function(int from, int to)? onMove;
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                columns.isEmpty
                    ? 'No columns configured'
                    : '${columns.length} ${columns.length == 1 ? 'column' : 'columns'} · widths are relative',
                style: DesignerTypography.helper,
              ),
            ),
            TextButton.icon(
              key: const ValueKey('table-add-column-button'),
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: DesignerSpacing.sm),
        if (columns.isEmpty)
          Container(
            key: const ValueKey('table-columns-empty-state'),
            padding: const EdgeInsets.all(DesignerSpacing.md),
            decoration: BoxDecoration(
              color: DesignerColors.appBackground,
              border: Border.all(color: DesignerColors.borderDefault),
              borderRadius: BorderRadius.circular(DesignerRadius.control),
            ),
            child: const Text(
              'Add a column to define the table fields rendered by the current model.',
              style: DesignerTypography.helper,
            ),
          )
        else
          for (var index = 0; index < columns.length; index++)
            TableColumnCard(
              key: ValueKey('table-column-card-$index'),
              column: columns[index],
              index: index,
              count: columns.length,
              onUpdate: onUpdate,
              onMove: onMove,
              onRemove: onRemove,
            ),
      ],
    );
  }
}

class TableColumnCard extends StatelessWidget {
  const TableColumnCard({
    super.key,
    required this.column,
    required this.index,
    required this.count,
    this.onUpdate,
    this.onMove,
    this.onRemove,
  });

  final Map<String, dynamic> column;
  final int index;
  final int count;
  final void Function(int index, String key, dynamic value)? onUpdate;
  final void Function(int from, int to)? onMove;
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignerSpacing.sm),
      padding: const EdgeInsets.all(DesignerSpacing.sm),
      decoration: BoxDecoration(
        color: DesignerColors.panelBackground,
        border: Border.all(color: DesignerColors.borderDefault),
        borderRadius: BorderRadius.circular(DesignerRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DesignerColors.appBackground,
                  borderRadius: BorderRadius.circular(DesignerRadius.badge),
                ),
                child: Text('${index + 1}', style: DesignerTypography.helper),
              ),
              const SizedBox(width: DesignerSpacing.sm),
              Expanded(
                child: Text(
                  column['label']?.toString().isNotEmpty == true
                      ? column['label'].toString()
                      : 'Column ${index + 1}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesignerTypography.controlLabel,
                ),
              ),
              IconButton(
                key: ValueKey('table-column-move-up-$index'),
                tooltip: 'Move column up',
                visualDensity: VisualDensity.compact,
                onPressed:
                    index > 0 ? () => onMove?.call(index, index - 1) : null,
                icon: const Icon(Icons.arrow_upward, size: 17),
              ),
              IconButton(
                key: ValueKey('table-column-move-down-$index'),
                tooltip: 'Move column down',
                visualDensity: VisualDensity.compact,
                onPressed: index < count - 1
                    ? () => onMove?.call(index, index + 1)
                    : null,
                icon: const Icon(Icons.arrow_downward, size: 17),
              ),
              IconButton(
                key: ValueKey('table-column-remove-$index'),
                tooltip: 'Remove column',
                visualDensity: VisualDensity.compact,
                onPressed: onRemove == null ? null : () => onRemove!(index),
                icon: const Icon(Icons.delete_outline, size: 17),
              ),
            ],
          ),
          const SizedBox(height: DesignerSpacing.sm),
          Row(
            children: [
              Expanded(
                child: PropertyInput(
                  fieldId: 'column-key-$index',
                  label: 'Key',
                  initialValue: column['key']?.toString() ?? '',
                  onSubmitted: (value) => onUpdate?.call(index, 'key', value),
                ),
              ),
              const SizedBox(width: DesignerSpacing.sm),
              Expanded(
                child: PropertyInput(
                  fieldId: 'column-label-$index',
                  label: 'Label',
                  initialValue: column['label']?.toString() ?? '',
                  onSubmitted: (value) => onUpdate?.call(index, 'label', value),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignerSpacing.sm),
          Row(
            children: [
              Expanded(
                child: NumberPropertyInput(
                  label: 'Width weight',
                  value: _number(column['width'], fallback: 1),
                  onSubmitted: (value) => onUpdate?.call(index, 'width', value),
                ),
              ),
              const SizedBox(width: DesignerSpacing.sm),
              Expanded(
                child: PropertyDropdown<String>(
                  label: 'Alignment',
                  value: _validAlignment(
                    column['alignment'] ?? column['align'],
                  ),
                  items: const [
                    DropdownMenuItem(value: 'left', child: Text('Left')),
                    DropdownMenuItem(value: 'center', child: Text('Center')),
                    DropdownMenuItem(value: 'right', child: Text('Right')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onUpdate?.call(index, 'alignment', value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static double _number(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String _validAlignment(dynamic value) {
    final alignment = value?.toString() ?? 'left';
    return const {'left', 'center', 'right'}.contains(alignment)
        ? alignment
        : 'left';
  }
}
