import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/solicitudes_screen.dart';

void main() {
  runApp(const ServiHogarConnectApp());
}

// Cambia este valor para cada captura: 1.0 (normal), 1.5, 2.0 (fuente ampliada)
// Antes de entregar el proyecto, vuelve este valor a 1.0.
const double _debugTextScale = 1.0;

class ServiHogarConnectApp extends StatelessWidget {
  const ServiHogarConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ServiHogar Connect',
      theme: AppTheme.light(),
      home: const MisSolicitudesScreen(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(_debugTextScale),
          ),
          child: child!,
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _cargando = false;
  Map<String, dynamic>? _respuesta;
  String? _error;

  Future<void> _consultarApi() async {
    setState(() {
      _cargando = true;
      _error = null;
      _respuesta = null;
    });

    try {
      final data = await ApiService.checkHealth();
      setState(() {
        _respuesta = data;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _consultarApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ServiHogar Connect')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Estado del backend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (_cargando) const CircularProgressIndicator(),
              if (!_cargando && _respuesta != null) ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 12),
                Text('✓ API conectada'),
                const SizedBox(height: 8),
                Text('${_respuesta!['message']}'),
                Text('Proyecto: ${_respuesta!['project']}'),
                Text('Versión: ${_respuesta!['version']}'),
              ],
              if (!_cargando && _error != null) ...[
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text('Error: $_error', textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cargando ? null : _consultarApi,
                child: const Text('Consultar API de nuevo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}