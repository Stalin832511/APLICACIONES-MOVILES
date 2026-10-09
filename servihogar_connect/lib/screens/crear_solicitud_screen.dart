import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/categoria.dart';
import '../models/solicitud.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/catalog_service.dart';
import '../services/evidence_service.dart';
import '../services/native/native_capabilities_service.dart';

class CrearSolicitudScreen extends StatefulWidget {
  final AppDatabase database;
  final int? initialCategoryId;

  const CrearSolicitudScreen({
    super.key,
    required this.database,
    this.initialCategoryId,
  });

  @override
  State<CrearSolicitudScreen> createState() =>
      _CrearSolicitudScreenState();
}

class _CrearSolicitudScreenState
    extends State<CrearSolicitudScreen> {
  late final AppDatabase _database;

  final TextEditingController _descripcionController =
      TextEditingController();

  List<CategoriaModel> _categorias = [];
  int? _idCategoriaSeleccionada;
  bool _cargandoCategorias = true;
  bool _categoriasDesdeCache = false;
  String? _errorCategorias;

  bool _guardando = false;
  bool _obteniendoUbicacion = false;
  bool _tomandoFoto = false;

  double? _latitud;
  double? _longitud;
  double? _precision;

  XFile? _foto;

  String? _mensajeUbicacion;
  String? _mensajeCamara;

  NativePermissionState _estadoUbicacion =
      NativePermissionState.denied;

  NativePermissionState _estadoCamara =
      NativePermissionState.denied;

  @override
  void initState() {
    super.initState();

    _database = widget.database;
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    setState(() {
      _cargandoCategorias = true;
      _errorCategorias = null;
    });

    try {
      final resultado = await CatalogService.loadCategories();
      if (!mounted) return;

      setState(() {
        _categorias = resultado.categories;
        _categoriasDesdeCache = resultado.fromCache;
        final requestedCategoryExists = _categorias.any(
          (categoria) => categoria.id == widget.initialCategoryId,
        );
        final selectedCategoryExists = _categorias.any(
          (categoria) => categoria.id == _idCategoriaSeleccionada,
        );
        if (requestedCategoryExists) {
          _idCategoriaSeleccionada = widget.initialCategoryId;
        } else if (!selectedCategoryExists) {
          _idCategoriaSeleccionada = _categorias.isEmpty
              ? null
              : _categorias.first.id;
        }
        _cargandoCategorias = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorCategorias = error.toString().replaceFirst('Exception: ', '');
        _cargandoCategorias = false;
      });
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();

    // NO cerrar AppDatabase aquí.
    //
    // La instancia es compartida por toda la aplicación
    // y será cerrada únicamente desde main.dart.
    super.dispose();
  }

  // ============================================================
  // OBTENER UBICACIÓN
  // ============================================================

  Future<void> _obtenerUbicacion() async {
    if (_obteniendoUbicacion) return;

    setState(() {
      _obteniendoUbicacion = true;
      _mensajeUbicacion = null;
    });

    final result =
        await NativeCapabilitiesService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      _obteniendoUbicacion = false;
      _estadoUbicacion = result.permissionState;
      _mensajeUbicacion = result.message;

      if (result.position != null) {
        _latitud = result.position!.latitude;
        _longitud = result.position!.longitude;
        _precision = result.position!.accuracy;
      }
    });

    if (result.locationServiceDisabled) {
      await _mostrarDialogoGPSDesactivado();
      return;
    }

    if (result.permissionState ==
        NativePermissionState.permanentlyDenied) {
      await _mostrarDialogoAjustes(
        titulo: 'Ubicación bloqueada',
        mensaje:
            'El permiso de ubicación está bloqueado. '
            'Debes habilitarlo desde los ajustes de la aplicación.',
      );
    }
  }

  // ============================================================
  // TOMAR FOTOGRAFÍA
  // ============================================================

  Future<void> _tomarFotografia() async {
    if (_tomandoFoto) return;

    setState(() {
      _tomandoFoto = true;
      _mensajeCamara = null;
    });

    final result =
        await NativeCapabilitiesService.takePhoto();

    if (!mounted) return;

    XFile? fotoPersistida;
    String? errorPersistencia;
    if (result.image != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final evidenceDirectory = Directory(
          '${directory.path}${Platform.pathSeparator}evidence',
        );
        await evidenceDirectory.create(recursive: true);
        final extension =
            result.image!.path.toLowerCase().endsWith('.png')
                ? '.png'
                : '.jpg';
        final persistentPath =
            '${evidenceDirectory.path}${Platform.pathSeparator}'
            'evidence_${const Uuid().v4()}$extension';
        final storedFile = await File(result.image!.path).copy(persistentPath);
        fotoPersistida = XFile(storedFile.path);
      } on FileSystemException catch (error) {
        debugPrint('No se pudo conservar la fotografía localmente: $error');
        errorPersistencia =
            'No se pudo conservar la fotografía en el dispositivo.';
      } on MissingPlatformDirectoryException catch (error) {
        debugPrint('No se pudo acceder al almacenamiento local: $error');
        errorPersistencia =
            'No se pudo acceder al almacenamiento local del dispositivo.';
      }
    }

    if (!mounted) return;

    setState(() {
      _tomandoFoto = false;
      _estadoCamara = result.permissionState;
      _foto = fotoPersistida;
      _mensajeCamara = errorPersistencia ?? result.message;
    });

    if (result.permissionState ==
        NativePermissionState.permanentlyDenied) {
      await _mostrarDialogoAjustes(
        titulo: 'Cámara bloqueada',
        mensaje:
            'El permiso de cámara está bloqueado. '
            'Debes habilitarlo desde los ajustes de la aplicación.',
      );
    }
  }

  // ============================================================
  // CREAR SOLICITUD
  // ============================================================

  Future<void> _crearSolicitud() async {
    final descripcion =
        _descripcionController.text.trim();

    if (descripcion.isEmpty) {
      _mostrarMensaje(
        'Escribe una descripción del servicio solicitado.',
        esError: true,
      );
      return;
    }

    final idCategoria = _idCategoriaSeleccionada;
    if (idCategoria == null) {
      _mostrarMensaje(
        'Selecciona una categoría activa antes de continuar.',
        esError: true,
      );
      return;
    }

    if (_guardando) return;

    // La ubicación se solicita en el momento de utilizarla.
    if (_latitud == null || _longitud == null) {
      _mostrarMensaje(
        'Obtén primero la ubicación del servicio.',
        esError: true,
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final idUsuario =
          await AuthService.getUserId();

      if (idUsuario == null) {
        throw Exception(
          'No existe una sesión de usuario activa.',
        );
      }

      final clientOperationId =
          const Uuid().v4();

      debugPrint(
        '========================================',
      );
      debugPrint('CREANDO SOLICITUD');
      debugPrint('Usuario: $idUsuario');
      debugPrint(
        'Categoría: $idCategoria',
      );
      debugPrint(
        'ClientOperationId: $clientOperationId',
      );
      debugPrint(
        'Descripción: $descripcion',
      );
      debugPrint(
        'Latitud: $_latitud',
      );
      debugPrint(
        'Longitud: $_longitud',
      );
      debugPrint(
        '========================================',
      );

      late final SolicitudModel solicitud;
      try {
        solicitud = await ApiService.crearSolicitud(
          idUsuario: idUsuario,
          idCategoria: idCategoria,
          clientOperationId:
              clientOperationId,
          descripcion: descripcion,
          latitud: _latitud!,
          longitud: _longitud!,
        );
      } on SocketException catch (error) {
        await _guardarSolicitudParaSincronizar(
          idUsuario: idUsuario,
          idCategoria: idCategoria,
          clientOperationId: clientOperationId,
          descripcion: descripcion,
          error: error,
        );
        return;
      } on TimeoutException catch (error) {
        await _guardarSolicitudParaSincronizar(
          idUsuario: idUsuario,
          idCategoria: idCategoria,
          clientOperationId: clientOperationId,
          descripcion: descripcion,
          error: error,
        );
        return;
      } on http.ClientException catch (error) {
        await _guardarSolicitudParaSincronizar(
          idUsuario: idUsuario,
          idCategoria: idCategoria,
          clientOperationId: clientOperationId,
          descripcion: descripcion,
          error: error,
        );
        return;
      } on ApiServiceException catch (error) {
        if (!error.isNetworkFailure) rethrow;
        await _guardarSolicitudParaSincronizar(
          idUsuario: idUsuario,
          idCategoria: idCategoria,
          clientOperationId: clientOperationId,
          descripcion: descripcion,
          error: error,
        );
        return;
      }

      debugPrint(
        'SOLICITUD CREADA ONLINE - ID: ${solicitud.id}',
      );

      await _guardarSolicitudLocal(
        id: solicitud.id.toString(),
        clientOperationId: clientOperationId,
        descripcion: solicitud.descripcion,
        status: solicitud.status.name,
        createdAt: solicitud.fechaCreacion,
      );

      if (_foto != null) {
        try {
          await EvidenceService.upload(
            idSolicitud: solicitud.id,
            filePath: _foto!.path,
          );
        } on DioException catch (error) {
          if (error.response == null) {
            await _guardarOperacionOffline(
              idUsuario: idUsuario,
              idCategoria: idCategoria,
              clientOperationId: clientOperationId,
              descripcion: descripcion,
            );
            if (!mounted) return;
            _mostrarMensaje(
              'Solicitud creada. La fotografía quedó pendiente de sincronización.',
            );
            _descripcionController.clear();
            await Future.delayed(const Duration(milliseconds: 800));
            if (!mounted) return;
            Navigator.of(context).pop(true);
            return;
          }

          if (error.response?.statusCode == 400 ||
              error.response?.statusCode == 413 ||
              error.response?.statusCode == 415) {
            if (!mounted) return;
            _mostrarMensaje(
              'La solicitud quedó creada, pero el servidor rechazó '
              'la fotografía. Usa una imagen JPEG, PNG o WebP de hasta 10 MB.',
              esError: true,
            );
            _descripcionController.clear();
            await Future.delayed(const Duration(milliseconds: 800));
            if (!mounted) return;
            Navigator.of(context).pop(true);
            return;
          }

          rethrow;
        }
      }

      if (!mounted) return;

      _mostrarMensaje(
        _foto == null
            ? 'Solicitud creada correctamente en el servidor.'
            : 'Solicitud y fotografía creadas correctamente en el servidor.',
      );
      _descripcionController.clear();

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint(
        'ERROR CREANDO SOLICITUD: $e',
      );

      if (!mounted) return;

      _mostrarMensaje(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  Future<void> _guardarSolicitudParaSincronizar({
    required int idUsuario,
    required int idCategoria,
    required String clientOperationId,
    required String descripcion,
    required Object error,
  }) async {
    debugPrint('No se pudo contactar con el servidor: $error');
    await _guardarOperacionOffline(
      idUsuario: idUsuario,
      idCategoria: idCategoria,
      clientOperationId: clientOperationId,
      descripcion: descripcion,
    );

    if (!mounted) return;
    _mostrarMensaje(
      'Sin conexión. La solicitud quedó guardada y será sincronizada posteriormente.',
    );
    _descripcionController.clear();

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  // ============================================================
  // GUARDAR SOLICITUD LOCAL
  // ============================================================

  Future<void> _guardarSolicitudLocal({
    required String id,
    required String clientOperationId,
    required String descripcion,
    required String status,
    required DateTime createdAt,
  }) async {
    await _database.serviceRequestDao
        .upsertRequest(
      ServiceRequestsCompanion.insert(
        id: id,
        clientOperationId:
            drift.Value(
          clientOperationId,
        ),
        description:
            descripcion,
        status:
            status,
        createdAt:
            createdAt,
        updatedAt:
            drift.Value(
          createdAt,
        ),
        serverUpdatedAt:
            drift.Value(
          createdAt,
        ),
        cachedAt:
            DateTime.now(),
      ),
    );

    debugPrint(
      'SOLICITUD GUARDADA EN SQLITE',
    );
  }

  // ============================================================
  // GUARDAR OPERACIÓN OFFLINE
  // ============================================================

  Future<void> _guardarOperacionOffline({
    required int idUsuario,
    required int idCategoria,
    required String clientOperationId,
    required String descripcion,
  }) async {
    final ahora =
        DateTime.now();

    final payload = jsonEncode({
      'idUsuario': idUsuario,
      'idCategoria':
          idCategoria,
      'clientOperationId':
          clientOperationId,
      'descripcion':
          descripcion,
      'estado':
          'publicada',

      // Ubicación obtenida del dispositivo.
      'latitud':
          _latitud,
      'longitud':
          _longitud,

      // Precisión disponible en el dispositivo.
      'precision':
          _precision,

      'fotoPath': _foto?.path,
      'fotoTomada':
          _foto != null,
    });

    await _database.syncQueueDao
        .insertOperation(
      SyncQueueCompanion.insert(
        id:
            clientOperationId,
        operationId:
            clientOperationId,
        operationType:
            'crear_solicitud',
        payload:
            payload,
        retryCount:
            const drift.Value(0),
        createdAt:
            ahora,
        nextRetryAt:
            drift.Value(ahora),
        status:
            'pending',
      ),
    );

    debugPrint(
      'OPERACIÓN AGREGADA A SYNC_QUEUE',
    );

    debugPrint(
      'operationId: '
      '$clientOperationId',
    );
  }

  // ============================================================
  // MENSAJES
  // ============================================================

  void _mostrarMensaje(
    String mensaje, {
    bool esError = false,
  }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(mensaje),
        backgroundColor:
            esError
                ? Colors.red
                : null,
      ),
    );
  }

  // ============================================================
  // DIÁLOGO AJUSTES
  // ============================================================

  Future<void> _mostrarDialogoAjustes({
    required String titulo,
    required String mensaje,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text(titulo),
          content:
              Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child:
                  const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();

                await NativeCapabilitiesService
                    .openAppSettingsPage();
              },
              child:
                  const Text('Abrir ajustes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarDialogoGPSDesactivado() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('GPS desactivado'),
          content:
              const Text(
            'El permiso de ubicación fue concedido, '
            'pero el GPS del teléfono está desactivado.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child:
                  const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();

                await NativeCapabilitiesService
                    .openLocationSettings();
              },
              child:
                  const Text('Abrir ubicación'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Nueva Solicitud',
        ),
      ),
      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(
            20,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Solicitar un servicio',
                style:
                    TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'Describe el servicio que necesitas. '
                'La ubicación permite registrar el lugar '
                'donde se requiere el servicio. '
                'Si no hay conexión, la solicitud se '
                'guardará localmente.',
              ),

              const SizedBox(
                height: 24,
              ),

              const Text(
                'Categoría',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              if (_cargandoCategorias)
                const LinearProgressIndicator()
              else if (_errorCategorias != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _errorCategorias!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    TextButton.icon(
                      onPressed: _cargarCategorias,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                )
              else if (_categorias.isEmpty)
                const Text('No hay categorías activas disponibles.')
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: _idCategoriaSeleccionada,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Selecciona un servicio',
                      ),
                      items: _categorias
                          .map(
                            (categoria) => DropdownMenuItem<int>(
                              value: categoria.id,
                              child: Text(categoria.nombre),
                            ),
                          )
                          .toList(),
                      onChanged: (idCategoria) {
                        setState(() {
                          _idCategoriaSeleccionada = idCategoria;
                        });
                      },
                    ),
                    if (_categoriasDesdeCache)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Catálogo guardado en este dispositivo; '
                          'se actualizará al recuperar la conexión.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),

              const SizedBox(
                height: 20,
              ),

              const Text(
                'Descripción',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextField(
                controller:
                    _descripcionController,
                maxLines: 6,
                textInputAction:
                    TextInputAction
                        .newline,
                decoration:
                    InputDecoration(
                  hintText:
                      'Ejemplo: Necesito reparar '
                      'una fuga de agua en la cocina.',
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  alignLabelWithHint:
                      true,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // UBICACIÓN
              // ==================================================

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.blue.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  border:
                      Border.all(
                    color:
                        Colors.blue.shade200,
                  ),
                ),
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            'Ubicación del servicio',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize:
                                  16,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'La ubicación se solicita únicamente '
                      'cuando presionas el botón.',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    if (_latitud != null &&
                        _longitud != null)
                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Latitud: '
                              '${_latitud!.toStringAsFixed(6)}',
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              'Longitud: '
                              '${_longitud!.toStringAsFixed(6)}',
                            ),
                            if (_precision !=
                                null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(
                                  top: 4,
                                ),
                                child:
                                    Text(
                                  'Precisión: '
                                  '${_precision!.toStringAsFixed(1)} m',
                                ),
                              ),
                          ],
                        ),
                      ),

                    if (_mensajeUbicacion !=
                        null)
                      Padding(
                        padding:
                            const EdgeInsets.only(
                          top: 10,
                        ),
                        child:
                            Text(
                          _mensajeUbicacion!,
                          style:
                              const TextStyle(
                            color:
                                Colors.orange,
                          ),
                        ),
                      ),

                    if (_estadoUbicacion ==
                        NativePermissionState.permanentlyDenied)
                      Padding(
                        padding:
                            const EdgeInsets.only(
                          top: 10,
                        ),
                        child:
                            OutlinedButton.icon(
                          onPressed: () =>
                              NativeCapabilitiesService
                                  .openAppSettingsPage(),
                          icon: const Icon(
                            Icons.settings,
                            size: 18,
                          ),
                          label: const Text(
                            'Abrir ajustes de la app',
                          ),
                        ),
                      ),

                    const SizedBox(
                      height: 12,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          FilledButton.icon(
                        onPressed:
                            _obteniendoUbicacion
                                ? null
                                : _obtenerUbicacion,
                        icon:
                            _obteniendoUbicacion
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location,
                                  ),
                        label:
                            Text(
                          _obteniendoUbicacion
                              ? 'Obteniendo ubicación...'
                              : _latitud == null
                                  ? 'Obtener ubicación'
                                  : 'Actualizar ubicación',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // CÁMARA
              // ==================================================

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.green.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  border:
                      Border.all(
                    color:
                        Colors.green.shade200,
                  ),
                ),
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.camera_alt,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            'Evidencia fotográfica',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize:
                                  16,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'Puedes tomar una fotografía del '
                      'servicio solicitado.',
                    ),

                    if (_foto != null) ...[
                      const SizedBox(
                        height: 12,
                      ),

                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                        child:
                            Image.file(
                          File(
                            _foto!.path,
                          ),
                          height:
                              180,
                          width:
                              double.infinity,
                          fit:
                              BoxFit.cover,
                        ),
                      ),
                    ],

                    if (_mensajeCamara !=
                        null)
                      Padding(
                        padding:
                            const EdgeInsets.only(
                          top: 10,
                        ),
                        child:
                            Text(
                          _mensajeCamara!,
                          style:
                              const TextStyle(
                            color:
                                Colors.orange,
                          ),
                        ),
                      ),

                    if (_estadoCamara ==
                        NativePermissionState.permanentlyDenied)
                      Padding(
                        padding:
                            const EdgeInsets.only(
                          top: 10,
                        ),
                        child:
                            OutlinedButton.icon(
                          onPressed: () =>
                              NativeCapabilitiesService
                                  .openAppSettingsPage(),
                          icon: const Icon(
                            Icons.settings,
                            size: 18,
                          ),
                          label: const Text(
                            'Abrir ajustes de la app',
                          ),
                        ),
                      ),

                    const SizedBox(
                      height: 12,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            _tomandoFoto
                                ? null
                                : _tomarFotografia,
                        icon:
                            _tomandoFoto
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                  ),
                        label:
                            Text(
                          _tomandoFoto
                              ? 'Abriendo cámara...'
                              : _foto == null
                                  ? 'Tomar fotografía'
                                  : 'Tomar otra fotografía',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // CREAR
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height:
                    52,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      _guardando ||
                              _cargandoCategorias ||
                              _categorias.isEmpty ||
                              _errorCategorias != null
                          ? null
                          : _crearSolicitud,
                  icon:
                      _guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                            ),
                  label:
                      Text(
                    _guardando
                        ? 'Guardando...'
                        : 'Crear solicitud',
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.blue.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child:
                    const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Text(
                        'La solicitud utiliza un '
                        'identificador único para evitar '
                        'duplicados durante la sincronización. '
                        'La ubicación se conserva también '
                        'dentro de la operación offline.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}