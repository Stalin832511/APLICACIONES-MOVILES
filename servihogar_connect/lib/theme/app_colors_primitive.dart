import 'package:flutter/material.dart';

/// Nivel PRIMITIVO: colores crudos, sin significado semántico.
/// Nadie fuera de app_theme.dart debería importar este archivo.
class AppColorsPrimitive {
  AppColorsPrimitive._();

  // Escala Indigo
  static const Color indigo50 = Color(0xFFEEF0FF);
  static const Color indigo500 = Color(0xFF4F46E5);
  static const Color indigo700 = Color(0xFF3730A3);

  // Escala Gris (neutro)
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray900 = Color(0xFF111827);

  // Escala Verde (éxito)
  static const Color green50 = Color(0xFFECFDF5);
  static const Color green600 = Color(0xFF059669);
  static const Color green800 = Color(0xFF065F46);

  // Escala Ámbar (advertencia / en proceso)
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber800 = Color(0xFF92400E);

  // Escala Roja (error)
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red800 = Color(0xFF991B1B);

  static const Color white = Color(0xFFFFFFFF);
}