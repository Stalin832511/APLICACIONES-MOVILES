import 'package:flutter/material.dart';

import '../../models/categoria.dart';
import '../../models/solicitud.dart';
import '../../screens/detalle_solicitud_screen.dart';
import '../../services/api_service.dart';
import '../../services/catalog_service.dart';
import '../../widgets/status_badge.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  static const _pageSize = 20;
  static const _statuses = <({String label, String? value})>[
    (label: 'Todas', value: null),
    (label: 'Pendientes', value: 'Pendiente'),
    (label: 'En proceso', value: 'En proceso'),
    (label: 'Completadas', value: 'Completada'),
    (label: 'Canceladas', value: 'Cancelada'),
  ];

  SolicitudesPage? _page;
  List<CategoriaModel> _categories = [];
  int _currentPage = 1;
  int? _selectedCategoryId;
  String? _selectedStatus;
  String? _error;
  String? _categoryError;
  bool _loading = true;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadRequests();
  }

  Future<void> _loadCategories() async {
    try {
      final result = await CatalogService.loadCategories();
      if (!mounted) return;
      setState(() {
        _categories = result.categories;
        _categoryError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _categoryError =
            'No se pudieron cargar las categorías para filtrar: $error';
      });
    }
  }

  Future<void> _loadRequests({int page = 1}) async {
    final generation = ++_requestGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService.fetchSolicitudesPaginadas(
        page: page,
        pageSize: _pageSize,
        estado: _selectedStatus,
        idCategoria: _selectedCategoryId,
      );
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _page = result;
        _currentPage = result.page;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted && generation == _requestGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _setStatus(String? status) async {
    if (_selectedStatus == status) return;
    setState(() => _selectedStatus = status);
    await _loadRequests();
  }

  Future<void> _setCategory(int? idCategoria) async {
    if (_selectedCategoryId == idCategoria) return;
    setState(() => _selectedCategoryId = idCategoria);
    await _loadRequests();
  }

  Future<void> _openRequest(SolicitudModel request) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DetalleSolicitudScreen(solicitud: request),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _statusLabel(SolicitudModel request) {
    final status =
        request.estadoOriginal?.trim().toLowerCase().replaceAll('_', ' ');
    if (status == null || status.isEmpty) {
      return switch (request.status) {
        RequestStatus.pendiente => 'Pendiente',
        RequestStatus.enCamino => 'En camino',
        RequestStatus.enProceso => 'En proceso',
        RequestStatus.completado => 'Completada',
      };
    }
    return switch (status) {
      'publicada' => 'Publicada',
      'pendiente' => 'Pendiente',
      'asignada' => 'Asignada',
      'en proceso' => 'En proceso',
      'en camino' => 'En camino',
      'completada' || 'completado' => 'Completada',
      'cancelada' || 'cancelado' => 'Cancelada',
      _ => '${status[0].toUpperCase()}${status.substring(1)}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requests = _page?.items ?? const <SolicitudModel>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes del sistema'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : () => _loadRequests(page: _currentPage),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadRequests(page: 1),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text(
              'Supervisa y revisa las solicitudes de servicio de la plataforma.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _statusFilters(),
            const SizedBox(height: 12),
            _categoryFilter(),
            if (_categoryError != null) ...[
              const SizedBox(height: 8),
              Text(
                _categoryError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (_loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_error != null) _errorCard(),
            if (!_loading && _error == null && requests.isEmpty)
              _emptyState(),
            for (final request in requests) _requestCard(request),
            if ((_page?.totalPages ?? 0) > 1) _pagination(),
          ],
        ),
      ),
    );
  }

  Widget _statusFilters() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final status in _statuses)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(status.label),
                  selected: _selectedStatus == status.value,
                  onSelected: _loading ? null : (_) => _setStatus(status.value),
                ),
              ),
          ],
        ),
      );

  Widget _categoryFilter() => InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Categoría',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.category_outlined),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            isExpanded: true,
            value: _selectedCategoryId,
            onChanged: _loading ? null : _setCategory,
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Todas las categorías'),
              ),
              for (final category in _categories)
                DropdownMenuItem<int?>(
                  value: category.id,
                  child: Text(category.nombre),
                ),
            ],
          ),
        ),
      );

  Widget _requestCard(SolicitudModel request) {
    final theme = Theme.of(context);
    final status = _statusLabel(request);
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openRequest(request),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.categoriaNombre ?? 'Servicio',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _statusChip(status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.descripcion,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _metadata(
                    Icons.numbers_rounded,
                    'Solicitud #${request.id}',
                  ),
                  if (request.usuarioNombre?.isNotEmpty == true)
                    _metadata(
                      Icons.person_outline_rounded,
                      request.usuarioNombre!,
                    ),
                  _metadata(
                    Icons.schedule_outlined,
                    _formatDate(request.fechaCreacion),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openRequest(request),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Revisar solicitud'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metadata(IconData icon, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 5),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      );

  Widget _statusChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      );

  Widget _pagination() {
    final totalPages = _page?.totalPages ?? 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Página anterior',
            onPressed: _loading || _currentPage <= 1
                ? null
                : () => _loadRequests(page: _currentPage - 1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text('Página $_currentPage de $totalPages'),
          IconButton(
            tooltip: 'Página siguiente',
            onPressed: _loading || _currentPage >= totalPages
                ? null
                : () => _loadRequests(page: _currentPage + 1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _loading ? null : () => _loadRequests(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay solicitudes con estos filtros.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
}
