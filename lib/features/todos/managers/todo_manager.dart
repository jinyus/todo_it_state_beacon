// ignore_for_file: prefer_collection_literals

import 'dart:collection';

import 'package:state_beacon/state_beacon.dart';
import 'package:uuid/uuid.dart';

import '../models/todo.dart';
import '../../../services/storage/hive_storage_service.dart';

/// Manager for todo business logic
///
/// This class contains all the business logic for managing todos.
/// It uses state_beacon for reactive state management
class TodoManager with BeaconController {
  final HiveStorageService _storageService;
  final Uuid _uuid = const Uuid();

  late final selectedTodo = B.writable<Todo?>(null);
  late final currentFilter = B.writable<TodoFilter>(TodoFilter.all);

  TodoManager(this._storageService) {
    todos.start();
  }

  late final todos = B.future(_loadTodos, manualStart: true);

  LinkedHashMap<String, Todo> get todoMap =>
      todos.lastData ?? LinkedHashMap<String, Todo>();

  LinkedHashMap<String, Todo> toMap(Iterable<Todo> todos) {
    return LinkedHashMap<String, Todo>.fromIterable(
      todos,
      key: (todo) => todo.id,
      value: (todo) => todo,
    );
  }

  Future<LinkedHashMap<String, Todo>> _loadTodos() async {
    final dtos = await _storageService.getAllTodos();
    final loadedTodos = dtos.map((dto) => Todo.fromDTO(dto)).toList();

    // Sort by created date (newest first)
    loadedTodos.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return toMap(loadedTodos);
  }

  /// Add a new todo
  Future<void> addTodo(TodoInput input) async {
    await todos.updateWith(() async {
      if (input.title.trim().isEmpty) {
        throw ValidationException('Title cannot be empty');
      }

      final now = DateTime.now();
      final newTodo = Todo(
        id: _uuid.v4(),
        title: input.title.trim(),
        description: input.description.trim(),
        isCompleted: false,
        createdAt: now,
      );

      await _storageService.saveTodo(newTodo.toDTO());

      return toMap([newTodo, ...todoMap.values]);
    });
  }

  Future<void> updateTodo(Todo todo) async {
    await todos.updateWith(() async {
      if (todo.title.trim().isEmpty) {
        throw ValidationException('Title cannot be empty');
      }

      final updatedTodo = todo.copyWith(updatedAt: DateTime.now());

      await _storageService.updateTodo(updatedTodo.toDTO());

      todoMap[todo.id] = updatedTodo;

      return LinkedHashMap<String, Todo>.from(todoMap);
    });
  }

  Future<void> deleteTodo(String id) async {
    await todos.updateWith(() async {
      await _storageService.deleteTodo(id);

      todoMap.remove(id);

      return LinkedHashMap<String, Todo>.from(todoMap);
    });

    // Clear selected todo if it was deleted
    if (selectedTodo.value?.id == id) {
      selectedTodo.value = null;
    }
  }

  Future<void> toggleTodo(String id) async {
    await todos.updateWith(() async {
      final todo = todoMap[id];
      if (todo == null) {
        throw NotFoundException('Todo not found');
      }

      final updatedTodo = todo.copyWith(
        isCompleted: !todo.isCompleted,
        updatedAt: DateTime.now(),
      );

      await _storageService.updateTodo(updatedTodo.toDTO());

      todoMap[todo.id] = updatedTodo;

      return LinkedHashMap<String, Todo>.from(todoMap);
    });
  }

  Future<void> clearCompleted() async {
    await todos.updateWith(() async {
      final completedTodos = todoMap.values.where((t) => t.isCompleted);

      for (final todo in completedTodos) {
        await _storageService.deleteTodo(todo.id);
      }

      final updatedTodos = todoMap.values.where((t) => !t.isCompleted);

      return toMap(updatedTodos);
    });
  }

  late final filteredTodos = B.derived(() {
    final currentTodos = todos.value.lastData?.values.toList() ?? [];
    return switch (currentFilter.value) {
      TodoFilter.all => currentTodos,
      TodoFilter.active => currentTodos.where((t) => !t.isCompleted).toList(),
      TodoFilter.completed => currentTodos.where((t) => t.isCompleted).toList(),
    };
  });

  late final activeCount = B.derived(() {
    final currentTodos = todos.value.lastData?.values.toList() ?? [];
    return currentTodos.where((t) => !t.isCompleted).length;
  });

  late final completedCount = B.derived(() {
    final currentTodos = todos.value.lastData?.values.toList() ?? [];
    return currentTodos.length - activeCount.value;
  });

  late final hasCompleted = B.derived(() {
    return completedCount.value > 0;
  });

  /// Set the current filter
  void setFilter(TodoFilter filter) {
    currentFilter.value = filter;
  }

  /// Select a todo for editing
  void selectTodo(Todo todo) {
    selectedTodo.value = todo;
  }

  /// Clear the selected todo
  void clearSelection() {
    selectedTodo.value = null;
  }
}

/// Input data for creating a new todo
class TodoInput {
  final String title;
  final String description;

  const TodoInput({required this.title, this.description = ''});
}

/// Filter options for todos
enum TodoFilter { all, active, completed }

/// Exception for validation errors
class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}

/// Exception for not found errors
class NotFoundException implements Exception {
  final String message;

  NotFoundException(this.message);

  @override
  String toString() => 'NotFoundException: $message';
}
