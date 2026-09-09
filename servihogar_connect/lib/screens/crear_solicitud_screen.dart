import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

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

      final ahora = DateTime.now();

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
        '========================================',
      );

      try {
        // ==================================================
        // INTENTO ONLINE
        // ==================================================

        final solicitud =
            await ApiService.crearSolicitud(
          idUsuario: idUsuario,
          idCategoria:
              _idCategoriaPlomeria,
          clientOperationId:
              clientOperationId,
          descripcion: descripcion,
          latitud: 0,
          longitud: 0,
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
        // ==================================================
        // MODO OFFLINE
        // ==================================================

        debugPrint(
          'NO HAY CONEXIÓN O FALLÓ EL SERVIDOR.',
        );

        debugPrint(
          'Guardando solicitud local y operación offline...',
        );

        debugPrint(
          'Error: $e',
        );

        // --------------------------------------------------
        // 1. Guardamos inmediatamente la solicitud en
        //    ServiceRequests para que aparezca en pantalla.
        // --------------------------------------------------

        await _guardarSolicitudLocal(
          id: 'local-$clientOperationId',
          clientOperationId:
              clientOperationId,
          descripcion:
              descripcion,
          status:
              'pendiente',
          createdAt:
              ahora,
        );

        debugPrint(
          'SOLICITUD OFFLINE GUARDADA EN SQLITE',
        );

        // --------------------------------------------------
        // 2. Guardamos la operación en SyncQueue.
        // --------------------------------------------------

        await _guardarOperacionOffline(
          idUsuario: idUsuario,
          clientOperationId:
              clientOperationId,
          descripcion:
              descripcion,
          createdAt:
              ahora,
        );

        debugPrint(
          'OPERACIÓN OFFLINE GUARDADA EN SYNC_QUEUE',
        );

        if (!mounted) return;

        _mostrarMensaje(
          'Sin conexión. La solicitud quedó '
          'guardada localmente y será sincronizada '
          'cuando vuelva la conexión.',
        );

        _descripcionController.clear();

        await Future.delayed(
          const Duration(
            milliseconds: 800,
          ),
        );

        if (!mounted) return;

        // Regresamos a la lista.
        //
        // La pantalla anterior recibirá true y
        // volverá a cargar SQLite.
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
      'SOLICITUD GUARDADA EN SQLITE: $id',
    );
  }

  Future<void> _guardarOperacionOffline({
    required int idUsuario,
    required String clientOperationId,
    required String descripcion,
    required DateTime createdAt,
  }) async {
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
      'latitud': 0,
      'longitud': 0,
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
            createdAt,
        nextRetryAt:
            drift.Value(createdAt),
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

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
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
                'Si no hay conexión, la solicitud '
                'se guardará localmente y se '
                'sincronizará posteriormente.',
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
                      'Plomería',
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
                height: 24,
              ),

              SizedBox(
                width:
                    double.infinity,
                height: 52,
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
                        'duplicados durante la sincronización.',
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