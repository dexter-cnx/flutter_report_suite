import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

class EscPosPreviewPanel extends StatelessWidget {
  const EscPosPreviewPanel({
    super.key,
    required this.bytes,
  });

  final List<int> bytes;

  @override
  Widget build(BuildContext context) {
    if (bytes.isEmpty) {
      return const Center(
        child: InlineAlert(
          key: ValueKey('preview-escpos-empty'),
          severity: InlineAlertSeverity.info,
          message:
              'ESC/POS bytes are not available. Render the template through report_engine first.',
        ),
      );
    }

    final hex = bytes
        .take(512)
        .map((value) => value.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');

    return ColoredBox(
      color: DesignerColors.appBackground,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(DesignerSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('ESC/POS byte stream', style: DesignerTypography.appTitle),
                const SizedBox(height: DesignerSpacing.sm),
                Text(
                  '${bytes.length} bytes rendered by report_engine',
                  key: const ValueKey('preview-escpos-byte-count'),
                  style: DesignerTypography.body,
                ),
                const SizedBox(height: DesignerSpacing.md),
                Expanded(
                  child: Container(
                    key: const ValueKey('preview-escpos-hex'),
                    padding: const EdgeInsets.all(DesignerSpacing.md),
                    decoration: BoxDecoration(
                      color: DesignerColors.panelBackground,
                      border: Border.all(color: DesignerColors.borderDefault),
                      borderRadius: BorderRadius.circular(DesignerRadius.control),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(hex, style: DesignerTypography.helper),
                    ),
                  ),
                ),
                const SizedBox(height: DesignerSpacing.md),
                const InlineAlert(
                  severity: InlineAlertSeverity.info,
                  message:
                      'Preview only. Sending requires a selected EscPosTransport. Hardware actions remain capability-gated.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
