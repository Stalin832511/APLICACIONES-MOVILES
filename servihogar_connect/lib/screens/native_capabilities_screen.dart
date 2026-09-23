import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/native/native_capabilities_service.dart';

class NativeCapabilitiesScreen extends StatefulWidget {
  const NativeCapabilitiesScreen({
    super.key,
  });

  @override
  State<NativeCapabilitiesScreen> createState() =>
      _NativeCapabilitiesScreenState();
}

class _NativeCapabilitiesScreenState
    extends State<NativeCapabilitiesScreen> {
  XFile? _photo;
  PositionData? _location;

  NativePermissionState _cameraState =
      NativePermissionState.denied;

  NativePermissionState _locationState =
      NativePermissionState.denied;

  bool _cameraLoading = false;
  bool _locationLoading = false;

  String? _cameraMessage;
  String? _locationMessage;

  // ============================================================
  // CÁMARA
  // ============================================================

  Future<void> _takePhoto() async {
    if (_cameraLoading) return;

    setState(() {
      _cameraLoading = true;
      _cameraMessage = null;
    });

    final result =
        await NativeCapabilitiesService.takePhoto();

    if (!mounted) return;

    setState(() {
      _cameraLoading = false;
      _cameraState = result.permissionState;
      _photo = result.image;
      _cameraMessage = result.message;
    });

    if (result.permissionState ==
        NativePermissionState.permanentlyDenied) {
      await _showSettingsDialog(
        title: 'Cámara bloqueada',
        message:
            'El permiso de cámara está bloqueado. '
            'Abre los ajustes de la aplicación para '
            'habilitarlo.',
      );
    }
  }

  // ============================================================
  // UBICACIÓN
  // ============================================================

  Future<void> _getLocation() async {
    if (_locationLoading) return;

    setState(() {
      _locationLoading = true;
      _locationMessage = null;
    });

    final result =
        await NativeCapabilitiesService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      _locationLoading = false;
      _locationState = result.permissionState;
      _locationMessage = result.message;

      if (result.position != null) {
        _location = PositionData(
          latitude: result.position!.latitude,
          longitude: result.position!.longitude,
          accuracy: result.position!.accuracy,
        );
      }
    });

    if (result.locationServiceDisabled) {
      await _showLocationSettingsDialog();
      return;
    }

    if (result.permissionState ==
        NativePermissionState.permanentlyDenied) {
      await _showSettingsDialog(
        title: 'Ubicación bloqueada',
        message:
            'El permiso de ubicación está bloqueado. '
            'Abre los ajustes de la aplicación para '
            'habilitarlo.',
      );
    }
  }

  // ============================================================
  // DIÁLOGO DE AJUSTES
  // ============================================================

  Future<void> _showSettingsDialog({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();

                await NativeCapabilitiesService
                    .openAppSettingsPage();
              },
              child: const Text('Abrir ajustes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLocationSettingsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('GPS desactivado'),
          content: const Text(
            'El permiso de ubicación está concedido, '
            'pero el servicio de ubicación del teléfono '
            'está desactivado.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();

                await NativeCapabilitiesService
                    .openLocationSettings();
              },
              child: const Text('Abrir ubicación'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // TEXTO DE PERMISO
  // ============================================================

  String _permissionText(
    NativePermissionState state,
  ) {
    switch (state) {
      case NativePermissionState.granted:
        return 'Concedido';

      case NativePermissionState.denied:
        return 'Denegado';

      case NativePermissionState.permanentlyDenied:
        return 'Denegado permanentemente';

      case NativePermissionState.restricted:
        return 'Restringido';

      case NativePermissionState.unavailable:
        return 'No disponible';
    }
  }

  Color _permissionColor(
    NativePermissionState state,
  ) {
    switch (state) {
      case NativePermissionState.granted:
        return Colors.green;

      case NativePermissionState.denied:
        return Colors.orange;

      case NativePermissionState.permanentlyDenied:
        return Colors.red;

      case NativePermissionState.restricted:
        return Colors.deepOrange;

      case NativePermissionState.unavailable:
        return Colors.grey;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Funciones del dispositivo',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Semana 14',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Prueba de capacidades nativas de '
            'ServiHogar Connect.',
          ),

          const SizedBox(height: 24),

          // ======================================================
          // CÁMARA
          // ======================================================

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Cámara',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Permite tomar una fotografía relacionada '
                    'con el servicio solicitado.',
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Text(
                        'Estado: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _permissionText(_cameraState),
                        style: TextStyle(
                          color: _permissionColor(
                            _cameraState,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  if (_photo != null) ...[
                    const SizedBox(height: 16),

                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(12),
                      child: Image.file(
                        File(_photo!.path),
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],

                  if (_cameraMessage != null) ...[
                    const SizedBox(height: 12),

                    Text(
                      _cameraMessage!,
                      style: const TextStyle(
                        color: Colors.orange,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _cameraLoading
                          ? null
                          : _takePhoto,
                      icon: _cameraLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                            ),
                      label: Text(
                        _cameraLoading
                            ? 'Abriendo cámara...'
                            : 'Tomar fotografía',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // UBICACIÓN
          // ======================================================

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ubicación GPS',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Obtiene la ubicación mientras el usuario '
                    'está utilizando la aplicación.',
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Text(
                        'Estado: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _permissionText(
                          _locationState,
                        ),
                        style: TextStyle(
                          color: _permissionColor(
                            _locationState,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  if (_location != null) ...[
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Latitud: '
                            '${_location!.latitude.toStringAsFixed(6)}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Longitud: '
                            '${_location!.longitude.toStringAsFixed(6)}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Precisión: '
                            '${_location!.accuracy.toStringAsFixed(1)} m',
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_locationMessage != null) ...[
                    const SizedBox(height: 12),

                    Text(
                      _locationMessage!,
                      style: const TextStyle(
                        color: Colors.orange,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _locationLoading
                          ? null
                          : _getLocation,
                      icon: _locationLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.my_location,
                            ),
                      label: Text(
                        _locationLoading
                            ? 'Obteniendo ubicación...'
                            : 'Obtener ubicación',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.security_outlined,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Los permisos se solicitan únicamente '
                      'cuando el usuario utiliza la función '
                      'correspondiente. La aplicación no solicita '
                      'cámara ni ubicación al iniciar.',
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
}

class PositionData {
  final double latitude;
  final double longitude;
  final double accuracy;

  const PositionData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });
}