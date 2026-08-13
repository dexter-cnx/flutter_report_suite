import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../design_system/design_system.dart';

typedef PreviewContentBuilder = Widget Function(Uint8List bytes);
typedef SystemPrintAction = Future<void> Function(Uint8List bytes);

class PreviewWorkspacePage extends StatefulWidget {
  const PreviewWorkspacePage({
    super.key,
    required this.pdfBytes,
    required this.paper,
    this.title = 'Preview',
    this.previewBuilder,
    this.onSystemPrint,
  });

  final Uint8List pdfBytes;
  final Map<String, dynamic> paper;
  final String title;
  final PreviewContentBuilder? previewBuilder;
  final SystemPrintAction? onSystemPrint;

  @override
  State<PreviewWorkspacePage> createState() => _PreviewWorkspacePageState();
}

class _PreviewWorkspacePageState extends State<PreviewWorkspacePage> {
  String? _printError;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= DesignerLayout.compactDesktopBreakpoint;

    return Scaffold(
      body: SafeArea(
        child: desktop
            ? DesignerAppShell(
                toolbar: _toolbar(),
                workspace: _preview(),
                rightPanel: _settingsPanel(),
                statusBar: _statusBar(),
              )
            : Column(
                children: [
                  SizedBox(
                    height: DesignerLayout.topToolbarHeight,
                    child: _toolbar(),
                  ),
                  Expanded(child: _preview()),
                  SizedBox(
                    height: 220,
                    child: _settingsPanel(),
                  ),
                  SizedBox(
                    height: DesignerLayout.statusBarHeight,
                    child: _statusBar(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignerSpacing.md),
      child: Row(
        children: [
          ToolbarButton(
            icon: Icons.arrow_back,
            tooltip: 'Back to designer',
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: DesignerSpacing.sm),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DesignerTypography.appTitle,
            ),
          ),
          ToolbarButton(
            key: const ValueKey('preview-system-print-button'),
            icon: Icons.print_outlined,
            tooltip: 'System Print',
            onPressed: _systemPrint,
          ),
        ],
      ),
    );
  }

  Widget _preview() {
    final override = widget.previewBuilder;
    if (override != null) return override(widget.pdfBytes);

    return ColoredBox(
      color: DesignerColors.appBackground,
      child: PdfPreview(
        build: (_) async => widget.pdfBytes,
      ),
    );
  }

  Widget _settingsPanel() {
    return Material(
      color: DesignerColors.panelBackground,
      child: Column(
        children: [
          const PanelHeader(title: 'Preview Settings'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                InspectorSection(
                  title: 'Output',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('PDF / System Print',
                          style: DesignerTypography.body),
                      const SizedBox(height: DesignerSpacing.xs),
                      Text(
                        'Uses the generated PDF from report_engine. Printing is delegated to the platform print dialog.',
                        style: DesignerTypography.helper,
                      ),
                    ],
                  ),
                ),
                InspectorSection(
                  title: 'Paper',
                  child: Text(
                    _paperDescription(),
                    key: const ValueKey('preview-paper-description'),
                    style: DesignerTypography.body,
                  ),
                ),
                if (_printError != null)
                  Padding(
                    padding: const EdgeInsets.all(DesignerSpacing.md),
                    child: InlineAlert(
                      key: const ValueKey('preview-print-error'),
                      severity: InlineAlertSeverity.error,
                      message: _printError!,
                      actionLabel: 'Dismiss',
                      onAction: () => setState(() => _printError = null),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBar() {
    return DesignerStatusBar(
      leading: Text(_paperDescription()),
      center: const Text('PDF preview · platform print available'),
      trailing: Text('${widget.pdfBytes.length} bytes'),
    );
  }

  Future<void> _systemPrint() async {
    setState(() => _printError = null);
    try {
      final action = widget.onSystemPrint;
      if (action != null) {
        await action(widget.pdfBytes);
      } else {
        await Printing.layoutPdf(onLayout: (_) async => widget.pdfBytes);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _printError = 'Unable to print: $error');
    }
  }

  String _paperDescription() {
    final width = _number(widget.paper['widthMm'], fallback: 80);
    final height = widget.paper['autoHeight'] == true
        ? null
        : _number(widget.paper['heightMm'], fallback: 200);
    final type = widget.paper['type']?.toString().toUpperCase() ?? 'PDF';
    return height == null
        ? '$type · ${width.toStringAsFixed(1)} mm · auto height'
        : '$type · ${width.toStringAsFixed(1)} × ${height.toStringAsFixed(1)} mm';
  }

  static double _number(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
