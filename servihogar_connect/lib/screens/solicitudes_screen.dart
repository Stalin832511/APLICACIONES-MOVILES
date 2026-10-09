import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import '../widgets/status_badge.dart';

import '../database/app_database.dart';
import '../models/categoria.dart';
import '../models/solicitud.dart';
import '../services/api_service.dart';
import '../services/catalog_service.dart';
import '../widgets/async_state_view.dart';
import '../widgets/service_request_card.dart';
import 'crear_solicitud_screen.dart';
import 'detalle_solicitud_screen.dart';

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
  // ==========================================================
  // CONFIGURACIÓN VISUAL
  // ==========================================================

  /// Imagen opcional para la cabecera del panel.
  ///
  /// Para usarla: copia la imagen en assets/images/, decláralo en
  /// pubspec.yaml (assets:) y escribe aquí la ruta, por ejemplo:
  /// 'assets/images/mis_solicitudes_header.jpg'.
  /// Mientras sea null se muestra la cabecera con degradado e icono.
  static const String? _heroImageAsset = null;

  static const Color _colorPendiente = Color(0xFFF59E0B);
  static const Color _colorEnCamino = Color(0xFF38BDF8);
  static const Color _colorEnProceso = Color(0xFF8B5CF6);
  static const Color _colorCompletado = Color(0xFF22C55E);

  static const Color _cardColor = Color(0xFF14131D);
  static const Color _cardBorder = Color(0xFF252431);

  // ==========================================================
  // ESTADO
  // ==========================================================

  late final AppDatabase _database;

  LoadStatus _status = LoadStatus.cargando;

  List<SolicitudModel> _solicitudes = [];

  String? _errorMessage;

  DateTime? _ultimaActualizacionLocal;

  bool _mostrandoDatosOffline = false;
  static const int _pageSize = 20;
  int _page = 1;
  int _totalCount = 0;
  int _totalPages = 1;
  bool _loadingMore = false;
  bool _usingLegacyEndpoint = false;
  String? _loadMoreError;
  String? _selectedStatus;
  int? _selectedCategoryId;
  List<CategoriaModel> _categorias = [];
  String? _categoryLoadError;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();

    _database = widget.database;

    _cargarCategorias();
    _cargarSolicitudes();
  }

  Future<void> _cargarCategorias() async {
    try {
      final result = await CatalogService.loadCategories();
      if (!mounted) return;
      setState(() {
        _categorias = result.categories;
        _categoryLoadError = null;
      });
    } catch (error) {
      debugPrint('No se pudo cargar el catálogo de filtros: $error');
      if (!mounted) return;
      setState(() {
        _categoryLoadError =
            'No se pudieron cargar las categorías para filtrar.';
      });
    }
  }

  Future<void> _cargarSolicitudes() async {
    if (!mounted) return;

    final generation = ++_requestGeneration;
    setState(() {
      _status = LoadStatus.cargando;
      _errorMessage = null;
      _page = 1;
      _totalCount = 0;
      _totalPages = 1;
      _loadingMore = false;
      _loadMoreError = null;
      _usingLegacyEndpoint = false;
    });

    try {
      final result = await ApiService.fetchSolicitudesPaginadas(
        page: 1,
        pageSize: _pageSize,
        estado: _selectedStatus,
        idCategoria: _selectedCategoryId,
      );

      await _guardarEnBaseLocal(result.items);
      final pending = _filtrarLocalmente(
        await _cargarSolicitudesPendientes(),
      );
      final items = _combinarSolicitudes(result.items, pending);

      if (!mounted || generation != _requestGeneration) return;

      setState(() {
        _solicitudes = items;
        _page = result.page;
        _totalCount = result.totalCount + items.length - result.items.length;
        _totalPages = result.totalPages;
        _status = items.isEmpty
            ? LoadStatus.vacio
            : LoadStatus.listo;
        _mostrandoDatosOffline = false;
        _ultimaActualizacionLocal = DateTime.now();
        _errorMessage = null;
      });
    } catch (e, stackTrace) {
      debugPrint('No se pudo cargar solicitudes paginadas: $e\n$stackTrace');
      try {
        final allRequests = await ApiService.fetchSolicitudes();
        await _guardarEnBaseLocal(allRequests);
        if (!mounted || generation != _requestGeneration) return;

        final pending = await _cargarSolicitudesPendientes();
        final filtered = _filtrarLocalmente(
          _combinarSolicitudes(allRequests, pending),
        );
        setState(() {
          _solicitudes = filtered;
          _page = 1;
          _totalCount = filtered.length;
          _totalPages = 1;
          _status = _solicitudes.isEmpty
              ? LoadStatus.vacio
              : LoadStatus.listo;
          _mostrandoDatosOffline = false;
          _usingLegacyEndpoint = true;
          _ultimaActualizacionLocal = DateTime.now();
          _errorMessage = null;
        });
      } catch (legacyError, legacyStack) {
        debugPrint('API legacy tampoco disponible: $legacyError\n$legacyStack');
        if (!mounted || generation != _requestGeneration) return;
        await _cargarDesdeBaseLocal();
        if (mounted &&
            generation == _requestGeneration &&
            _mostrandoDatosOffline &&
            _status == LoadStatus.listo) {
          _aplicarFiltrosAListaLocal();
        }
      }
    }
  }

  List<SolicitudModel> _combinarSolicitudes(
    List<SolicitudModel> serverRequests,
    List<SolicitudModel> pendingRequests,
  ) {
    final serverOperationIds = serverRequests
        .map((request) => request.clientOperationId)
        .whereType<String>()
        .toSet();
    return [
      ...pendingRequests.where(
        (request) => !serverOperationIds.contains(request.clientOperationId),
      ),
      ...serverRequests,
    ];
  }

  Future<List<SolicitudModel>> _cargarSolicitudesPendientes() async {
    final operations = await _database.syncQueueDao.getAllOperations();
    final requests = <SolicitudModel>[];
    var localId = -1;

    for (final operation in operations) {
      if (operation.operationType != 'crear_solicitud') continue;

      try {
        final payload =
            jsonDecode(operation.payload) as Map<String, dynamic>;
        final categoryId = int.tryParse(
          payload['idCategoria']?.toString() ?? '',
        );
        final matchingCategories = _categorias
            .where((category) => category.id == categoryId);
        final categoryName = matchingCategories.isEmpty
            ? (categoryId == null ? null : 'Servicio #$categoryId')
            : matchingCategories.first.nombre;
        requests.add(
          SolicitudModel.fromPendingPayload(
            localId: localId--,
            payload: payload,
            createdAt: operation.createdAt,
            categoryName: categoryName,
            syncFailed: operation.status == 'failed',
          ),
        );
      } on FormatException catch (error) {
        debugPrint(
          'No se pudo leer la solicitud pendiente '
          '${operation.operationId}: $error',
        );
      } on TypeError catch (error) {
        debugPrint(
          'Formato inválido en solicitud pendiente '
          '${operation.operationId}: $error',
        );
      }
    }

    return requests;
  }

  List<SolicitudModel> _filtrarLocalmente(
    List<SolicitudModel> solicitudes,
  ) {
    return solicitudes.where((solicitud) {
      final matchesStatus = _selectedStatus == null ||
          _estadoApi(solicitud.status) == _selectedStatus;
      final matchesCategory = _selectedCategoryId == null ||
          solicitud.idCategoria == _selectedCategoryId;
      return matchesStatus && matchesCategory;
    }).toList();
  }

  void _aplicarFiltrosAListaLocal() {
    final filtered = _filtrarLocalmente(_solicitudes);
    setState(() {
      _solicitudes = filtered;
      _status = filtered.isEmpty ? LoadStatus.vacio : LoadStatus.listo;
      _totalCount = filtered.length;
      _totalPages = 1;
      _usingLegacyEndpoint = true;
    });
  }

  String _estadoApi(RequestStatus status) {
    switch (status) {
      case RequestStatus.pendiente:
        return 'Pendiente';
      case RequestStatus.enCamino:
        return 'En camino';
      case RequestStatus.enProceso:
        return 'En proceso';
      case RequestStatus.completado:
        return 'Completado';
    }
  }

  Future<void> _cargarMas() async {
    if (_loadingMore || _page >= _totalPages || _usingLegacyEndpoint) return;
    final generation = _requestGeneration;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      final result = await ApiService.fetchSolicitudesPaginadas(
        page: _page + 1,
        pageSize: _pageSize,
        estado: _selectedStatus,
        idCategoria: _selectedCategoryId,
      );
      await _guardarEnBaseLocal(result.items);
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        final existingIds = _solicitudes.map((item) => item.id).toSet();
        _solicitudes.addAll(
          result.items.where((item) => !existingIds.contains(item.id)),
        );
        _page = result.page;
        _totalCount = result.totalCount;
        _totalPages = result.totalPages;
        _status = _solicitudes.isEmpty ? LoadStatus.vacio : LoadStatus.listo;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loadingMore = false;
        _loadMoreError = 'No se pudo cargar la siguiente página. $error';
      });
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
      final solicitudesPendientes = await _cargarSolicitudesPendientes();

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

      if (registros.isEmpty && solicitudesPendientes.isEmpty) {
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

      final solicitudesLocalesFiltradas = _filtrarLocalmente([
        ...solicitudesPendientes,
        ...solicitudesLocales,
      ]);

      DateTime fechaCacheMasReciente = registros.isEmpty
          ? solicitudesPendientes.first.fechaCreacion
          : registros.first.cachedAt;

      for (final registro in registros) {
        if (registro.cachedAt.isAfter(
          fechaCacheMasReciente,
        )) {
          fechaCacheMasReciente =
              registro.cachedAt;
        }
      }

      debugPrint(
        'SQLITE y cola: datos preparados = '
        '${solicitudesLocalesFiltradas.length}',
      );

      if (!mounted) return;

      setState(() {
        _solicitudes = solicitudesLocalesFiltradas;
        _status = solicitudesLocalesFiltradas.isEmpty
            ? LoadStatus.vacio
            : LoadStatus.listo;
        _ultimaActualizacionLocal =
            fechaCacheMasReciente;
        _mostrandoDatosOffline = true;
        _totalCount = solicitudesLocalesFiltradas.length;
        _totalPages = 1;
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

      case 'en proceso':
      case 'en_proceso':
      case 'enproceso':
        return RequestStatus.enProceso;

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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalleSolicitudScreen(solicitud: solicitud),
      ),
    );
  }

  bool get _hayFiltrosActivos =>
      _selectedStatus != null || _selectedCategoryId != null;

  // ==========================================================
  // ESTADÍSTICAS PARA EL PANEL
  // ==========================================================

  Color _colorEstado(RequestStatus status) {
    switch (status) {
      case RequestStatus.pendiente:
        return _colorPendiente;
      case RequestStatus.enCamino:
        return _colorEnCamino;
      case RequestStatus.enProceso:
        return _colorEnProceso;
      case RequestStatus.completado:
        return _colorCompletado;
    }
  }

  Map<RequestStatus, int> _contarPorEstado(List<SolicitudModel> items) {
    final conteo = <RequestStatus, int>{
      for (final status in RequestStatus.values) status: 0,
    };
    for (final item in items) {
      conteo[item.status] = (conteo[item.status] ?? 0) + 1;
    }
    return conteo;
  }

  List<MapEntry<String, int>> _topCategorias(List<SolicitudModel> items) {
    final conteo = <String, int>{};
    for (final item in items) {
      final nombre = item.categoriaNombre?.trim();
      final clave =
          (nombre == null || nombre.isEmpty) ? 'Sin categoría' : nombre;
      conteo[clave] = (conteo[clave] ?? 0) + 1;
    }
    final ordenado = conteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ordenado.take(5).toList();
  }

  /// Solicitudes creadas por día en los últimos 7 días
  /// (el último elemento es hoy).
  List<int> _actividadSemana(List<SolicitudModel> items) {
    final hoy = DateTime.now();
    final base = DateTime(hoy.year, hoy.month, hoy.day);
    final conteo = List<int>.filled(7, 0);

    for (final item in items) {
      final fecha = item.fechaCreacion;
      final dia = DateTime(fecha.year, fecha.month, fecha.day);
      final diferencia = base.difference(dia).inDays;
      if (diferencia >= 0 && diferencia < 7) {
        conteo[6 - diferencia]++;
      }
    }
    return conteo;
  }

  String _letraDia(DateTime fecha) {
    const letras = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return letras[fecha.weekday - 1];
  }

  // ==========================================================
  // PANEL SUPERIOR (CABECERA, KPIs Y GRÁFICAS)
  // ==========================================================

  Widget _buildDashboard(List<SolicitudModel> solicitudes) {
    final conteo = _contarPorEstado(solicitudes);
    final pendientes = conteo[RequestStatus.pendiente] ?? 0;
    final enCurso = (conteo[RequestStatus.enCamino] ?? 0) +
        (conteo[RequestStatus.enProceso] ?? 0);
    final completadas = conteo[RequestStatus.completado] ?? 0;
    final porSincronizar =
        solicitudes.where((solicitud) => solicitud.pendingSync).length;
    final parcial = _totalCount > solicitudes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(porSincronizar),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildKpi(
                icon: Icons.assignment_rounded,
                label: 'Total',
                value: math.max(_totalCount, solicitudes.length),
                color: const Color(0xFFAA8BFF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpi(
                icon: Icons.hourglass_top_rounded,
                label: 'Pendientes',
                value: pendientes,
                color: _colorPendiente,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpi(
                icon: Icons.local_shipping_rounded,
                label: 'En curso',
                value: enCurso,
                color: _colorEnCamino,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpi(
                icon: Icons.verified_rounded,
                label: 'Completadas',
                value: completadas,
                color: _colorCompletado,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildEstadoChart(conteo, solicitudes.length),
        const SizedBox(height: 12),
        _buildActividadChart(solicitudes),
        const SizedBox(height: 12),
        _buildCategoriaChart(solicitudes),
        if (parcial)
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Text(
              'Las gráficas se calculan con las solicitudes cargadas. '
              'Usa "Cargar más" para incluir más resultados.',
              style: TextStyle(color: Color(0xFF777486), fontSize: 10.5),
            ),
          ),
        const SizedBox(height: 22),
        const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Text(
            'Listado de solicitudes',
            style: TextStyle(
              color: Color(0xFFF2F0FA),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        _buildResultsSummary(),
      ],
    );
  }

  Widget _buildHero(int porSincronizar) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3B2F66)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B1F8F), Color(0xFF1B1140), Color(0xFF0F0B24)],
        ),
      ),
      child: Stack(
        children: [
          if (_heroImageAsset != null)
            Positioned.fill(
              child: Image.asset(
                _heroImageAsset!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF120A33).withValues(alpha: 0.92),
                    const Color(0xFF120A33).withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -34,
            top: -34,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 22,
            bottom: 14,
            child: Icon(
              Icons.home_repair_service_rounded,
              size: 92,
              color: Colors.white.withValues(alpha: 0.13),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 168),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.dashboard_rounded,
                          size: 13,
                          color: Color(0xFFD8CCFF),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'PANEL DE SERVICIOS',
                          style: TextStyle(
                            color: Color(0xFFD8CCFF),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tu hogar,\nsiempre bajo control',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sigue cada servicio desde que lo pides '
                    'hasta que queda resuelto.',
                    style: TextStyle(
                      color: Color(0xFFC9C0E8),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildHeroChip(
                        _mostrandoDatosOffline
                            ? Icons.cloud_off_rounded
                            : Icons.cloud_done_rounded,
                        _mostrandoDatosOffline
                            ? 'Modo sin conexión'
                            : 'Sincronizado',
                        _mostrandoDatosOffline
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF4ADE80),
                      ),
                      if (porSincronizar > 0)
                        _buildHeroChip(
                          Icons.sync_rounded,
                          '$porSincronizar por sincronizar',
                          const Color(0xFFFBBF24),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpi({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: value),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, animated, child) => Text(
                    '$animated',
                    style: const TextStyle(
                      color: Color(0xFFF8F7FF),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFAAA7B8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFFB9A5FF)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFF2F0FA),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF8E8B9E),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// Gráfica de dona con la distribución por estado.
  Widget _buildEstadoChart(Map<RequestStatus, int> conteo, int total) {
    final estados = RequestStatus.values;

    return _buildSectionCard(
      icon: Icons.donut_large_rounded,
      title: 'Distribución por estado',
      subtitle: 'Cómo van tus servicios ahora mismo',
      child: Row(
        children: [
          SizedBox(
            width: 124,
            height: 124,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, progress, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(124, 124),
                      painter: _DonutPainter(
                        values: [
                          for (final estado in estados)
                            (conteo[estado] ?? 0).toDouble(),
                        ],
                        colors: [
                          for (final estado in estados) _colorEstado(estado),
                        ],
                        progress: progress,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            color: Color(0xFFF8F7FF),
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'solicitudes',
                          style: TextStyle(
                            color: Color(0xFF8E8B9E),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                for (final estado in estados)
                  _buildLegendRow(
                    color: _colorEstado(estado),
                    label: _estadoApi(estado),
                    count: conteo[estado] ?? 0,
                    total: total,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow({
    required Color color,
    required String label,
    required int count,
    required int total,
  }) {
    final porcentaje = total == 0 ? 0 : (count * 100 / total).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFD9D6E6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFFF2F0FA),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 34,
            child: Text(
              '$porcentaje%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF8E8B9E),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gráfica de barras con las solicitudes creadas en los últimos 7 días.
  Widget _buildActividadChart(List<SolicitudModel> solicitudes) {
    final datos = _actividadSemana(solicitudes);
    final maximo = datos.reduce(math.max);
    final hoy = DateTime.now();
    const alturaMaxima = 78.0;

    return _buildSectionCard(
      icon: Icons.bar_chart_rounded,
      title: 'Actividad de los últimos 7 días',
      subtitle: 'Solicitudes creadas por día',
      child: SizedBox(
        height: alturaMaxima + 44,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < datos.length; i++)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      datos[i] > 0 ? '${datos[i]}' : '',
                      style: const TextStyle(
                        color: Color(0xFFD9D6E6),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: maximo == 0 ? 0 : datos[i] / maximo,
                      ),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, factor, child) {
                        return Container(
                          width: 20,
                          height: math.max(5.0, alturaMaxima * factor),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: datos[i] > 0
                                  ? const [
                                      Color(0xFF6D3FD6),
                                      Color(0xFFB9A5FF),
                                    ]
                                  : const [
                                      Color(0xFF252431),
                                      Color(0xFF252431),
                                    ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _letraDia(
                        hoy.subtract(Duration(days: 6 - i)),
                      ),
                      style: TextStyle(
                        color: i == datos.length - 1
                            ? const Color(0xFFB9A5FF)
                            : const Color(0xFF8E8B9E),
                        fontSize: 11,
                        fontWeight: i == datos.length - 1
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Barras horizontales con las categorías más solicitadas.
  Widget _buildCategoriaChart(List<SolicitudModel> solicitudes) {
    final top = _topCategorias(solicitudes);
    final hayCategorias = top.any((entry) => entry.key != 'Sin categoría');
    final maximo = top.isEmpty ? 1 : top.first.value;

    return _buildSectionCard(
      icon: Icons.category_rounded,
      title: 'Servicios más solicitados',
      subtitle: 'Top de categorías',
      child: (!hayCategorias || _mostrandoDatosOffline)
          ? const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFF8E8B9E),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conéctate al servidor para ver el detalle por categoría.',
                    style: TextStyle(
                      color: Color(0xFF8E8B9E),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                for (final entry in top)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFD9D6E6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${entry.value}',
                              style: const TextStyle(
                                color: Color(0xFFF2F0FA),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 8,
                            color: const Color(0xFF252431),
                            alignment: Alignment.centerLeft,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0,
                                end: entry.value / maximo,
                              ),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              builder: (context, factor, child) {
                                return FractionallySizedBox(
                                  widthFactor: factor,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF6D3FD6),
                                          Color(0xFFB9A5FF),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  // ==========================================================
  // SECCIÓN INFORMATIVA (FINAL DE LA PÁGINA)
  // ==========================================================

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            'Acerca de tus solicitudes',
            style: TextStyle(
              color: Color(0xFFF2F0FA),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        _buildSectionCard(
          icon: Icons.info_rounded,
          title: '¿Qué es esta sección?',
          child: const Text(
            'Aquí encuentras todos los servicios del hogar que has pedido: '
            'plomería, electricidad, limpieza y más. Puedes consultar el '
            'estado de cada uno, filtrarlos por estado o categoría y abrir '
            'el detalle para ver la ubicación y la descripción que enviaste.',
            style: TextStyle(
              color: Color(0xFFB4B1C4),
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          icon: Icons.route_rounded,
          title: '¿Cómo funciona un servicio?',
          subtitle: 'Las cuatro etapas de tu solicitud',
          child: Column(
            children: [
              _buildStep(
                icon: Icons.hourglass_top_rounded,
                color: _colorPendiente,
                title: 'Pendiente',
                text: 'Tu solicitud fue registrada y espera a un profesional.',
              ),
              _buildStep(
                icon: Icons.local_shipping_rounded,
                color: _colorEnCamino,
                title: 'En camino',
                text: 'Un profesional aceptó y se dirige a tu ubicación.',
              ),
              _buildStep(
                icon: Icons.handyman_rounded,
                color: _colorEnProceso,
                title: 'En proceso',
                text: 'El trabajo se está realizando en tu hogar.',
              ),
              _buildStep(
                icon: Icons.verified_rounded,
                color: _colorCompletado,
                title: 'Completado',
                text: 'El servicio terminó y queda en tu historial.',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          icon: Icons.lightbulb_rounded,
          title: 'Consejos útiles',
          child: Column(
            children: [
              _buildTip(
                Icons.cloud_off_rounded,
                'Funciona sin conexión',
                'Puedes crear solicitudes sin internet; se enviarán solas '
                    'cuando vuelva la conexión.',
              ),
              _buildTip(
                Icons.photo_camera_rounded,
                'Describe bien el problema',
                'Una descripción clara y tu ubicación ayudan a que el '
                    'profesional llegue preparado.',
              ),
              _buildTip(
                Icons.refresh_rounded,
                'Actualiza deslizando',
                'Desliza hacia abajo en la lista para recargar tus '
                    'solicitudes.',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep({
    required IconData icon,
    required Color color,
    required String title,
    required String text,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFF302E3D),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Color(0xFFB4B1C4),
                      fontSize: 12,
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

  Widget _buildTip(
    IconData icon,
    String title,
    String text, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFAA8BFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF2F0FA),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFFB4B1C4),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FILTROS
  // ==========================================================

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14131D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF252431)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: Color(0xFFAA8BFF),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Filtrar solicitudes',
                  style: TextStyle(
                    color: Color(0xFFF2F0FA),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_hayFiltrosActivos)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = null;
                      _selectedCategoryId = null;
                    });
                    _cargarSolicitudes();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB9A5FF),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Limpiar'),
                ),
            ],
          ),
          if (_categoryLoadError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _categoryLoadError!,
                      style: const TextStyle(
                        color: Color(0xFFFFC56D),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _cargarCategorias,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedStatus,
                  isExpanded: true,
                  decoration: _filterDecoration('Estado'),
                  dropdownColor: const Color(0xFF1A1925),
                  style: const TextStyle(
                    color: Color(0xFFF2F0FA),
                    fontSize: 12,
                  ),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Pendiente',
                      child: Text('Pendiente'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'En camino',
                      child: Text('En camino'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'En proceso',
                      child: Text('En proceso'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Completado',
                      child: Text('Completado'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == _selectedStatus) return;
                    setState(() => _selectedStatus = value);
                    _cargarSolicitudes();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _selectedCategoryId,
                  isExpanded: true,
                  decoration: _filterDecoration('Categoría'),
                  dropdownColor: const Color(0xFF1A1925),
                  style: const TextStyle(
                    color: Color(0xFFF2F0FA),
                    fontSize: 12,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ..._categorias.map(
                      (category) => DropdownMenuItem<int?>(
                        value: category.id,
                        child: Text(
                          category.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == _selectedCategoryId) return;
                    setState(() => _selectedCategoryId = value);
                    _cargarSolicitudes();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _filterDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFFAAA7B8),
        fontSize: 12,
      ),
      filled: true,
      fillColor: const Color(0xFF0D0C13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF302E3D)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF302E3D)),
      ),
    );
  }

  Widget _buildResultsSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _hayFiltrosActivos
                  ? '$_totalCount resultados'
                  : 'Mis servicios · $_totalCount',
              style: const TextStyle(
                color: Color(0xFFAAA7B8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_totalPages > 1)
            Text(
              'Página $_page de $_totalPages',
              style: const TextStyle(
                color: Color(0xFF777486),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter() {
    if (_loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              _loadMoreError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFF9B9B), fontSize: 12),
            ),
            TextButton.icon(
              onPressed: _cargarMas,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF8B5CF6),
            ),
          ),
        ),
      );
    }
    if (_page >= _totalPages || _usingLegacyEndpoint) {
      return const SizedBox(height: 4);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: _cargarMas,
          icon: const Icon(Icons.expand_more_rounded),
          label: const Text('Cargar más'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC6B6FF),
            side: const BorderSide(color: Color(0xFF51436F)),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

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
          _buildFilters(),
          if (_mostrandoDatosOffline &&
              _solicitudes.isNotEmpty)
            _buildOfflineBanner(),

          if (_usingLegacyEndpoint)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF302A1D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Paginación no disponible; se muestran los datos del servicio anterior.',
                style: TextStyle(color: Color(0xFFE8C97A), fontSize: 11),
              ),
            ),

          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF8B5CF6),
              backgroundColor:
                  const Color(0xFF1A1925),
              onRefresh:
                  _cargarSolicitudes,
              child: AsyncStateView<List<SolicitudModel>>(
                status: _status,
                data: _solicitudes,
                errorMessage:
                    _errorMessage,
                emptyMessage:
                    _mostrandoDatosOffline &&
                            _selectedCategoryId != null
                        ? 'La copia sin conexión no incluye categorías. Conéctate para filtrar por categoría.'
                        : _hayFiltrosActivos
                        ? 'No hay solicitudes que coincidan con estos filtros.'
                        : 'Aún no tienes solicitudes registradas',
                onRetry:
                    _cargarSolicitudes,
                builder: (
                  context,
                  solicitudes,
                ) {
                  final showPagination = !_usingLegacyEndpoint &&
                      (_page < _totalPages || _loadingMore || _loadMoreError != null);
                  final total = solicitudes.length;

                  // Estructura de la lista:
                  //   0                  -> panel (cabecera, KPIs, gráficas)
                  //   1..total           -> tarjetas de solicitudes
                  //   total + 1          -> paginación (si aplica)
                  //   último             -> sección informativa
                  return ListView.separated(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      18,
                      16,
                      18,
                      105,
                    ),
                    itemCount: total +
                        1 +
                        (showPagination ? 1 : 0) +
                        1,
                    separatorBuilder:
                        (_, index) =>
                            const SizedBox(
                      height: 12,
                    ),
                    itemBuilder:
                        (context, index) {
                      if (index == 0) return _buildDashboard(solicitudes);
                      if (index <= total) {
                        return _buildRequestItem(
                          solicitudes[index - 1],
                        );
                      }
                      if (showPagination && index == total + 1) {
                        return _buildPaginationFooter();
                      }
                      return _buildInfoSection();
                    },
                  );
                },
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
          if (solicitud.pendingSync)
            solicitud.syncFailed
                ? 'No se pudo sincronizar'
                : 'Esperando conexión',
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

/// Pinta la gráfica de dona de la distribución por estado.
class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double progress;

  const _DonutPainter({
    required this.values,
    required this.colors,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0xFF252431);
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return;

    final visibles = values.where((value) => value > 0).length;
    final gap = visibles > 1 ? 0.07 : 0.0;
    var start = -math.pi / 2;

    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;

      final sweep = values[i] / total * math.pi * 2 * progress;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = colors[i];

      canvas.drawArc(
        rect,
        start,
        sweep > gap ? sweep - gap : sweep,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.values != values ||
        oldDelegate.colors != colors;
  }
}