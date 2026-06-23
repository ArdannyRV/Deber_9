import 'package:equatable/equatable.dart';

class ActivitySession extends Equatable {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final String activityType;
  final int steps;
  final double distanceKm;
  final double calories;

  const ActivitySession({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.activityType,
    required this.steps,
    required this.distanceKm,
    required this.calories,
  });

  Duration get duration => endTime.difference(startTime);

  ActivitySession copyWith({String? name}) {
    return ActivitySession(
      id: id,
      name: name ?? this.name,
      startTime: startTime,
      endTime: endTime,
      activityType: activityType,
      steps: steps,
      distanceKm: distanceKm,
      calories: calories,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, startTime, endTime, activityType, steps, distanceKm, calories];
}
