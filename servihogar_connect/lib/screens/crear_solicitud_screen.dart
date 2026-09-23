import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/native/native_capabilities_service.dart';

class CrearSolicitudScreen extends StatefulWidget {
  final AppDatabase database;

  const CrearSolicitudScreen({
    super.key,
    required this.database,
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

  static const int _idCategoriaPlomeria = 1;

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

    setState(() {
      _tomandoFoto = false;
      _estadoCamara = result.permissionState;
      _foto = result.image;
      _mensajeCamara = result.message;
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
        'Categoría: $_idCategoriaPlomeria',
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

      try {
        final solicitud =
            await ApiService.crearSolicitud(
          idUsuario: idUsuario,
          idCategoria:
              _idCategoriaPlomeria,
          clientOperationId:
              clientOperationId,
          descripcion: descripcion,
          latitud: _latitud!,
          longitud: _longitud!,
        );

        debugPrint(
          'SOLICITUD CREADA ONLINE - '
          'ID: ${solicitud.id}',
        );

        await _guardarSolicitudLocal(
          id: solicitud.id.toString(),
          clientOperationId:
              clientOperationId,
          descripcion:
              solicitud.descripcion,
          status:
              solicitud.status.name,
          createdAt:
              solicitud.fechaCreacion,
        );

        if (!mounted) return;

        _mostrarMensaje(
          'Solicitud creada correctamente '
          'en el servidor.',
        );

        _descripcionController.clear();

        await Future.delayed(
          const Duration(
            milliseconds: 800,
          ),
        );

        if (!mounted) return;

        Navigator.of(context).pop(true);
      } catch (e) {
        debugPrint(
          'NO HAY CONEXIÓN O FALLÓ EL SERVIDOR.',
        );
        debugPrint(
          'Guardando operación offline...',
        );
        debugPrint(
          'Error: $e',
        );

        await _guardarOperacionOffline(
          idUsuario: idUsuario,
          clientOperationId:
              clientOperationId,
          descripcion: descripcion,
        );

        if (!mounted) return;

        _mostrarMensaje(
          'Sin conexión. La solicitud quedó '
          'guardada y será sincronizada '
          'posteriormente.',
        );

        _descripcionController.clear();

        await Future.delayed(
          const Duration(
            milliseconds: 800,
          ),
        );

        if (!mounted) return;

        Navigator.of(context).pop(true);
      }
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
    required String clientOperationId,
    required String descripcion,
  }) async {
    final ahora =
        DateTime.now();

    final payload = jsonEncode({
      'idUsuario': idUsuario,
      'idCategoria':
          _idCategoriaPlomeria,
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

      // La fotografía se mantiene como evidencia
      // local de la sesión. No se sube al backend
      // porque el endpoint actual no implementa
      // carga de archivos.
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

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration:
                    BoxDecoration(
                  border:
                      Border.all(
                    color:
                        Colors.grey.shade400,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child:
                    const Row(
                  children: [
                    Icon(
                      Icons.plumbing,
                    ),
                    SizedBox(
                      width: 12,
                    ),
                    Text(
                      'Plomeria',
                      style:
                          TextStyle(
                        fontSize:
                            16,
                      ),
                    ),
                  ],
                ),
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
                      _guardando
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