import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Estados posibles de una solicitud de servicio.
enum RequestStatus { pendiente, enCamino, completado }

extension RequestStatusParsing on RequestStatus {
  /// Convierte el texto que llega de la API (campo "Estado")
  /// al enum tipado. Cualquier valor no reconocido cae en pendiente.
  static RequestStatus fromApiValue(String value) {
    switch (value.toLowerCase().trim()) {
      case 'en camino':
      case 'en_camino':
      case 'encamino':
        return RequestStatus.enCamino;
      case 'completado':
      case 'completada':
      case 'finalizado':
        return RequestStatus.completado;
      default:
        return RequestStatus.pendiente;
    }
  }
}

/// COMPONENTE REUTILIZABLE #1: StatusBadge
///
/// INTERFAZ PÚBLICA
/// - Entrada:     status (RequestStatus) — obligatorio
/// - Presentación: ninguna configuración extra; el color y texto
///                 se derivan del token semántico correspondiente
/// - Callback:    ninguno (es de solo lectura / informativo)
/// - Contenido delegado: ninguno (no acepta widgets hijos)
///
/// No conoce la API ni realiza navegación: solo traduce un
/// RequestStatus a una representación visual consistente.
class StatusBadge extends StatelessWidget {
  final RequestStatus status;

  const StatusBadge({super.key, required this.status});

  ({Color bg, Color fg, String label, IconData icon}) _visualFor(
    AppStatusColors colors,
  ) {
    switch (status) {
      case RequestStatus.pendiente:
        return (
          bg: colors.pendienteBg,
          fg: colors.pendienteFg,
          label: 'Pendiente',
          icon: Icons.schedule,
        );
      case RequestStatus.enCamino:
        return (
          bg: colors.enCaminoBg,
          fg: colors.enCaminoFg,
          label: 'En camino',
          icon: Icons.directions_run,
        );
      case RequestStatus.completado:
        return (
          bg: colors.completadoBg,
          fg: colors.completadoFg,
          label: 'Completado',
          icon: Icons.check_circle,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColors = Theme.of(context).extension<AppStatusColors>()!;
    final v = _visualFor(statusColors);

    // Semantics: el color NO es el único medio de información —
    // el texto y el ícono también comunican el estado.
    return Semantics(
      label: 'Estado de la solicitud: ${v.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: v.bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(v.icon, size: 14, color: v.fg),
            const SizedBox(width: AppSpacing.xs),
            Text(
              v.label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: v.fg),
            ),
          ],
        ),
      ),
    );
  }
}