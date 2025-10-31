import 'package:hive/hive.dart';
import '../../features/todos/models/todo_dto.dart';

/// Service for managing local storage using Hive
///
/// This service handles all Hive operations for todos.
/// It should never modify app state directly, only perform I/O operations.
class HiveStorageService {
  static const String _todosBoxName = 'todos';
  Box<TodoDTO>? _todosBox;

  /// Initialize the Hive storage service
  ///
  /// Must be called before using any other methods.
  /// This is typically called during app initialization.
  Future<void> init() async {
    if (_todosBox == null || !_todosBox!.isOpen) {
      _todosBox = await Hive.openBox<TodoDTO>(_todosBoxName);
    }
  }

  /// Get reference to the todos box
  Box<TodoDTO> get _box {
    if (_todosBox == null || !_todosBox!.isOpen) {
      throw StateError(
        'HiveStorageService not initialized. Call init() first.',
      );
    }
    return _todosBox!;
  }

  /// Get all todos from storage
  Future<List<TodoDTO>> getAllTodos() async {
    try {
      return _box.values.toList();
    } catch (e) {
      throw StorageException('Failed to get all todos: $e');
    }
  }

  /// Get a specific todo by ID
  Future<TodoDTO?> getTodoById(String id) async {
    try {
      return _box.values.firstWhere(
        (todo) => todo.id == id,
        orElse: () => throw StateError('Todo not found'),
      );
    } on StateError {
      return null;
    } catch (e) {
      throw StorageException('Failed to get todo by id: $e');
    }
  }

  /// Save a new todo to storage
  Future<void> saveTodo(TodoDTO todo) async {
    try {
      await _box.put(todo.id, todo);
    } catch (e) {
      throw StorageException('Failed to save todo: $e');
    }
  }

  /// Update an existing todo in storage
  Future<void> updateTodo(TodoDTO todo) async {
    try {
      if (!_box.containsKey(todo.id)) {
        throw StorageException('Todo with id ${todo.id} not found');
      }
      await _box.put(todo.id, todo);
    } catch (e) {
      throw StorageException('Failed to update todo: $e');
    }
  }

  /// Delete a todo from storage by ID
  Future<void> deleteTodo(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StorageException('Failed to delete todo: $e');
    }
  }

  /// Delete all todos from storage
  Future<void> deleteAllTodos() async {
    try {
      await _box.clear();
    } catch (e) {
      throw StorageException('Failed to delete all todos: $e');
    }
  }

  /// Watch for changes to todos in real-time
  ///
  /// Returns a stream that emits the full list of todos whenever
  /// the box changes.
  Stream<List<TodoDTO>> watchTodos() {
    return _box.watch().map((_) => _box.values.toList());
  }

  /// Get the count of todos in storage
  Future<int> getTodoCount() async {
    try {
      return _box.length;
    } catch (e) {
      throw StorageException('Failed to get todo count: $e');
    }
  }

  /// Close the storage box
  ///
  /// Should be called when the app is closing.
  Future<void> close() async {
    if (_todosBox?.isOpen == true) {
      await _todosBox!.close();
    }
  }

  /// Compact the storage box to reduce file size
  Future<void> compact() async {
    try {
      await _box.compact();
    } catch (e) {
      throw StorageException('Failed to compact storage: $e');
    }
  }
}

/// Custom exception for storage-related errors
class StorageException implements Exception {
  final String message;

  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
