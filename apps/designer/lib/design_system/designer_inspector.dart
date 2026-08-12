import 'package:flutter/material.dart';

import 'designer_colors.dart';
import 'designer_controls.dart';
import 'designer_spacing.dart';

class DesignerInspector extends StatelessWidget {
  const DesignerInspector({
    super.key,
    required this.element,
    required this.onContentSubmitted,
    required this.onGeometrySubmitted,
    required this.onFontSizeSubmitted,
    required this.onBoldChanged,
    required this.onAlignmentChanged,
    required this.onDelete,
    this.tableColumns = const <Map<String, dynamic>>[],
    this.onAddTableColumn,
    this.onUpdateTableColumn,
    this.onMoveTableColumn,
    this.onRemoveTableColumn,
  });

  final Map<String, dynamic>? element;
  final ValueChanged<String> onContentSubmitted;
  final void Function(String key, double value) onGeometrySubmitted;
  final ValueChanged<double> onFontSizeSubmitted;
  final ValueChanged<bool> onBoldChanged;
  final ValueChanged<String> onAlignmentChanged;
  final VoidCallback onDelete;
  final List<Map<String, dynamic>> tableColumns;
  final VoidCallback? onAddTableColumn;
  final void Function(int index, String key, dynamic value)?
      onUpdateTableColumn;
  final void Function(int from, int to)? onMoveTableColumn;
  final ValueChanged<int>? onRemoveTableColumn;

  @override
  Widget build(BuildContext context) {
    final selected = element;
    if (selected == null) {
      return const Material(
        color: DesignerColors.panelBackground,
        child: Column(
          children: [
            PanelHeader(title: 'Inspector'),
            Expanded(child: Center(child: Text('Select an element to edit'))),
          ],
        ),
      );
    }

    final style = Map<String, dynamic>.from(
      selected['style'] as Map? ?? const <String, dynamic>{},
    );

    return Material(
      color: DesignerColors.panelBackground,
      child: Column(
        children: [
          const PanelHeader(title: 'Inspector'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                InspectorSection(
                  key: const ValueKey('inspector-section-content'),
                  title: 'Content',
                  child: PropertyInput(
                    fieldId: 'element-content',
                    label: 'Key / Text',
                    initialValue: selected['key']?.toString() ?? '',
                    onSubmitted: onContentSubmitted,
                  ),
                ),
                InspectorSection(
                  key: const ValueKey('inspector-section-geometry'),
                  title: 'Geometry',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _geometryInput(
                              selected,
                              'x',
                              'X',
                            ),
                          ),
                          const SizedBox(width: DesignerSpacing.sm),
                          Expanded(
                            child: _geometryInput(
                              selected,
                              'y',
                              'Y',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignerSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _geometryInput(
                              selected,
                              'w',
                              'W',
                            ),
                          ),
                          const SizedBox(width: DesignerSpacing.sm),
                          Expanded(
                            child: _geometryInput(
                              selected,
                              'h',
                              'H',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                InspectorSection(
                  key: const ValueKey('inspector-section-typography'),
                  title: 'Typography',
                  child: Column(
                    children: [
                      NumberPropertyInput(
                        label: 'Font Size',
                        unit: 'pt',
                        value: _number(style['fontSize'], fallback: 10),
                        onSubmitted: onFontSizeSubmitted,
                      ),
                      const SizedBox(height: DesignerSpacing.sm),
                      PropertyToggle(
                        label: 'Bold',
                        value: style['bold'] == true,
                        onChanged: onBoldChanged,
                      ),
                      const SizedBox(height: DesignerSpacing.sm),
                      PropertyDropdown<String>(
                        label: 'Alignment',
                        value: _validAlignment(style['align']),
                        items: const [
                          DropdownMenuItem(value: 'left', child: Text('Left')),
                          DropdownMenuItem(
                            value: 'center',
                            child: Text('Center'),
                          ),
                          DropdownMenuItem(
                            value: 'right',
                            child: Text('Right'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) onAlignmentChanged(value);
                        },
                      ),
                    ],
                  ),
                ),
                if (selected['type'] == 'table')
                  InspectorSection(
                    key: const ValueKey('inspector-section-table-columns'),
                    title: 'Table Columns',
                    trailing: IconButton(
                      tooltip: 'Add column',
                      visualDensity: VisualDensity.compact,
                      onPressed: onAddTableColumn,
                      icon: const Icon(Icons.add, size: 18),
                    ),
                    child: Column(
                      children: [
                        for (var index = 0;
                            index < tableColumns.length;
                            index++)
                          _TableColumnCard(
                            column: tableColumns[index],
                            index: index,
                            count: tableColumns.length,
                            onUpdate: onUpdateTableColumn,
                            onMove: onMoveTableColumn,
                            onRemove: onRemoveTableColumn,
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(DesignerSpacing.md),
                  child: FilledButton.tonalIcon(
                    key: const ValueKey('delete-element-button'),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete element'),
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _geometryInput(
    Map<String, dynamic> selected,
    String key,
    String label,
  ) {
    return NumberPropertyInput(
      label: label,
      unit: 'mm',
      value: _number(selected[key]),
      onSubmitted: (value) => onGeometrySubmitted(key, value),
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

class _TableColumnCard extends StatelessWidget {
  const _TableColumnCard({
    required this.column,
    required this.index,
    required this.count,
    required this.onUpdate,
    required this.onMove,
    required this.onRemove,
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
        border: Border.all(color: DesignerColors.borderDefault),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
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
                  label: 'Width',
                  value: DesignerInspector._number(
                    column['width'],
                    fallback: 1,
                  ),
                  onSubmitted: (value) => onUpdate?.call(index, 'width', value),
                ),
              ),
              const SizedBox(width: DesignerSpacing.sm),
              Expanded(
                child: PropertyDropdown<String>(
                  label: 'Alignment',
                  value: DesignerInspector._validAlignment(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Move column up',
                onPressed:
                    index > 0 ? () => onMove?.call(index, index - 1) : null,
                icon: const Icon(Icons.arrow_upward, size: 18),
              ),
              IconButton(
                tooltip: 'Move column down',
                onPressed: index < count - 1
                    ? () => onMove?.call(index, index + 1)
                    : null,
                icon: const Icon(Icons.arrow_downward, size: 18),
              ),
              IconButton(
                tooltip: 'Remove column',
                onPressed: () => onRemove?.call(index),
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
