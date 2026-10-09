import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../features/admin/admin_requests_screen.dart';
import '../models/marketplace_models.dart';
import '../services/auth_service.dart';
import '../services/marketplace_api_service.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({
    super.key,
    required this.database,
    this.api,
  });

  final AppDatabase database;
  final MarketplaceApiService? api;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late final MarketplaceApiService _api =
      widget.api ?? MarketplaceApiService();
  MarketplaceSummary? _summary;
  List<MarketplaceCategory>? _categories;
  List<MarketplaceProfessional>? _professionals;
  bool _loading = true;
  String? _summaryError;
  String? _categoryError;
  String? _professionalError;
  final Set<int> _savingCategories = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _summaryError = null;
      _categoryError = null;
      _professionalError = null;
    });
    await Future.wait([
      _loadSummary(),
      _loadCategories(),
      _loadProfessionals(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await _api.getAdminSummary();
      if (mounted) setState(() => _summary = summary);
    } catch (error) {
      if (mounted) setState(() => _summaryError = marketplaceErrorMessage(error));
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _api.getCategories();
      if (mounted) setState(() => _categories = categories);
    } catch (error) {
      if (mounted) {
        setState(() => _categoryError = marketplaceErrorMessage(error));
      }
    }
  }

  Future<void> _loadProfessionals() async {
    try {
      final professionals = await _api.getAdminProfessionals();
      if (mounted) setState(() => _professionals = professionals);
    } catch (error) {
      if (mounted) {
        setState(() => _professionalError = marketplaceErrorMessage(error));
      }
    }
  }

  Future<void> _createProfessional() async {
    List<MarketplaceAdminUser> eligibleUsers;
    try {
      final users = await _api.getAdminUsers();
      final existingProfessionalUserIds = (_professionals ?? const [])
          .map((professional) => professional.idUsuario)
          .toSet();
      eligibleUsers = users.where((user) {
        final role = user.tipoUsuario.trim().toLowerCase();
        return user.id > 0 &&
            !existingProfessionalUserIds.contains(user.id) &&
            !role.contains('profesional') &&
            !role.contains('professional') &&
            !role.contains('admin') &&
            !role.contains('administrador');
      }).toList();
    } catch (error) {
      if (mounted) _message(marketplaceErrorMessage(error), isError: true);
      return;
    }
    if (!mounted) return;
    if (eligibleUsers.isEmpty) {
      _message('No hay cuentas elegibles para habilitar como profesional.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final specialtyController = TextEditingController();
    final descriptionController = TextEditingController();
    final rateController = TextEditingController();
    int? selectedUserId;
    final result = await showDialog<
        ({int userId, String specialty, String description, double rate})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Habilitar profesional'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selecciona una cuenta existente. Su rol cambiará a '
                    'profesional al crear el perfil.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedUserId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Cuenta elegible',
                    ),
                    items: eligibleUsers
                        .map(
                          (user) => DropdownMenuItem<int>(
                            value: user.id,
                            child: Text(
                              '${user.nombreCompleto.isEmpty ? 'Usuario' : user.nombreCompleto}'
                              '${user.email.isEmpty ? '' : ' · ${user.email}'}'
                              ' · #${user.id}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedUserId = value),
                    validator: (value) =>
                        value == null ? 'Selecciona una cuenta.' : null,
                  ),
                  TextFormField(
                    controller: specialtyController,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Especialidad'),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Ingresa una especialidad.'
                        : null,
                  ),
                  TextFormField(
                    controller: descriptionController,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                    ),
                  ),
                  TextFormField(
                    controller: rateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Tarifa por hora',
                      prefixText: '\$ ',
                    ),
                    validator: (value) {
                      final rate = double.tryParse(
                        (value ?? '').trim().replaceAll(',', '.'),
                      );
                      return rate == null || !rate.isFinite || rate <= 0
                          ? 'Ingresa una tarifa mayor que cero.'
                          : null;
                    },
                  ),
                ],
              ),
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
                    userId: selectedUserId!,
                    specialty: specialtyController.text.trim(),
                    description: descriptionController.text.trim(),
                    rate: double.parse(
                      rateController.text.trim().replaceAll(',', '.'),
                    ),
                  ),
                );
              },
              child: const Text('Crear perfil'),
            ),
          ],
        ),
      ),
    );
    specialtyController.dispose();
    descriptionController.dispose();
    rateController.dispose();
    if (result == null || !mounted) return;
    try {
      await _api.createProfessional(
        userId: result.userId,
        specialty: result.specialty,
        description: result.description,
        hourlyRate: result.rate,
      );
      if (!mounted) return;
      _message('Perfil profesional creado y cuenta habilitada.');
      await Future.wait([_loadProfessionals(), _loadSummary()]);
    } catch (error) {
      if (mounted) _message(marketplaceErrorMessage(error), isError: true);
    }
  }

  Future<void> _editCategory({MarketplaceCategory? category}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.nombre ?? '');
    final descriptionController =
        TextEditingController(text: category?.descripcion ?? '');
    var active = category?.activa ?? true;
    final result = await showDialog<
        ({String name, String description, bool active})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Nueva categoría' : 'Editar categoría'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Ingresa un nombre.'
                        : null,
                  ),
                  TextFormField(
                    controller: descriptionController,
                    maxLength: 240,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: 'Descripción'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Categoría activa'),
                    value: active,
                    onChanged: (value) =>
                        setDialogState(() => active = value),
                  ),
                ],
              ),
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
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    active: active,
                  ),
                );
              },
              child: Text(category == null ? 'Crear' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    descriptionController.dispose();
    if (result == null || !mounted) return;
    try {
      if (category == null) {
        await _api.createCategory(
          name: result.name,
          description: result.description,
        );
      } else {
        await _api.updateCategory(
          MarketplaceCategory(
            idCategoria: category.idCategoria,
            nombre: result.name,
            descripcion: result.description,
            activa: result.active,
          ),
        );
      }
      if (!mounted) return;
      _message(category == null
          ? 'Categoría creada.'
          : 'Categoría actualizada.');
      await _loadCategories();
    } catch (error) {
      if (mounted) _message(marketplaceErrorMessage(error), isError: true);
    }
  }

  Future<void> _toggleCategory(MarketplaceCategory category) async {
    setState(() => _savingCategories.add(category.idCategoria));
    try {
      await _api.updateCategory(
        MarketplaceCategory(
          idCategoria: category.idCategoria,
          nombre: category.nombre,
          descripcion: category.descripcion,
          activa: !category.activa,
        ),
      );
      await _loadCategories();
      if (mounted) {
        _message(
          category.activa
              ? 'Categoría desactivada.'
              : 'Categoría activada.',
        );
      }
    } catch (error) {
      if (mounted) _message(marketplaceErrorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() => _savingCategories.remove(category.idCategoria));
      }
    }
  }

  void _message(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

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
      debugPrint('No se pudo cerrar la sesión de administrador: $error');
      if (!mounted) return;
      _message('No se pudo completar el cierre de sesión.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de administración'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading &&
              _summary == null &&
              _categories == null &&
              _professionals == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Resumen de actividad',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (_summaryError != null)
                    _errorPanel(_summaryError!, _loadSummary),
                  if (_summary != null) _summaryGrid(_summary!),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.assignment_outlined),
                      title: const Text('Supervisar solicitudes'),
                      subtitle: const Text(
                        'Buscar servicios por estado y categoría',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminRequestsScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Categorías de servicio',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _editCategory(),
                        icon: const Icon(Icons.add),
                        label: const Text('Crear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_categoryError != null)
                    _errorPanel(_categoryError!, _loadCategories),
                  if (_categories == null && _categoryError == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (_categories?.isEmpty == true)
                    _emptyCategories(),
                  for (final category in _categories ?? const [])
                    _categoryTile(category),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Perfiles profesionales',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _createProfessional,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Habilitar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Asigna un perfil profesional a una cuenta registrada.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (_professionalError != null)
                    _errorPanel(_professionalError!, _loadProfessionals),
                  if (_professionals == null && _professionalError == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (_professionals?.isEmpty == true)
                    _emptyProfessionals(),
                  for (final professional in _professionals ?? const [])
                    _professionalTile(professional),
                ],
              ),
            ),
    );
  }

  Widget _summaryGrid(MarketplaceSummary summary) => GridView.count(
        crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.65,
        children: [
          _metric('Pendientes', summary.solicitudesPendientes,
              Icons.pending_actions_outlined),
          _metric('En proceso', summary.solicitudesEnProceso,
              Icons.handyman_outlined),
          _metric('Completadas', summary.solicitudesCompletadas,
              Icons.task_alt_outlined),
          _metric('Profesionales', summary.profesionalesActivos,
              Icons.engineering_outlined),
          _metric('Categorías activas', summary.categoriasActivas,
              Icons.category_outlined),
        ],
      );

  Widget _metric(String label, int value, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: colors.primary),
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryTile(MarketplaceCategory category) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: category.activa
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.category_outlined,
              color: category.activa
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          title: Text(category.nombre),
          subtitle: Text(
            category.descripcion.isEmpty
                ? (category.activa ? 'Activa' : 'Inactiva')
                : '${category.descripcion} · '
                    '${category.activa ? 'Activa' : 'Inactiva'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Wrap(
            spacing: 0,
            children: [
              IconButton(
                tooltip: 'Editar categoría',
                onPressed: () => _editCategory(category: category),
                icon: const Icon(Icons.edit_outlined),
              ),
              _savingCategories.contains(category.idCategoria)
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: category.activa
                          ? 'Desactivar categoría'
                          : 'Activar categoría',
                      onPressed: () => _toggleCategory(category),
                      icon: Icon(
                        category.activa
                            ? Icons.toggle_on_outlined
                            : Icons.toggle_off_outlined,
                        color: category.activa
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
            ],
          ),
        ),
      );

  Widget _professionalTile(MarketplaceProfessional professional) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.engineering_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            professional.nombreUsuario.isEmpty
                ? professional.especialidad
                : professional.nombreUsuario,
          ),
          subtitle: Text(
            'Usuario #${professional.idUsuario} · ${professional.especialidad}'
            '${professional.emailUsuario.isEmpty ? '' : '\n${professional.emailUsuario}'}'
            '\nTarifa: \$${professional.tarifaHora.toStringAsFixed(2)}/h',
          ),
          isThreeLine: true,
          trailing: professional.calificacionPromedio == null
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 17, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(professional.calificacionPromedio!
                        .toStringAsFixed(1)),
                  ],
                ),
        ),
      );

  Widget _errorPanel(String message, Future<void> Function() retry) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: Text(message)),
              IconButton(
                tooltip: 'Reintentar',
                onPressed: retry,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      );

  Widget _emptyCategories() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(Icons.category_outlined, size: 42),
            SizedBox(height: 8),
            Text('Aún no hay categorías. Crea la primera para comenzar.'),
          ],
        ),
      );

  Widget _emptyProfessionals() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.engineering_outlined, size: 42),
            SizedBox(height: 8),
            Text('Aún no hay perfiles profesionales habilitados.'),
          ],
        ),
      );
}
