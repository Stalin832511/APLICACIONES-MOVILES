import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ============================================================
/// ESPACIADO
/// ============================================================

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
}

/// ============================================================
/// RADIOS
/// ============================================================

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 22;
}

/// ============================================================
/// COLORES DE ESTADOS DE SOLICITUD
/// ============================================================

@immutable
class AppStatusColors
    extends ThemeExtension<AppStatusColors> {
  final Color pendienteBg;
  final Color pendienteFg;
  final Color pendienteBorder;

  final Color enCaminoBg;
  final Color enCaminoFg;
  final Color enCaminoBorder;

  final Color completadoBg;
  final Color completadoFg;
  final Color completadoBorder;

  const AppStatusColors({
    required this.pendienteBg,
    required this.pendienteFg,
    required this.pendienteBorder,
    required this.enCaminoBg,
    required this.enCaminoFg,
    required this.enCaminoBorder,
    required this.completadoBg,
    required this.completadoFg,
    required this.completadoBorder,
  });

  static const dark =
      AppStatusColors(
    pendienteBg:
        Color(0x33F59E0B),
    pendienteFg:
        Color(0xFFFBBF24),
    pendienteBorder:
        Color(0x66F59E0B),

    enCaminoBg:
        Color(0x333B82F6),
    enCaminoFg:
        Color(0xFF60A5FA),
    enCaminoBorder:
        Color(0x663B82F6),

    completadoBg:
        Color(0x3322C55E),
    completadoFg:
        Color(0xFF4ADE80),
    completadoBorder:
        Color(0x6622C55E),
  );

  static const light =
      AppStatusColors(
    pendienteBg:
        Color(0xFFFFF4D6),
    pendienteFg:
        Color(0xFF9A6700),
    pendienteBorder:
        Color(0xFFFFD666),

    enCaminoBg:
        Color(0xFFE8F1FF),
    enCaminoFg:
        Color(0xFF1769AA),
    enCaminoBorder:
        Color(0xFFA9C9F7),

    completadoBg:
        Color(0xFFE5F7ED),
    completadoFg:
        Color(0xFF16794A),
    completadoBorder:
        Color(0xFFA8DFC1),
  );

  @override
  AppStatusColors copyWith({
    Color? pendienteBg,
    Color? pendienteFg,
    Color? pendienteBorder,
    Color? enCaminoBg,
    Color? enCaminoFg,
    Color? enCaminoBorder,
    Color? completadoBg,
    Color? completadoFg,
    Color? completadoBorder,
  }) {
    return AppStatusColors(
      pendienteBg:
          pendienteBg ??
              this.pendienteBg,
      pendienteFg:
          pendienteFg ??
              this.pendienteFg,
      pendienteBorder:
          pendienteBorder ??
              this.pendienteBorder,

      enCaminoBg:
          enCaminoBg ??
              this.enCaminoBg,
      enCaminoFg:
          enCaminoFg ??
              this.enCaminoFg,
      enCaminoBorder:
          enCaminoBorder ??
              this.enCaminoBorder,

      completadoBg:
          completadoBg ??
              this.completadoBg,
      completadoFg:
          completadoFg ??
              this.completadoFg,
      completadoBorder:
          completadoBorder ??
              this.completadoBorder,
    );
  }

  @override
  AppStatusColors lerp(
    ThemeExtension<AppStatusColors>?
        other,
    double t,
  ) {
    if (other is! AppStatusColors) {
      return this;
    }

    return AppStatusColors(
      pendienteBg:
          Color.lerp(
            pendienteBg,
            other.pendienteBg,
            t,
          )!,
      pendienteFg:
          Color.lerp(
            pendienteFg,
            other.pendienteFg,
            t,
          )!,
      pendienteBorder:
          Color.lerp(
            pendienteBorder,
            other.pendienteBorder,
            t,
          )!,

      enCaminoBg:
          Color.lerp(
            enCaminoBg,
            other.enCaminoBg,
            t,
          )!,
      enCaminoFg:
          Color.lerp(
            enCaminoFg,
            other.enCaminoFg,
            t,
          )!,
      enCaminoBorder:
          Color.lerp(
            enCaminoBorder,
            other.enCaminoBorder,
            t,
          )!,

      completadoBg:
          Color.lerp(
            completadoBg,
            other.completadoBg,
            t,
          )!,
      completadoFg:
          Color.lerp(
            completadoFg,
            other.completadoFg,
            t,
          )!,
      completadoBorder:
          Color.lerp(
            completadoBorder,
            other.completadoBorder,
            t,
          )!,
    );
  }
}

/// ============================================================
/// TEMA PRINCIPAL
/// ============================================================

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final colorScheme =
        const ColorScheme.dark(
      primary:
          AppColors.primary,

      onPrimary:
          Colors.white,

      primaryContainer:
          AppColors.primaryDark,

      onPrimaryContainer:
          Colors.white,

      secondary:
          AppColors.secondary,

      onSecondary:
          Colors.white,

      surface:
          AppColors.surface,

      onSurface:
          AppColors.textPrimary,

      surfaceContainerHighest:
          AppColors.surfaceLight,

      onSurfaceVariant:
          AppColors.textSecondary,

      outline:
          AppColors.border,

      error:
          AppColors.error,

      onError:
          Colors.white,
    );

    return ThemeData(
      useMaterial3: true,

      brightness:
          Brightness.dark,

      colorScheme:
          colorScheme,

      scaffoldBackgroundColor:
          AppColors.background,

      fontFamily:
          'Arial',

      appBarTheme:
          const AppBarTheme(
        backgroundColor:
            AppColors.background,
        foregroundColor:
            AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme:
          CardThemeData(
        color:
            AppColors.surface,
        elevation: 0,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            AppRadius.lg,
          ),
          side:
              const BorderSide(
            color:
                AppColors.border,
          ),
        ),
      ),

      inputDecorationTheme:
          InputDecorationTheme(
        filled: true,
        fillColor:
            AppColors.surface,

        hintStyle:
            const TextStyle(
          color:
              AppColors.textTertiary,
        ),

        labelStyle:
            const TextStyle(
          color:
              AppColors.textSecondary,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            AppRadius.md,
          ),
          borderSide:
              const BorderSide(
            color:
                AppColors.border,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            AppRadius.md,
          ),
          borderSide:
              const BorderSide(
            color:
                AppColors.primary,
            width: 1.5,
          ),
        ),

        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            AppRadius.md,
          ),
          borderSide:
              const BorderSide(
            color:
                AppColors.error,
          ),
        ),

        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            AppRadius.md,
          ),
          borderSide:
              const BorderSide(
            color:
                AppColors.error,
            width: 1.5,
          ),
        ),
      ),

      elevatedButtonTheme:
          ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              AppColors.primary,
          foregroundColor:
              Colors.white,

          minimumSize:
              const Size(
            double.infinity,
            52,
          ),

          elevation: 0,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),

          textStyle:
              const TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      filledButtonTheme:
          FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
          backgroundColor:
              AppColors.primary,
          foregroundColor:
              Colors.white,

          minimumSize:
              const Size(
            double.infinity,
            52,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),

          textStyle:
              const TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme:
          TextButtonThemeData(
        style:
            TextButton.styleFrom(
          foregroundColor:
              AppColors.primaryLight,

          textStyle:
              const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      iconTheme:
          const IconThemeData(
        color:
            AppColors.textPrimary,
      ),

      dividerTheme:
          const DividerThemeData(
        color:
            AppColors.border,
        thickness: 1,
      ),

      snackBarTheme:
          SnackBarThemeData(
        backgroundColor:
            AppColors.surfaceElevated,
        contentTextStyle:
            const TextStyle(
          color:
              AppColors.textPrimary,
          fontWeight:
              FontWeight.w600,
        ),
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
      ),

      extensions:
          const <ThemeExtension<dynamic>>[
        AppStatusColors.dark,
      ],

      textTheme:
          const TextTheme(
        titleLarge:
            TextStyle(
          fontSize: 22,
          fontWeight:
              FontWeight.w800,
          color:
              AppColors.textPrimary,
        ),

        titleMedium:
            TextStyle(
          fontSize: 17,
          fontWeight:
              FontWeight.w700,
          color:
              AppColors.textPrimary,
        ),

        titleSmall:
            TextStyle(
          fontSize: 15,
          fontWeight:
              FontWeight.w700,
          color:
              AppColors.textPrimary,
        ),

        bodyLarge:
            TextStyle(
          fontSize: 16,
          color:
              AppColors.textPrimary,
        ),

        bodyMedium:
            TextStyle(
          fontSize: 14,
          color:
              AppColors.textSecondary,
        ),

        bodySmall:
            TextStyle(
          fontSize: 12,
          color:
              AppColors.textSecondary,
        ),

        labelLarge:
            TextStyle(
          fontSize: 14,
          fontWeight:
              FontWeight.w700,
        ),

        labelMedium:
            TextStyle(
          fontSize: 12,
          fontWeight:
              FontWeight.w600,
        ),

        labelSmall:
            TextStyle(
          fontSize: 11,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }

  /// Tema claro.
  ///
  /// Lo mantenemos para que la arquitectura pueda
  /// soportar posteriormente una preferencia de usuario.
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme:
          ColorScheme.fromSeed(
        seedColor:
            AppColors.primary,
        brightness:
            Brightness.light,
      ),
      scaffoldBackgroundColor:
          const Color(0xFFF9FAFB),
      extensions:
          const <ThemeExtension<dynamic>>[
        AppStatusColors.light,
      ],
    );
  }
}