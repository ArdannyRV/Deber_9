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
}
