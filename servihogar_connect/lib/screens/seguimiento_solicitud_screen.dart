import 'package:flutter/material.dart';

import '../models/solicitud.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

class SeguimientoSolicitudScreen extends StatelessWidget {
  final SolicitudModel solicitud;

  const SeguimientoSolicitudScreen({
    super.key,
    required this.solicitud,
  });

  int get _activeStep {
    if (solicitud.pendingSync) return 0;
    return switch (solicitud.status) {
      RequestStatus.pendiente => 0,
      RequestStatus.enCamino => 1,
      RequestStatus.enProceso => 2,
      RequestStatus.completado => 3,
    };
  }

  String _fecha(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year} · '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final steps = [
      (
        icon: Icons.receipt_long_rounded,
        title: 'Solicitud recibida',
        detail: solicitud.pendingSync
            ? 'Guardada en este dispositivo. Se enviará cuando vuelva la conexión.'
            : 'Registrada el ${_fecha(solicitud.fechaCreacion)}.',
      ),
      (
        icon: Icons.directions_car_filled_rounded,
        title: 'Atención en camino',
        detail: 'Este paso se actualizará cuando recibamos el cambio de estado.',
      ),
      (
        icon: Icons.handyman_rounded,
        title: 'Servicio en proceso',
        detail: 'El avance se mostrará aquí cuando el estado se actualice.',
      ),
      (
        icon: Icons.check_circle_rounded,
        title: 'Servicio completado',
        detail: 'La solicitud aparecerá como completada al finalizar el trabajo.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF312E81), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solicitud.pendingSync
                      ? 'Esperando conexión'
                      : 'Solicitud #${solicitud.id}',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  solicitud.descripcion,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.home_repair_service_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        solicitud.categoriaNombre ?? 'Servicio del hogar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    StatusBadge(status: solicitud.status),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Progreso del servicio',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < steps.length; index++)
            _ProgressStep(
              icon: steps[index].icon,
              title: steps[index].title,
              detail: steps[index].detail,
              active: index == _activeStep,
              complete: index < _activeStep,
              last: index == steps.length - 1,
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'El seguimiento refleja el último estado recibido por la '
                    'aplicación. Todavía no se muestra la ubicación en vivo ni '
                    'un tiempo estimado de llegada.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (solicitud.latitud != null && solicitud.longitud != null) ...[
            const SizedBox(height: 14),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              tileColor: colors.surfaceContainerHighest,
              leading: Icon(Icons.location_on_outlined, color: colors.primary),
              title: const Text('Ubicación del servicio'),
              subtitle: Text(
                '${solicitud.latitud!.toStringAsFixed(5)}, '
                '${solicitud.longitud!.toStringAsFixed(5)}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final bool active;
  final bool complete;
  final bool last;

  const _ProgressStep({
    required this.icon,
    required this.title,
    required this.detail,
    required this.active,
    required this.complete,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = complete || active
        ? colors.primary
        : colors.onSurfaceVariant;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: foreground.withValues(alpha: 0.14),
                  child: Icon(icon, size: 20, color: foreground),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      color: complete
                          ? colors.primary
                          : colors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                          color: active ? colors.primary : null,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
