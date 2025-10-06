import 'dart:convert';

/// Domain entity: Habit
class Habit {
  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;
  /// Map of yyyy-MM-dd -> true for completed days
  final Map<String, bool> completions;

  const Habit({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.archived = false,
    this.completions = const {},
  });

  Habit copyWith({
    String? id,
    String? name,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
    Map<String, bool>? completions,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
      completions: completions ?? this.completions,
    );
  }

  bool isCompletedOn(String dateKey) => completions[dateKey] == true;

  Habit toggleCompletion(String dateKey) {
    final newMap = Map<String, bool>.from(completions);
    if (newMap[dateKey] == true) {
      newMap.remove(dateKey);
    } else {
      newMap[dateKey] = true;
    }
    return copyWith(
      completions: newMap,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'ownerId': ownerId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'archived': archived,
        'completions': completions,
      };

  String toJson() => jsonEncode(toMap());

  static Habit fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      name: map['name'] as String,
      ownerId: map['ownerId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      archived: (map['archived'] as bool?) ?? false,
      completions: (map['completions'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v == true)) ??
          const {},
    );
  }

  static Habit fromJson(String source) => fromMap(jsonDecode(source));
}
