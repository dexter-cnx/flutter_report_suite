import 'package:flutter/material.dart';
import 'package:report_engine/report_engine.dart';

import '../design_system/design_system.dart';
import 'designer_page.dart';

class TemplateGalleryPage extends StatefulWidget {
  const TemplateGalleryPage({super.key});

  @override
  State<TemplateGalleryPage> createState() => _TemplateGalleryPageState();
}

class _TemplateGalleryPageState extends State<TemplateGalleryPage> {
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

  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: DesignerAppShell(
          toolbar: _toolbar(),
          workspace: _workspace(),
        ),
      ),
    );
  }

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignerSpacing.lg),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Report Templates',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DesignerTypography.appTitle,
            ),
          ),
          Text(
            'Choose a starting point',
            style: DesignerTypography.helper,
          ),
        ],
      ),
    );
  }

  Widget _workspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 4
            : width >= 700
                ? 2
                : 1;

        return ColoredBox(
          color: DesignerColors.appBackground,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignerSpacing.xxl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create a report',
                      style: DesignerTypography.screenTitle,
                    ),
                    const SizedBox(height: DesignerSpacing.xs),
                    const Text(
                      'Start blank or open a built-in template as an editable working copy.',
                      style: DesignerTypography.body,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: DesignerSpacing.lg),
                      InlineAlert(
                        key: const ValueKey('gallery-open-error'),
                        message: _errorMessage!,
                        severity: InlineAlertSeverity.error,
                        actionLabel: 'Dismiss',
                        onAction: () => setState(() => _errorMessage = null),
                      ),
                    ],
                    const SizedBox(height: DesignerSpacing.xxl),
                    GridView.count(
                      key: ValueKey('template-gallery-grid-$columns'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: columns,
                      childAspectRatio: columns == 1 ? 2.5 : 1.35,
                      mainAxisSpacing: DesignerSpacing.lg,
                      crossAxisSpacing: DesignerSpacing.lg,
                      children: [
                        TemplateCard(
                          key: const ValueKey('template-card-blank'),
                          title: 'Blank Template',
                          description: 'Create a new report from scratch',
                          icon: Icons.add,
                          badge: 'NEW',
                          primary: true,
                          onPressed: () => _openDesigner(context),
                        ),
                        ..._templates.map(
                          (item) => TemplateCard(
                            key: ValueKey('template-card-${item.asset}'),
                            title: item.title,
                            description: 'Built-in · opens as editable copy',
                            icon: item.icon,
                            badge: 'BUILT-IN',
                            onPressed: () => _openBuiltIn(context, item),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openBuiltIn(
    BuildContext context,
    ({String title, String asset, IconData icon}) item,
  ) async {
    try {
      final template = await TemplateStorageService().loadFromAssets(item.asset);
      if (!context.mounted) return;
      _openDesigner(
        context,
        initialTemplate: template,
        workingCopyId: '${template['id'] ?? 'template'}-copy',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to open template: $error');
    }
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
