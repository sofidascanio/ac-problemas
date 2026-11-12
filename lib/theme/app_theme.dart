import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Único punto de definición visual. Un solo acento; el resto neutro.
class AppTheme {
  static const acento = Color(0xFF5B6EE1);

  /// Verde de "¡Correcto!" (fondo y texto), según brillo.
  static Color verdeFondo(Brightness b) =>
      b == Brightness.dark ? const Color(0xFF1F3D2B) : const Color(0xFFDDF3E4);
  static Color verdeTexto(Brightness b) =>
      b == Brightness.dark ? const Color(0xFF8BE0A4) : const Color(0xFF14602E);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final scheme = ColorScheme.fromSeed(
      seedColor: acento,
      brightness: b,
      dynamicSchemeVariant: DynamicSchemeVariant.neutral,
    ).copyWith(primary: acento, onPrimary: Colors.white);

    final base = ThemeData(brightness: b).textTheme;
    final cuerpo = GoogleFonts.interTextTheme(base);
    TextStyle? titulo(TextStyle? s) => s == null
        ? null
        : GoogleFonts.nunito(textStyle: s, fontWeight: FontWeight.w700);
    final texto = cuerpo.copyWith(
      displayLarge: titulo(cuerpo.displayLarge),
      displayMedium: titulo(cuerpo.displayMedium),
      displaySmall: titulo(cuerpo.displaySmall),
      headlineLarge: titulo(cuerpo.headlineLarge),
      headlineMedium: titulo(cuerpo.headlineMedium),
      headlineSmall: titulo(cuerpo.headlineSmall),
      titleLarge: titulo(cuerpo.titleLarge),
      titleMedium: titulo(cuerpo.titleMedium),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: texto,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: texto.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 10,
        borderRadius: BorderRadius.circular(8),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
