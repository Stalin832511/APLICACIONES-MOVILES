import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Estado de una operación asíncrona genérica (ej. una llamada HTTP).
enum LoadStatus { cargando, listo, vacio, error }

/// COMPONENTE REUTILIZABLE #3: AsyncStateView<T>
///
/// INTERFAZ PÚBLICA
/// - Entrada (datos):
///     status       (LoadStatus)      — en qué estado está la operación
///     data         (T?)              — el dato ya cargado (si status == listo)
///     errorMessage (String?)         — mensaje a mostrar si status == error
/// - Configuración de presentación:
///     emptyMessage (String)          — texto del estado vacío, personalizable
/// - Callback:
///     onRetry (VoidCallback?)        — botón "Reintentar" en error y vacío
/// - Contenido delegado:
///     builder (Widget Function(BuildContext, T)) — CÓMO dibujar el
///     contenido cuando status == listo. Este es el punto clave de
///     reutilización: AsyncStateView no sabe si T es una lista de
///     solicitudes, un mapa de /health, o cualquier otra cosa.
///
/// No hace fetch de datos (no conoce ApiService ni http): solo
/// reacciona al LoadStatus que la pantalla le pasa.
class AsyncStateView<T> extends StatelessWidget {
  final LoadStatus status;
  final T? data;
  final String? errorMessage;
  final String emptyMessage;
  final VoidCallback? onRetry;
  final Widget Function(BuildContext context, T data) builder;

  const AsyncStateView({
    super.key,
    required this.status,
    required this.builder,
    this.data,
    this.errorMessage,
    this.emptyMessage = 'No hay elementos para mostrar',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    switch (status) {
      case LoadStatus.cargando:
        return Semantics(
          label: 'Cargando contenido',
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: CircularProgressIndicator(),
            ),
          ),
        );

      case LoadStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: colorScheme.error,
                  size: 40,
                  semanticLabel: 'Error',
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  errorMessage ?? 'Ocurrió un error inesperado',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  // Botón con área táctil mínima 48x48dp (por defecto en Material)
                  ElevatedButton(
                    onPressed: onRetry,
                    child: const Text('Reintentar'),
                  ),
                ],
              ],
            ),
          ),
        );

      case LoadStatus.vacio:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: 40,
                  semanticLabel: 'Sin contenido',
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  emptyMessage,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: onRetry,
                    child: const Text('Actualizar'),
                  ),
                ],
              ],
            ),
          ),
        );

      case LoadStatus.listo:
        if (data == null) {
          // Estado inconsistente (no debería pasar si la pantalla
          // gestiona bien el LoadStatus), se trata como vacío.
          return const SizedBox.shrink();
        }
        return builder(context, data as T);
    }
  }
}