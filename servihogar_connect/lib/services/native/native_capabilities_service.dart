import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

enum NativePermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unavailable,
}

class CameraResult {
  final NativePermissionState permissionState;
  final XFile? image;
  final String? message;

  const CameraResult({
    required this.permissionState,
    this.image,
    this.message,
  });

  bool get success =>
      permissionState == NativePermissionState.granted &&
      image != null;
}

class LocationResult {
  final NativePermissionState permissionState;
  final Position? position;
  final String? message;
  final bool locationServiceDisabled;

  const LocationResult({
    required this.permissionState,
    this.position,
    this.message,
    this.locationServiceDisabled = false,
  });

  bool get success =>
      permissionState == NativePermissionState.granted &&
      position != null;
}

class NativeCapabilitiesService {
  NativeCapabilitiesService._();

  static final ImagePicker _imagePicker = ImagePicker();

  // ============================================================
  // CÁMARA
  // ============================================================

  static Future<CameraResult> takePhoto() async {
    final permission = await Permission.camera.request();

    switch (permission) {
      case PermissionStatus.granted:
        break;

      case PermissionStatus.denied:
        return const CameraResult(
          permissionState: NativePermissionState.denied,
          message:
              'El permiso de cámara fue denegado. '
              'Puedes volver a solicitarlo cuando lo necesites.',
        );

      case PermissionStatus.permanentlyDenied:
        return const CameraResult(
          permissionState:
              NativePermissionState.permanentlyDenied,
          message:
              'El permiso de cámara está bloqueado. '
              'Debes habilitarlo desde los ajustes de la aplicación.',
        );

      case PermissionStatus.restricted:
        return const CameraResult(
          permissionState: NativePermissionState.restricted,
          message:
              'El acceso a la cámara está restringido '
              'por el sistema.',
        );

      case PermissionStatus.limited:
        // En cámara no necesitamos un acceso limitado.
        break;

      case PermissionStatus.provisional:
        break;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null) {
        return const CameraResult(
          permissionState: NativePermissionState.granted,
          message: 'No se tomó ninguna fotografía.',
        );
      }

      return CameraResult(
        permissionState: NativePermissionState.granted,
        image: image,
      );
    } catch (e) {
      return CameraResult(
        permissionState: NativePermissionState.unavailable,
        message:
            'No fue posible abrir la cámara: $e',
      );
    }
  }

  // ============================================================
  // ESTADO DE CÁMARA
  // ============================================================

  static Future<NativePermissionState> cameraPermissionState() async {
    final status = await Permission.camera.status;

    switch (status) {
      case PermissionStatus.granted:
        return NativePermissionState.granted;

      case PermissionStatus.denied:
        return NativePermissionState.denied;

      case PermissionStatus.permanentlyDenied:
        return NativePermissionState.permanentlyDenied;

      case PermissionStatus.restricted:
        return NativePermissionState.restricted;

      case PermissionStatus.limited:
        return NativePermissionState.granted;

      case PermissionStatus.provisional:
        return NativePermissionState.granted;
    }
  }

  // ============================================================
  // UBICACIÓN
  // ============================================================

  static Future<LocationResult> getCurrentLocation() async {
    final permission =
        await Permission.locationWhenInUse.request();

    switch (permission) {
      case PermissionStatus.granted:
        break;

      case PermissionStatus.denied:
        return const LocationResult(
          permissionState: NativePermissionState.denied,
          message:
              'El permiso de ubicación fue denegado. '
              'Puedes volver a solicitarlo cuando lo necesites.',
        );

      case PermissionStatus.permanentlyDenied:
        return const LocationResult(
          permissionState:
              NativePermissionState.permanentlyDenied,
          message:
              'El permiso de ubicación está bloqueado. '
              'Debes habilitarlo desde los ajustes de la aplicación.',
        );

      case PermissionStatus.restricted:
        return const LocationResult(
          permissionState: NativePermissionState.restricted,
          message:
              'El acceso a la ubicación está restringido '
              'por el sistema.',
        );

      case PermissionStatus.limited:
        return const LocationResult(
          permissionState: NativePermissionState.granted,
          message:
              'La ubicación tiene acceso limitado.',
        );

      case PermissionStatus.provisional:
        break;
    }

    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return const LocationResult(
        permissionState: NativePermissionState.granted,
        locationServiceDisabled: true,
        message:
            'El permiso fue concedido, pero el GPS del teléfono '
            'está desactivado.',
      );
    }

    try {
      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      return LocationResult(
        permissionState: NativePermissionState.granted,
        position: position,
      );
    } catch (e) {
      return LocationResult(
        permissionState: NativePermissionState.unavailable,
        message:
            'No fue posible obtener la ubicación: $e',
      );
    }
  }

  // ============================================================
  // ESTADO DE UBICACIÓN
  // ============================================================

  static Future<NativePermissionState>
      locationPermissionState() async {
    final status =
        await Permission.locationWhenInUse.status;

    switch (status) {
      case PermissionStatus.granted:
        return NativePermissionState.granted;

      case PermissionStatus.denied:
        return NativePermissionState.denied;

      case PermissionStatus.permanentlyDenied:
        return NativePermissionState.permanentlyDenied;

      case PermissionStatus.restricted:
        return NativePermissionState.restricted;

      case PermissionStatus.limited:
        return NativePermissionState.granted;

      case PermissionStatus.provisional:
        return NativePermissionState.granted;
    }
  }

// ============================================================
// AJUSTES DE LA APLICACIÓN
// ============================================================

  static Future<bool> openAppSettingsPage() {
    return openAppSettings();
  }

  // ============================================================
  // AJUSTES DE UBICACIÓN DEL SISTEMA
  // ============================================================

  static Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }
}