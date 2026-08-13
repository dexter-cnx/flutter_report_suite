import 'package:flutter/material.dart';

import 'designer_colors.dart';
import 'designer_controls.dart';
import 'designer_spacing.dart';
import 'table_column_editor.dart';

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

    return KeyedSubtree(
      key: ValueKey('designer-inspector-${selected['id']}'),
      child: Material(
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
                              child: _geometryInput(selected, 'x', 'X'),
                            ),
                            const SizedBox(width: DesignerSpacing.sm),
                            Expanded(
                              child: _geometryInput(selected, 'y', 'Y'),
                            ),
                          ],
                        ),
                        const SizedBox(height: DesignerSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _geometryInput(selected, 'w', 'W'),
                            ),
                            const SizedBox(width: DesignerSpacing.sm),
                            Expanded(
                              child: _geometryInput(selected, 'h', 'H'),
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
                          onSubmitted: (value) {
                            if (value.isFinite && value >= 6 && value <= 30) {
                              onFontSizeSubmitted(value);
                            }
                          },
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
                            DropdownMenuItem(
                              value: 'left',
                              child: Text('Left'),
                            ),
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
                      child: TableColumnEditor(
                        columns: tableColumns,
                        onAdd: onAddTableColumn,
                        onUpdate: onUpdateTableColumn,
                        onMove: onMoveTableColumn,
                        onRemove: onRemoveTableColumn,
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
