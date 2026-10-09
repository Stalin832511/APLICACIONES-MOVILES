import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../features/chat/chat_solicitud_screen.dart';
import '../models/marketplace_models.dart';
import '../services/auth_service.dart';
import '../services/marketplace_api_service.dart';
import 'login_screen.dart';

class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({
    super.key,
    required this.database,
    this.api,
  });

  final AppDatabase database;
  final MarketplaceApiService? api;

  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  late final MarketplaceApiService _api =
      widget.api ?? MarketplaceApiService();
  ProfessionalRequestsPage? _result;
  List<ProfessionalRequest>? _assigned;
  bool _loading = true;
  bool _assignedLoading = true;
  bool _submitting = false;
  String? _error;
  String? _assignedError;
  int _page = 1;
  int _tab = 0;
  final Set<int> _updatingRequests = {};

  @override
  void initState() {
    super.initState();
    _load();
    _loadAssigned();
  }

  Future<void> _loadAssigned() async {
    setState(() {
      _assignedLoading = true;
      _assignedError = null;
    });
    try {
      final assigned = await _api.getProfessionalAssigned();
      if (mounted) setState(() => _assigned = assigned);
    } catch (error) {
      if (mounted) {
        setState(() => _assignedError = marketplaceErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _assignedLoading = false);
    }
  }

  Future<void> _advanceAssignment(ProfessionalRequest request) async {
    final current = _normalizedStatus(request.estado);
    final nextStatus = current == 'asignada'
        ? 'en proceso'
        : current == 'en proceso'
            ? 'completada'
            : null;
    if (nextStatus == null) return;
    setState(() => _updatingRequests.add(request.idSolicitud));
    try {
      await _api.updateRequestStatus(
        requestId: request.idSolicitud,
        status: nextStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nextStatus == 'completada'
              ? 'Trabajo marcado como completado.'
              : 'Trabajo marcado en proceso.'),
        ),
      );
      await _loadAssigned();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(marketplaceErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingRequests.remove(request.idSolicitud));
      }
    }
  }

  String _normalizedStatus(String? status) =>
      status?.trim().toLowerCase().replaceAll('_', ' ') ?? '';

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          'Se cerrará tu sesión y se eliminarán las solicitudes guardadas '
          'en este dispositivo y la cola de sincronización.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.database.serviceRequestDao.deleteAllRequests();
      await widget.database.syncQueueDao.deleteAllOperations();
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LoginScreen(database: widget.database),
        ),
        (_) => false,
      );
    } catch (error) {
      debugPrint('No se pudo cerrar la sesión profesional: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo completar el cierre de sesión.')),
      );
    }
  }

  Future<void> _load({int? page}) async {
    if (page != null) _page = page;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result =
          await _api.getProfessionalRequests(page: _page, pageSize: 20);
      if (!mounted) return;
      setState(() {
        _result = result;
        _page = result.page;
      });
    } catch (error) {
      if (mounted) setState(() => _error = marketplaceErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendQuote(ProfessionalRequest request) async {
    final formKey = GlobalKey<FormState>();
    final priceController = TextEditingController();
    final timeController = TextEditingController();
    final quote = await showDialog<({double price, String time})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cotizar solicitud #${request.idSolicitud}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio ofertado',
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  final price =
                      double.tryParse((value ?? '').trim().replaceAll(',', '.'));
                  if (price == null || !price.isFinite || price <= 0) {
                    return 'Ingresa un precio mayor que cero.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: timeController,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Tiempo estimado',
                  hintText: 'Ej.: 2 horas',
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Indica el tiempo estimado.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                dialogContext,
                (
                  price: double.parse(
                    priceController.text.trim().replaceAll(',', '.'),
                  ),
                  time: timeController.text.trim(),
                ),
              );
            },
            child: const Text('Enviar oferta'),
          ),
        ],
      ),
    );
    priceController.dispose();
    timeController.dispose();
    if (quote == null || !mounted) return;
    setState(() => _submitting = true);
    try {
      await _api.submitQuote(
        requestId: request.idSolicitud,
        price: quote.price,
        estimatedTime: quote.time,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu oferta fue enviada al cliente.')),
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(marketplaceErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Oportunidades' : 'Mis trabajos'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading || _assignedLoading
                ? null
                : () => _tab == 0 ? _load() : _loadAssigned(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _tab == 0
          ? _opportunitiesBody(theme)
          : _assignedBody(theme),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Oportunidades',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Mis trabajos',
          ),
        ],
      ),
    );
  }

  Widget _opportunitiesBody(ThemeData theme) =>
      _loading && _result == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _result == null
              ? _loadError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Solicitudes cercanas a tu experiencia',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_result?.totalCount ?? 0} solicitudes disponibles',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        _inlineError(_error!),
                      ],
                      const SizedBox(height: 12),
                      if (_loading)
                        const LinearProgressIndicator(),
                      if ((_result?.items ?? []).isEmpty && !_loading)
                        _emptyState()
                      else
                        for (final request in _result?.items ??
                            const <ProfessionalRequest>[])
                          _requestCard(request),
                      if ((_result?.totalPages ?? 0) > 1)
                        _pagination(theme),
                    ],
                  ),
              );

  Widget _assignedBody(ThemeData theme) {
    if (_assignedLoading && _assigned == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_assignedError != null && _assigned == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 44),
              const SizedBox(height: 12),
              Text(_assignedError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadAssigned,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAssigned,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Trabajos con cotización aceptada',
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (_assignedError != null) _inlineError(_assignedError!),
          if (_assignedLoading) const LinearProgressIndicator(),
          if ((_assigned ?? []).isEmpty && !_assignedLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 56),
              child: Column(
                children: [
                  Icon(Icons.work_off_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(
                    'No tienes trabajos asignados por ahora.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          for (final request in _assigned ?? const <ProfessionalRequest>[])
            _assignedCard(request),
        ],
      ),
    );
  }

  Widget _assignedCard(ProfessionalRequest request) {
    final status = _normalizedStatus(request.estado);
    final nextLabel = status == 'asignada'
        ? 'Iniciar trabajo'
        : status == 'en proceso'
            ? 'Marcar completado'
            : null;
    final busy = _updatingRequests.contains(request.idSolicitud);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.categoriaNombre,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _assignmentStatusChip(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(request.descripcion),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _meta(Icons.numbers_outlined, 'Solicitud #${request.idSolicitud}'),
                if (request.idCotizacion != null)
                  _meta(Icons.receipt_long_outlined,
                      'Cotización #${request.idCotizacion}'),
                if (request.precioOfertado != null)
                  _meta(Icons.payments_outlined,
                      '\$${request.precioOfertado!.toStringAsFixed(2)}'),
                if (request.tiempoEstimado?.isNotEmpty == true)
                  _meta(Icons.schedule_outlined, request.tiempoEstimado!),
              ],
            ),
            if (nextLabel != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : () => _advanceAssignment(request),
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(status == 'asignada'
                          ? Icons.play_arrow
                          : Icons.task_alt),
                  label: Text(nextLabel),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatSolicitudScreen(
                      requestId: request.idSolicitud,
                      conversationTitle: 'Chat con el cliente',
                    ),
                  ),
                ),
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Abrir chat del servicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assignmentStatusChip(String status) {
    final label = status.isEmpty
        ? 'Sin estado'
        : '${status[0].toUpperCase()}${status.substring(1)}';
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status == 'completada'
            ? colors.tertiaryContainer
            : status == 'en proceso'
                ? colors.primaryContainer
                : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }

  Widget _requestCard(ProfessionalRequest request) {
    final theme = Theme.of(context);
    final hasLocation = request.latitud != null && request.longitud != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.categoriaNombre,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  '#${request.idSolicitud}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(request.descripcion),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _meta(Icons.calendar_today_outlined, _date(request.fechaCreacion)),
                if (hasLocation)
                  _meta(
                    Icons.location_on_outlined,
                    '${request.latitud!.toStringAsFixed(3)}, '
                        '${request.longitud!.toStringAsFixed(3)}',
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : () => _sendQuote(request),
                icon: const Icon(Icons.request_quote_outlined),
                label: const Text('Enviar cotización'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 5),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      );

  Widget _pagination(ThemeData theme) {
    final current = _result?.page ?? _page;
    final total = _result?.totalPages ?? 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Página anterior',
            onPressed: _loading || current <= 1 ? null : () => _load(page: current - 1),
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Página $current de $total', style: theme.textTheme.bodyMedium),
          IconButton(
            tooltip: 'Página siguiente',
            onPressed: _loading || current >= total
                ? null
                : () => _load(page: current + 1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _loadError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 44),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );

  Widget _inlineError(String error) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(error),
      );

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay solicitudes disponibles por ahora.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
}
