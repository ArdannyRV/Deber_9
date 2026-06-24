import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/data/datasources/accelerometer_datasource.dart';
import '../../../auth/domain/entities/step_data.dart';
import '../../../../features/history/domain/entities/activity_session.dart';
import '../../../../features/history/presentation/bloc/history_bloc.dart';

/// Widget que muestra el contador de pasos
///
/// EXPLICACIÓN DIDÁCTICA:
/// - Usa StreamSubscription para escuchar el EventChannel
/// - Actualiza UI cada vez que llegan nuevos datos
class StepCounterWidget extends StatefulWidget {
  const StepCounterWidget({super.key});

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget> {
  final AccelerometerDataSource _dataSource = AccelerometerDataSourceImpl();

  StreamSubscription<StepData>? _subscription;
  StepData? _currentData;
  bool _isTracking = false;
  DateTime? _startTime;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _toggleTracking() {
    if (_isTracking) {
      _stopTracking();
    } else {
      _startTracking();
    }
  }

  void _startTracking() async {
    // Solicitar permisos
    final hasPermission = await _dataSource.requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permisos de sensores denegados'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await _dataSource.startCounting();
    _startTime = DateTime.now();

    // SUSCRIBIRSE AL STREAM
    _subscription = _dataSource.stepStream.listen(
      (data) {
        setState(() {
          _currentData = data;
        });
      },
      onError: (error) {
        print('Error en stream: $error');
      },
    );

    setState(() {
      _isTracking = true;
    });
  }

  void _stopTracking() async {
    await _dataSource.stopCounting();
    _subscription?.cancel();

    if ((_currentData?.stepCount ?? 0) > 0) {
      final session = ActivitySession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Sesión de pasos',
        startTime: _startTime!,
        endTime: DateTime.now(),
        activityType: _currentData?.activityType.name ?? 'stationary',
        steps: _currentData?.stepCount ?? 0,
        distanceKm: 0,
        calories: _currentData?.estimatedCalories ?? 0,
      );
      if (context.mounted) {
        context.read<HistoryBloc>().add(HistorySessionAdded(session));
      }
    }

    setState(() {
      _isTracking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8E8E8), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.directions_walk, color: Color(0xFFFF6B00), size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Contador de Pasos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0A0A0A)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _toggleTracking,
                  icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                  label: Text(_isTracking ? 'Detener' : 'Iniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking ? const Color(0xFFF5F5F5) : const Color(0xFFFF6B00),
                    foregroundColor: _isTracking ? const Color(0xFFFF6B00) : Colors.white,
                    side: _isTracking ? const BorderSide(color: Color(0xFFFF6B00)) : null,
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: Color(0xFFE8E8E8)),

            // Pasos y calorías en una sola fila
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Pasos (izquierda)
                Column(
                  children: [
                    Text(
                      '${_currentData?.stepCount ?? 0}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF6B00),
                      ),
                    ),
                    const Text(
                      'pasos',
                      style: TextStyle(fontSize: 16, color: Color(0xFF999999)),
                    ),
                  ],
                ),

                // Separador vertical
                Container(
                  height: 60,
                  width: 1,
                  color: const Color(0xFFE8E8E8),
                ),

                // Calorías (derecha)
                Column(
                  children: [
                    Text(
                      '${_currentData?.estimatedCalories.toStringAsFixed(1) ?? "0"}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF6B00),
                      ),
                    ),
                    const Text(
                      'cal',
                      style: TextStyle(fontSize: 16, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
