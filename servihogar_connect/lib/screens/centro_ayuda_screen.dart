import 'package:flutter/material.dart';

/// Pregunta frecuente con su categoría para poder filtrarla.
class _Faq {
  final IconData icon;
  final String category;
  final String question;
  final String answer;

  const _Faq({
    required this.icon,
    required this.category,
    required this.question,
    required this.answer,
  });
}

class CentroAyudaScreen extends StatefulWidget {
  const CentroAyudaScreen({super.key});

  @override
  State<CentroAyudaScreen> createState() => _CentroAyudaScreenState();
}

class _CentroAyudaScreenState extends State<CentroAyudaScreen> {
  static const String _todas = 'Todas';

  static const List<String> _categorias = [
    _todas,
    'Solicitudes',
    'Ubicación',
    'Sin conexión',
    'Seguimiento',
    'Seguridad',
  ];

  static const List<_Faq> _preguntas = [
    _Faq(
      icon: Icons.add_task_rounded,
      category: 'Solicitudes',
      question: '¿Cómo solicito un servicio?',
      answer:
          'Abre Servicios, elige una categoría y pulsa “Solicitar este '
          'servicio”. Describe el trabajo y agrega la ubicación requerida '
          'antes de guardar la solicitud.',
    ),
    _Faq(
      icon: Icons.sync_rounded,
      category: 'Sin conexión',
      question: '¿Qué ocurre si pierdo la conexión?',
      answer:
          'Las solicitudes guardadas sin conexión permanecen en el '
          'dispositivo y se envían cuando vuelve internet. Puedes verlas '
          'en Mis solicitudes mientras esperan sincronización.',
    ),
    _Faq(
      icon: Icons.location_on_outlined,
      category: 'Ubicación',
      question: '¿Para qué se usa mi ubicación?',
      answer:
          'La ubicación se adjunta a la solicitud para indicar dónde se '
          'necesita el servicio. Se pide permiso cuando decides obtenerla.',
    ),
    _Faq(
      icon: Icons.photo_camera_outlined,
      category: 'Solicitudes',
      question: '¿Dónde veo la fotografía que agregué?',
      answer:
          'Si todavía no hay conexión, la evidencia se conserva en este '
          'dispositivo y su detalle queda disponible desde la solicitud. '
          'Después de sincronizar, se consulta al servidor.',
    ),
    _Faq(
      icon: Icons.timeline_rounded,
      category: 'Seguimiento',
      question: '¿Cómo consulto el avance?',
      answer:
          'Abre una solicitud desde Mis solicitudes y selecciona '
          '“Ver seguimiento”. La pantalla muestra el último estado '
          'recibido por la aplicación.',
    ),
    _Faq(
      icon: Icons.flag_rounded,
      category: 'Seguimiento',
      question: '¿Qué significa cada estado?',
      answer:
          'Pendiente: la solicitud fue registrada y espera atención. '
          'En camino: el servicio va hacia tu ubicación. En proceso: el '
          'trabajo se está realizando. Completado: el servicio terminó.',
    ),
    _Faq(
      icon: Icons.lock_outline_rounded,
      category: 'Seguridad',
      question: '¿Mis datos de acceso están seguros?',
      answer:
          'La sesión se guarda mediante almacenamiento seguro del '
          'dispositivo y tu contraseña no se almacena localmente. Al cerrar '
          'sesión se eliminan la sesión y los datos locales de la aplicación.',
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _categoriaSeleccionada = _todas;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Faq> get _preguntasFiltradas {
    final consulta = _query.toLowerCase().trim();
    return _preguntas.where((faq) {
      final coincideCategoria = _categoriaSeleccionada == _todas ||
          faq.category == _categoriaSeleccionada;
      final coincideTexto = consulta.isEmpty ||
          faq.question.toLowerCase().contains(consulta) ||
          faq.answer.toLowerCase().contains(consulta);
      return coincideCategoria && coincideTexto;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filtradas = _preguntasFiltradas;

    return Scaffold(
      appBar: AppBar(title: const Text('Centro de ayuda')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          _buildHero(),
          const SizedBox(height: 16),
          _buildSearchField(colors),
          const SizedBox(height: 12),
          _buildCategoryChips(colors),
          const SizedBox(height: 22),
          _buildQuickGuide(colors, textTheme),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.quiz_rounded, color: colors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Preguntas frecuentes',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${filtradas.length} de ${_preguntas.length}',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtradas.isEmpty)
            _buildEmptyResults(colors, textTheme)
          else
            for (final faq in filtradas)
              _HelpQuestion(
                key: ValueKey(faq.question),
                icon: faq.icon,
                question: faq.question,
                answer: faq.answer,
                category: faq.category,
              ),
          const SizedBox(height: 16),
          _buildStatesLegend(colors, textTheme),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'El chat en tiempo real y el contacto directo con '
                    'profesionales aún no están disponibles en la aplicación.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.45,
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

  // ==========================================================
  // CABECERA, BÚSQUEDA Y FILTROS
  // ==========================================================

  Widget _buildHero() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 16,
            child: Icon(
              Icons.support_agent_rounded,
              size: 84,
              color: Colors.white.withValues(alpha: 0.13),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                SizedBox(height: 16),
                Text(
                  '¿En qué podemos ayudarte?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Encuentra respuestas sobre solicitudes, ubicación y uso sin conexión.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ColorScheme colors) {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Busca una pregunta o tema',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar búsqueda',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ColorScheme colors) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categorias.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final categoria = _categorias[index];
          final seleccionada = categoria == _categoriaSeleccionada;
          return ChoiceChip(
            label: Text(categoria),
            selected: seleccionada,
            showCheckmark: false,
            onSelected: (_) {
              setState(() => _categoriaSeleccionada = categoria);
            },
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: seleccionada ? colors.onPrimary : null,
            ),
            selectedColor: colors.primary,
          );
        },
      ),
    );
  }

  // ==========================================================
  // GUÍA RÁPIDA, ESTADOS Y RESULTADOS VACÍOS
  // ==========================================================

  Widget _buildQuickGuide(ColorScheme colors, TextTheme textTheme) {
    const pasos = [
      (
        icon: Icons.category_rounded,
        title: 'Elige',
        text: 'Escoge el servicio que necesitas.',
      ),
      (
        icon: Icons.edit_note_rounded,
        title: 'Describe',
        text: 'Cuenta el problema y agrega ubicación.',
      ),
      (
        icon: Icons.track_changes_rounded,
        title: 'Sigue',
        text: 'Consulta el avance en Mis solicitudes.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.rocket_launch_rounded, color: colors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Primeros pasos',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < pasos.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              pasos[i].icon,
                              size: 19,
                              color: colors.primary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: colors.primary.withValues(alpha: 0.5),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        pasos[i].title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pasos[i].text,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatesLegend(ColorScheme colors, TextTheme textTheme) {
    const estados = [
      (
        icon: Icons.hourglass_top_rounded,
        color: Color(0xFFF59E0B),
        label: 'Pendiente',
      ),
      (
        icon: Icons.local_shipping_rounded,
        color: Color(0xFF38BDF8),
        label: 'En camino',
      ),
      (
        icon: Icons.handyman_rounded,
        color: Color(0xFF8B5CF6),
        label: 'En proceso',
      ),
      (
        icon: Icons.verified_rounded,
        color: Color(0xFF22C55E),
        label: 'Completado',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_rounded, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Estados de una solicitud',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final estado in estados)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: estado.color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: estado.color.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estado.icon, size: 16, color: estado.color),
                      const SizedBox(width: 6),
                      Text(
                        estado.label,
                        style: TextStyle(
                          color: estado.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults(ColorScheme colors, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 38,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          const Text(
            'No encontramos resultados',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Prueba con otras palabras o cambia la categoría.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _query = '';
                _categoriaSeleccionada = _todas;
              });
            },
            child: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }
}

class _HelpQuestion extends StatelessWidget {
  final IconData icon;
  final String question;
  final String answer;
  final String category;

  const _HelpQuestion({
    super.key,
    required this.icon,
    required this.question,
    required this.answer,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colors.primary, size: 20),
        ),
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              category,
              style: TextStyle(
                color: colors.primary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}