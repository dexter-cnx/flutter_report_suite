import 'package:flutter/material.dart';

import 'designer_colors.dart';
import 'designer_spacing.dart';
import 'designer_typography.dart';

enum DesignerLeftPanelMode {
  elements('Elements'),
  layers('Layers'),
  data('Data');

  const DesignerLeftPanelMode(this.label);

  final String label;
}

class DesignerLeftPanel extends StatelessWidget {
  const DesignerLeftPanel({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.elements,
    required this.layers,
    required this.data,
    this.footer,
  });

  final DesignerLeftPanelMode mode;
  final ValueChanged<DesignerLeftPanelMode> onModeChanged;
  final Widget elements;
  final Widget layers;
  final Widget data;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DesignerColors.panelBackground,
      child: Column(
        children: [
          _PanelModeTabs(
            mode: mode,
            onChanged: onModeChanged,
          ),
          const Divider(height: 1),
          Expanded(
            child: switch (mode) {
              DesignerLeftPanelMode.elements => elements,
              DesignerLeftPanelMode.layers => layers,
              DesignerLeftPanelMode.data => data,
            },
          ),
          if (footer != null) ...[
            const Divider(height: 1),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _PanelModeTabs extends StatelessWidget {
  const _PanelModeTabs({
    required this.mode,
    required this.onChanged,
  });

  final DesignerLeftPanelMode mode;
  final ValueChanged<DesignerLeftPanelMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: DesignerLeftPanelMode.values
            .map(
              (value) => Expanded(
                child: _PanelModeTab(
                  key: ValueKey('left-panel-tab-${value.name}'),
                  label: value.label,
                  selected: value == mode,
                  onTap: () => onChanged(value),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PanelModeTab extends StatelessWidget {
  const _PanelModeTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? DesignerColors.primarySubtle
            : DesignerColors.panelBackground,
        child: InkWell(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected
                      ? DesignerColors.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              label,
              style: DesignerTypography.label.copyWith(
                color: selected
                    ? DesignerColors.primary
                    : DesignerColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ToolPanelItem extends StatelessWidget {
  const ToolPanelItem({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.description,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      hint: description,
      child: Material(
        color: DesignerColors.panelBackground,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignerSpacing.md,
                vertical: DesignerSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: DesignerColors.textSecondary,
                  ),
                  const SizedBox(width: DesignerSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: DesignerTypography.body),
                        if (description != null)
                          Text(
                            description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DesignerTypography.helper,
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.add,
                    size: 16,
                    color: DesignerColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DesignerPanelStateMessage extends StatelessWidget {
  const DesignerPanelStateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignerSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: DesignerColors.textMuted),
            const SizedBox(height: DesignerSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: DesignerTypography.label,
            ),
            const SizedBox(height: DesignerSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: DesignerTypography.helper,
            ),
          ],
        ),
      ),
    );
  }
}
