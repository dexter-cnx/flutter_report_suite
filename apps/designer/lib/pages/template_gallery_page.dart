import 'package:flutter/material.dart';
import 'package:report_engine/report_engine.dart';

import 'designer_page.dart';

class TemplateGalleryPage extends StatelessWidget {
  const TemplateGalleryPage({super.key});

  static const _templates = <({String title, String asset, IconData icon})>[
    (
      title: '80mm Receipt',
      asset: 'assets/templates/thermal_80.json',
      icon: Icons.receipt_long,
    ),
    (
      title: '58mm Receipt',
      asset: 'assets/templates/thermal_58.json',
      icon: Icons.receipt,
    ),
    (
      title: 'A4 Invoice',
      asset: 'assets/templates/a4_invoice.json',
      icon: Icons.description,
    ),
    (
      title: '4x6 Sticker',
      asset: 'assets/templates/sticker_4x6.json',
      icon: Icons.sell,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Templates')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 1100 ? 4 : width >= 700 ? 2 : 1;
          return GridView.count(
            crossAxisCount: columns,
            childAspectRatio: columns == 1 ? 2.7 : 1.45,
            padding: const EdgeInsets.all(20),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _newTemplateCard(context),
              ..._templates.map((item) => _templateCard(context, item)),
            ],
          );
        },
      ),
    );
  }

  Widget _newTemplateCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _openDesigner(context),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, size: 40),
              SizedBox(height: 8),
              Text(
                'Blank Template',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Create a new report from scratch',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _templateCard(
    BuildContext context,
    ({String title, String asset, IconData icon}) item,
  ) {
    return Card(
      child: InkWell(
        onTap: () async {
          try {
            final template =
                await TemplateStorageService().loadFromAssets(item.asset);
            if (!context.mounted) return;
            _openDesigner(
              context,
              initialTemplate: template,
              workingCopyId: '${template['id'] ?? 'template'}-copy',
            );
          } catch (error) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Unable to open template: $error')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 40),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Built-in • opens as editable copy',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDesigner(
    BuildContext context, {
    Map<String, dynamic>? initialTemplate,
    String? workingCopyId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DesignerPage(
          initialTemplate: initialTemplate,
          initialTemplateId: workingCopyId,
        ),
      ),
    );
  }
}
