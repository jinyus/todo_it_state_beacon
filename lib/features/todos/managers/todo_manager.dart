import 'package:flutter/foundation.dart';
import 'package:command_it/command_it.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:uuid/uuid.dart';

import '../models/todo.dart';
import '../../../services/storage/hive_storage_service.dart';

/// Manager for todo business logic
///
/// This class contains all the business logic for managing todos.
/// It uses Commands for state-modifying operations and ValueNotifiers
/// for reactive data.
class TodoManager with BeaconController {
  final HiveStorageService _storageService;
  final Uuid _uuid = const Uuid();

  late final selectedTodo = B.writable<Todo?>(null);
  late final currentFilter = B.writable<TodoFilter>(TodoFilter.all);

  TodoManager(this._storageService) {
    todos.start();
  }

  late final todos = B.future(_loadTodos, manualStart: true);

  List<Todo> get todoList => todos.lastData ?? [];

  Future<List<Todo>> _loadTodos() async {
    final dtos = await _storageService.getAllTodos();
    final loadedTodos = dtos.map((dto) => Todo.fromDTO(dto)).toList();

    // Sort by created date (newest first)
    loadedTodos.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return loadedTodos;
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

      // no need to refetch from source, just add to current list
      // since it was successfully saved
      return [newTodo, ...todoList];
    });
  }

  Future<void> updateTodo(Todo todo) async {
    await todos.updateWith(() async {
      if (todo.title.trim().isEmpty) {
        throw ValidationException('Title cannot be empty');
      }

      final updatedTodo = todo.copyWith(updatedAt: DateTime.now());

      await _storageService.updateTodo(updatedTodo.toDTO());

      final index = todoList.indexWhere(
        (existing) => existing.id == updatedTodo.id,
      );

      if (index == -1) {
        throw NotFoundException('Todo not found');
      }

      final updatedTodos = List<Todo>.from(todoList);
      updatedTodos[index] = updatedTodo;

      return updatedTodos;
    });
  }

  Future<void> deleteTodo(String id) async {
    await todos.updateWith(() async {
      await _storageService.deleteTodo(id);

      final updatedTodos = todoList.where((todo) => todo.id != id).toList();

      return updatedTodos;
    });

    // Clear selected todo if it was deleted
    if (selectedTodo.value?.id == id) {
      selectedTodo.value = null;
    }
  }

  Future<void> toggleTodo(String id) async {
    await todos.updateWith(() async {
      final index = todoList.indexWhere((t) => t.id == id);

      if (index == -1) {
        throw NotFoundException('Todo not found');
      }

      final todo = todoList[index];
      final updatedTodo = todo.copyWith(
        isCompleted: !todo.isCompleted,
        updatedAt: DateTime.now(),
      );

      await _storageService.updateTodo(updatedTodo.toDTO());

      final updatedTodos = List<Todo>.from(todoList);
      updatedTodos[index] = updatedTodo;

      return updatedTodos;
    });
  }

  Future<void> clearCompleted() async {
    await todos.updateWith(() async {
      final completedTodos = todoList.where((t) => t.isCompleted);

      for (final todo in completedTodos) {
        await _storageService.deleteTodo(todo.id);
      }

      final remainingTodos = todoList.where((t) => !t.isCompleted).toList();

      return remainingTodos;
    });
  }

  late final filteredTodos = B.derived(() {
    final currentTodos = todos.value.lastData ?? [];
    return switch (currentFilter.value) {
      TodoFilter.all => currentTodos,
      TodoFilter.active => currentTodos.where((t) => !t.isCompleted).toList(),
      TodoFilter.completed => currentTodos.where((t) => t.isCompleted).toList(),
    };
  });

  late final activeCount = B.derived(() {
    final currentTodos = todos.value.lastData ?? [];
    return currentTodos.where((t) => !t.isCompleted).length;
  });

  late final completedCount = B.derived(() {
    final currentTodos = todos.value.lastData ?? [];
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
