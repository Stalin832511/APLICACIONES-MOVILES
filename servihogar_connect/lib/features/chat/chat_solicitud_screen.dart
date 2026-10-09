import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'chat_message.dart';
import 'chat_service.dart';

class ChatSolicitudScreen extends StatefulWidget {
  const ChatSolicitudScreen({
    super.key,
    required this.requestId,
    required this.conversationTitle,
    this.service,
  });

  final int requestId;
  final String conversationTitle;
  final ChatService? service;

  @override
  State<ChatSolicitudScreen> createState() => _ChatSolicitudScreenState();
}

class _ChatSolicitudScreenState extends State<ChatSolicitudScreen> {
  static const _maxMessageLength = 2000;

  late final ChatService _service = widget.service ?? ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<int, ChatMessage> _messagesById = {};
  Timer? _pollTimer;
  int? _currentUserId;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  String? _syncNotice;

  List<ChatMessage> get _messages {
    final items = _messagesById.values.toList()
      ..sort((a, b) => a.idMensaje.compareTo(b.idMensaje));
    return items;
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _currentUserId = await AuthService.getUserId();
      if (!mounted) return;
      if (_currentUserId == null) {
        setState(() {
          _loading = false;
          _error = 'No se pudo identificar la sesión activa.';
        });
        return;
      }

      await _loadMessages();
      if (!mounted) return;
      _pollTimer = Timer.periodic(
        const Duration(seconds: 8),
        (_) => _loadMessages(silent: true),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo iniciar el chat: $error';
      });
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (_loading && silent) return;
    if (!silent && _messagesById.isEmpty && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final wasNearBottom = !_scrollController.hasClients ||
        _scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <
            120;
    final latestId = _messagesById.keys.isEmpty
        ? 0
        : _messagesById.keys.reduce((a, b) => a > b ? a : b);
    try {
      final messages = await _service.getMessages(
        requestId: widget.requestId,
        afterId: latestId,
      );
      if (!mounted) return;
      final previousCount = _messagesById.length;
      setState(() {
        for (final message in messages) {
          _messagesById[message.idMensaje] = message;
        }
        _error = null;
        _syncNotice = null;
        _loading = false;
      });
      if (messages.isNotEmpty &&
          (previousCount == 0 || wasNearBottom)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_messagesById.isEmpty || !silent) {
          _error = error.toString();
        } else {
          _syncNotice = 'No se pudo actualizar el chat. Reintentando…';
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_sending) return;
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    if (message.length > _maxMessageLength) {
      _showMessage(
        'El mensaje no puede superar $_maxMessageLength caracteres.',
        isError: true,
      );
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final sent = await _service.sendMessage(
        requestId: widget.requestId,
        message: message,
      );
      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _messagesById[sent.idMensaje] = sent;
        _syncNotice = null;
      });
      _scrollToBottom();
    } catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final messages = _messages;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversationTitle),
            Text(
              'Solicitud #${widget.requestId}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar mensajes',
            onPressed: _loading ? null : _loadMessages,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_syncNotice != null)
              Material(
                color: colors.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sync_problem_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _syncNotice!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: _loading && messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && messages.isEmpty
                      ? _errorView()
                      : messages.isEmpty
                          ? _emptyView()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                              itemCount: messages.length,
                              itemBuilder: (context, index) => _messageBubble(
                                messages[index],
                              ),
                            ),
            ),
            _composer(colors, theme),
          ],
        ),
      ),
    );
  }

  Widget _messageBubble(ChatMessage message) {
    final isMine = message.idEmisor == _currentUserId;
    final colors = Theme.of(context).colorScheme;
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final background = isMine ? colors.primaryContainer : colors.surfaceContainer;
    final foreground =
        isMine ? colors.onPrimaryContainer : colors.onSurface;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Card(
          color: background,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMine && message.nombreCompleto.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      message.nombreCompleto,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: foreground.withValues(alpha: 0.72),
                          ),
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  message.mensaje,
                  style: TextStyle(color: foreground),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.fechaEnvio),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foreground.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _composer(ColorScheme colors, ThemeData theme) {
    final length = _messageController.text.length;
    return Material(
      elevation: 6,
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: _maxMessageLength,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje…',
                    counterText: '$length/$_maxMessageLength',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Enviar mensaje',
                onPressed: _sending ||
                        _messageController.text.trim().isEmpty ||
                        length > _maxMessageLength
                    ? null
                    : _sendMessage,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.forum_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Inicia la conversación',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Coordina los detalles del servicio por este chat privado.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 44),
              const SizedBox(height: 12),
              Text(_error ?? 'No se pudo cargar el chat.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadMessages,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
}
