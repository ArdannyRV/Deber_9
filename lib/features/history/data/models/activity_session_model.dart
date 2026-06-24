import '../../domain/entities/activity_session.dart';

class ActivitySessionModel extends ActivitySession {
  const ActivitySessionModel({
    required super.id,
    required super.name,
    required super.startTime,
    required super.endTime,
    required super.activityType,
    required super.steps,
    required super.distanceKm,
    required super.calories,
  });

  factory ActivitySessionModel.fromEntity(ActivitySession session) {
    return ActivitySessionModel(
      id: session.id,
      name: session.name,
      startTime: session.startTime,
      endTime: session.endTime,
      activityType: session.activityType,
      steps: session.steps,
      distanceKm: session.distanceKm,
      calories: session.calories,
    );
  }

  factory ActivitySessionModel.fromJson(Map<String, dynamic> json) {
    return ActivitySessionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      activityType: json['activityType'] as String,
      steps: json['steps'] as int,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'activityType': activityType,
      'steps': steps,
      'distanceKm': distanceKm,
      'calories': calories,
    };
  }
}
