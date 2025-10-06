import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/habits/habit.dart';
import '../../domain/habits/habit_repository.dart';

class SharedPrefsHabitRepository implements HabitRepository {
  static const _key = 'habits_v1';

  @override
  Future<List<Habit>> fetchAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((m) => Habit.fromMap(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveAll(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final list = habits.map((h) => h.toMap()).toList();
    await prefs.setString(_key, jsonEncode(list));
  }

  // New methods - basic implementation for compatibility
  @override
  Stream<List<Habit>> watchHabits() async* {
    yield await fetchAll();
  }

  @override
  Future<void> addHabit(Habit habit) async {
    final habits = await fetchAll();
    // For SharedPrefs, we'll use a default ownerId since we don't have auth
    final habitWithDefaults = habit.copyWith(
      ownerId: habit.ownerId.isEmpty ? 'local_user' : habit.ownerId,
    );
    habits.add(habitWithDefaults);
    await saveAll(habits);
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final habits = await fetchAll();
    final index = habits.indexWhere((h) => h.id == habit.id);
    if (index >= 0) {
      habits[index] = habit;
      await saveAll(habits);
    }
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    final habits = await fetchAll();
    habits.removeWhere((h) => h.id == habitId);
    await saveAll(habits);
  }
}
