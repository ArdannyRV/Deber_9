import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/step_data.dart';

abstract class AccelerometerDataSource {
  Stream<StepData> get stepStream;
  Future<void> startCounting();
  Future<void> stopCounting();
  Future<bool> requestPermissions();
}

class AccelerometerDataSourceImpl implements AccelerometerDataSource {
  // Umbrales de detección (no modificar)
  static const double _walkingThreshold = 13.0;
  static const double _runningThreshold = 19.0;

  // Estado interno
  int _stepCount = 0;
  double _lastMagnitude = 0.0;
  final List<double> _magnitudeHistory = [];
  static const int _historySize = 10;
  int _sampleCount = 0;
  String _lastActivityType = 'stationary';
  int _activityConfidence = 0;

  final StreamController<StepData> _controller =
      StreamController<StepData>.broadcast();

  StreamSubscription? _sensorSubscription;

  @override
  Stream<StepData> get stepStream => _controller.stream;

  @override
  Future<void> startCounting() async {
    if (_sensorSubscription != null) return;

    _stepCount = 0;
    _lastMagnitude = 0.0;
    _magnitudeHistory.clear();
    _sampleCount = 0;
    _lastActivityType = 'stationary';
    _activityConfidence = 0;

    _sensorSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      final x = event.x;
      final y = event.y;
      final z = event.z;
      final magnitude = sqrt(x * x + y * y + z * z);

      // Promedio móvil
      _magnitudeHistory.add(magnitude);
      if (_magnitudeHistory.length > _historySize) {
        _magnitudeHistory.removeAt(0);
      }
      final avgMagnitude =
          _magnitudeHistory.reduce((a, b) => a + b) / _magnitudeHistory.length;

      // Detección de paso por cruce de umbral
      if (magnitude > 12.0 && _lastMagnitude <= 12.0) {
        _stepCount++;
      }
      _lastMagnitude = magnitude;

      // Clasificación de actividad con promedio móvil
      final newActivityType = avgMagnitude < _walkingThreshold
          ? 'stationary'
          : avgMagnitude < _runningThreshold
              ? 'walking'
              : 'running';

      // Confianza: requiere 3 lecturas consecutivas iguales para cambiar
      if (newActivityType == _lastActivityType) {
        _activityConfidence++;
      } else {
        _activityConfidence = 0;
      }
      final finalActivityType =
          _activityConfidence >= 3 ? newActivityType : _lastActivityType;
      _lastActivityType = newActivityType;

      // Emitir cada 3 muestras
      _sampleCount++;
      if (_sampleCount >= 3) {
        _sampleCount = 0;
        _controller.add(StepData(
          stepCount: _stepCount,
          activityType: _parseActivityType(finalActivityType),
          magnitude: avgMagnitude,
        ));
      }
    });
  }

  @override
  Future<void> stopCounting() async {
    await _sensorSubscription?.cancel();
    _sensorSubscription = null;
  }

  @override
  Future<bool> requestPermissions() async {
    final activityStatus = await Permission.activityRecognition.request();
    final sensorsStatus = await Permission.sensors.request();
    return activityStatus.isGranted && sensorsStatus.isGranted;
  }

  ActivityType _parseActivityType(String type) {
    switch (type) {
      case 'walking':
        return ActivityType.walking;
      case 'running':
        return ActivityType.running;
      default:
        return ActivityType.stationary;
    }
  }
}
