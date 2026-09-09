import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Estado de una operación asíncrona genérica,
/// por ejemplo, una llamada HTTP.
enum LoadStatus {
  cargando,
  listo,
  vacio,
  error,
}

/// Componente reutilizable para representar los diferentes
/// estados de una operación asíncrona.
///
/// Interfaz pública:
/// - status: estado actual de la operación.
/// - data: dato cargado cuando el estado es [LoadStatus.listo].
/// - errorMessage: mensaje mostrado cuando existe un error.
/// - emptyMessage: texto mostrado cuando no existen datos.
/// - onRetry: callback opcional para reintentar.
/// - builder: función encargada de construir el contenido cargado.
///
/// Este componente no realiza llamadas HTTP ni obtiene datos.
/// Solamente representa visualmente el estado que recibe
/// de la pantalla que lo utiliza.
class AsyncStateView<T> extends StatelessWidget {
  final LoadStatus status;
  final T? data;
  final String? errorMessage;
  final String emptyMessage;
  final VoidCallback? onRetry;
  final Widget Function(
    BuildContext context,
    T data,
  ) builder;

  const AsyncStateView({
    super.key,
    required this.status,
    required this.builder,
    this.data,
    this.errorMessage,
    this.emptyMessage =
        'No hay elementos para mostrar',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final textTheme =
        Theme.of(context).textTheme;

    switch (status) {
      case LoadStatus.cargando:
        return Semantics(
          label: 'Cargando contenido',
          child: const Center(
            child: Padding(
              padding:
                  EdgeInsets.all(AppSpacing.xl),
              child:
                  CircularProgressIndicator(),
            ),
          ),
        );

      case LoadStatus.error:
        return Center(
          child: Padding(
            padding:
                const EdgeInsets.all(
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: colorScheme.error,
                  size: 40,
                  semanticLabel: 'Error',
                ),
                const SizedBox(
                  height: AppSpacing.sm,
                ),
                Text(
                  errorMessage ??
                      'Ocurrió un error inesperado',
                  style: textTheme.bodyMedium,
                  textAlign:
                      TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(
                    height: AppSpacing.md,
                  ),
                  ElevatedButton(
                    onPressed: onRetry,
                    child:
                        const Text('Reintentar'),
                  ),
                ],
              ],
            ),
          ),
        );

      case LoadStatus.vacio:
        return Center(
          child: Padding(
            padding:
                const EdgeInsets.all(
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  color:
                      colorScheme
                          .onSurfaceVariant,
                  size: 40,
                  semanticLabel:
                      'Sin contenido',
                ),
                const SizedBox(
                  height: AppSpacing.sm,
                ),
                Text(
                  emptyMessage,
                  style:
                      textTheme.bodyMedium
                          ?.copyWith(
                    color: colorScheme
                        .onSurfaceVariant,
                  ),
                  textAlign:
                      TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(
                    height: AppSpacing.md,
                  ),
                  OutlinedButton(
                    onPressed: onRetry,
                    child:
                        const Text('Actualizar'),
                  ),
                ],
              ],
            ),
          ),
        );

      case LoadStatus.listo:
        if (data == null) {
          return const SizedBox.shrink();
        }

        return builder(
          context,
          data as T,
        );
    }
  }
}