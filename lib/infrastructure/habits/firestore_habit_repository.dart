import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesomehabits/domain/habits/habit.dart';
import 'package:awesomehabits/domain/habits/habit_repository.dart';
import 'package:awesomehabits/firestore/firestore_data_schema.dart';

class FirestoreHabitRepository implements HabitRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreHabitRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // Legacy methods for backward compatibility
  @override
  Future<List<Habit>> fetchAll() async {
    final userId = _currentUserId;
    if (userId == null) return <Habit>[];

    final snapshot = await _firestore
        .collection(FirestoreCollections.habits)
        .where(HabitFields.ownerId, isEqualTo: userId)
        .where(HabitFields.archived, isEqualTo: false)
        .orderBy(HabitFields.createdAt, descending: true)
        .limit(100)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return _habitFromFirestore(data);
    }).toList();
  }

  @override
  Future<void> saveAll(List<Habit> habits) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be authenticated to save habits');
    }

    final batch = _firestore.batch();
    for (final habit in habits) {
      final habitWithOwner = habit.copyWith(ownerId: userId);
      final docRef = _firestore
          .collection(FirestoreCollections.habits)
          .doc(habit.id);
      batch.set(docRef, _habitToFirestore(habitWithOwner));
    }
    await batch.commit();
  }

  @override
  Stream<List<Habit>> watchHabits() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(<Habit>[]);
    }

    return _firestore
        .collection(FirestoreCollections.habits)
        .where(HabitFields.ownerId, isEqualTo: userId)
        .where(HabitFields.archived, isEqualTo: false)
        .orderBy(HabitFields.createdAt, descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _habitFromFirestore(data);
      }).toList();
    });
  }

  @override
  Future<void> addHabit(Habit habit) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be authenticated to add habits');
    }

    final habitWithOwner = habit.copyWith(ownerId: userId);
    final docData = _habitToFirestore(habitWithOwner);

    await _firestore
        .collection(FirestoreCollections.habits)
        .doc(habit.id)
        .set(docData);
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be authenticated to update habits');
    }

    if (habit.ownerId != userId) {
      throw Exception('User can only update their own habits');
    }

    final updatedHabit = habit.copyWith(updatedAt: DateTime.now());
    final docData = _habitToFirestore(updatedHabit);

    await _firestore
        .collection(FirestoreCollections.habits)
        .doc(habit.id)
        .update(docData);
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be authenticated to delete habits');
    }

    // First check if the habit belongs to the current user
    final doc = await _firestore
        .collection(FirestoreCollections.habits)
        .doc(habitId)
        .get();

    if (!doc.exists) {
      throw Exception('Habit not found');
    }

    final data = doc.data()!;
    if (data[HabitFields.ownerId] != userId) {
      throw Exception('User can only delete their own habits');
    }

    await _firestore
        .collection(FirestoreCollections.habits)
        .doc(habitId)
        .delete();
  }

  Map<String, dynamic> _habitToFirestore(Habit habit) => {
        HabitFields.id: habit.id,
        HabitFields.name: habit.name,
        HabitFields.ownerId: habit.ownerId,
        HabitFields.createdAt: Timestamp.fromDate(habit.createdAt),
        HabitFields.updatedAt: Timestamp.fromDate(habit.updatedAt),
        HabitFields.archived: habit.archived,
        HabitFields.completions: habit.completions,
      };

  Habit _habitFromFirestore(Map<String, dynamic> data) {
    return Habit(
      id: data[HabitFields.id] as String,
      name: data[HabitFields.name] as String,
      ownerId: data[HabitFields.ownerId] as String,
      createdAt: (data[HabitFields.createdAt] as Timestamp).toDate(),
      updatedAt: (data[HabitFields.updatedAt] as Timestamp).toDate(),
      archived: data[HabitFields.archived] as bool? ?? false,
      completions: (data[HabitFields.completions] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v == true)) ??
          const <String, bool>{},
    );
  }
}