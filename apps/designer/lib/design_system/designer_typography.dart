import 'package:flutter/material.dart';

import 'designer_colors.dart';

abstract final class DesignerTypography {
  static const appTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: DesignerColors.textPrimary,
  );

  static const screenTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 28 / 18,
    color: DesignerColors.textPrimary,
  );

  static const panelTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 20 / 13,
    color: DesignerColors.textPrimary,
  );

  static const sectionTitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 16 / 11,
    letterSpacing: 0.35,
    color: DesignerColors.textSecondary,
  );

  static const controlLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    color: DesignerColors.textSecondary,
  );

  static const controlValue = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 20 / 13,
    color: DesignerColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 20 / 13,
    color: DesignerColors.textPrimary,
  );

  static const helper = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 16 / 11,
    color: DesignerColors.textSecondary,
  );

  static const status = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 16 / 11,
    color: DesignerColors.textSecondary,
  );

  static const monospace = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: DesignerColors.textPrimary,
  );
}
