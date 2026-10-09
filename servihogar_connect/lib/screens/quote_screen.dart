import 'package:flutter/material.dart';

import '../features/chat/chat_solicitud_screen.dart';
import '../models/marketplace_models.dart';
import '../services/auth_service.dart';
import '../services/marketplace_api_service.dart';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({
    super.key,
    required this.requestId,
    required this.description,
    this.api,
  });

  final int requestId;
  final String description;
  final MarketplaceApiService? api;

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  late final MarketplaceApiService _api =
      widget.api ?? MarketplaceApiService();
  List<MarketplaceQuote>? _quotes;
  bool _loading = true;
  final Set<int> _busyQuotes = {};
  final Set<int> _ratedProfessionals = {};
  String? _error;
  String? _requestStatus;
  bool _isCustomer = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _load();
  }

  Future<void> _loadRole() async {
    final role = (await AuthService.getUserRole())?.trim().toLowerCase() ?? '';
    if (mounted) {
      setState(() => _isCustomer = role == 'cliente' || role == 'customer');
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.getQuotes(widget.requestId);
      if (!mounted) return;
      setState(() {
        _quotes = response.items;
        _requestStatus = response.estado;
      });
    } catch (error) {
      if (mounted) setState(() => _error = marketplaceErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isAccepted(MarketplaceQuote quote) {
    final status = quote.estado.toLowerCase().trim();
    return status == 'aceptada' || status == 'accepted';
  }

  bool get _requestCompleted {
    final status = _requestStatus?.trim().toLowerCase().replaceAll('_', ' ');
    return status == 'completada' || status == 'completado' ||
        status == 'completed';
  }

  Future<void> _rateProfessional(MarketplaceQuote quote) async {
    final commentController = TextEditingController();
    var score = 5;
    final rating = await showDialog<({int score, String comment})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Califica a ${quote.profesionalNombre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Cómo fue tu experiencia con este profesional?'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    tooltip: '${index + 1} estrellas',
                    onPressed: () => setDialogState(() => score = index + 1),
                    icon: Icon(
                      index < score ? Icons.star_rounded : Icons.star_outline,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                ),
              ),
              Center(child: Text('$score de 5')),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                  hintText: 'Comparte tu experiencia',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                (
                  score: score,
                  comment: commentController.text.trim(),
                ),
              ),
              child: const Text('Enviar calificación'),
            ),
          ],
        ),
      ),
    );
    commentController.dispose();
    if (rating == null || !mounted) return;
    setState(() => _busyQuotes.add(quote.idCotizacion));
    try {
      await _api.submitRating(
        requestId: widget.requestId,
        professionalId: quote.idProfesional,
        score: rating.score,
        comment: rating.comment,
      );
      if (!mounted) return;
      setState(() => _ratedProfessionals.add(quote.idProfesional));
      _message('Gracias por calificar el servicio.');
    } catch (error) {
      if (!mounted) return;
      final message = marketplaceErrorMessage(error);
      if (message.toLowerCase().contains('ya calificaste')) {
        setState(() => _ratedProfessionals.add(quote.idProfesional));
        _message('Ya calificaste a este profesional.');
      } else {
        _message(message, error: true);
      }
    } finally {
      if (mounted) setState(() => _busyQuotes.remove(quote.idCotizacion));
    }
  }

  Future<void> _accept(MarketplaceQuote quote) async {
    setState(() => _busyQuotes.add(quote.idCotizacion));
    try {
      await _api.acceptQuote(
        requestId: widget.requestId,
        quoteId: quote.idCotizacion,
      );
      if (!mounted) return;
      _message('Cotización aceptada. Ya puedes coordinar el servicio.');
      await _load();
    } catch (error) {
      if (mounted) _message(marketplaceErrorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _busyQuotes.remove(quote.idCotizacion));
    }
  }

  void _message(String value, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Cotizaciones #${widget.requestId}'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading && _quotes == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tu solicitud', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(widget.description),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_requestStatus?.isNotEmpty ?? false) _requestStateCard(),
                  if ((_requestStatus?.trim().toLowerCase() == 'en proceso') ||
                      (_requestStatus?.trim().toLowerCase() == 'en_proceso'))
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Servicio en proceso'),
                        subtitle: const Text(
                          'Podrás calificar al profesional cuando el servicio '
                          'se marque como completado.',
                        ),
                      ),
                    ),
                  if (_error != null) _errorPanel(),
                  if (_loading) const LinearProgressIndicator(),
                  if ((_quotes?.isEmpty ?? false) && !_loading && _error == null)
                    _emptyState(),
                  for (final quote in _quotes ?? const <MarketplaceQuote>[])
                    _quoteCard(quote),
                ],
              ),
            ),
    );
  }

  Widget _requestStateCard() {
    final status = _requestStatus!.trim().toLowerCase().replaceAll('_', ' ');
    final label = status.isEmpty
        ? 'Sin estado'
        : '${status[0].toUpperCase()}${status.substring(1)}';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('Estado de la solicitud'),
        subtitle: Text(label),
      ),
    );
  }

  Widget _quoteCard(MarketplaceQuote quote) {
    final accepted = _isAccepted(quote);
    final statusLabel = quote.estado.isEmpty
        ? 'Pendiente'
        : '${quote.estado[0].toUpperCase()}${quote.estado.substring(1)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.engineering_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.profesionalNombre,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        quote.profesionalEspecialidad,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _statusChip(statusLabel, accepted),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _detail(
                    Icons.payments_outlined,
                    'Precio',
                    '\$${quote.precioOfertado.toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: _detail(
                    Icons.schedule_outlined,
                    'Tiempo estimado',
                    quote.tiempoEstimado.isEmpty
                        ? 'No indicado'
                        : quote.tiempoEstimado,
                  ),
                ),
              ],
            ),
            if (quote.calificacionPromedio != null) ...[
              const SizedBox(height: 12),
              _detail(
                Icons.star_outline,
                'Calificación',
                quote.calificacionPromedio!.toStringAsFixed(1),
              ),
            ],
            if (accepted && _isCustomer) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatSolicitudScreen(
                        requestId: widget.requestId,
                        conversationTitle: quote.profesionalNombre,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('Chatear con el profesional'),
                ),
              ),
            ],
            if (accepted && _requestCompleted && _isCustomer) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: quote.yaCalificado ||
                        _ratedProfessionals.contains(quote.idProfesional)
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Ya calificaste este servicio'),
                      )
                    : FilledButton.icon(
                        onPressed: _busyQuotes.contains(quote.idCotizacion)
                            ? null
                            : () => _rateProfessional(quote),
                        icon: _busyQuotes.contains(quote.idCotizacion)
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.star_outline),
                        label: const Text('Calificar profesional'),
                      ),
              ),
            ],
            if (!accepted && _canAcceptQuotes) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busyQuotes.contains(quote.idCotizacion)
                      ? null
                      : () => _accept(quote),
                  icon: _busyQuotes.contains(quote.idCotizacion)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Aceptar cotización'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _canAcceptQuotes {
    final status = _requestStatus?.trim().toLowerCase().replaceAll('_', ' ');
    return _isCustomer &&
        !(_quotes?.any(_isAccepted) ?? false) &&
        (status == null ||
            status.isEmpty ||
            status == 'publicada' ||
            status == 'pendiente');
  }

  Widget _detail(IconData icon, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
        ],
      );

  Widget _statusChip(String label, bool accepted) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: accepted
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      );

  Widget _errorPanel() => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_error!),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.request_quote_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Todavía no recibes cotizaciones.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Te avisaremos cuando un profesional envíe una oferta.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
}
