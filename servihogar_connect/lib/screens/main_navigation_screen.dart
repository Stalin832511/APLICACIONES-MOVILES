import 'package:flutter/material.dart';

import '../database/app_database.dart';
import 'actividad_screen.dart';
import 'catalogo_servicios_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'solicitudes_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final AppDatabase database;

  const MainNavigationScreen({
    super.key,
    required this.database,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  int _activityRefreshToken = 0;
  late final List<Widget?> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        database: widget.database,
        onOpenRequests: () => _selectTab(1, refresh: true),
        onOpenActivity: () => _selectTab(2),
        onOpenCatalog: () => _selectTab(3),
        onOpenProfile: () => _selectTab(4),
      ),
      null,
      null,
      null,
      null,
    ];
  }

  void _selectTab(int index, {bool refresh = false}) {
    if (refresh && index == 1) {
      _screens[index] = MisSolicitudesScreen(database: widget.database);
    }
    if (index == 2 && _screens[index] != null) {
      _screens[index] = ActividadScreen(
        database: widget.database,
        refreshToken: ++_activityRefreshToken,
      );
    }
    if (_screens[index] == null) {
      _screens[index] = switch (index) {
        1 => MisSolicitudesScreen(database: widget.database),
        2 => ActividadScreen(
            database: widget.database,
            refreshToken: _activityRefreshToken,
          ),
        3 => CatalogoServiciosScreen(
            database: widget.database,
            onRequestCreated: () => _selectTab(1, refresh: true),
          ),
        4 => ProfileScreen(database: widget.database),
        _ => const SizedBox.shrink(),
      };
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            for (final screen in _screens) screen ?? const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Solicitudes',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Actividad',
          ),
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman_rounded),
            label: 'Servicios',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
