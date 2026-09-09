import 'package:flutter/material.dart';

/// ============================================================
/// COLORES SEMÁNTICOS DE SERVIHOGAR CONNECT
/// ============================================================
///
/// Este archivo es el que deben utilizar las pantallas
/// y componentes de la aplicación.
///
/// Los valores primitivos se mantienen separados en:
///
///     app_colors_primitive.dart
///
/// De esta manera, si posteriormente cambiamos la identidad
/// visual de la aplicación, podemos modificar los colores
/// en un único lugar.
///

class AppColors {
  AppColors._();

  // ==========================================================
  // FONDO GENERAL
  // ==========================================================

  /// Fondo principal de las pantallas.
  static const Color background =
      Color(0xFF09090F);

  /// Fondo alternativo ligeramente elevado.
  static const Color backgroundSecondary =
      Color(0xFF0F0F17);

  // ==========================================================
  // SUPERFICIES
  // ==========================================================

  /// Color principal de las tarjetas.
  static const Color surface =
      Color(0xFF12121B);

  /// Superficie secundaria.
  static const Color surfaceLight =
      Color(0xFF1A1925);

  /// Superficie elevada.
  static const Color surfaceElevated =
      Color(0xFF211F2D);

  // ==========================================================
  // COLOR PRINCIPAL
  // ==========================================================

  /// Morado principal de ServiHogar.
  static const Color primary =
      Color(0xFF8B5CF6);

  /// Morado oscuro para botones y estados activos.
  static const Color primaryDark =
      Color(0xFF6D28D9);

  /// Morado claro para fondos y contenedores.
  static const Color primaryLight =
      Color(0xFFA78BFA);

  // ==========================================================
  // COLOR SECUNDARIO
  // ==========================================================

  static const Color secondary =
      Color(0xFF6366F1);

  // ==========================================================
  // TEXTOS
  // ==========================================================

  /// Texto principal.
  static const Color textPrimary =
      Color(0xFFF8F7FF);

  /// Texto secundario.
  static const Color textSecondary =
      Color(0xFF9A98A8);

  /// Texto terciario.
  static const Color textTertiary =
      Color(0xFF6F6D7A);

  /// Texto deshabilitado.
  static const Color textDisabled =
      Color(0xFF4E4C58);

  // ==========================================================
  // BORDES
  // ==========================================================

  static const Color border =
      Color(0xFF252431);

  static const Color borderLight =
      Color(0xFF302E3D);

  // ==========================================================
  // ESTADOS GENERALES
  // ==========================================================

  /// Operación exitosa.
  static const Color success =
      Color(0xFF22C55E);

  /// Información.
  static const Color info =
      Color(0xFF3B82F6);

  /// Advertencia.
  static const Color warning =
      Color(0xFFF59E0B);

  /// Error.
  static const Color error =
      Color(0xFFEF4444);

  // ==========================================================
  // SOLICITUDES
  // ==========================================================

  /// Solicitud pendiente.
  static const Color requestPending =
      Color(0xFFF59E0B);

  /// Solicitud en camino.
  static const Color requestOnTheWay =
      Color(0xFF3B82F6);

  /// Solicitud completada.
  static const Color requestCompleted =
      Color(0xFF22C55E);

  // ==========================================================
  // CATEGORÍAS DE SERVICIOS
  // ==========================================================

  /// Electricidad.
  static const Color electricity =
      Color(0xFFA855F7);

  /// Plomería.
  static const Color plumbing =
      Color(0xFF3B82F6);

  /// Limpieza.
  static const Color cleaning =
      Color(0xFF14B8A6);

  /// Servicios generales.
  static const Color general =
      Color(0xFFF59E0B);

  // ==========================================================
  // UTILIDADES
  // ==========================================================

  /// Fondo translúcido del color principal.
  static Color primaryContainer({
    double opacity = 0.12,
  }) {
    return primary.withValues(
      alpha: opacity,
    );
  }

  /// Fondo translúcido para estados exitosos.
  static Color successContainer({
    double opacity = 0.12,
  }) {
    return success.withValues(
      alpha: opacity,
    );
  }

  /// Fondo translúcido para advertencias.
  static Color warningContainer({
    double opacity = 0.12,
  }) {
    return warning.withValues(
      alpha: opacity,
    );
  }

  /// Fondo translúcido para errores.
  static Color errorContainer({
    double opacity = 0.12,
  }) {
    return error.withValues(
      alpha: opacity,
    );
  }

  /// Fondo translúcido para información.
  static Color infoContainer({
    double opacity = 0.12,
  }) {
    return info.withValues(
      alpha: opacity,
    );
  }
}