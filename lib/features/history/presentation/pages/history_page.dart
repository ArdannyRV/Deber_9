import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/history_bloc.dart';
import '../../domain/entities/activity_session.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        final sessions =
            state is HistoryLoaded ? state.sessions : <ActivitySession>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WeeklyChart(sessions: sessions),
              const SizedBox(height: 20),
              Text(
                'Sesiones (${sessions.length})',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (sessions.isEmpty)
                _EmptyState()
              else
                ...sessions.map((s) => _SessionCard(session: s)).toList(),
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pasos esta semana',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: CustomPaint(
                painter: _BarChartPainter(
                  values: values,
                  labels: labels,
                  maxVal: maxVal == 0 ? 1 : maxVal,
                  color: const Color(0xFF6366F1),
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
    final emptyPaint = Paint()..color = color.withOpacity(0.12);
    final textStyle = const TextStyle(color: Colors.grey, fontSize: 11);

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
        return Colors.orange;
      case 'walking':
        return Colors.blue;
      default:
        return Colors.grey;
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
        title: const Text('Renombrar sesión'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
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
    final color = _activityColor(session.activityType);

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<HistoryBloc>().add(HistorySessionDeleted(session.id));
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_activityIcon(session.activityType),
                    color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDuration(session.duration)}  ·  ${session.steps} pasos  ·  ${session.calories.toStringAsFixed(1)} cal',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      '${session.startTime.day}/${session.startTime.month}/${session.startTime.year}',
                      style:
                          TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _showRenameDialog(context),
                color: Colors.grey[500],
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
            Icon(Icons.history, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Sin sesiones guardadas',
                style: TextStyle(color: Colors.grey[400], fontSize: 15)),
            const SizedBox(height: 4),
            Text('Inicia una actividad en la pestaña Actividad',
                style: TextStyle(color: Colors.grey[300], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
