import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../services/auth_service.dart';
import 'centro_ayuda_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppDatabase database;

  const ProfileScreen({
    super.key,
    required this.database,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// Resumen de actividad calculado con los datos locales (SQLite).
class _ProfileStats {
  final int total;
  final int pendientes;
  final int enCurso;
  final int completadas;
  final int porSincronizar;
  final List<int> semana;

  const _ProfileStats({
    required this.total,
    required this.pendientes,
    required this.enCurso,
    required this.completadas,
    required this.porSincronizar,
    required this.semana,
  });

  static const vacio = _ProfileStats(
    total: 0,
    pendientes: 0,
    enCurso: 0,
    completadas: 0,
    porSincronizar: 0,
    semana: [0, 0, 0, 0, 0, 0, 0],
  );
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ==========================================================
  // CONFIGURACIÓN VISUAL
  // ==========================================================

  /// Imagen opcional de portada para la cabecera del perfil.
  ///
  /// Copia la imagen en assets/images/, decláralo en pubspec.yaml
  /// (assets:) y escribe aquí la ruta, por ejemplo:
  /// 'assets/images/perfil_portada.jpg'. Si es null se usa el degradado.
  static const String? _coverImageAsset = null;

  static const Color _colorPendiente = Color(0xFFF59E0B);
  static const Color _colorEnCurso = Color(0xFF38BDF8);
  static const Color _colorCompletado = Color(0xFF22C55E);
  static const Color _colorTotal = Color(0xFFAA8BFF);

  // ==========================================================
  // ESTADO
  // ==========================================================

  String? _email;
  int? _userId;
  String? _role;
  _ProfileStats _stats = _ProfileStats.vacio;
  bool _cargando = true;
  bool _cerrandoSesion = false;

  @override
  void initState() {
    super.initState();
    _cargarInformacionUsuario();
  }

  Future<void> _cargarInformacionUsuario() async {
    final email = await AuthService.getUserEmail();
    final userId = await AuthService.getUserId();
    final role = await AuthService.getUserRole();
    final stats = await _cargarEstadisticas();

    if (!mounted) return;

    setState(() {
      _email = email;
      _userId = userId;
      _role = role;
      _stats = stats;
      _cargando = false;
    });
  }

  /// Calcula el resumen de actividad con la base local.
  /// Si falla, el perfil se muestra igual con el resumen en cero.
  Future<_ProfileStats> _cargarEstadisticas() async {
    try {
      final registros =
          await widget.database.serviceRequestDao.getAllRequests();
      final operaciones =
          await widget.database.syncQueueDao.getAllOperations();

      final porSincronizar = operaciones
          .where((operacion) => operacion.operationType == 'crear_solicitud')
          .length;

      var pendientes = 0;
      var enCurso = 0;
      var completadas = 0;

      final hoy = DateTime.now();
      final base = DateTime(hoy.year, hoy.month, hoy.day);
      final semana = List<int>.filled(7, 0);

      for (final registro in registros) {
        switch (_categoriaEstado(registro.status)) {
          case 0:
            pendientes++;
          case 1:
            enCurso++;
          default:
            completadas++;
        }

        final fecha = registro.createdAt;
        final dia = DateTime(fecha.year, fecha.month, fecha.day);
        final diferencia = base.difference(dia).inDays;
        if (diferencia >= 0 && diferencia < 7) {
          semana[6 - diferencia]++;
        }
      }

      return _ProfileStats(
        total: registros.length + porSincronizar,
        pendientes: pendientes + porSincronizar,
        enCurso: enCurso,
        completadas: completadas,
        porSincronizar: porSincronizar,
        semana: semana,
      );
    } catch (e) {
      debugPrint('No se pudo calcular el resumen del perfil: $e');
      return _ProfileStats.vacio;
    }
  }

  /// 0 = pendiente, 1 = en curso, 2 = completado.
  int _categoriaEstado(String estado) {
    switch (estado.toLowerCase().trim()) {
      case 'completado':
      case 'completada':
      case 'completed':
      case 'finalizado':
      case 'finalizada':
        return 2;
      case 'en camino':
      case 'encamino':
      case 'en_camino':
      case 'en proceso':
      case 'en_proceso':
      case 'enproceso':
        return 1;
      default:
        return 0;
    }
  }

  // ==========================================================
  // DATOS DERIVADOS PARA MOSTRAR
  // ==========================================================

  String get _baseNombre {
    final local = (_email ?? '').split('@').first;
    return local.replaceAll(RegExp(r'[._\-\d]+'), ' ').trim();
  }

  String get _nombreVisible {
    final base = _baseNombre;
    if (base.isEmpty) return 'Usuario de ServiHogar';
    return base
        .split(RegExp(r'\s+'))
        .map(
          (parte) => parte.isEmpty
              ? parte
              : parte[0].toUpperCase() + parte.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  String get _iniciales {
    final base = _baseNombre;
    if (base.isEmpty) return 'U';
    final partes = base.split(RegExp(r'\s+'));
    final primera = partes.first[0];
    final segunda = partes.length > 1 ? partes[1][0] : '';
    return (primera + segunda).toUpperCase();
  }

  String get _rolVisible {
    final rol = (_role ?? '').trim();
    if (rol.isEmpty) return 'Usuario';
    return rol[0].toUpperCase() + rol.substring(1).toLowerCase();
  }

  String _letraDia(DateTime fecha) {
    const letras = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return letras[fecha.weekday - 1];
  }

  // ==========================================================
  // CERRAR SESIÓN
  // ==========================================================

  Future<void> _mostrarConfirmacionCerrarSesion() async {
    if (_cerrandoSesion) return;

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.logout_rounded),
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Estás seguro de que deseas cerrar sesión?\n\n'
            'Se eliminará la sesión almacenada y también '
            'los datos locales de la aplicación.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await _cerrarSesion();
    }
  }

  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion) return;

    setState(() {
      _cerrandoSesion = true;
    });

    try {
      // ==========================================================
      // 1. LIMPIAR DATOS LOCALES DE SOLICITUDES
      // ==========================================================

      await widget.database.serviceRequestDao.deleteAllRequests();

      // ==========================================================
      // 2. LIMPIAR COLA DE SINCRONIZACIÓN
      // ==========================================================

      await widget.database.syncQueueDao.deleteAllOperations();

      // ==========================================================
      // 3. ELIMINAR SESIÓN SEGURA
      // ==========================================================

      await AuthService.logout();

      if (!mounted) return;

      // ==========================================================
      // 4. ELIMINAR TODA LA PILA DE NAVEGACIÓN
      // ==========================================================

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            database: widget.database,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cerrandoSesion = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo completar el cierre de sesión.',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        bottom: false,
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: _cargarInformacionUsuario,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    32,
                  ),
                  children: [
                    _buildProfileHeader(
                      theme,
                      colors,
                    ),
                    const SizedBox(height: 16),
                    _buildStatsGrid(colors),
                    const SizedBox(height: 14),
                    _buildEstadoChart(colors),
                    const SizedBox(height: 12),
                    _buildActividadChart(colors),
                    const SizedBox(height: 12),
                    _buildAccountCard(colors),
                    const SizedBox(height: 12),
                    _buildSecurityCard(colors),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Cuenta'),
                    const SizedBox(height: 10),
                    _buildProfileOption(
                      icon: Icons.person_outline_rounded,
                      title: 'Información personal',
                      subtitle: 'Consulta los datos de tu cuenta',
                      onTap: _mostrarInformacionPersonal,
                    ),
                    _buildProfileOption(
                      icon: Icons.location_on_outlined,
                      title: 'Direcciones',
                      subtitle: 'Administra tus direcciones',
                      enabled: false,
                      onTap: () {},
                    ),
                    _buildProfileOption(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notificaciones',
                      subtitle: 'Configura tus avisos',
                      enabled: false,
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Configuración'),
                    const SizedBox(height: 10),
                    _buildProfileOption(
                      icon: Icons.palette_outlined,
                      title: 'Apariencia',
                      subtitle: 'Personaliza la apariencia de la aplicación',
                      enabled: false,
                      onTap: () {},
                    ),
                    _buildProfileOption(
                      icon: Icons.security_outlined,
                      title: 'Seguridad',
                      subtitle: 'Sesión y almacenamiento seguro',
                      onTap: _mostrarSeguridad,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Soporte'),
                    const SizedBox(height: 10),
                    _buildProfileOption(
                      icon: Icons.help_outline_rounded,
                      title: 'Centro de ayuda',
                      subtitle:
                          'Guías para solicitudes, ubicación y sincronización',
                      onTap: _mostrarAyuda,
                    ),
                    const SizedBox(height: 28),
                    _buildLogoutButton(),
                    const SizedBox(height: 20),
                    Text(
                      'ServiHogar Connect · 1.0.0',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ==========================================================
  // CABECERA
  // ==========================================================

  Widget _buildProfileHeader(
    ThemeData theme,
    ColorScheme colors,
  ) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3B1F8F),
            Color(0xFF1B1140),
            Color(0xFF0F0B24),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          if (_coverImageAsset != null)
            Positioned.fill(
              child: Image.asset(
                _coverImageAsset!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF120A33).withValues(alpha: 0.55),
                    const Color(0xFF120A33).withValues(alpha: 0.90),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -50,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFB9A5FF), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1B1140),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _iniciales,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF22C55E),
                          border: Border.all(
                            color: const Color(0xFF1B1140),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _nombreVisible,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email ?? 'Usuario de ServiHogar',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC9C0E8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildHeaderChip(
                      Icons.workspace_premium_rounded,
                      _rolVisible,
                      const Color(0xFFD8CCFF),
                    ),
                    _buildHeaderChip(
                      Icons.verified_user_rounded,
                      'Sesión activa',
                      const Color(0xFF4ADE80),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RESUMEN Y GRÁFICAS
  // ==========================================================

  Widget _buildStatsGrid(ColorScheme colors) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpi(
                colors: colors,
                icon: Icons.assignment_rounded,
                label: 'Solicitudes',
                value: _stats.total,
                color: _colorTotal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpi(
                colors: colors,
                icon: Icons.verified_rounded,
                label: 'Completadas',
                value: _stats.completadas,
                color: _colorCompletado,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpi(
                colors: colors,
                icon: Icons.local_shipping_rounded,
                label: 'En curso',
                value: _stats.enCurso,
                color: _colorEnCurso,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpi(
                colors: colors,
                icon: Icons.hourglass_top_rounded,
                label: 'Pendientes',
                value: _stats.pendientes,
                color: _colorPendiente,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpi({
    required ColorScheme colors,
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
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
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
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
    required ColorScheme colors,
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
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
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: colors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
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

  /// Dona con la distribución de solicitudes por estado.
  Widget _buildEstadoChart(ColorScheme colors) {
    final total = _stats.pendientes + _stats.enCurso + _stats.completadas;

    return _buildSectionCard(
      colors: colors,
      icon: Icons.donut_large_rounded,
      title: 'Resumen de tus servicios',
      subtitle: 'Distribución por estado',
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, progress, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(120, 120),
                      painter: _DonutPainter(
                        values: [
                          _stats.pendientes.toDouble(),
                          _stats.enCurso.toDouble(),
                          _stats.completadas.toDouble(),
                        ],
                        colors: const [
                          _colorPendiente,
                          _colorEnCurso,
                          _colorCompletado,
                        ],
                        trackColor:
                            colors.outlineVariant.withValues(alpha: 0.5),
                        progress: progress,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'servicios',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
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
                _buildLegendRow(
                  colors,
                  _colorPendiente,
                  'Pendientes',
                  _stats.pendientes,
                  total,
                ),
                _buildLegendRow(
                  colors,
                  _colorEnCurso,
                  'En curso',
                  _stats.enCurso,
                  total,
                ),
                _buildLegendRow(
                  colors,
                  _colorCompletado,
                  'Completadas',
                  _stats.completadas,
                  total,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(
    ColorScheme colors,
    Color color,
    String label,
    int count,
    int total,
  ) {
    final porcentaje = total == 0 ? 0 : (count * 100 / total).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
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
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Barras con las solicitudes creadas en los últimos 7 días.
  Widget _buildActividadChart(ColorScheme colors) {
    final datos = _stats.semana;
    final maximo = datos.reduce(math.max);
    final hoy = DateTime.now();
    const alturaMaxima = 72.0;

    return _buildSectionCard(
      colors: colors,
      icon: Icons.bar_chart_rounded,
      title: 'Tu actividad reciente',
      subtitle: 'Solicitudes de los últimos 7 días',
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
                            gradient: datos[i] > 0
                                ? const LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Color(0xFF6D3FD6),
                                      Color(0xFFB9A5FF),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      colors.outlineVariant
                                          .withValues(alpha: 0.5),
                                      colors.outlineVariant
                                          .withValues(alpha: 0.5),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _letraDia(hoy.subtract(Duration(days: 6 - i))),
                      style: TextStyle(
                        color: i == datos.length - 1
                            ? colors.primary
                            : colors.onSurfaceVariant,
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

  // ==========================================================
  // DATOS DE LA CUENTA Y SEGURIDAD
  // ==========================================================

  Widget _buildAccountCard(ColorScheme colors) {
    return _buildSectionCard(
      colors: colors,
      icon: Icons.badge_rounded,
      title: 'Datos de la cuenta',
      subtitle: 'Información de tu sesión actual',
      child: Column(
        children: [
          _buildDataRow(
            colors,
            Icons.alternate_email_rounded,
            'Correo electrónico',
            _email ?? 'No disponible',
          ),
          _buildDataRow(
            colors,
            Icons.workspace_premium_rounded,
            'Tipo de cuenta',
            _role == null || _role!.trim().isEmpty
                ? 'No disponible'
                : _rolVisible,
          ),
          _buildDataRow(
            colors,
            Icons.fingerprint_rounded,
            'Identificador de usuario',
            _userId?.toString() ?? 'No disponible',
          ),
          _buildDataRow(
            colors,
            Icons.sync_rounded,
            'Sincronización',
            _stats.porSincronizar == 0
                ? 'Todo al día'
                : '${_stats.porSincronizar} solicitud(es) por enviar',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(
    ColorScheme colors,
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(ColorScheme colors) {
    return _buildSectionCard(
      colors: colors,
      icon: Icons.shield_rounded,
      title: 'Tu cuenta está protegida',
      subtitle: 'Seguridad y privacidad',
      child: Row(
        children: [
          Expanded(
            child: _buildSecurityBadge(
              colors,
              Icons.lock_rounded,
              'Sesión cifrada',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSecurityBadge(
              colors,
              Icons.password_rounded,
              'Sin contraseña local',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSecurityBadge(
              colors,
              Icons.cloud_sync_rounded,
              'Datos sincronizados',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadge(
    ColorScheme colors,
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF22C55E)),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // OPCIONES
  // ==========================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: Color(0xFF9A98A8),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.48,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: ListTile(
          enabled: enabled,
          onTap: enabled ? onTap : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: colors.primary,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(subtitle),
          ),
          trailing: enabled
              ? const Icon(
                  Icons.chevron_right_rounded,
                )
              : const Text(
                  'Próximamente',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _cerrandoSesion
            ? null
            : _mostrarConfirmacionCerrarSesion,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.error,
          side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _cerrandoSesion
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.logout_rounded,
              ),
        label: Text(
          _cerrandoSesion
              ? 'Cerrando sesión...'
              : 'Cerrar sesión',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DIÁLOGOS Y NAVEGACIÓN
  // ==========================================================

  Future<void> _mostrarInformacionPersonal() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.person_rounded),
          title: const Text(
            'Información personal',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Correo electrónico',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _email ?? 'No disponible',
              ),
              const SizedBox(height: 16),
              const Text(
                'Identificador de usuario',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _userId?.toString() ?? 'No disponible',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarSeguridad() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.shield_rounded),
          title: const Text(
            'Seguridad',
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.lock_outline_rounded,
                ),
                title: Text(
                  'Sesión protegida',
                ),
                subtitle: Text(
                  'El token de sesión se almacena mediante almacenamiento seguro.',
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.password_outlined,
                ),
                title: Text(
                  'Contraseña',
                ),
                subtitle: Text(
                  'La contraseña no se almacena localmente.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarAyuda() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CentroAyudaScreen(),
      ),
    );
  }
}

/// Pinta la gráfica de dona del resumen por estado.
class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color trackColor;
  final double progress;

  const _DonutPainter({
    required this.values,
    required this.colors,
    required this.trackColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 15.0;
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
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
        oldDelegate.colors != colors ||
        oldDelegate.trackColor != trackColor;
  }
}