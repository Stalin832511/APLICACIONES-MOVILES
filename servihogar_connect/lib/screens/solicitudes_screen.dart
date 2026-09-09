import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import '../widgets/status_badge.dart';

import '../database/app_database.dart';
import '../models/solicitud.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/async_state_view.dart';
import '../widgets/service_request_card.dart';
import 'crear_solicitud_screen.dart';

class MisSolicitudesScreen extends StatefulWidget {
  final AppDatabase database;

  const MisSolicitudesScreen({
    super.key,
    required this.database,
  });

  @override
  State<MisSolicitudesScreen> createState() =>
      _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState
    extends State<MisSolicitudesScreen> {
  late final AppDatabase _database;

  LoadStatus _status = LoadStatus.cargando;

  List<SolicitudModel> _solicitudes = [];

  String? _errorMessage;

  DateTime? _ultimaActualizacionLocal;

  bool _mostrandoDatosOffline = false;

  @override
  void initState() {
    super.initState();

    _database = widget.database;

    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    if (!mounted) return;

    setState(() {
      _status = LoadStatus.cargando;
      _errorMessage = null;
    });

    try {
      debugPrint('========================================');
      debugPrint('INTENTANDO CARGAR SOLICITUDES DESDE API');
      debugPrint('========================================');

      final datosServidor =
          await ApiService.fetchSolicitudes();

      debugPrint(
        'API OK - solicitudes recibidas: '
        '${datosServidor.length}',
      );

      await _guardarEnBaseLocal(datosServidor);

      if (!mounted) return;

      setState(() {
        _solicitudes = datosServidor;
        _status = datosServidor.isEmpty
            ? LoadStatus.vacio
            : LoadStatus.listo;
        _mostrandoDatosOffline = false;
        _ultimaActualizacionLocal =
            DateTime.now();
        _errorMessage = null;
      });

      debugPrint('DATOS MOSTRADOS DESDE API');
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('API SIN CONEXIÓN');
      debugPrint('ERROR API: $e');
      debugPrint('========================================');

      debugPrint('$stackTrace');

      await _cargarDesdeBaseLocal();
    }
  }

  Future<void> _guardarEnBaseLocal(
    List<SolicitudModel> solicitudes,
  ) async {
    final ahora = DateTime.now();

    debugPrint('----------------------------------------');
    debugPrint('GUARDANDO DATOS EN SQLITE');
    debugPrint(
      'Cantidad: ${solicitudes.length}',
    );
    debugPrint('----------------------------------------');

    for (final solicitud in solicitudes) {
      debugPrint(
        'Guardando solicitud '
        '${solicitud.id}: ${solicitud.descripcion}',
      );

      await _database.serviceRequestDao.upsertRequest(
        ServiceRequestsCompanion.insert(
          id: solicitud.id.toString(),
          clientOperationId:
              const drift.Value.absent(),
          description: solicitud.descripcion,
          status: solicitud.status.name,
          createdAt: solicitud.fechaCreacion,
          updatedAt:
              drift.Value(solicitud.fechaCreacion),
          serverUpdatedAt:
              drift.Value(solicitud.fechaCreacion),
          cachedAt: ahora,
        ),
      );
    }

    debugPrint('SQLITE: guardado terminado');
  }

  Future<void> _cargarDesdeBaseLocal() async {
    try {
      debugPrint('========================================');
      debugPrint('INTENTANDO CARGAR DATOS DESDE SQLITE');
      debugPrint('========================================');

      final registros =
          await _database.serviceRequestDao.getAllRequests();

      debugPrint(
        'SQLITE: registros encontrados = '
        '${registros.length}',
      );

      for (final registro in registros) {
        debugPrint(
          'SQLITE: '
          'id=${registro.id}, '
          'descripcion=${registro.description}, '
          'estado=${registro.status}, '
          'cachedAt=${registro.cachedAt}',
        );
      }

      if (registros.isEmpty) {
        debugPrint(
          'SQLITE: LA BASE LOCAL ESTA VACIA',
        );

        if (!mounted) return;

        setState(() {
          _solicitudes = [];
          _status = LoadStatus.error;
          _mostrandoDatosOffline = true;
          _errorMessage =
              'Sin conexión y no existen datos '
              'guardados localmente.';
        });

        return;
      }

      final solicitudesLocales =
          <SolicitudModel>[];

      for (final registro in registros) {
        solicitudesLocales.add(
          SolicitudModel(
            id: int.tryParse(registro.id) ?? 0,
            descripcion: registro.description,
            status: _convertirEstado(
              registro.status,
            ),
            fechaCreacion: registro.createdAt,
            categoriaNombre: null,
            usuarioNombre: null,
          ),
        );
      }

      DateTime fechaCacheMasReciente =
          registros.first.cachedAt;

      for (final registro in registros) {
        if (registro.cachedAt.isAfter(
          fechaCacheMasReciente,
        )) {
          fechaCacheMasReciente =
              registro.cachedAt;
        }
      }

      debugPrint(
        'SQLITE: datos preparados = '
        '${solicitudesLocales.length}',
      );

      if (!mounted) return;

      setState(() {
        _solicitudes = solicitudesLocales;
        _status = LoadStatus.listo;
        _ultimaActualizacionLocal =
            fechaCacheMasReciente;
        _mostrandoDatosOffline = true;
        _errorMessage = null;
      });

      debugPrint('========================================');
      debugPrint(
        'DATOS OFFLINE MOSTRADOS CORRECTAMENTE',
      );
      debugPrint('========================================');
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('ERROR LEYENDO SQLITE');
      debugPrint('ERROR: $e');
      debugPrint('========================================');

      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _solicitudes = [];
        _status = LoadStatus.error;
        _mostrandoDatosOffline = true;
        _errorMessage =
            'No fue posible cargar los datos locales: $e';
      });
    }
  }

  RequestStatus _convertirEstado(String estado) {
    final valor = estado.toLowerCase().trim();

    switch (valor) {
      case 'completado':
      case 'completada':
      case 'completed':
      case 'finalizado':
      case 'finalizada':
        return RequestStatus.completado;

      case 'en camino':
      case 'encamino':
      case 'en_camino':
        return RequestStatus.enCamino;

      case 'pendiente':
      case 'pending':
      default:
        return RequestStatus.pendiente;
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  String _textoAntiguedad(DateTime fecha) {
    final ahora = DateTime.now();

    final diferencia = ahora.difference(fecha);

    if (diferencia.inSeconds < 60) {
      return 'actualizado hace unos segundos';
    }

    if (diferencia.inMinutes < 60) {
      return 'actualizado hace '
          '${diferencia.inMinutes} min';
    }

    if (diferencia.inHours < 24) {
      return 'actualizado hace '
          '${diferencia.inHours} h';
    }

    return 'actualizado hace '
        '${diferencia.inDays} días';
  }

  Future<void> _abrirCrearSolicitud() async {
    final creada =
        await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CrearSolicitudScreen(
          database: _database,
        ),
      ),
    );

    if (creada == true && mounted) {
      await _cargarSolicitudes();
    }
  }

  void _mostrarDetalle(SolicitudModel solicitud) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6)
                    .withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFF8B5CF6),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Solicitud #${solicitud.id}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1925),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF09090F),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF09090F),
        surfaceTintColor:
            Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Mis Solicitudes',
              style: TextStyle(
                color: Color(0xFFF8F7FF),
                fontWeight: FontWeight.w800,
                fontSize: 23,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Consulta y administra tus servicios',
              style: TextStyle(
                color: Color(0xFF9A98A8),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Nueva solicitud',
              style: IconButton.styleFrom(
                backgroundColor:
                    const Color(0xFF1A1925),
                foregroundColor:
                    const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  side: const BorderSide(
                    color: Color(0xFF252431),
                  ),
                ),
              ),
              icon: const Icon(
                Icons.add_rounded,
                size: 25,
              ),
              onPressed:
                  _abrirCrearSolicitud,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          if (_mostrandoDatosOffline &&
              _solicitudes.isNotEmpty)
            _buildOfflineBanner(),

          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF8B5CF6),
              backgroundColor:
                  const Color(0xFF1A1925),
              onRefresh:
                  _cargarSolicitudes,
              child:
                  AsyncStateView<
                      List<SolicitudModel>>(
                status: _status,
                data: _solicitudes,
                errorMessage:
                    _errorMessage,
                emptyMessage:
                    'Aún no tienes solicitudes registradas',
                onRetry:
                    _cargarSolicitudes,
                builder: (
                  context,
                  solicitudes,
                ) =>
                    ListView.separated(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    16,
                    18,
                    105,
                  ),
                  itemCount:
                      solicitudes.length,
                  separatorBuilder:
                      (_, index) =>
                          const SizedBox(
                    height: 12,
                  ),
                  itemBuilder:
                      (context, index) {
                    final s =
                        solicitudes[index];

                    return _buildRequestItem(
                      s,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _abrirCrearSolicitud,
        backgroundColor:
            const Color(0xFF8B5CF6),
        foregroundColor:
            Colors.white,
        elevation: 5,
        icon: const Icon(
          Icons.add_rounded,
          size: 23,
        ),
        label: const Text(
          'Nueva solicitud',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        18,
        8,
        18,
        2,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B)
            .withValues(alpha: 0.09),
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFF59E0B)
              .withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B)
                  .withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFFBBF24),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Modo sin conexión',
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 13.5,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _ultimaActualizacionLocal ==
                          null
                      ? 'Mostrando información local'
                      : 'Datos locales · '
                          '${_textoAntiguedad(_ultimaActualizacionLocal!)}',
                  style: const TextStyle(
                    color: Color(0xFFC7A95D),
                    fontSize: 11.5,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(
    SolicitudModel solicitud,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.12,
            ),
            blurRadius: 15,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),
      child: ServiceRequestCard(
        titulo: solicitud.descripcion,
        subtitulo: [
          if (solicitud.categoriaNombre !=
              null)
            solicitud.categoriaNombre!,
          if (solicitud.usuarioNombre !=
              null)
            solicitud.usuarioNombre!,
        ].join(' · '),
        fecha: _formatearFecha(
          solicitud.fechaCreacion,
        ),
        status: solicitud.status,
        onTap: () {
          _mostrarDetalle(
            solicitud,
          );
        },
      ),
    );
  }
}