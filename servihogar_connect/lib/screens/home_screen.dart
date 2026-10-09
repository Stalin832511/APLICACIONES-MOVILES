import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/categoria.dart';
import '../services/auth_service.dart';
import '../services/catalog_service.dart';
import '../widgets/service_category_style.dart';
import 'crear_solicitud_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.database,
    this.onOpenRequests,
    this.onOpenActivity,
    this.onOpenCatalog,
    this.onOpenProfile,
  });

  final AppDatabase database;
  final VoidCallback? onOpenRequests;
  final VoidCallback? onOpenActivity;
  final VoidCallback? onOpenCatalog;
  final VoidCallback? onOpenProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CategoriaModel> _categories = [];
  bool _loading = true;
  bool _fromCache = false;
  String? _error;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final email = await AuthService.getUserEmail();
    if (mounted) setState(() => _email = email);
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await CatalogService.loadCategories();
      if (!mounted) return;
      setState(() {
        _categories = result.categories;
        _fromCache = result.fromCache;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _createRequest({int? categoryId}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CrearSolicitudScreen(
          database: widget.database,
          initialCategoryId: categoryId,
        ),
      ),
    );
  }

  void _openRequests() {
    final callback = widget.onOpenRequests;
    if (callback != null) {
      callback();
    } else {
      _showNavigationUnavailable();
    }
  }

  void _openCatalog() {
    final callback = widget.onOpenCatalog;
    if (callback != null) {
      callback();
    } else {
      _showNavigationUnavailable();
    }
  }

  void _showNavigationUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Esta sección no está disponible.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final firstName = (_email ?? '').split('@').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ServiHogar'),
        actions: [
          IconButton(
            tooltip: 'Mi perfil',
            onPressed: widget.onOpenProfile,
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCategories,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            _buildLogoHeader(context),
            const SizedBox(height: 20),
            Text(
              firstName.isEmpty ? 'Hola, bienvenido' : 'Hola, $firstName',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '¿Qué necesitas resolver hoy?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            _buildRequestBanner(context),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Servicios para tu hogar',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _openCatalog,
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_fromCache)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Mostrando el catálogo guardado en este dispositivo.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            if (_loading && _categories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _categories.isEmpty)
              _buildLoadError(context)
            else if (_categories.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'No hay servicios disponibles por ahora.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 640 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _categories.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.28,
                    ),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return _CategoryCard(
                        category: category,
                        onTap: () => _createRequest(categoryId: category.id),
                      );
                    },
                  );
                },
              ),
            if (_error != null && _categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'No se pudo actualizar el catálogo. Se muestran los últimos '
                'servicios cargados.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.error,
                ),
              ),
            ],
            const SizedBox(height: 28),
            _buildShortcuts(context),
          ],
        ),
      ),
    );
  }

  /// Logo grande de bienvenida al abrir la app.
  ///
  /// Es el primer elemento del scroll: el usuario lo ve de inmediato
  /// al entrar y puede deslizar hacia abajo para ver el resto de Inicio.
  Widget _buildLogoHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 1.05,
          child: Image.asset(
            'assets/images/Logo1.jpeg',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestBanner(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: colors.primaryContainer,
      child: InkWell(
        onTap: () => _createRequest(),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                Icons.home_repair_service_rounded,
                size: 34,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solicita un servicio',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Cuéntanos qué necesitas y encuentra ayuda.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: colors.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcuts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos rápidos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Mis solicitudes'),
                subtitle: const Text('Consulta el estado de tus servicios'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _openRequests,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: const Text('Actividad'),
                subtitle: const Text('Revisa el resumen de tus solicitudes'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: widget.onOpenActivity ?? _openRequests,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadError(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(Icons.cloud_off_outlined, color: colors.error, size: 36),
            const SizedBox(height: 8),
            const Text(
              'No se pudo cargar el catálogo de servicios.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loading ? null : _loadCategories,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  final CategoriaModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ServiceCategoryStyle.color(category.nombre);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  ServiceCategoryStyle.icon(category.nombre),
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                category.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                (category.descripcion?.trim().isNotEmpty ?? false)
                    ? category.descripcion!
                    : 'Solicitar servicio',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}