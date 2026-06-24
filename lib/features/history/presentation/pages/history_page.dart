import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/history_bloc.dart';
import '../../domain/entities/activity_session.dart';
import '../../../../shared/widgets/banner_header.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _activeFilter = 'fecha';

  Widget _buildFilterButton(String label, String value) {
    final isActive = _activeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0x1AFF6B00) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFFFF6B00) : const Color(0xFFE8E8E8),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFFFF6B00) : const Color(0xFF999999),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        final sessions =
            state is HistoryLoaded ? state.sessions : <ActivitySession>[];

        final sorted = List.of(sessions);
        if (_activeFilter == 'mas') {
          sorted.sort((a, b) => b.steps.compareTo(a.steps));
        } else if (_activeFilter == 'menos') {
          sorted.sort((a, b) => a.steps.compareTo(b.steps));
        } else if (_activeFilter == 'fecha') {
          sorted.sort((a, b) => b.startTime.compareTo(a.startTime));
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BannerHeader(
                title: 'Mi Historial',
                subtitle: '${sessions.length} sesiones',
                icon: Icons.bar_chart,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WeeklyChart(sessions: sessions),
                    const SizedBox(height: 20),
                    const Text(
                      'Sesiones',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0A0A0A)),
                    ),
                    const SizedBox(height: 12),
              Row(
                children: [
                  _buildFilterButton('📅 Más reciente', 'fecha'),
                  const SizedBox(width: 8),
                  _buildFilterButton('↓ Más pasos', 'mas'),
                  const SizedBox(width: 8),
                  _buildFilterButton('↑ Menos pasos', 'menos'),
                ],
              ),
              const SizedBox(height: 16),
              if (sorted.isEmpty)
                _EmptyState()
              else
                ...sorted.map((s) => _SessionCard(session: s)).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<ActivitySession> sessions;
  const _WeeklyChart({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return DateTime(day.year, day.month, day.day);
    });

    final stepsPerDay = {for (final d in days) d: 0};
    for (final session in sessions) {
      final key = DateTime(
          session.startTime.year,
          session.startTime.month,
          session.startTime.day);
      if (stepsPerDay.containsKey(key)) {
        stepsPerDay[key] = stepsPerDay[key]! + session.steps;
      }
    }

    final values = days.map((d) => stepsPerDay[d]!.toDouble()).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final labels = days
        .map((d) => ['L', 'M', 'X', 'J', 'V', 'S', 'D'][d.weekday - 1])
        .toList();

    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8E8E8), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Semana actual',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0A0A0A))),
            const SizedBox(height: 12),
            SizedBox(
              height: 108,
              child: CustomPaint(
                painter: _BarChartPainter(
                  values: values,
                  labels: labels,
                  maxVal: maxVal == 0 ? 1 : maxVal,
                  color: const Color(0xFFFF6B00),
                ),
                size: Size.infinite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double maxVal;
  final Color color;

  _BarChartPainter({
    required this.values,
    required this.labels,
    required this.maxVal,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()..color = color;
    final emptyPaint = Paint()..color = const Color(0xFFE8E8E8);
    final textStyle = const TextStyle(color: Color(0xFF999999), fontSize: 11);

    final chartHeight = size.height - 20;
    final barWidth = (size.width / values.length) * 0.5;
    final gap = (size.width / values.length) * 0.5;

    for (int i = 0; i < values.length; i++) {
      final x = i * (barWidth + gap) + gap / 2;
      final barHeight = (values[i] / maxVal) * chartHeight;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, barWidth, chartHeight),
          const Radius.circular(4),
        ),
        emptyPaint,
      );

      if (barHeight > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
                x, chartHeight - barHeight, barWidth, barHeight),
            const Radius.circular(4),
          ),
          barPaint,
        );
      }

      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x + barWidth / 2 - tp.width / 2, chartHeight + 4),
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.values != values;
}

class _SessionCard extends StatelessWidget {
  final ActivitySession session;
  const _SessionCard({required this.session});

  IconData _activityIcon(String type) {
    switch (type) {
      case 'running':
        return Icons.directions_run;
      case 'walking':
        return Icons.directions_walk;
      default:
        return Icons.accessibility_new;
    }
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'running':
        return const Color(0xFFFF6B00);
      case 'walking':
        return const Color(0xFF555555);
      default:
        return const Color(0xFF999999);
    }
  }

  Color _activityBgColor(String type) {
    switch (type) {
      case 'running':
        return const Color(0x1AFF6B00);
      case 'walking':
        return const Color(0xFFF0F0F0);
      default:
        return const Color(0xFFF0F0F0);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}h ${m}m' : '${m}:${s}';
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: session.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE8E8E8), width: 1),
        ),
        title: const Text('Renombrar sesión', style: TextStyle(color: Color(0xFF0A0A0A))),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Color(0xFF0A0A0A)),
          decoration: const InputDecoration(
            labelText: 'Nombre',
            labelStyle: TextStyle(color: Color(0xFF555555)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE8E8E8))),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF6B00))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF555555))),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context
                    .read<HistoryBloc>()
                    .add(HistorySessionRenamed(session.id, name));
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Color(0xFFCC0000)),
      ),
      onDismissed: (_) {
        context.read<HistoryBloc>().add(HistorySessionDeleted(session.id));
      },
      child: Card(
        color: const Color(0xFFFFFFFF),
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE8E8E8), width: 1),
        ),
        elevation: 0,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: session.activityType == 'running'
                    ? const Color(0xFFFF6B00)
                    : session.activityType == 'walking'
                        ? const Color(0xFF555555)
                        : const Color(0xFFCCCCCC),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _activityBgColor(session.activityType),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_activityIcon(session.activityType),
                    color: _activityColor(session.activityType), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.name,
                        style: const TextStyle(
                            color: Color(0xFF0A0A0A),
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDuration(session.duration)}  ·  ${session.steps} pasos  ·  ${session.calories.toStringAsFixed(1)} cal',
                      style: const TextStyle(color: Color(0xFF555555), fontSize: 12),
                    ),
                    Text(
                      '${session.startTime.day}/${session.startTime.month}/${session.startTime.year}',
                      style: const TextStyle(color: Color(0xFF999999), fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _showRenameDialog(context),
                color: const Color(0xFF999999),
              ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.bar_chart_outlined, size: 64, color: Color(0xFFE8E8E8)),
            const SizedBox(height: 12),
            const Text('Sin sesiones guardadas',
                style: TextStyle(color: Color(0xFF999999), fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Inicia una actividad en la pestaña Actividad',
                style: TextStyle(color: Color(0xFF999999), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
