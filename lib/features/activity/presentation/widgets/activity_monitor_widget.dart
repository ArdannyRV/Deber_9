import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/activity_detector_service.dart';
import '../../../../core/services/voice_service.dart';

class ActivityMonitorWidget extends StatefulWidget {
  const ActivityMonitorWidget({super.key});

  @override
  State<ActivityMonitorWidget> createState() => _ActivityMonitorWidgetState();
}

class _ActivityMonitorWidgetState extends State<ActivityMonitorWidget> {
  final ActivityDetectorService _activityService = ActivityDetectorService();
  final VoiceService _voiceService = VoiceService();

  StreamSubscription<ActivityState>? _activitySub;
  StreamSubscription<void>? _fallSub;

  ActivityState _currentState = ActivityState.stationary;
  bool _isMonitoring = false;
  bool _isEmergencyActive = false;

  @override
  void initState() {
    super.initState();
    _voiceService.init();
  }

  @override
  void dispose() {
    _stopMonitoring();
    super.dispose();
  }

  void _toggleMonitoring() {
    if (_isMonitoring) {
      _stopMonitoring();
    } else {
      _startMonitoring();
    }
  }

  void _startMonitoring() {
    _activityService.startDetection();

    // Escuchar cambios de actividad con DEBOUNCE
    _activitySub = _activityService.debouncedActivityStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
        });
        
        // Mute normal announcements if fall emergency is active
        if (!_isEmergencyActive) {
          _voiceService.announceActivity(state);
        }
      }
    });

    // Escuchar caídas
    _fallSub = _activityService.fallStream.listen((_) {
      _handleFallDetected();
    });

    setState(() {
      _isMonitoring = true;
    });
  }

  void _stopMonitoring() {
    _activityService.stopDetection();
    _activitySub?.cancel();
    _fallSub?.cancel();

    setState(() {
      _isMonitoring = false;
      _currentState = ActivityState.stationary;
    });
  }

  Future<void> _handleFallDetected() async {
    // Evitar múltiples diálogos
    if (_isEmergencyActive) return;

    setState(() {
      _isEmergencyActive = true;
    });

    _voiceService.announceFall();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const FallEmergencyDialog();
      },
    );

    if (mounted) {
      setState(() {
        _isEmergencyActive = false;
      });
    }
  }

  String _getActivityName(ActivityState state) {
    switch (state) {
      case ActivityState.stationary:
        return "Quieto";
      case ActivityState.walking:
        return "Caminando";
      case ActivityState.running:
        return "Corriendo";
    }
  }

  IconData _getActivityIcon(ActivityState state) {
    switch (state) {
      case ActivityState.stationary:
        return Icons.accessibility_new;
      case ActivityState.walking:
        return Icons.directions_walk;
      case ActivityState.running:
        return Icons.directions_run;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isMonitoring ? Colors.transparent : const Color(0xFFE8E8E8),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: _isMonitoring
              ? const LinearGradient(
                  colors: [Color(0xFF0A0A0A), Color(0xFF1F1F1F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _isMonitoring ? null : const Color(0xFFFFFFFF),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt, color: Color(0xFFFF6B00), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Monitor de Actividad',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _isMonitoring ? Colors.white : const Color(0xFF0A0A0A),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _toggleMonitoring,
                  icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
                  label: Text(_isMonitoring ? 'Detener' : 'Iniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMonitoring ? const Color(0xFF1A1A1A) : const Color(0xFFFF6B00),
                    foregroundColor: _isMonitoring ? const Color(0xFFFF6B00) : Colors.white,
                    side: _isMonitoring ? const BorderSide(color: Color(0xFFFF6B00)) : null,
                  ),
                ),
              ],
            ),
            Divider(color: _isMonitoring ? const Color(0xFF333333) : const Color(0xFFE8E8E8)),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.all(_currentState == ActivityState.running ? 16.0 : 12.0),
              decoration: BoxDecoration(
                color: _isMonitoring ? const Color(0xFFFF6B00) : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: _currentState == ActivityState.running
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF6B00).withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 5,
                        )
                      ]
                    : [],
              ),
              child: Icon(
                _getActivityIcon(_currentState),
                size: 40,
                color: _isMonitoring ? Colors.white : const Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isMonitoring ? _getActivityName(_currentState) : 'Inactivo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isMonitoring ? Colors.white : const Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FallEmergencyDialog extends StatefulWidget {
  const FallEmergencyDialog({super.key});

  @override
  State<FallEmergencyDialog> createState() => _FallEmergencyDialogState();
}

class _FallEmergencyDialogState extends State<FallEmergencyDialog> {
  Timer? _timer;
  int _secondsLeft = 15;
  bool _isEmergency = false;
  final VoiceService _voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _timer?.cancel();
          _triggerEmergency();
        }
      });
    });
  }

  void _triggerEmergency() {
    setState(() {
      _isEmergency = true;
    });
    _voiceService.announceFallEmergency();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8E8E8), width: 1),
      ),
      title: Text(
        _isEmergency ? "¡EMERGENCIA!" : "¿Estás bien?",
        style: TextStyle(
          color: _isEmergency ? const Color(0xFFFF6B00) : const Color(0xFF0A0A0A),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 64,
            color: Color(0xFFFF6B00),
          ),
          const SizedBox(height: 16),
          Text(
            _isEmergency
                ? "Llamando a contacto de emergencia..."
                : "Se detectó una posible caída. ¿Necesitas ayuda?",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF555555)),
          ),
          if (!_isEmergency) ...[
            const SizedBox(height: 16),
            Text(
              "$_secondsLeft s",
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0A0A0A)),
            ),
          ]
        ],
      ),
      actions: [
        if (!_isEmergency)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Estoy bien", style: TextStyle(color: Color(0xFF555555))),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Lógica adicional para llamar emergencia
          },
          child: Text(
            _isEmergency ? "Cerrar" : "Llamar ahora",
            style: const TextStyle(color: Color(0xFFFF6B00)),
          ),
        ),
      ],
    );
  }
}
