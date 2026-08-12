import 'package:flutter/material.dart';

import 'designer_colors.dart';
import 'designer_layout.dart';
import 'designer_radius.dart';
import 'designer_typography.dart';

abstract final class DesignerTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: DesignerColors.primary,
      brightness: Brightness.light,
      surface: DesignerColors.panelBackground,
      error: DesignerColors.error,
    );

    const inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(DesignerRadius.control)),
      borderSide: BorderSide(color: DesignerColors.borderDefault),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: DesignerColors.appBackground,
      dividerColor: DesignerColors.borderDefault,
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignerColors.panelBackground,
        foregroundColor: DesignerColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: DesignerLayout.topToolbarHeight,
        titleTextStyle: DesignerTypography.appTitle,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: DesignerColors.panelBackground,
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(DesignerRadius.control)),
          borderSide: BorderSide(color: DesignerColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(DesignerRadius.control)),
          borderSide: BorderSide(color: DesignerColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(DesignerRadius.control)),
          borderSide: BorderSide(color: DesignerColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(DesignerRadius.control)),
          borderSide: BorderSide(color: DesignerColors.error, width: 2),
        ),
        labelStyle: DesignerTypography.controlLabel,
        hintStyle: TextStyle(
          fontSize: 12,
          color: DesignerColors.textMuted,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: DesignerTypography.screenTitle,
        titleMedium: DesignerTypography.appTitle,
        titleSmall: DesignerTypography.panelTitle,
        bodyLarge: DesignerTypography.body,
        bodyMedium: DesignerTypography.body,
        bodySmall: DesignerTypography.helper,
        labelLarge: DesignerTypography.controlLabel,
        labelMedium: DesignerTypography.controlLabel,
        labelSmall: DesignerTypography.status,
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: DesignerTypography.helper.copyWith(color: Colors.white),
        decoration: BoxDecoration(
          color: DesignerColors.textPrimary,
          borderRadius: BorderRadius.circular(DesignerRadius.control),
        ),
      ),
    );
  }
}
