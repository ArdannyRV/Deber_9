import '../models/activity_session_model.dart';
import '../../domain/entities/activity_session.dart';

class HistoryLocalDatasource {
  static final HistoryLocalDatasource _instance =
      HistoryLocalDatasource._internal();
  factory HistoryLocalDatasource() => _instance;
  HistoryLocalDatasource._internal();

  final List<ActivitySessionModel> _sessions = [];

  List<ActivitySession> getAll() => List.unmodifiable(_sessions);

  void add(ActivitySession session) {
    _sessions.insert(0, ActivitySessionModel.fromEntity(session));
  }

  void updateName(String id, String newName) {
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index != -1) {
      final updated = ActivitySessionModel.fromEntity(
        _sessions[index].copyWith(name: newName),
      );
      _sessions[index] = updated;
    }
  }

  void delete(String id) {
    _sessions.removeWhere((s) => s.id == id);
  }
}
