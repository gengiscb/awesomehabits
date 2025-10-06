import 'habit.dart';

/// Abstract repository defining persistence-agnostic operations for Habits.
abstract class HabitRepository {
  // Legacy methods for backward compatibility
  Future<List<Habit>> fetchAll();
  Future<void> saveAll(List<Habit> habits);
  
  // New stream-based and individual operations for Firebase
  Stream<List<Habit>> watchHabits();
  Future<void> addHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  Future<void> deleteHabit(String habitId);
}
