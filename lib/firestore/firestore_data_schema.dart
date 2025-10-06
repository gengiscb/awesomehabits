// Firestore Data Schema for AwesomeHabits app
//
// This file defines the structure of documents stored in Firestore
// and provides type-safe access to collection and field names.

class FirestoreCollections {
  static const String habits = 'habits';
}

class HabitFields {
  static const String id = 'id';
  static const String name = 'name';
  static const String ownerId = 'owner_id';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String archived = 'archived';
  static const String completions = 'completions';
}

// Firestore document structure for Habit
//
// Collection: habits
// Document ID: auto-generated
// Fields:
// - id: String - unique habit identifier
// - name: String - habit name
// - owner_id: String - user ID who owns this habit
// - createdAt: Timestamp - when habit was created
// - updatedAt: Timestamp - when habit was last modified
// - archived: bool - whether habit is archived
// - completions: Map<String, bool> - map of date strings to completion status
class HabitDocument {
  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;
  final Map<String, bool> completions;

  const HabitDocument({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
    required this.completions,
  });

  Map<String, dynamic> toFirestore() => {
        HabitFields.id: id,
        HabitFields.name: name,
        HabitFields.ownerId: ownerId,
        HabitFields.createdAt: createdAt,
        HabitFields.updatedAt: updatedAt,
        HabitFields.archived: archived,
        HabitFields.completions: completions,
      };

  static HabitDocument fromFirestore(Map<String, dynamic> data) {
    return HabitDocument(
      id: data[HabitFields.id] as String,
      name: data[HabitFields.name] as String,
      ownerId: data[HabitFields.ownerId] as String,
      createdAt: (data[HabitFields.createdAt] as DateTime),
      updatedAt: (data[HabitFields.updatedAt] as DateTime),
      archived: data[HabitFields.archived] as bool? ?? false,
      completions: (data[HabitFields.completions] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v == true)) ??
          const <String, bool>{},
    );
  }
}
