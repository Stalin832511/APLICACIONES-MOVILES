import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import 'solicitudes_screen.dart';

/// ============================================================
/// COLORES PRINCIPALES DE SERVIHOGAR CONNECT
/// ============================================================

class HomeColors {
  HomeColors._();

  static const background =
      Color(0xFF09090F);

  static const surface =
      Color(0xFF12121B);

  static const surfaceLight =
      Color(0xFF1A1925);

  static const purple =
      Color(0xFF8B5CF6);

  static const purpleDark =
      Color(0xFF6D28D9);

  static const blue =
      Color(0xFF3B82F6);

  static const cyan =
      Color(0xFF14B8A6);

  static const orange =
      Color(0xFFF59E0B);

  static const green =
      Color(0xFF22C55E);

  static const white =
      Color(0xFFF8F7FF);

  static const gray =
      Color(0xFF9A98A8);

  static const border =
      Color(0xFF252431);
}

/// ============================================================
/// PANTALLA PRINCIPAL - INICIO
/// ============================================================

class HomeScreen extends StatefulWidget {
  final AppDatabase database;

  const HomeScreen({
    super.key,
    required this.database,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  late final AppDatabase _database;

  String _nombreUsuario = 'Cliente';

  bool _cargandoUsuario = true;

  @override
  void initState() {
    super.initState();

    _database = widget.database;

    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    try {
      final email =
          await AuthService.getUserEmail();

      if (!mounted) return;

      setState(() {
        _nombreUsuario =
            _obtenerNombre(email);
        _cargandoUsuario = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _nombreUsuario = 'Cliente';
        _cargandoUsuario = false;
      });
    }
  }

  String _obtenerNombre(String? email) {
    if (email == null ||
        email.trim().isEmpty) {
      return 'Cliente';
    }

    final usuario =
        email.split('@').first.trim();

    if (usuario.isEmpty) {
      return 'Cliente';
    }

    final palabras = usuario
        .replaceAll(
          RegExp(r'[._-]+'),
          ' ',
        )
        .split(' ')
        .where(
          (element) =>
              element.trim().isNotEmpty,
        )
        .toList();

    if (palabras.isEmpty) {
      return 'Cliente';
    }

    return palabras
        .map(
          (palabra) =>
              palabra[0].toUpperCase() +
              palabra
                  .substring(1)
                  .toLowerCase(),
        )
        .join(' ');
  }

  void _mostrarProximamente(
    String nombre,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration:
                    BoxDecoration(
                  color: HomeColors.purple
                      .withValues(
                    alpha: 0.18,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color:
                      HomeColors.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$nombre estará disponible próximamente.',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor:
              HomeColors.surfaceLight,
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
          duration:
              const Duration(
            seconds: 2,
          ),
        ),
      );
  }

  Future<void>
      _abrirMisSolicitudes() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MisSolicitudesScreen(
          database: _database,
        ),
      ),
    );
  }

  Future<void>
      _abrirNuevaSolicitud() async {
    await _abrirMisSolicitudes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          HomeColors.background,

      body: SafeArea(
        child: RefreshIndicator(
          color: HomeColors.purple,
          backgroundColor:
              HomeColors.surface,
          onRefresh: _cargarUsuario,
          child:
              SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildHeader(),

                const SizedBox(
                  height: 22,
                ),

                _buildWelcomeCard(),

                const SizedBox(
                  height: 28,
                ),

                _buildSectionTitle(),

                const SizedBox(
                  height: 14,
                ),

                _buildServicesGrid(),

                const SizedBox(
                  height: 26,
                ),

                _buildQuickAccessCard(),

                const SizedBox(
                  height: 18,
                ),

                const ApiStatusCard(),

                const SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar:
          _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'ServiHogar',
                style: TextStyle(
                  color:
                      HomeColors.white,
                  fontSize: 25,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Servicios para tu hogar',
                style: TextStyle(
                  color: HomeColors.gray
                      .withValues(
                    alpha: 0.95,
                  ),
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        _HeaderIconButton(
          icon:
              Icons.notifications_none_rounded,
          onTap: () {
            _mostrarProximamente(
              'Notificaciones',
            );
          },
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(24),
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF312E81),
            Color(0xFF6D28D9),
            Color(0xFF7C3AED),
          ],
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: HomeColors.purple
                .withValues(
              alpha: 0.20,
            ),
            blurRadius: 24,
            offset:
                const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -35,
            child: Container(
              width: 130,
              height: 130,
              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withValues(
                  alpha: 0.06,
                ),
                shape:
                    BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            right: 20,
            bottom: -55,
            child: Container(
              width: 100,
              height: 100,
              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withValues(
                  alpha: 0.04,
                ),
                shape:
                    BoxShape.circle,
              ),
            ),
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration:
                        BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.12,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        const Icon(
                      Icons.home_rounded,
                      color:
                          Colors.white,
                      size: 22,
                    ),
                  ),

                  const SizedBox(
                    width: 11,
                  ),

                  Expanded(
                    child: Text(
                      _cargandoUsuario
                          ? 'Hola 👋'
                          : 'Hola 👋 $_nombreUsuario',
                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              const Text(
                '¿Qué necesitas hoy?',
                style: TextStyle(
                  color:
                      Colors.white,
                  fontSize: 24,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'Encuentra servicios para tu hogar '
                'de forma sencilla y segura.',
                style: TextStyle(
                  color:
                      Colors.white70,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(
                height: 19,
              ),

              SizedBox(
                height: 45,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      _abrirNuevaSolicitud,
                  icon:
                      const Icon(
                    Icons.add_rounded,
                    size: 20,
                  ),
                  label:
                      const Text(
                    'Nueva solicitud',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.white,
                    foregroundColor:
                        HomeColors
                            .purpleDark,
                    elevation: 0,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 18,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return const Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Servicios',
          style: TextStyle(
            color:
                HomeColors.white,
            fontSize: 20,
            fontWeight:
                FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Elige el servicio que necesitas',
          style: TextStyle(
            color:
                HomeColors.gray,
            fontSize: 13,
            fontWeight:
                FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.18,
      children: [
        _ServiceCard(
          icon:
              Icons.bolt_rounded,
          title: 'Electricidad',
          subtitle:
              'Electricistas',
          color:
              const Color(0xFFA855F7),
          onTap: () {
            _mostrarProximamente(
              'Electricidad',
            );
          },
        ),

        _ServiceCard(
          icon:
              Icons.water_drop_outlined,
          title: 'Plomería',
          subtitle: 'Plomeros',
          color:
              HomeColors.blue,
          onTap: () {
            _abrirNuevaSolicitud();
          },
        ),

        _ServiceCard(
          icon:
              Icons.cleaning_services_outlined,
          title: 'Limpieza',
          subtitle:
              'Profesionales',
          color:
              HomeColors.cyan,
          onTap: () {
            _mostrarProximamente(
              'Limpieza',
            );
          },
        ),

        _ServiceCard(
          icon:
              Icons.handyman_outlined,
          title: 'General',
          subtitle:
              'Otros servicios',
          color:
              HomeColors.orange,
          onTap: () {
            _mostrarProximamente(
              'Servicios generales',
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap:
            _abrirMisSolicitudes,
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(17),
          decoration:
              BoxDecoration(
            color:
                HomeColors.surface,
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color:
                  HomeColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color:
                      HomeColors.purple
                          .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .list_alt_rounded,
                  color:
                      HomeColors.purple,
                  size: 25,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Mis Solicitudes',
                      style:
                          TextStyle(
                        color:
                            HomeColors
                                .white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Consulta y administra tus solicitudes',
                      style:
                          TextStyle(
                        color:
                            HomeColors
                                .gray,
                        fontSize: 11.5,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 34,
                height: 34,
                decoration:
                    BoxDecoration(
                  color:
                      HomeColors
                          .surfaceLight,
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  color:
                      HomeColors.gray,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration:
          const BoxDecoration(
        color:
            HomeColors.surface,
        border: Border(
          top: BorderSide(
            color:
                HomeColors.border,
            width: 0.7,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child:
            NavigationBar(
          height: 68,
          backgroundColor:
              HomeColors.surface,
          indicatorColor:
              HomeColors.purple
                  .withValues(
            alpha: 0.16,
          ),
          selectedIndex: 0,
          labelBehavior:
              NavigationDestinationLabelBehavior
                  .alwaysShow,
          onDestinationSelected:
              (index) {
            switch (index) {
              case 0:
                break;

              case 1:
                _abrirMisSolicitudes();
                break;

              case 2:
                _mostrarProximamente(
                  'Chat',
                );
                break;

              case 3:
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                      database: _database,
                    ),
                  ),
                );
                break;
            }
          },
          destinations:
              const [
            NavigationDestination(
              icon: Icon(
                Icons
                    .home_outlined,
                color:
                    HomeColors.gray,
              ),
              selectedIcon:
                  Icon(
                Icons
                    .home_rounded,
                color:
                    HomeColors
                        .purple,
              ),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(
                Icons
                    .receipt_long_outlined,
                color:
                    HomeColors.gray,
              ),
              selectedIcon:
                  Icon(
                Icons
                    .receipt_long_rounded,
                color:
                    HomeColors
                        .purple,
              ),
              label: 'Solicitudes',
            ),
            NavigationDestination(
              icon: Icon(
                Icons
                    .chat_bubble_outline_rounded,
                color:
                    HomeColors.gray,
              ),
              selectedIcon:
                  Icon(
                Icons
                    .chat_bubble_rounded,
                color:
                    HomeColors
                        .purple,
              ),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(
                Icons
                    .person_outline_rounded,
                color:
                    HomeColors.gray,
              ),
              selectedIcon:
                  Icon(
                Icons
                    .person_rounded,
                color:
                    HomeColors
                        .purple,
              ),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// BOTÓN DEL ENCABEZADO
/// ============================================================

class _HeaderIconButton
    extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(14),
        child: Container(
          width: 45,
          height: 45,
          decoration:
              BoxDecoration(
            color:
                HomeColors.surfaceLight,
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color:
                  HomeColors.border,
            ),
          ),
          child: Icon(
            icon,
            color:
                HomeColors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// TARJETA DE SERVICIO
/// ============================================================

class _ServiceCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(20),
        child: Container(
          padding:
              const EdgeInsets.all(16),
          decoration:
              BoxDecoration(
            color:
                HomeColors.surface,
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color:
                  HomeColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration:
                    BoxDecoration(
                  color:
                      color.withValues(
                    alpha: 0.13,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),

              const Spacer(),

              Text(
                title,
                style:
                    const TextStyle(
                  color:
                      HomeColors.white,
                  fontSize: 14.5,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                subtitle,
                style:
                    const TextStyle(
                  color:
                      HomeColors.gray,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// ESTADO DE LA API
/// ============================================================

class ApiStatusCard
    extends StatefulWidget {
  const ApiStatusCard({
    super.key,
  });

  @override
  State<ApiStatusCard> createState() =>
      _ApiStatusCardState();
}

class _ApiStatusCardState
    extends State<ApiStatusCard> {
  bool _loading = true;

  bool _connected = false;

  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();

    _checkApi();
  }

  Future<void> _checkApi() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final result =
          await ApiService.checkHealth();

      if (!mounted) return;

      setState(() {
        _data = result;
        _connected = true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _connected = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _connected
        ? HomeColors.green
        : const Color(0xFFEF4444);

    return Container(
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color:
            HomeColors.surface,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
              HomeColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration:
                BoxDecoration(
              color:
                  color.withValues(
                alpha: 0.12,
              ),
              shape:
                  BoxShape.circle,
            ),
            child: Icon(
              _connected
                  ? Icons
                      .cloud_done_outlined
                  : Icons
                      .cloud_off_outlined,
              color: color,
              size: 22,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'Estado del sistema',
                  style:
                      TextStyle(
                    color:
                        HomeColors
                            .white,
                    fontSize: 13.5,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                if (_loading)
                  const Text(
                    'Comprobando conexión...',
                    style:
                        TextStyle(
                      color:
                          HomeColors
                              .gray,
                      fontSize: 11,
                    ),
                  )
                else
                  Text(
                    _connected
                        ? 'API conectada correctamente'
                        : 'API no disponible',
                    style:
                        TextStyle(
                      color: _connected
                          ? HomeColors
                              .green
                          : const Color(
                              0xFFEF4444,
                            ),
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                if (_connected &&
                    _data != null)
                  Text(
                    '${_data!['project'] ?? 'ServiHogar Connect'}',
                    style:
                        const TextStyle(
                      color:
                          HomeColors
                              .gray,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Actualizar',
            onPressed:
                _loading
                    ? null
                    : _checkApi,
            icon:
                const Icon(
              Icons
                  .refresh_rounded,
              color:
                  HomeColors
                      .purple,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}