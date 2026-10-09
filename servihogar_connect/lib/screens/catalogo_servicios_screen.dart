import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/categoria.dart';
import '../services/catalog_service.dart';
import '../widgets/service_category_style.dart';
import 'detalle_servicio_screen.dart';

class CatalogoServiciosScreen extends StatefulWidget {
  final AppDatabase database;
  final VoidCallback? onRequestCreated;

  const CatalogoServiciosScreen({
    super.key,
    required this.database,
    this.onRequestCreated,
  });

  @override
  State<CatalogoServiciosScreen> createState() =>
      _CatalogoServiciosScreenState();
}

class _CatalogoServiciosScreenState extends State<CatalogoServiciosScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<CategoriaModel> _categories = [];
  bool _loading = true;
  bool _fromCache = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<CategoriaModel> get _filteredCategories {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _categories;
    return _categories.where((category) {
      return category.nombre.toLowerCase().contains(query) ||
          (category.descripcion?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _openDetails(CategoriaModel category) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DetalleServicioScreen(
          category: category,
          database: widget.database,
        ),
      ),
    );
    if (created == true && mounted) {
      final onRequestCreated = widget.onRequestCreated;
      if (onRequestCreated != null) {
        onRequestCreated();
      } else {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de servicios'),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadCategories,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _categories.isEmpty
                  ? _buildError(colors, textTheme)
                  : _buildCatalog(colors, textTheme),
        ),
      ),
    );
  }

  Widget _buildError(ColorScheme colors, TextTheme textTheme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        Icon(Icons.cloud_off_rounded, size: 52, color: colors.error),
        const SizedBox(height: 16),
        Text(
          'No se pudo cargar el catálogo',
          textAlign: TextAlign.center,
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        Center(
          child: FilledButton.icon(
            onPressed: _loadCategories,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ),
      ],
    );
  }

  Widget _buildCatalog(ColorScheme colors, TextTheme textTheme) {
    final categories = _filteredCategories;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text(
          'Encuentra ayuda para tu hogar',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Explora los servicios disponibles y elige el que necesitas.',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        if (_fromCache) ...[
          const SizedBox(height: 12),
          const _CatalogNotice(
            icon: Icons.offline_pin_rounded,
            message: 'Mostrando el catálogo guardado en este dispositivo.',
          ),
        ],
        const SizedBox(height: 18),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Buscar un servicio',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (categories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Text(
              _categories.isEmpty
                  ? 'No hay servicios disponibles por ahora.'
                  : 'No encontramos servicios para “$_query”.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          )
        else
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CategoryTile(
                category: category,
                onTap: () => _openDetails(category),
              ),
            ),
          ),
      ],
    );
  }
}

class _CatalogNotice extends StatelessWidget {
  final IconData icon;
  final String message;

  const _CatalogNotice({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoriaModel category;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = ServiceCategoryStyle.color(category.nombre);
    final description = category.descripcion?.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: 0.16),
          child: Icon(ServiceCategoryStyle.icon(category.nombre), color: accent),
        ),
        title: Text(
          category.nombre,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description?.isNotEmpty == true
                ? description!
                : 'Conoce este servicio y solicita atención.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
