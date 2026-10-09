import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/evidencia.dart';
import '../models/solicitud.dart';
import '../services/evidence_service.dart';
import 'quote_screen.dart';
import 'seguimiento_solicitud_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

/// Pantalla real: "Detalle de Solicitud".
class DetalleSolicitudScreen extends StatefulWidget {
  final SolicitudModel solicitud;

  const DetalleSolicitudScreen({super.key, required this.solicitud});

  @override
  State<DetalleSolicitudScreen> createState() =>
      _DetalleSolicitudScreenState();
}

class _DetalleSolicitudScreenState extends State<DetalleSolicitudScreen> {
  late Future<List<_EvidenciaCargada>> _evidenciasFuture;

  SolicitudModel get solicitud => widget.solicitud;

  @override
  void initState() {
    super.initState();
    _evidenciasFuture = solicitud.pendingSync || solicitud.id <= 0
        ? Future.value(const <_EvidenciaCargada>[])
        : _cargarEvidencias();
  }

  Future<List<_EvidenciaCargada>> _cargarEvidencias() async {
    final evidencias = await EvidenceService.list(
      idSolicitud: solicitud.id,
    );
    return Future.wait(
      evidencias.map(
        (evidencia) async => _EvidenciaCargada(
          evidencia: evidencia,
          bytes: await EvidenceService.fetchBytes(
            idSolicitud: solicitud.id,
            evidenciaId: evidencia.idEvidencia,
          ),
        ),
      ),
    );
  }

  void _reintentarCarga() {
    setState(() {
      _evidenciasFuture = _cargarEvidencias();
    });
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/${fecha.year} '
        '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
  }

  String _formatearTamano(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _copiarCoordenadas() async {
    final texto =
        '${solicitud.latitud!.toStringAsFixed(6)}, '
        '${solicitud.longitud!.toStringAsFixed(6)}';
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coordenadas copiadas.')),
    );
  }

  /// Muestra una imagen a pantalla completa con zoom.
  void _abrirImagen(ImageProvider imagen, String titulo) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Center(
                    child: Image(
                      image: imagen,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Text(
                        'No se pudo mostrar la imagen.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Cerrar',
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                        Expanded(
                          child: Text(
                            titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // COMPONENTES
  // ==========================================================

  /// Fila de información con etiqueta, valor e icono opcional.
  Widget _fila(
    BuildContext context,
    String etiqueta,
    String valor, {
    IconData? icono,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icono != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icono, size: 18, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloSeccion(
    BuildContext context,
    IconData icono,
    String titulo,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icono, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _tarjeta(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: child,
    );
  }

  Widget _buildHero(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 14,
            child: Icon(
              Icons.home_repair_service_rounded,
              size: 70,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            solicitud.pendingSync
                                ? Icons.cloud_upload_outlined
                                : Icons.confirmation_number_outlined,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            solicitud.pendingSync
                                ? 'Sin sincronizar'
                                : 'Solicitud #${solicitud.id}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    StatusBadge(status: solicitud.status),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  solicitud.descripcion,
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    if (solicitud.categoriaNombre != null)
                      _heroDato(
                        Icons.category_rounded,
                        solicitud.categoriaNombre!,
                      ),
                    _heroDato(
                      Icons.event_rounded,
                      _formatearFecha(solicitud.fechaCreacion),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDato(IconData icono, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 15, color: Colors.white70),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUbicacion(BuildContext context, bool tieneUbicacion) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tieneUbicacion)
            SizedBox(
              height: 110,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MapGridPainter(
                        lineColor:
                            colorScheme.outlineVariant.withValues(alpha: 0.6),
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: colorScheme.primary,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Ubicación',
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (tieneUbicacion)
                      IconButton(
                        tooltip: 'Copiar coordenadas',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: _copiarCoordenadas,
                      ),
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
        ],
      ),
    );
  }

  // ==========================================================
  // EVIDENCIAS
  // ==========================================================

  Widget _evidencias(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    if (solicitud.pendingSync) {
      final photoPath = solicitud.localPhotoPath;
      final photoFile = photoPath == null ? null : File(photoPath);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(context, Icons.photo_library_rounded, 'Evidencia'),
          const SizedBox(height: AppSpacing.sm),
          if (photoFile != null && photoFile.existsSync())
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _abrirImagen(
                      FileImage(photoFile),
                      'Fotografía local',
                    ),
                    child: Image.file(
                      photoFile,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Text('No se pudo mostrar la fotografía local.'),
                      ),
                    ),
                  ),
                  const ListTile(
                    leading: Icon(Icons.cloud_upload_outlined),
                    title: Text('Fotografía guardada en este dispositivo'),
                    subtitle: Text(
                      'Se enviará cuando la solicitud se sincronice.',
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'No hay una fotografía local adjunta.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      );
    }

    return FutureBuilder<List<_EvidenciaCargada>>(
      future: _evidenciasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('No se pudieron cargar las evidencias.'),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _reintentarCarga,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final evidencias =
            snapshot.data ?? const <_EvidenciaCargada>[];
        if (evidencias.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'No hay evidencias subidas. La fotografía capturada '
                    'en este dispositivo, si existe, permanece local.',
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloSeccion(
              context,
              Icons.photo_library_rounded,
              'Evidencias (${evidencias.length})',
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final item in evidencias)
              Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.evidencia.tipoContenido.startsWith('image/'))
                      InkWell(
                        onTap: () => _abrirImagen(
                          MemoryImage(item.bytes),
                          item.evidencia.nombreArchivo,
                        ),
                        child: Image.memory(
                          item.bytes,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              SizedBox(
                            height: 100,
                            child: Center(
                              child: Text(
                                'No se pudo mostrar ${item.evidencia.nombreArchivo}.',
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Icon(Icons.attach_file, size: 36),
                      ),
                    ListTile(
                      title: Text(item.evidencia.nombreArchivo),
                      subtitle: Text(
                        '${item.evidencia.tipoContenido} · '
                        '${_formatearFecha(item.evidencia.fechaCreacion)}',
                      ),
                      trailing: Text(_formatearTamano(
                        item.evidencia.tamanoBytes,
                      )),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tieneUbicacion =
        solicitud.latitud != null && solicitud.longitud != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          solicitud.pendingSync
              ? 'Solicitud sin sincronizar'
              : 'Solicitud #${solicitud.id}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildHero(context),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SeguimientoSolicitudScreen(
                  solicitud: solicitud,
                ),
              ),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.timeline_rounded),
            label: const Text('Ver seguimiento del servicio'),
          ),
          const SizedBox(height: AppSpacing.md),
          if (solicitud.pendingSync)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: solicitud.syncFailed
                    ? colorScheme.errorContainer
                    : colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    solicitud.syncFailed
                        ? Icons.sync_problem_rounded
                        : Icons.cloud_upload_outlined,
                    color: solicitud.syncFailed
                        ? colorScheme.onErrorContainer
                        : colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      solicitud.syncFailed
                          ? 'El servidor rechazó la solicitud. Los datos '
                              'permanecen guardados localmente y no se '
                              'enviarán automáticamente.'
                          : 'Guardada en este dispositivo. Se enviará al '
                              'recuperar la conexión.',
                      style: TextStyle(
                        color: solicitud.syncFailed
                            ? colorScheme.onErrorContainer
                            : colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _tarjeta(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tituloSeccion(
                  context,
                  Icons.info_rounded,
                  'Información de la solicitud',
                ),
                const SizedBox(height: AppSpacing.sm),
                if (solicitud.categoriaNombre != null)
                  _fila(
                    context,
                    solicitud.pendingSync
                        ? 'Categoría seleccionada'
                        : 'Categoría',
                    solicitud.categoriaNombre!,
                    icono: Icons.category_rounded,
                  ),
                if (solicitud.usuarioNombre != null)
                  _fila(
                    context,
                    'Solicitado por',
                    solicitud.usuarioNombre!,
                    icono: Icons.person_rounded,
                  ),
                _fila(
                  context,
                  'Fecha de creación',
                  _formatearFecha(solicitud.fechaCreacion),
                  icono: Icons.event_rounded,
                ),
                if (!solicitud.pendingSync &&
                    solicitud.clientOperationId != null)
                  _fila(
                    context,
                    'ID de operación (offline-sync)',
                    solicitud.clientOperationId!,
                    icono: Icons.fingerprint_rounded,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildUbicacion(context, tieneUbicacion),
          const SizedBox(height: AppSpacing.md),
          _evidencias(context),
          const SizedBox(height: AppSpacing.md),
          if (!solicitud.pendingSync)
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => QuoteScreen(
                    requestId: solicitud.id,
                    description: solicitud.descripcion,
                  ),
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.request_quote_outlined),
              label: const Text('Ver cotizaciones'),
            ),
        ],
      ),
    );
  }
}

class _EvidenciaCargada {
  final EvidenciaModel evidencia;
  final Uint8List bytes;

  const _EvidenciaCargada({
    required this.evidencia,
    required this.bytes,
  });
}

/// Fondo decorativo tipo mapa (cuadrícula) para la tarjeta de ubicación.
class _MapGridPainter extends CustomPainter {
  final Color lineColor;
  final Color backgroundColor;

  const _MapGridPainter({
    required this.lineColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = backgroundColor,
    );

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    const paso = 26.0;
    for (var x = 0.0; x <= size.width; x += paso) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += paso) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}