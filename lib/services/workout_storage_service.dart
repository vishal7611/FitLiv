import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_session.dart';

class WorkoutStorageService {
  static const String _key = 'workout_sessions';

  static Future<void> saveSession(WorkoutSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existing = prefs.getStringList(_key) ?? [];
    existing.add(jsonEncode(session.toMap()));
    await prefs.setStringList(_key, existing);
  }

  static Future<List<WorkoutSession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> strings = prefs.getStringList(_key) ?? [];
    return strings.map((s) => WorkoutSession.fromMap(jsonDecode(s))).toList();
  }
}