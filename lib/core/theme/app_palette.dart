import 'package:flutter/material.dart';

/// Paleta de colores XtDespachos basada en Pantone.
///
/// - **3035 C** (#003E51): Azul oscuro / profesional
/// - **7466 C** (#00B0B9): Cyan / primario
/// - **356 C** (#007A33): Verde / secundario
/// - **389 C** (#D0DF00): Lima / acento
/// - **5487 C** (#5E6575): Gris oscuro — cuerpos de texto
/// - **5527 C** (#BCC9C5): Gris claro — texto secundario / complementario
class AppPalette {
  AppPalette._();

  // ─── Pantone base ─────────────────────────────────────────────────────────

  /// Pantone 3035 C — RGB 0, 62, 81 — Azul oscuro
  static const Color pantone3035 = Color(0xFF003E51);

  /// Pantone 7466 C — RGB 0, 176, 185 — Cyan
  static const Color pantone7466 = Color(0xFF00B0B9);

  /// Pantone 356 C — RGB 0, 122, 51 — Verde
  static const Color pantone356 = Color(0xFF007A33);

  /// Pantone 389 C — RGB 208, 223, 0 — Lima
  static const Color pantone389 = Color(0xFFD0DF00);

  /// Pantone 5487 C — RGB 94, 101, 117 — Gris oscuro (cuerpos de texto)
  static const Color pantone5487 = Color(0xFF5E6575);

  /// Pantone 5527 C — RGB 188, 201, 197 — Gris claro (texto secundario)
  static const Color pantone5527 = Color(0xFFBCC9C5);

  // ─── Nombres semánticos (mismo valor que Pantone) ─────────────────────────

  static const Color brandDark = pantone3035;
  static const Color brandPrimary = pantone7466;
  static const Color brandGreen = pantone356;
  static const Color brandLime = pantone389;

  /// Gris oscuro — recomendado para cuerpo de texto en publicaciones y piezas.
  static const Color textGrayDark = pantone5487;

  /// Gris claro — texto secundario y uso complementario.
  static const Color textGrayLight = pantone5527;

  // ─── Variantes claras (containers / fondos) ────────────────────────────────

  static const Color primaryContainerLight = Color(0xFFE0F7F8);
  static const Color secondaryContainerLight = Color(0xFFC8E6D0);
  static const Color tertiaryContainerLight = Color(0xFFF0F5C2);

  // ─── Variantes oscuras (texto sobre claro, bordes) ─────────────────────────

  static const Color onPrimaryContainer = Color(0xFF003E51);
  static const Color onSecondaryContainer = Color(0xFF004D21);
  static const Color onTertiaryContainer = Color(0xFF3D4500);

  // ─── Neutros (superficies y texto) ────────────────────────────────────────
  // Cuerpos de texto y complementarios según manual de marca (5487 C, 5527 C).

  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceDim = Color(0xFFE8ECED);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5F5F5);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE0E0E0);

  /// Texto principal — Pantone 5487 C (gris oscuro).
  static const Color onSurface = pantone5487;

  /// Texto secundario / variante — Pantone 5527 C (gris claro). En fondos oscuros usar onSurface.
  static const Color onSurfaceVariant = pantone5527;

  /// Bordes y divisores — derivado del gris oscuro.
  static const Color outline = pantone5487;

  /// Bordes suaves / deshabilitados.
  static const Color outlineVariant = pantone5527;

  // ─── Error (Material) ─────────────────────────────────────────────────────

  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onErrorContainer = Color(0xFF410E0B);
}
