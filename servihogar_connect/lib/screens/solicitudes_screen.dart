import 'package:flutter/material.dart';
import '../models/solicitud.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/async_state_view.dart';
import '../widgets/service_request_card.dart';

/// Pantalla real: "Mis Solicitudes"
/// Endpoint asociado: GET /api/Solicitudes
///
/// Ensamblada EXCLUSIVAMENTE con componentes del catálogo:
/// AsyncStateView + ServiceRequestCard (que a su vez compone StatusBadge).
class MisSolicitudesScreen extends StatefulWidget {
  const MisSolicitudesScreen({super.key});

  @override
  State<MisSolicitudesScreen> createState() => _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends State<MisSolicitudesScreen> {
  LoadStatus _status = LoadStatus.cargando;
  List<SolicitudModel> _solicitudes = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() {
      _status = LoadStatus.cargando;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.fetchSolicitudes();
      setState(() {
        _solicitudes = data;
        _status = data.isEmpty ? LoadStatus.vacio : LoadStatus.listo;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _status = LoadStatus.error;
      });
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Solicitudes')),
      body: RefreshIndicator(
        onRefresh: _cargarSolicitudes,
        child: AsyncStateView<List<SolicitudModel>>(
          status: _status,
          data: _solicitudes,
          errorMessage: _errorMessage,
          emptyMessage: 'Aún no tienes solicitudes registradas',
          onRetry: _cargarSolicitudes,
          builder: (context, solicitudes) => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: solicitudes.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final s = solicitudes[index];
              return ServiceRequestCard(
                titulo: s.descripcion,
                subtitulo: [
                  if (s.categoriaNombre != null) s.categoriaNombre!,
                  if (s.usuarioNombre != null) s.usuarioNombre!,
                ].join(' · '),
                fecha: _formatearFecha(s.fechaCreacion),
                status: s.status,
                onTap: () {
                  // La tarjeta delega la acción; esta pantalla decide
                  // qué hacer (aquí, un ejemplo simple con SnackBar).
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Solicitud #${s.id}')),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}