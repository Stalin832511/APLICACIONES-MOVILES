import 'package:flutter/material.dart';
import 'app_colors_primitive.dart';

/// Nivel SEMÁNTICO: le da significado/uso a los primitivos.
/// Este es el archivo que consumen los componentes y pantallas.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
}

/// Colores adicionales que ColorScheme no cubre directamente
/// (estados de negocio: pendiente, en camino, completado).
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  final Color pendienteBg;
  final Color pendienteFg;
  final Color enCaminoBg;
  final Color enCaminoFg;
  final Color completadoBg;
  final Color completadoFg;

  const AppStatusColors({
    required this.pendienteBg,
    required this.pendienteFg,
    required this.enCaminoBg,
    required this.enCaminoFg,
    required this.completadoBg,
    required this.completadoFg,
  });

  static const light = AppStatusColors(
    pendienteBg: AppColorsPrimitive.gray100,
    pendienteFg: AppColorsPrimitive.gray700,
    enCaminoBg: AppColorsPrimitive.amber50,
    enCaminoFg: AppColorsPrimitive.amber800,
    completadoBg: AppColorsPrimitive.green50,
    completadoFg: AppColorsPrimitive.green800,
  );

  @override
  AppStatusColors copyWith({
    Color? pendienteBg,
    Color? pendienteFg,
    Color? enCaminoBg,
    Color? enCaminoFg,
    Color? completadoBg,
    Color? completadoFg,
  }) {
    return AppStatusColors(
      pendienteBg: pendienteBg ?? this.pendienteBg,
      pendienteFg: pendienteFg ?? this.pendienteFg,
      enCaminoBg: enCaminoBg ?? this.enCaminoBg,
      enCaminoFg: enCaminoFg ?? this.enCaminoFg,
      completadoBg: completadoBg ?? this.completadoBg,
      completadoFg: completadoFg ?? this.completadoFg,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return this;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: AppColorsPrimitive.indigo500,
      onPrimary: AppColorsPrimitive.white,
      primaryContainer: AppColorsPrimitive.indigo50,
      onPrimaryContainer: AppColorsPrimitive.indigo700,
      surface: AppColorsPrimitive.white,
      onSurface: AppColorsPrimitive.gray900,
      surfaceContainerHighest: AppColorsPrimitive.gray50,
      onSurfaceVariant: AppColorsPrimitive.gray500,
      outline: AppColorsPrimitive.gray300,
      error: AppColorsPrimitive.red600,
      onError: AppColorsPrimitive.white,
      errorContainer: AppColorsPrimitive.red50,
      onErrorContainer: AppColorsPrimitive.red800,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColorsPrimitive.gray50,
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      extensions: const [AppStatusColors.light],
    );
  }
}