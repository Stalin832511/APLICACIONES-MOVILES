import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../services/auth_service.dart';
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

class _ProfileScreenState extends State<ProfileScreen> {
  String? _email;
  int? _userId;
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

    if (!mounted) return;

    setState(() {
      _email = email;
      _userId = userId;
      _cargando = false;
    });
  }

  Future<void> _mostrarConfirmacionCerrarSesion() async {
    if (_cerrandoSesion) return;

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
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
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  32,
                ),
                children: [
                  _buildProfileHeader(
                    theme,
                    colors,
                  ),
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
                    title: 'Ayuda',
                    subtitle: 'Información y soporte de la aplicación',
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
    );
  }

  Widget _buildProfileHeader(
    ThemeData theme,
    ColorScheme colors,
  ) {
    final email = _email ?? 'Usuario de ServiHogar';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.outlineVariant.withValues(
            alpha: 0.55,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFF6366F1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi cuenta',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
        child: ListTile(
          enabled: enabled,
          onTap: enabled ? onTap : null,
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
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _cerrandoSesion
            ? null
            : _mostrarConfirmacionCerrarSesion,
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

  Future<void> _mostrarInformacionPersonal() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Ayuda',
          ),
          content: const Text(
            'ServiHogar Connect permite consultar y gestionar '
            'solicitudes de servicios para el hogar.\n\n'
            'La aplicación también cuenta con almacenamiento '
            'local para permitir el funcionamiento sin conexión '
            'y una cola de sincronización para operaciones pendientes.',
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
}