import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

/// COMPONENTE REUTILIZABLE #2: ServiceRequestCard
///
/// INTERFAZ PÚBLICA
/// - Entrada (datos):
///     titulo        (String)  — ej. descripción de la solicitud
///     subtitulo     (String)  — ej. categoría + nombre de usuario
///     fecha         (String)  — fecha ya formateada, la tarjeta no formatea fechas
///     status        (RequestStatus)
/// - Configuración de presentación: ninguna (usa siempre los tokens del tema)
/// - Callback:
///     onTap  (VoidCallback?) — se dispara al tocar la tarjeta;
///     la tarjeta NO decide qué pasa al tocarla (no navega por sí misma)
/// - Contenido delegado: ninguno en esta versión (podría aceptar un
///   `trailing` opcional en el futuro sin romper el resto de usos)
///
/// No hace fetch de datos ni conoce rutas de navegación: solo
/// recibe strings y un enum, y delega la acción de tocar vía callback.
class ServiceRequestCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String fecha;
  final RequestStatus status;
  final VoidCallback? onTap;

  const ServiceRequestCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.fecha,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: 'Solicitud: $titulo, $subtitulo, $fecha',
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            // Área táctil: padding generoso para superar 48x48dp mínimo
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitulo,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  fecha,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}