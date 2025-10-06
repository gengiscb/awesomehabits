import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../core/date_key.dart';
import '../../domain/habits/habit.dart';
import '../../domain/habits/habit_repository.dart';
import '../../infrastructure/habits/firestore_habit_repository.dart';
import '../../infrastructure/auth/auth_service.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.read(authServiceProvider);
  return authService.authStateChanges;
});

// Repository provider — uses Firestore
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return FirestoreHabitRepository();
});

class HabitListController extends AsyncNotifier<List<Habit>> {
  late final HabitRepository _repo = ref.read(habitRepositoryProvider);

  @override
  Future<List<Habit>> build() async {
    // Watch auth state and return empty list if not authenticated
    final authState = await ref.watch(authStateProvider.future);
    if (authState == null) {
      return <Habit>[];
    }

    // Use stream-based approach with Firestore
    final habitStream = _repo.watchHabits();
    return habitStream.first;
  }

  Future<void> addHabit(String name) async {
    final newHabit = Habit(
      id: const Uuid().v4(),
      name: name.trim(),
      ownerId: '', // Will be set by repository
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repo.addHabit(newHabit);
    // Refresh the list
    ref.invalidateSelf();
  }

  Future<void> toggleToday(String habitId) async {
    final habits = state.value ?? const <Habit>[];
    final habit = habits.where((h) => h.id == habitId).firstOrNull;
    if (habit == null) return;
    
    final today = DateKey.today();
    final updatedHabit = habit.toggleCompletion(today);
    await _repo.updateHabit(updatedHabit);
    // Refresh the list
    ref.invalidateSelf();
  }

  Future<void> deleteHabit(String habitId) async {
    await _repo.deleteHabit(habitId);
    // Refresh the list
    ref.invalidateSelf();
  }
}

// Stream provider for habits that automatically updates
final habitStreamProvider = StreamProvider<List<Habit>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(<Habit>[]);
      }
      final repo = ref.read(habitRepositoryProvider);
      return repo.watchHabits();
    },
    loading: () => Stream.value(<Habit>[]),
    error: (_, __) => Stream.value(<Habit>[]),
  );
});

final habitListControllerProvider =
    AsyncNotifierProvider<HabitListController, List<Habit>>(HabitListController.new);
