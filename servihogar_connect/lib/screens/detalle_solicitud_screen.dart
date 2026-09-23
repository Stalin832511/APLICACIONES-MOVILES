import 'package:flutter/material.dart';
import '../models/solicitud.dart';
import '../widgets/status_badge.dart';
import '../theme/app_theme.dart';

/// Pantalla real: "Detalle de Solicitud"
/// No hace fetch de datos ni conoce otras rutas: recibe la
/// SolicitudModel ya cargada por MisSolicitudesScreen.
class DetalleSolicitudScreen extends StatelessWidget {
  final SolicitudModel solicitud;

  const DetalleSolicitudScreen({super.key, required this.solicitud});

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/${fecha.year} '
        '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
  }

  Widget _fila(BuildContext context, String etiqueta, String valor) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(valor, style: textTheme.bodyMedium),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tieneUbicacion = solicitud.latitud != null && solicitud.longitud != null;

    return Scaffold(
      appBar: AppBar(title: Text('Solicitud #${solicitud.id}')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(solicitud.descripcion, style: textTheme.titleLarge),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(status: solicitud.status),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          if (solicitud.categoriaNombre != null)
            _fila(context, 'Categoría', solicitud.categoriaNombre!),
          if (solicitud.usuarioNombre != null)
            _fila(context, 'Solicitado por', solicitud.usuarioNombre!),
          _fila(context, 'Fecha de creación', _formatearFecha(solicitud.fechaCreacion)),
          if (solicitud.clientOperationId != null)
            _fila(context, 'ID de operación (offline-sync)', solicitud.clientOperationId!),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        color: colorScheme.onSurfaceVariant, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Ubicación', style: textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (tieneUbicacion)
                  Text(
                    'Lat: ${solicitud.latitud!.toStringAsFixed(6)}\n'
                    'Long: ${solicitud.longitud!.toStringAsFixed(6)}',
                    style: textTheme.bodyMedium,
                  )
                else
                  Text(
                    'No se registró ubicación para esta solicitud.',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(Icons.photo_camera_outlined,
                    color: colorScheme.onSurfaceVariant, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'La fotografía se guarda solo en el dispositivo que creó la '
                    'solicitud; aún no se sincroniza con el servidor.',
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
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