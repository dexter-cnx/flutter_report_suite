import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../design_system/design_system.dart';
import 'esc_pos_preview_panel.dart';

typedef PreviewContentBuilder = Widget Function(Uint8List bytes);
typedef SystemPrintAction = Future<void> Function(Uint8List bytes);

enum PreviewOutputMode { pdf, escPos }

class PreviewWorkspacePage extends StatefulWidget {
  const PreviewWorkspacePage({
    super.key,
    required this.pdfBytes,
    required this.paper,
    this.escPosBytes = const <int>[],
    this.title = 'Preview',
    this.previewBuilder,
    this.onSystemPrint,
  });

  final Uint8List pdfBytes;
  final List<int> escPosBytes;
  final Map<String, dynamic> paper;
  final String title;
  final PreviewContentBuilder? previewBuilder;
  final SystemPrintAction? onSystemPrint;

  @override
  State<PreviewWorkspacePage> createState() => _PreviewWorkspacePageState();
}

class _PreviewWorkspacePageState extends State<PreviewWorkspacePage> {
  PreviewOutputMode _mode = PreviewOutputMode.pdf;
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
          if (_mode == PreviewOutputMode.pdf)
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
    if (_mode == PreviewOutputMode.escPos) {
      return EscPosPreviewPanel(bytes: widget.escPosBytes);
    }

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
                      SegmentedButton<PreviewOutputMode>(
                        key: const ValueKey('preview-output-mode'),
                        segments: const [
                          ButtonSegment(
                            value: PreviewOutputMode.pdf,
                            label: Text('PDF'),
                            icon: Icon(Icons.picture_as_pdf_outlined),
                          ),
                          ButtonSegment(
                            value: PreviewOutputMode.escPos,
                            label: Text('ESC/POS'),
                            icon: Icon(Icons.receipt_long_outlined),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _mode = selection.single;
                            _printError = null;
                          });
                        },
                      ),
                      const SizedBox(height: DesignerSpacing.sm),
                      Text(
                        _mode == PreviewOutputMode.pdf
                            ? 'PDF / System Print'
                            : 'ESC/POS / Rendered bytes',
                        style: DesignerTypography.body,
                      ),
                      const SizedBox(height: DesignerSpacing.xs),
                      Text(
                        _mode == PreviewOutputMode.pdf
                            ? 'Uses the generated PDF from report_engine. Printing is delegated to the platform print dialog.'
                            : 'Uses bytes rendered by report_engine. Sending requires an explicit EscPosTransport.',
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
    final isPdf = _mode == PreviewOutputMode.pdf;
    return DesignerStatusBar(
      leading: Text(_paperDescription()),
      center: Text(
        isPdf
            ? 'PDF preview · platform print available'
            : 'ESC/POS preview · transport not selected',
      ),
      trailing: Text(
        '${isPdf ? widget.pdfBytes.length : widget.escPosBytes.length} bytes',
      ),
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
