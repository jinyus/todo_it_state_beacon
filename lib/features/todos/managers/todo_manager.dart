import 'package:flutter/foundation.dart';
import 'package:command_it/command_it.dart';
import 'package:uuid/uuid.dart';

import '../models/todo.dart';
import '../../../services/storage/hive_storage_service.dart';

/// Manager for todo business logic
///
/// This class contains all the business logic for managing todos.
/// It uses Commands for state-modifying operations and ValueNotifiers
/// for reactive data.
class TodoManager {
  final HiveStorageService _storageService;
  final Uuid _uuid = const Uuid();

  // Reactive state
  final ValueNotifier<List<Todo>> todos = ValueNotifier([]);
  final ValueNotifier<Todo?> selectedTodo = ValueNotifier(null);
  final ValueNotifier<TodoFilter> currentFilter = ValueNotifier(TodoFilter.all);

  // Commands
  late final Command<void, List<Todo>> loadTodosCommand;
  late final Command<TodoInput, void> addTodoCommand;
  late final Command<Todo, void> updateTodoCommand;
  late final Command<String, void> deleteTodoCommand;
  late final Command<String, void> toggleTodoCommand;
  late final Command<void, void> clearCompletedCommand;

  TodoManager(this._storageService) {
    _initializeCommands();
  }

  void _initializeCommands() {
    // Load todos command
    loadTodosCommand = Command.createAsyncNoParam(
      _loadTodos,
      initialValue: [],
    );

    // Add todo command
    addTodoCommand = Command.createAsync<TodoInput, void>(
      _addTodo,
      initialValue: null,
    );

    // Update todo command
    updateTodoCommand = Command.createAsync<Todo, void>(
      _updateTodo,
      initialValue: null,
    );

    // Delete todo command
    deleteTodoCommand = Command.createAsync<String, void>(
      _deleteTodo,
      initialValue: null,
    );

    // Toggle todo completion command
    toggleTodoCommand = Command.createAsync<String, void>(
      _toggleTodo,
      initialValue: null,
    );

    // Clear completed todos command
    clearCompletedCommand = Command.createAsyncNoParam(
      _clearCompleted,
      initialValue: null,
    );

    // Auto-load todos on initialization
    loadTodosCommand();
  }

  /// Load all todos from storage
  Future<List<Todo>> _loadTodos() async {
    final dtos = await _storageService.getAllTodos();
    final loadedTodos = dtos.map((dto) => Todo.fromDTO(dto)).toList();

    // Sort by created date (newest first)
    loadedTodos.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    todos.value = loadedTodos;
    return loadedTodos;
  }

  /// Add a new todo
  Future<void> _addTodo(TodoInput input) async {
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
    loadTodosCommand();
  }

  /// Update an existing todo
  Future<void> _updateTodo(Todo todo) async {
    if (todo.title.trim().isEmpty) {
      throw ValidationException('Title cannot be empty');
    }

    final updatedTodo = todo.copyWith(
      updatedAt: DateTime.now(),
    );

    await _storageService.updateTodo(updatedTodo.toDTO());
    loadTodosCommand();
  }

  /// Delete a todo by ID
  Future<void> _deleteTodo(String id) async {
    await _storageService.deleteTodo(id);
    loadTodosCommand();

    // Clear selected todo if it was deleted
    if (selectedTodo.value?.id == id) {
      selectedTodo.value = null;
    }
  }

  /// Toggle todo completion status
  Future<void> _toggleTodo(String id) async {
    final todo = todos.value.firstWhere(
      (t) => t.id == id,
      orElse: () => throw NotFoundException('Todo not found'),
    );

    final updatedTodo = todo.copyWith(
      isCompleted: !todo.isCompleted,
      updatedAt: DateTime.now(),
    );

    await _storageService.updateTodo(updatedTodo.toDTO());
    loadTodosCommand();
  }

  /// Clear all completed todos
  Future<void> _clearCompleted() async {
    final completedTodos = todos.value.where((t) => t.isCompleted);

    for (final todo in completedTodos) {
      await _storageService.deleteTodo(todo.id);
    }

    loadTodosCommand();
  }

  /// Get filtered todos based on current filter
  List<Todo> get filteredTodos {
    switch (currentFilter.value) {
      case TodoFilter.all:
        return todos.value;
      case TodoFilter.active:
        return todos.value.where((t) => !t.isCompleted).toList();
      case TodoFilter.completed:
        return todos.value.where((t) => t.isCompleted).toList();
    }
  }

  /// Get count of active todos
  int get activeTodoCount {
    return todos.value.where((t) => !t.isCompleted).length;
  }

  /// Get count of completed todos
  int get completedTodoCount {
    return todos.value.where((t) => t.isCompleted).length;
  }

  /// Check if there are any completed todos
  bool get hasCompletedTodos {
    return completedTodoCount > 0;
  }

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

  /// Dispose resources
  void dispose() {
    todos.dispose();
    selectedTodo.dispose();
    currentFilter.dispose();
  }
}

/// Input data for creating a new todo
class TodoInput {
  final String title;
  final String description;

  const TodoInput({
    required this.title,
    this.description = '',
  });
}

/// Filter options for todos
enum TodoFilter {
  all,
  active,
  completed,
}

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
