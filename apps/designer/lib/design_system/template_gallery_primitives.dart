import 'package:flutter/material.dart';

import 'designer_colors.dart';
import 'designer_radius.dart';
import 'designer_spacing.dart';
import 'designer_typography.dart';

class TemplateCard extends StatefulWidget {
  const TemplateCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onPressed,
    this.badge,
    this.primary = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onPressed;
  final String? badge;
  final bool primary;

  @override
  State<TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<TemplateCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.primary
        ? DesignerColors.primary
        : _hovered
            ? DesignerColors.borderStrong
            : DesignerColors.borderDefault;
    final iconColor = widget.primary
        ? DesignerColors.primary
        : DesignerColors.textSecondary;

    return Semantics(
      button: true,
      label: widget.title,
      hint: widget.description,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hovered
                ? DesignerColors.surfaceHover
                : DesignerColors.panelBackground,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(DesignerRadius.menu),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(DesignerRadius.menu),
            child: InkWell(
              borderRadius: BorderRadius.circular(DesignerRadius.menu),
              onTap: widget.onPressed,
              child: Padding(
                padding: const EdgeInsets.all(DesignerSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: widget.primary
                                ? DesignerColors.primarySubtle
                                : DesignerColors.appBackground,
                            borderRadius: BorderRadius.circular(
                              DesignerRadius.control,
                            ),
                          ),
                          child: Icon(widget.icon, size: 24, color: iconColor),
                        ),
                        const Spacer(),
                        if (widget.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignerSpacing.sm,
                              vertical: DesignerSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: DesignerColors.appBackground,
                              borderRadius: BorderRadius.circular(
                                DesignerRadius.badge,
                              ),
                            ),
                            child: Text(
                              widget.badge!,
                              style: DesignerTypography.helper,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(widget.title, style: DesignerTypography.panelTitle),
                    const SizedBox(height: DesignerSpacing.xs),
                    Text(
                      widget.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DesignerTypography.helper,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
