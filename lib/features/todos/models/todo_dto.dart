import 'package:hive/hive.dart';

part 'todo_dto.g.dart';

/// Data Transfer Object for Todo
///
/// This is the storage representation of a todo, optimized for Hive.
/// It contains only serializable data types.
@HiveType(typeId: 0)
class TodoDTO extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final bool isCompleted;

  @HiveField(4)
  final int createdAt; // Stored as milliseconds since epoch

  @HiveField(5)
  final int? updatedAt; // Stored as milliseconds since epoch

  TodoDTO({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  String toString() {
    return 'TodoDTO(id: $id, title: $title, description: $description, isCompleted: $isCompleted, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
