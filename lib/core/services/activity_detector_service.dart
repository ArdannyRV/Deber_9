import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:rxdart/rxdart.dart';

enum ActivityState {
  stationary,
  walking,
  running,
}

class ActivityDetectorService {
  final _activityController = BehaviorSubject<ActivityState>.seeded(ActivityState.stationary);
  final _fallController = PublishSubject<void>();

  StreamSubscription? _accelerometerSubscription;
  
  DateTime? _lastRunTime;
  DateTime? _lastWalkTime;
  
  // Configuración de umbrales
  static const double _walkingThreshold = 13.0;
  static const double _runningThreshold = 21.0;
  static const double _fallThreshold = 55.0; 

  ActivityState _lastEmittedState = ActivityState.stationary;
  ActivityState _pendingState = ActivityState.stationary;
  Timer? _debounceTimer;

  Stream<void> get fallStream => _fallController.stream;

  void startDetection() {
    if (_accelerometerSubscription != null) return;

    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final magnitude = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
      final now = DateTime.now();
      
      if (magnitude > _fallThreshold) {
        _fallController.add(null);
      }

      if (magnitude > _runningThreshold) {
        _lastRunTime = now;
        _lastWalkTime = now;
      } else if (magnitude > _walkingThreshold) {
        _lastWalkTime = now;
      } else {
        if (_lastRunTime != null &&
            now.difference(_lastRunTime!).inMilliseconds > 1500) {
          _lastRunTime = null;
        }
        if (_lastWalkTime != null &&
            now.difference(_lastWalkTime!).inMilliseconds > 2000) {
          _lastWalkTime = null;
        }
      }

      ActivityState calculatedState;
      if (_lastRunTime != null && now.difference(_lastRunTime!).inMilliseconds < 1500) {
        calculatedState = ActivityState.running;
      } else if (_lastWalkTime != null && now.difference(_lastWalkTime!).inMilliseconds < 2000) {
        calculatedState = ActivityState.walking;
      } else {
        calculatedState = ActivityState.stationary;
      }

      _handleStateTransition(calculatedState);
    });
  }

  void _handleStateTransition(ActivityState newState) {
    if (newState == _pendingState) return;
    _pendingState = newState;
    _debounceTimer?.cancel();
    if (newState == _lastEmittedState) return;

    int oldIntensity = _lastEmittedState.index;
    int newIntensity = newState.index;

    final delay = newIntensity > oldIntensity
        ? const Duration(milliseconds: 600)
        : const Duration(milliseconds: 2000);

    _debounceTimer = Timer(delay, () {
      _lastEmittedState = newState;
      _activityController.add(newState);
    });
  }

  void stopDetection() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _lastRunTime = null;
    _lastWalkTime = null;
    _debounceTimer?.cancel();
  }

  Stream<ActivityState> get debouncedActivityStream {
    return _activityController.stream.distinct();
  }
}
