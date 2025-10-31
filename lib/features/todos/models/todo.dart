import 'todo_dto.dart';

/// Domain model for a Todo item
///
/// This is the business logic representation of a todo.
/// It is immutable and contains all the business rules and conversions.
class Todo {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create a copy of this Todo with some fields updated
  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert domain model to DTO for storage
  TodoDTO toDTO() {
    return TodoDTO(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted,
      createdAt: createdAt.millisecondsSinceEpoch,
      updatedAt: updatedAt?.millisecondsSinceEpoch,
    );
  }

  /// Create domain model from DTO
  factory Todo.fromDTO(TodoDTO dto) {
    return Todo(
      id: dto.id,
      title: dto.title,
      description: dto.description,
      isCompleted: dto.isCompleted,
      createdAt: DateTime.fromMillisecondsSinceEpoch(dto.createdAt),
      updatedAt: dto.updatedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(dto.updatedAt!)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Todo &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.isCompleted == isCompleted &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        isCompleted.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, description: $description, isCompleted: $isCompleted, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
