import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/categoria.dart';
import '../widgets/service_category_style.dart';
import 'crear_solicitud_screen.dart';

class DetalleServicioScreen extends StatelessWidget {
  final CategoriaModel category;
  final AppDatabase database;

  const DetalleServicioScreen({
    super.key,
    required this.category,
    required this.database,
  });

  Future<void> _createRequest(BuildContext context) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CrearSolicitudScreen(
          database: database,
          initialCategoryId: category.id,
        ),
      ),
    );
    if (created == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = ServiceCategoryStyle.color(category.nombre);
    final description = category.descripcion?.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del servicio')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Container(
              height: 190,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                ServiceCategoryStyle.icon(category.nombre),
                size: 82,
                color: accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              category.nombre,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description?.isNotEmpty == true
                  ? description!
                  : 'Solicita ayuda profesional para este servicio del hogar.',
              style: textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              '¿Cómo funciona?',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            const _ServiceStep(
              number: '1',
              title: 'Cuéntanos qué necesitas',
              description: 'Describe el problema o trabajo en tu hogar.',
            ),
            const _ServiceStep(
              number: '2',
              title: 'Indica dónde se realizará',
              description: 'Usa la ubicación del dispositivo para tu solicitud.',
            ),
            const _ServiceStep(
              number: '3',
              title: 'Consulta el seguimiento',
              description: 'Revisa el estado desde la sección Mis solicitudes.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _createRequest(context),
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Solicitar este servicio'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _ServiceStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.primaryContainer,
            child: Text(
              number,
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
