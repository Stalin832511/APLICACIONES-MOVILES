import 'package:flutter/material.dart';

class ServiceCategoryStyle {
  ServiceCategoryStyle._();

  static IconData icon(String name) {
    final value = name.toLowerCase();
    if (value.contains('plomer')) return Icons.water_drop_outlined;
    if (value.contains('electric')) return Icons.bolt_rounded;
    if (value.contains('limpieza')) return Icons.cleaning_services_outlined;
    if (value.contains('pintura')) return Icons.format_paint_outlined;
    if (value.contains('cerrajer')) return Icons.key_rounded;
    if (value.contains('aire') || value.contains('climat')) {
      return Icons.ac_unit_rounded;
    }
    if (value.contains('jard')) return Icons.yard_outlined;
    if (value.contains('carpinter')) return Icons.carpenter_outlined;
    if (value.contains('instal')) return Icons.install_desktop_outlined;
    return Icons.handyman_outlined;
  }

  static Color color(String name) {
    final value = name.toLowerCase();
    if (value.contains('plomer')) return const Color(0xFF3B82F6);
    if (value.contains('electric')) return const Color(0xFFA855F7);
    if (value.contains('limpieza')) return const Color(0xFF14B8A6);
    if (value.contains('pintura')) return const Color(0xFFEC4899);
    if (value.contains('cerrajer')) return const Color(0xFFF59E0B);
    if (value.contains('aire') || value.contains('climat')) {
      return const Color(0xFF38BDF8);
    }
    if (value.contains('jard')) return const Color(0xFF22C55E);
    if (value.contains('carpinter')) return const Color(0xFFD97706);
    return const Color(0xFF8B5CF6);
  }
}
