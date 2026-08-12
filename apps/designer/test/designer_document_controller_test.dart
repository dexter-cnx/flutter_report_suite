import 'package:flutter_test/flutter_test.dart';
import 'package:report_designer/controllers/designer_document_controller.dart';

void main() {
  Map<String, dynamic> textElement(String id) => <String, dynamic>{
        'id': id,
        'type': 'text',
        'key': 'Hello',
        'x': 0.0,
        'y': 0.0,
        'w': 20.0,
        'h': 10.0,
        'style': <String, dynamic>{'fontSize': 10.0},
      };

  Map<String, dynamic> tableElement() => <String, dynamic>{
        'id': 'table',
        'type': 'table',
        'key': '{{items}}',
        'x': 0.0,
        'y': 0.0,
        'w': 60.0,
        'h': 30.0,
        'style': <String, dynamic>{},
        'columns': <Map<String, dynamic>>[
          <String, dynamic>{
            'key': 'name',
            'label': 'Item',
            'width': 2.0,
            'alignment': 'left',
            'futureField': 'preserved',
          },
          <String, dynamic>{
            'key': 'qty',
            'label': 'Qty',
            'width': 1.0,
            'alignment': 'right',
          },
        ],
      };

  test('add delete undo and redo restore document state', () {
    final controller = DesignerDocumentController();
    controller.addElement(textElement('one'));
    expect(controller.elements, hasLength(1));

    controller.deleteSelected();
    expect(controller.elements, isEmpty);

    controller.undo();
    expect(controller.elements, hasLength(1));

    controller.redo();
    expect(controller.elements, isEmpty);
  });

  test('geometry snaps to five millimetre grid', () {
    final controller = DesignerDocumentController();
    controller.addElement(textElement('one'));
    controller.moveSelected(12.2, 18.1);
    controller.resizeSelected(23.0, 17.0);

    final element = controller.selectedElement!;
    expect(element['x'], 10.0);
    expect(element['y'], 20.0);
    expect(element['w'], 25.0);
    expect(element['h'], 15.0);
  });

  test('drag interaction creates one undo transaction and snaps on end', () {
    final controller = DesignerDocumentController();
    controller.addElement(textElement('one'));
    controller.beginInteraction();
    controller.moveSelectedInteractive(7.1, 12.6);
    controller.moveSelectedInteractive(13.2, 17.8);
    controller.endInteraction();

    expect(controller.selectedElement!['x'], 15.0);
    expect(controller.selectedElement!['y'], 20.0);

    controller.undo();
    expect(controller.elements.single['x'], 0.0);
    expect(controller.elements.single['y'], 0.0);
  });

  test('resize and property changes participate in undo redo', () {
    final controller = DesignerDocumentController();
    controller.addElement(textElement('one'));

    controller.resizeSelected(42, 19);
    expect(controller.selectedElement!['w'], 40.0);
    expect(controller.selectedElement!['h'], 20.0);

    controller.updateSelected('key', 'Changed');
    expect(controller.selectedElement!['key'], 'Changed');

    controller.undo();
    expect(controller.elements.single['key'], 'Hello');

    controller.undo();
    expect(controller.elements.single['w'], 20.0);
    expect(controller.elements.single['h'], 10.0);

    controller.redo();
    expect(controller.elements.single['w'], 40.0);
    expect(controller.elements.single['h'], 20.0);
  });

  test('table columns add edit reorder remove and preserve unknown fields', () {
    final controller = DesignerDocumentController();
    controller.addElement(tableElement());

    controller.updateTableColumn(0, 'label', 'Product');
    controller.updateTableColumn(0, 'width', -1);
    controller.addTableColumn();
    controller.reorderTableColumn(2, 1);
    controller.removeTableColumn(2);

    final columns = List<Map<String, dynamic>>.from(
      controller.selectedElement!['columns'] as List,
    );
    expect(columns, hasLength(2));
    expect(columns.first['label'], 'Product');
    expect(columns.first['width'], 2.0);
    expect(columns.first['futureField'], 'preserved');
    expect(columns[1]['key'], 'field3');
  });

  test('table column edit can be undone', () {
    final controller = DesignerDocumentController();
    controller.addElement(tableElement());
    controller.updateTableColumn(0, 'alignment', 'center');
    expect(
      (controller.selectedElement!['columns'] as List).first['alignment'],
      'center',
    );

    controller.undo();
    expect(
      (controller.elements.single['columns'] as List).first['alignment'],
      'left',
    );
  });

  test('zoom is clamped without mutating document geometry', () {
    final controller = DesignerDocumentController();
    controller.addElement(textElement('one'));
    final before = controller.document;

    controller.setZoom(10);

    expect(controller.zoom, 2.0);
    expect(controller.document, before);
  });
}
