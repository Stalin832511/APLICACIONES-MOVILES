import 'dart:convert';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/solicitud.dart';
import '../services/api_service.dart';
import '../widgets/home_service_illustration.dart';
import '../widgets/status_badge.dart';
import 'detalle_solicitud_screen.dart';

class ActividadScreen extends StatefulWidget {
  final AppDatabase database;
  final int refreshToken;

  const ActividadScreen({
    super.key,
    required this.database,
    this.refreshToken = 0,
  });

  @override
  State<ActividadScreen> createState() => _ActividadScreenState();
}

class _ActividadScreenState extends State<ActividadScreen> {
  late Future<_ActivityData> _activityFuture;

  @override
  void initState() {
    super.initState();
    _activityFuture = _loadActivity();
  }

  @override
  void didUpdateWidget(covariant ActividadScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      _activityFuture = _loadActivity();
    }
  }

  Future<_ActivityData> _loadActivity() async {
    try {
      final results = await Future.wait([
        ApiService.fetchSolicitudesPaginadas(page: 1, pageSize: 100),
        ApiService.fetchSolicitudesPaginadas(
          page: 1,
          pageSize: 1,
          estado: 'Pendiente',
        ),
        ApiService.fetchSolicitudesPaginadas(
          page: 1,
          pageSize: 1,
          estado: 'En camino',
        ),
        ApiService.fetchSolicitudesPaginadas(
          page: 1,
          pageSize: 1,
          estado: 'En proceso',
        ),
        ApiService.fetchSolicitudesPaginadas(
          page: 1,
          pageSize: 1,
          estado: 'Completado',
        ),
      ]);
      final page = results.first;
      final counts = <RequestStatus, int>{
        RequestStatus.pendiente: results[1].totalCount,
        RequestStatus.enCamino: results[2].totalCount,
        RequestStatus.enProceso: results[3].totalCount,
        RequestStatus.completado: results[4].totalCount,
      };
      final pending = await _loadPendingRequests();
      final serverOperationIds = page.items
          .map((request) => request.clientOperationId)
          .whereType<String>()
          .toSet();
      final newPending = pending
          .where(
            (request) =>
                !serverOperationIds.contains(request.clientOperationId),
          )
          .toList();
      counts[RequestStatus.pendiente] =
          counts[RequestStatus.pendiente]! +
              newPending
                  .where((request) => request.status == RequestStatus.pendiente)
                  .length;
      return _ActivityData(
        requests: _combineRequests(page.items, pending),
        recentRequestCount: page.items.length,
        counts: counts,
        total: page.totalCount + newPending.length,
        isOffline: false,
      );
    } catch (error, stackTrace) {
      debugPrint('No se pudo cargar actividad desde API: $error\n$stackTrace');
      return _loadCachedActivity();
    }
  }

  Future<_ActivityData> _loadCachedActivity() async {
    final localRecords = await widget.database.serviceRequestDao.getAllRequests();
    final cached = localRecords.map(
      (record) => SolicitudModel(
        id: int.tryParse(record.id) ?? 0,
        descripcion: record.description,
        status: RequestStatusParsing.fromApiValue(record.status),
        fechaCreacion: record.createdAt,
        clientOperationId: record.clientOperationId,
      ),
    );
    final pending = await _loadPendingRequests();
    final requests = _combineRequests(cached.toList(), pending)
      ..sort((first, second) => second.fechaCreacion.compareTo(first.fechaCreacion));
    if (requests.isEmpty) {
      throw Exception(
        'No hay actividad guardada. Conéctate a internet e inténtalo de nuevo.',
      );
    }

    final counts = <RequestStatus, int>{
      for (final status in RequestStatus.values)
        status: requests.where((request) => request.status == status).length,
    };
    return _ActivityData(
      requests: requests.take(20).toList(),
      recentRequestCount: requests.length,
      counts: counts,
      total: requests.length,
      isOffline: true,
    );
  }

  Future<List<SolicitudModel>> _loadPendingRequests() async {
    final operations = await widget.database.syncQueueDao.getAllOperations();
    final requests = <SolicitudModel>[];
    var localId = -1;
    for (final operation in operations) {
      if (operation.operationType != 'crear_solicitud') continue;
      try {
        final payload =
            jsonDecode(operation.payload) as Map<String, dynamic>;
        requests.add(
          SolicitudModel.fromPendingPayload(
            localId: localId--,
            payload: payload,
            createdAt: operation.createdAt,
            categoryName: null,
            syncFailed: operation.status == 'failed',
          ),
        );
      } on FormatException catch (error) {
        debugPrint(
          'No se pudo leer la solicitud pendiente '
          '${operation.operationId}: $error',
        );
      } on TypeError catch (error) {
        debugPrint(
          'Formato inválido en solicitud pendiente '
          '${operation.operationId}: $error',
        );
      }
    }
    return requests;
  }

  List<SolicitudModel> _combineRequests(
    List<SolicitudModel> serverRequests,
    List<SolicitudModel> pendingRequests,
  ) {
    final serverOperationIds = serverRequests
        .map((request) => request.clientOperationId)
        .whereType<String>()
        .toSet();
    return [
      ...pendingRequests.where(
        (request) => !serverOperationIds.contains(request.clientOperationId),
      ),
      ...serverRequests,
    ]..sort(
        (first, second) =>
            second.fechaCreacion.compareTo(first.fechaCreacion),
      );
  }

  Future<void> _refresh() async {
    setState(() => _activityFuture = _loadActivity());
    await _activityFuture;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi actividad',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar actividad',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<_ActivityData>(
        future: _activityFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ActivityError(
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _refresh,
            );
          }
          final data = snapshot.requireData;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              children: [
                Text(
                  _greeting(),
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tu hogar, al día',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 18),
                _ActivityHero(data: data),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.work_history_rounded,
                        label: 'Solicitudes',
                        value: '${data.total}',
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.pending_actions_rounded,
                        label: 'En seguimiento',
                        value:
                            '${data.counts[RequestStatus.pendiente]! + data.counts[RequestStatus.enCamino]! + data.counts[RequestStatus.enProceso]!}',
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionHeader(
                  title: 'Estado de tus servicios',
                  subtitle: data.isOffline
                      ? 'Resumen de la información guardada'
                      : 'Distribución de tus solicitudes',
                ),
                const SizedBox(height: 12),
                _StatusOverview(counts: data.counts),
                const SizedBox(height: 22),
                _SectionHeader(
                  title: 'Últimos 7 días',
                  subtitle: data.isOffline
                      ? 'Basado en actividad guardada'
                      : 'Basado en las últimas '
                          '${data.recentRequestCount} solicitudes cargadas',
                ),
                const SizedBox(height: 12),
                _WeeklyActivityCard(requests: data.requests),
                const SizedBox(height: 22),
                _SectionHeader(
                  title: 'Actividad reciente',
                  subtitle: 'Toca una solicitud para ver sus detalles',
                ),
                const SizedBox(height: 10),
                if (data.requests.isEmpty)
                  const _EmptyActivity()
                else
                  for (final request in data.requests.take(5))
                    _RecentRequestTile(
                      request: request,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DetalleSolicitudScreen(
                            solicitud: request,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActivityData {
  final List<SolicitudModel> requests;
  final Map<RequestStatus, int> counts;
  final int total;
  final int recentRequestCount;
  final bool isOffline;

  const _ActivityData({
    required this.requests,
    required this.counts,
    required this.total,
    required this.recentRequestCount,
    required this.isOffline,
  });
}

class _ActivityHero extends StatelessWidget {
  final _ActivityData data;

  const _ActivityHero({required this.data});

  @override
  Widget build(BuildContext context) {
    final inProgress = data.counts[RequestStatus.enCamino]! +
        data.counts[RequestStatus.enProceso]!;
    final completed = data.counts[RequestStatus.completado]!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF30246C), Color(0xFF6D28D9), Color(0xFF4234A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -4,
            top: -2,
            child: Opacity(
              opacity: 0.9,
              child: const HomeServiceIllustration(size: 116),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    data.isOffline ? 'RESUMEN LOCAL' : 'RESUMEN GENERAL',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                '$inProgress',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                inProgress == 1
                    ? 'servicio en progreso'
                    : 'servicios en progreso',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _HeroStat(
                    icon: Icons.check_circle_rounded,
                    label: '$completed completados',
                  ),
                  const SizedBox(width: 16),
                  _HeroStat(
                    icon: data.isOffline
                        ? Icons.cloud_off_rounded
                        : Icons.cloud_done_rounded,
                    label: data.isOffline ? 'Modo sin conexión' : 'Datos al día',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 17, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _StatusOverview extends StatelessWidget {
  final Map<RequestStatus, int> counts;

  const _StatusOverview({required this.counts});

  @override
  Widget build(BuildContext context) {
    const statuses = [
      (
        status: RequestStatus.pendiente,
        label: 'Pendientes',
        color: Color(0xFFF59E0B),
        icon: Icons.schedule_rounded,
      ),
      (
        status: RequestStatus.enCamino,
        label: 'En camino',
        color: Color(0xFF38BDF8),
        icon: Icons.directions_car_filled_rounded,
      ),
      (
        status: RequestStatus.enProceso,
        label: 'En proceso',
        color: Color(0xFF8B5CF6),
        icon: Icons.handyman_rounded,
      ),
      (
        status: RequestStatus.completado,
        label: 'Completados',
        color: Color(0xFF22C55E),
        icon: Icons.check_circle_rounded,
      ),
    ];
    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final item in statuses)
                Expanded(
                  flex: counts[item.status] == 0 ? 1 : counts[item.status]!,
                  child: Container(
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: item.color.withValues(
                        alpha: counts[item.status] == 0 ? 0.18 : 1,
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in statuses)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(item.icon, size: 17, color: item.color),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                  Text(
                    '${counts[item.status]}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 35,
                    child: Text(
                      total == 0
                          ? '0%'
                          : '${(counts[item.status]! / total * 100).round()}%',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  final List<SolicitudModel> requests;

  const _WeeklyActivityCard({required this.requests});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final today = DateUtils.dateOnly(DateTime.now());
    final counts = List<int>.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return requests.where((request) {
        return DateUtils.isSameDay(request.fechaCreacion, date);
      }).length;
    });
    final maxCount = counts.fold<int>(0, (max, count) => count > max ? count : max);
    final labels = List<String>.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      const weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
      return weekdays[date.weekday - 1];
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 112,
            child: CustomPaint(
              painter: _ActivityChartPainter(
                values: counts,
                maxValue: maxCount,
                lineColor: colors.primary,
                gridColor: colors.outlineVariant,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < counts.length; index++)
                    Expanded(
                      child: Align(
                        alignment: Alignment(
                          0,
                          maxCount == 0
                              ? 0.9
                              : 0.9 - (counts[index] / maxCount) * 1.75,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${counts[index]}',
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final label in labels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityChartPainter extends CustomPainter {
  final List<int> values;
  final int maxValue;
  final Color lineColor;
  final Color gridColor;

  const _ActivityChartPainter({
    required this.values,
    required this.maxValue,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var row = 0; row < 3; row++) {
      final y = size.height * (0.25 + row * 0.3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (values.isEmpty || maxValue == 0) return;

    final points = List<Offset>.generate(values.length, (index) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final y = size.height * (0.78 - values[index] / maxValue * 0.62);
      return Offset(x, y);
    });
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final middleX = (previous.dx + current.dx) / 2;
      path.cubicTo(middleX, previous.dy, middleX, current.dy, current.dx, current.dy);
    }
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.26),
            lineColor.withValues(alpha: 0.01),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = lineColor);
      canvas.drawCircle(
        point,
        2,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.maxValue != maxValue ||
      oldDelegate.lineColor != lineColor;
}

class _RecentRequestTile extends StatelessWidget {
  final SolicitudModel request;
  final VoidCallback onTap;

  const _RecentRequestTile({
    required this.request,
    required this.onTap,
  });

  String get _date {
    final date = request.fechaCreacion;
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            request.pendingSync
                ? Icons.cloud_upload_outlined
                : Icons.home_repair_service_outlined,
            color: colors.primary,
          ),
        ),
        title: Text(
          request.descripcion,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            if (request.categoriaNombre != null) request.categoriaNombre!,
            _date,
            if (request.pendingSync) 'Pendiente de sincronización',
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: StatusBadge(status: request.status),
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.insert_chart_outlined_rounded,
            size: 42,
            color: colors.primary,
          ),
          const SizedBox(height: 10),
          const Text(
            'Tu actividad aparecerá aquí',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Cuando crees una solicitud, podrás consultar su avance desde esta página.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ActivityError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ActivityError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 46, color: colors.error),
            const SizedBox(height: 14),
            Text(
              'No se pudo cargar tu actividad',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
