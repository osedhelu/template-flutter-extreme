import 'package:flutter/material.dart';
import 'package:wap_xcontrol/core/theme/app_palette.dart';

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.light(
    primary: AppPalette.pantone7466,
    onPrimary: Colors.white,
    primaryContainer: AppPalette.primaryContainerLight,
    onPrimaryContainer: AppPalette.onPrimaryContainer,
    secondary: AppPalette.pantone356,
    onSecondary: Colors.white,
    secondaryContainer: AppPalette.secondaryContainerLight,
    onSecondaryContainer: AppPalette.onSecondaryContainer,
    tertiary: AppPalette.pantone389,
    onTertiary: AppPalette.onTertiaryContainer,
    tertiaryContainer: AppPalette.tertiaryContainerLight,
    onTertiaryContainer: AppPalette.onTertiaryContainer,
    error: AppPalette.error,
    onError: AppPalette.onError,
    errorContainer: AppPalette.errorContainer,
    onErrorContainer: AppPalette.onErrorContainer,
    surface: AppPalette.surface,
    onSurface: AppPalette.onSurface,
    onSurfaceVariant: AppPalette.onSurfaceVariant,
    outline: AppPalette.outline,
    outlineVariant: AppPalette.outlineVariant,
    shadow: Colors.black26,
    scrim: Colors.black54,
    inverseSurface: AppPalette.onSurface,
    onInverseSurface: AppPalette.surface,
    inversePrimary: AppPalette.primaryContainerLight,
    surfaceContainerHighest: AppPalette.surfaceContainerHighest,
  );

  const radius = 14.0;

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        elevation: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        elevation: 0,
      ),
    ),
  );
}
