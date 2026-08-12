import 'package:flutter/material.dart';

import 'designer_colors.dart';
import 'designer_layout.dart';
import 'designer_radius.dart';
import 'designer_spacing.dart';
import 'designer_typography.dart';

class ToolbarButton extends StatelessWidget {
  const ToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: DesignerLayout.standardControlHeight,
        child: IconButton(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor:
                selected ? DesignerColors.primarySubtle : Colors.transparent,
            foregroundColor: selected
                ? DesignerColors.primary
                : DesignerColors.textSecondary,
            disabledForegroundColor: DesignerColors.textMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignerRadius.control),
            ),
          ),
          icon: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: DesignerLayout.panelHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: DesignerSpacing.md),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DesignerColors.borderDefault),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: DesignerTypography.panelTitle,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class InspectorSection extends StatefulWidget {
  const InspectorSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
    this.trailing,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final Widget? trailing;

  @override
  State<InspectorSection> createState() => _InspectorSectionState();
}

class _InspectorSectionState extends State<InspectorSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DesignerColors.borderDefault),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: SizedBox(
              height: DesignerLayout.panelHeaderHeight,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: DesignerSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 16,
                      color: DesignerColors.textSecondary,
                    ),
                    const SizedBox(width: DesignerSpacing.xs),
                    Expanded(
                      child: Text(
                        widget.title.toUpperCase(),
                        style: DesignerTypography.sectionTitle,
                      ),
                    ),
                    if (widget.trailing != null) widget.trailing!,
                  ],
                ),
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignerSpacing.md,
                DesignerSpacing.sm,
                DesignerSpacing.md,
                DesignerSpacing.md,
              ),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

class PropertyInput extends StatelessWidget {
  const PropertyInput({
    super.key,
    this.initialValue,
    this.label,
    this.hintText,
    this.onSubmitted,
    this.enabled = true,
  });

  final String? initialValue;
  final String? label;
  final String? hintText;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DesignerLayout.compactControlHeight,
      child: TextFormField(
        initialValue: initialValue,
        enabled: enabled,
        style: DesignerTypography.controlValue,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
        ),
        onFieldSubmitted: onSubmitted,
      ),
    );
  }
}

class NumberPropertyInput extends StatelessWidget {
  const NumberPropertyInput({
    super.key,
    required this.value,
    required this.onSubmitted,
    this.label,
    this.unit,
    this.fractionDigits = 1,
  });

  final double value;
  final ValueChanged<double> onSubmitted;
  final String? label;
  final String? unit;
  final int fractionDigits;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DesignerLayout.compactControlHeight,
      child: TextFormField(
        key: ValueKey('$label-$value'),
        initialValue: value.toStringAsFixed(fractionDigits),
        style: DesignerTypography.controlValue,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
        ),
        onFieldSubmitted: (raw) {
          final parsed = double.tryParse(raw);
          if (parsed != null) onSubmitted(parsed);
        },
      ),
    );
  }
}

class PropertyDropdown<T> extends StatelessWidget {
  const PropertyDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DesignerLayout.compactControlHeight,
      child: DropdownButtonFormField<T>(
        // Flutter 3.32.7 uses `value`; later Flutter versions prefer
        // `initialValue` for form fields.
        // ignore: deprecated_member_use
        value: value,
        isExpanded: true,
        style: DesignerTypography.controlValue,
        decoration: InputDecoration(labelText: label),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

class PropertyToggle extends StatelessWidget {
  const PropertyToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DesignerLayout.compactControlHeight,
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: DesignerTypography.controlLabel),
          ),
          Checkbox(
            value: value,
            visualDensity: VisualDensity.compact,
            onChanged: onChanged == null
                ? null
                : (next) => onChanged!(next ?? false),
          ),
        ],
      ),
    );
  }
}

class ZoomControl extends StatelessWidget {
  const ZoomControl({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.5,
    this.max = 2.0,
    this.step = 0.1,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double step;

  @override
  Widget build(BuildContext context) {
    void change(double next) => onChanged(next.clamp(min, max).toDouble());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ToolbarButton(
          icon: Icons.remove,
          tooltip: 'Zoom out',
          onPressed: value <= min ? null : () => change(value - step),
        ),
        SizedBox(
          width: 52,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.center,
            style: DesignerTypography.status,
          ),
        ),
        ToolbarButton(
          icon: Icons.add,
          tooltip: 'Zoom in',
          onPressed: value >= max ? null : () => change(value + step),
        ),
      ],
    );
  }
}

enum InlineAlertSeverity { info, success, warning, error }

class InlineAlert extends StatelessWidget {
  const InlineAlert({
    super.key,
    required this.message,
    this.severity = InlineAlertSeverity.info,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final InlineAlertSeverity severity;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (severity) {
      InlineAlertSeverity.info => (DesignerColors.info, Icons.info_outline),
      InlineAlertSeverity.success =>
        (DesignerColors.success, Icons.check_circle_outline),
      InlineAlertSeverity.warning =>
        (DesignerColors.warning, Icons.warning_amber_outlined),
      InlineAlertSeverity.error => (DesignerColors.error, Icons.error_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignerSpacing.md,
        vertical: DesignerSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(DesignerRadius.control),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: DesignerSpacing.sm),
          Expanded(child: Text(message, style: DesignerTypography.helper)),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
