import 'package:flutter/material.dart';

/// Estados posibles de una solicitud de servicio.
enum RequestStatus {
  pendiente,
  enCamino,
  enProceso,
  completado,
}

extension RequestStatusParsing on RequestStatus {
  /// Convierte el texto recibido desde la API
  /// al estado correspondiente.
  ///
  /// Si el valor no es reconocido,
  /// se utiliza pendiente como estado seguro.
  static RequestStatus fromApiValue(
    String value,
  ) {
    switch (value.toLowerCase().trim()) {
      case 'en camino':
      case 'en_camino':
      case 'encamino':
        return RequestStatus.enCamino;

      case 'en proceso':
      case 'en_proceso':
        return RequestStatus.enProceso;

      case 'publicada':
      case 'asignada':
      case 'pendiente':
        return RequestStatus.pendiente;

      case 'completado':
      case 'completada':
      case 'finalizado':
      case 'finalizada':
        return RequestStatus.completado;

      default:
        return RequestStatus.pendiente;
    }
  }
}

/// Componente reutilizable para mostrar
/// visualmente el estado de una solicitud.
class StatusBadge extends StatelessWidget {
  final RequestStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  /// Obtiene la apariencia visual profesional
  /// correspondiente a cada estado.
  ({
    Color bg,
    Color fg,
    Color border,
    String label,
    IconData icon,
  }) _visualFor(
    BuildContext context,
  ) {
    switch (status) {
      case RequestStatus.pendiente:
        return (
          bg: const Color(0xFFFFF4D6),
          fg: const Color(0xFF9A6700),
          border: const Color(0xFFFFD666),
          label: 'Pendiente',
          icon: Icons.schedule_rounded,
        );

      case RequestStatus.enCamino:
        return (
          bg: const Color(0xFFE8F1FF),
          fg: const Color(0xFF1769AA),
          border: const Color(0xFFA9C9F7),
          label: 'En camino',
          icon: Icons.directions_car_filled_rounded,
        );

      case RequestStatus.enProceso:
        return (
          bg: const Color(0xFFE8F1FF),
          fg: const Color(0xFF1769AA),
          border: const Color(0xFFA9C9F7),
          label: 'En proceso',
          icon: Icons.handyman_rounded,
        );

      case RequestStatus.completado:
        return (
          bg: const Color(0xFFE5F7ED),
          fg: const Color(0xFF16794A),
          border: const Color(0xFFA8DFC1),
          label: 'Completado',
          icon: Icons.check_circle_rounded,
        );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final visual = _visualFor(context);

    return Semantics(
      label:
          'Estado de la solicitud: '
          '${visual.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: visual.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: visual.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: visual.fg.withValues(
                  alpha: 0.12,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                visual.icon,
                size: 14,
                color: visual.fg,
              ),
            ),
            const SizedBox(
              width: 7,
            ),
            Flexible(
              child: Text(
                visual.label,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    theme.textTheme.labelMedium
                        ?.copyWith(
                  color: visual.fg,
                  fontWeight:
                      FontWeight.w700,
                  fontSize: 12.5,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}