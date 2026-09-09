import 'package:flutter/material.dart';

/// ============================================================
/// COLORES PRIMITIVOS
/// ============================================================
///
/// Este archivo contiene únicamente valores de color.
///
/// No deben utilizarse directamente desde las pantallas.
/// Las pantallas deben consumir AppColors.
///
/// Arquitectura:
///
///     AppColorsPrimitive
///             ↓
///         AppColors
///             ↓
///         AppTheme
///             ↓
///       UI / Widgets
///

class AppColorsPrimitive {
  AppColorsPrimitive._();

  // ==========================================================
  // BLANCOS Y NEGROS
  // ==========================================================

  static const Color white =
      Color(0xFFFFFFFF);

  static const Color black =
      Color(0xFF000000);

  // ==========================================================
  // ESCALA OSCURA
  // ==========================================================

  static const Color dark950 =
      Color(0xFF09090F);

  static const Color dark900 =
      Color(0xFF0F0F17);

  static const Color dark800 =
      Color(0xFF12121B);

  static const Color dark700 =
      Color(0xFF1A1925);

  static const Color dark600 =
      Color(0xFF211F2D);

  static const Color dark500 =
      Color(0xFF252431);

  // ==========================================================
  // ESCALA MORADA
  // ==========================================================

  static const Color purple50 =
      Color(0xFFF5F3FF);

  static const Color purple100 =
      Color(0xFFEDE9FE);

  static const Color purple300 =
      Color(0xFFC4B5FD);

  static const Color purple400 =
      Color(0xFFA78BFA);

  static const Color purple500 =
      Color(0xFF8B5CF6);

  static const Color purple600 =
      Color(0xFF7C3AED);

  static const Color purple700 =
      Color(0xFF6D28D9);

  static const Color purple800 =
      Color(0xFF5B21B6);

  // ==========================================================
  // ESCALA INDIGO
  // ==========================================================

  static const Color indigo50 =
      Color(0xFFEEF0FF);

  static const Color indigo500 =
      Color(0xFF6366F1);

  static const Color indigo700 =
      Color(0xFF3730A3);

  // ==========================================================
  // ESCALA AZUL
  // ==========================================================

  static const Color blue50 =
      Color(0xFFEFF6FF);

  static const Color blue500 =
      Color(0xFF3B82F6);

  static const Color blue700 =
      Color(0xFF1D4ED8);

  // ==========================================================
  // ESCALA VERDE
  // ==========================================================

  static const Color green50 =
      Color(0xFFECFDF5);

  static const Color green500 =
      Color(0xFF22C55E);

  static const Color green600 =
      Color(0xFF059669);

  static const Color green800 =
      Color(0xFF065F46);

  // ==========================================================
  // ESCALA ÁMBAR
  // ==========================================================

  static const Color amber50 =
      Color(0xFFFFFBEB);

  static const Color amber500 =
      Color(0xFFF59E0B);

  static const Color amber600 =
      Color(0xFFD97706);

  static const Color amber800 =
      Color(0xFF92400E);

  // ==========================================================
  // ESCALA ROJA
  // ==========================================================

  static const Color red50 =
      Color(0xFFFEF2F2);

  static const Color red500 =
      Color(0xFFEF4444);

  static const Color red600 =
      Color(0xFFDC2626);

  static const Color red800 =
      Color(0xFF991B1B);

  // ==========================================================
  // ESCALA GRIS
  // ==========================================================

  static const Color gray50 =
      Color(0xFFF9FAFB);

  static const Color gray100 =
      Color(0xFFF3F4F6);

  static const Color gray300 =
      Color(0xFFD1D5DB);

  static const Color gray500 =
      Color(0xFF6B7280);

  static const Color gray700 =
      Color(0xFF374151);

  static const Color gray900 =
      Color(0xFF111827);
}