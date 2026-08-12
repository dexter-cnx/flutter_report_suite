import 'package:flutter/material.dart';

import 'designer_colors.dart';
import 'designer_layout.dart';
import 'designer_spacing.dart';
import 'designer_typography.dart';

class DesignerAppShell extends StatelessWidget {
  const DesignerAppShell({
    super.key,
    required this.toolbar,
    required this.workspace,
    this.leftPanel,
    this.rightPanel,
    this.statusBar,
  });

  final Widget toolbar;
  final Widget workspace;
  final Widget? leftPanel;
  final Widget? rightPanel;
  final Widget? statusBar;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DesignerColors.appBackground,
      child: Column(
        children: [
          SizedBox(
            height: DesignerLayout.topToolbarHeight,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: DesignerColors.panelBackground,
                border: Border(
                  bottom: BorderSide(color: DesignerColors.borderDefault),
                ),
              ),
              child: toolbar,
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (leftPanel != null)
                  SizedBox(
                    width: DesignerLayout.leftPanelWidth,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: DesignerColors.panelBackground,
                        border: Border(
                          right: BorderSide(
                            color: DesignerColors.borderDefault,
                          ),
                        ),
                      ),
                      child: leftPanel,
                    ),
                  ),
                Expanded(child: workspace),
                if (rightPanel != null)
                  SizedBox(
                    width: DesignerLayout.rightInspectorWidth,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: DesignerColors.panelBackground,
                        border: Border(
                          left: BorderSide(
                            color: DesignerColors.borderDefault,
                          ),
                        ),
                      ),
                      child: rightPanel,
                    ),
                  ),
              ],
            ),
          ),
          if (statusBar != null)
            SizedBox(
              height: DesignerLayout.statusBarHeight,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: DesignerColors.panelBackground,
                  border: Border(
                    top: BorderSide(color: DesignerColors.borderDefault),
                  ),
                ),
                child: statusBar,
              ),
            ),
        ],
      ),
    );
  }
}

class DesignerStatusBar extends StatelessWidget {
  const DesignerStatusBar({
    super.key,
    required this.leading,
    this.center,
    this.trailing,
  });

  final Widget leading;
  final Widget? center;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignerSpacing.md),
      child: Row(
        children: [
          DefaultTextStyle(
            style: DesignerTypography.status,
            child: leading,
          ),
          if (center != null) ...[
            const Spacer(),
            DefaultTextStyle(
              style: DesignerTypography.status,
              child: center!,
            ),
          ],
          const Spacer(),
          if (trailing != null)
            DefaultTextStyle(
              style: DesignerTypography.status,
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
