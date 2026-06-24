import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_session_model.dart';
import '../../domain/entities/activity_session.dart';

class HistoryLocalDatasource {
  static final HistoryLocalDatasource _instance =
      HistoryLocalDatasource._internal();
  factory HistoryLocalDatasource() => _instance;
  HistoryLocalDatasource._internal();

  static const String _storageKey = 'activity_sessions';

  Future<List<ActivitySessionModel>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((json) => ActivitySessionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save(List<ActivitySessionModel> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  Future<List<ActivitySession>> getAll() async {
    final sessions = await _load();
    return List.unmodifiable(sessions);
  }

  Future<void> add(ActivitySession session) async {
    final sessions = await _load();
    sessions.insert(0, ActivitySessionModel.fromEntity(session));
    await _save(sessions);
  }

  Future<void> updateName(String id, String newName) async {
    final sessions = await _load();
    final index = sessions.indexWhere((s) => s.id == id);
    if (index != -1) {
      final updated = ActivitySessionModel.fromEntity(
        sessions[index].copyWith(name: newName),
      );
      sessions[index] = updated;
      await _save(sessions);
    }
  }

  Future<void> delete(String id) async {
    final sessions = await _load();
    sessions.removeWhere((s) => s.id == id);
    await _save(sessions);
  }
}
