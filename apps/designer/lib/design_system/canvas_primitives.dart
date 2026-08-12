import 'package:flutter/material.dart';

import 'designer_colors.dart';
import 'designer_elevation.dart';
import 'designer_layout.dart';
import 'designer_typography.dart';

class CanvasViewport extends StatelessWidget {
  const CanvasViewport({
    super.key,
    required this.child,
    this.boundaryMargin = const EdgeInsets.all(120),
  });

  final Widget child;
  final EdgeInsets boundaryMargin;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DesignerColors.workspaceBackground,
      child: InteractiveViewer(
        scaleEnabled: false,
        boundaryMargin: boundaryMargin,
        child: Center(child: child),
      ),
    );
  }
}

class CanvasPage extends StatelessWidget {
  const CanvasPage({
    super.key,
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.none,
      decoration: const BoxDecoration(
        color: DesignerColors.canvasBackground,
        boxShadow: DesignerElevation.canvasPaper,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.fromBorderSide(
                  BorderSide(color: DesignerColors.borderStrong),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum CanvasRulerAxis { horizontal, vertical }

class CanvasRuler extends StatelessWidget {
  const CanvasRuler({
    super.key,
    required this.axis,
    required this.lengthMm,
    required this.scale,
    this.stepMm = 10,
  });

  final CanvasRulerAxis axis;
  final double lengthMm;
  final double scale;
  final double stepMm;

  @override
  Widget build(BuildContext context) {
    final marks = (lengthMm / stepMm).floor();
    final horizontal = axis == CanvasRulerAxis.horizontal;
    final width = horizontal ? lengthMm * scale : 28.0;
    final height = horizontal ? 22.0 : lengthMm * scale + 22.0;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: List.generate(marks + 1, (index) {
          final value = index * stepMm;
          return Positioned(
            left: horizontal ? value * scale : null,
            top: horizontal ? null : 22 + value * scale,
            right: horizontal ? null : 2,
            child: Text(
              value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
              style: DesignerTypography.status.copyWith(fontSize: 9),
            ),
          );
        }),
      ),
    );
  }
}

class CanvasGuideOverlay extends StatelessWidget {
  const CanvasGuideOverlay({
    super.key,
    this.showVerticalCenter = true,
    this.showHorizontalCenter = true,
  });

  final bool showVerticalCenter;
  final bool showHorizontalCenter;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showVerticalCenter)
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 1,
                color: DesignerColors.info.withValues(alpha: 0.4),
              ),
            ),
          if (showHorizontalCenter)
            Align(
              alignment: Alignment.center,
              child: Container(
                height: 1,
                color: DesignerColors.info.withValues(alpha: 0.4),
              ),
            ),
        ],
      ),
    );
  }
}

class CanvasSelectionOverlay extends StatelessWidget {
  const CanvasSelectionOverlay({
    super.key,
    required this.child,
    this.selected = true,
    this.showHandles = true,
  });

  final Widget child;
  final bool selected;
  final bool showHandles;

  @override
  Widget build(BuildContext context) {
    if (!selected) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: DesignerColors.primary.withValues(alpha: 0.05),
            border: Border.all(color: DesignerColors.primary),
          ),
          child: child,
        ),
        if (showHandles) ..._handles(),
      ],
    );
  }

  List<Widget> _handles() {
    const size = DesignerLayout.selectionHandleSize;
    const half = size / 2;

    Widget handle(
      String id, {
      double? left,
      double? right,
      double? top,
      double? bottom,
    }) {
      return Positioned(
        left: left,
        right: right,
        top: top,
        bottom: bottom,
        child: Container(
          key: ValueKey('selection-handle-$id'),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: DesignerColors.panelBackground,
            border: Border.all(color: DesignerColors.primary),
          ),
        ),
      );
    }

    return [
      handle('top-left', left: -half, top: -half),
      handle('top-right', right: -half, top: -half),
      handle('bottom-left', left: -half, bottom: -half),
      handle('bottom-right', right: -half, bottom: -half),
    ];
  }
}
