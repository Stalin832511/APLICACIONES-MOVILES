import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'database/app_database.dart';
import 'screens/admin_dashboard.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/professional_dashboard.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ServiHogarConnectApp(),
  );
}

class ServiHogarConnectApp extends StatefulWidget {
  const ServiHogarConnectApp({
    super.key,
  });

  @override
  State<ServiHogarConnectApp> createState() =>
      _ServiHogarConnectAppState();
}

class _ServiHogarConnectAppState
    extends State<ServiHogarConnectApp> {
  // Una sola instancia de AppDatabase
  // para toda la aplicación.
  final AppDatabase _database = AppDatabase();

  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;

  bool _sincronizando = false;

  @override
  void initState() {
    super.initState();

    _configurarConectividad();
  }

  void _configurarConectividad() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(
      (resultados) {
        final hayConexion = resultados.any(
          (resultado) =>
              resultado != ConnectivityResult.none,
        );

        debugPrint(
          '========================================',
        );
        debugPrint(
          'CAMBIO DE CONECTIVIDAD',
        );
        debugPrint(
          'RESULTADO: $resultados',
        );
        debugPrint(
          'HAY CONEXIÓN: $hayConexion',
        );
        debugPrint(
          '========================================',
        );

        if (hayConexion) {
          _sincronizarPendientes();
        }
      },
    );

    _verificarConexionInicial();
  }

  Future<void> _verificarConexionInicial() async {
    try {
      final resultados =
          await Connectivity().checkConnectivity();

      final hayConexion = resultados.any(
        (resultado) =>
            resultado != ConnectivityResult.none,
      );

      debugPrint(
        '========================================',
      );
      debugPrint(
        'VERIFICACIÓN INICIAL DE CONECTIVIDAD',
      );
      debugPrint(
        'RESULTADO: $resultados',
      );
      debugPrint(
        'HAY CONEXIÓN: $hayConexion',
      );
      debugPrint(
        '========================================',
      );

      if (hayConexion) {
        await _sincronizarPendientes();
      }
    } catch (e) {
      debugPrint(
        'ERROR VERIFICANDO CONECTIVIDAD: $e',
      );
    }
  }

  Future<void> _sincronizarPendientes() async {
    if (_sincronizando) {
      debugPrint(
        'SYNC: ya existe una sincronización en curso.',
      );
      return;
    }

    _sincronizando = true;

    debugPrint(
      '========================================',
    );
    debugPrint(
      'INICIANDO SINCRONIZACIÓN AUTOMÁTICA',
    );
    debugPrint(
      '========================================',
    );

    try {
      final sesionActiva =
          await AuthService.hasActiveSession();

      if (!sesionActiva) {
        debugPrint(
          'SYNC: no existe una sesión activa.',
        );
        return;
      }

      final syncService = SyncService(_database);

      await syncService.processPendingOperations();
    } catch (e, stackTrace) {
      debugPrint(
        'ERROR EN SINCRONIZACIÓN AUTOMÁTICA: $e',
      );

      debugPrint(
        '$stackTrace',
      );
    } finally {
      _sincronizando = false;

      debugPrint(
        '========================================',
      );
      debugPrint(
        'SINCRONIZACIÓN AUTOMÁTICA FINALIZADA',
      );
      debugPrint(
        '========================================',
      );
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();

    // La base de datos se cierra solamente
    // cuando se destruye la aplicación.
    _database.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,

      // Tema centralizado de toda la aplicación.
      //
      // A partir de aquí las pantallas podrán utilizar
      // los mismos colores, tipografías, radios, botones,
      // campos y superficies.
      theme: AppTheme.dark(),

      home: SessionCheckScreen(
        database: _database,
      ),
    );
  }
}

class SessionCheckScreen extends StatefulWidget {
  final AppDatabase database;

  const SessionCheckScreen({
    super.key,
    required this.database,
  });

  @override
  State<SessionCheckScreen> createState() =>
      _SessionCheckScreenState();
}

class _SessionCheckScreenState
    extends State<SessionCheckScreen> {
  @override
  void initState() {
    super.initState();

    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    final sesionActiva =
        await AuthService.hasActiveSession();

    if (!mounted) return;

    if (sesionActiva) {
      final role = await AuthService.getUserRole();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _screenForRole(role),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            database: widget.database,
          ),
        ),
      );
    }
  }

  Widget _screenForRole(String? role) {
    final normalized = role?.trim().toLowerCase() ?? '';
    if (normalized.contains('admin')) {
      return AdminDashboard(database: widget.database);
    }
    if (normalized.contains('profesional') ||
        normalized.contains('professional')) {
      return ProfessionalDashboard(database: widget.database);
    }
    return MainNavigationScreen(database: widget.database);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}