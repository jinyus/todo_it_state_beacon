import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:todoit/features/todos/models/todo_dto.dart';
import 'package:todoit/services/storage/hive_storage_service.dart';

void main() {
  group('HiveStorageService', () {
    late HiveStorageService storageService;
    late Box<TodoDTO> testBox;
    final testDate = DateTime(2025, 10, 31, 12, 0, 0);

    setUpAll(() async {
      // Initialize Hive with a temporary directory for testing
      Hive.init('./test/hive_test_db');
      Hive.registerAdapter(TodoDTOAdapter());
    });

    setUp(() async {
      storageService = HiveStorageService();

      // Clear any existing box
      if (Hive.isBoxOpen('todos')) {
        testBox = Hive.box<TodoDTO>('todos');
        await testBox.clear();
      }

      await storageService.init();
    });

    tearDown(() async {
      if (Hive.isBoxOpen('todos')) {
        final box = Hive.box<TodoDTO>('todos');
        await box.clear();
        await box.close();
      }
    });

    tearDownAll(() async {
      await Hive.deleteFromDisk();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        final service = HiveStorageService();
        await service.init();

        // Should not throw
        await service.getAllTodos();
      });

      test('should throw StorageException when not initialized', () async {
        final service = HiveStorageService();

        expect(
          () => service.getAllTodos(),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('CRUD Operations', () {
      test('getAllTodos should return empty list initially', () async {
        final todos = await storageService.getAllTodos();
        expect(todos, isEmpty);
      });

      test('saveTodo should save a todo', () async {
        final todo = TodoDTO(
          id: 'test-1',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        await storageService.saveTodo(todo);

        final todos = await storageService.getAllTodos();
        expect(todos.length, 1);
        expect(todos.first.id, 'test-1');
        expect(todos.first.title, 'Test Todo');
      });

      test('saveTodo should save multiple todos', () async {
        final todo1 = TodoDTO(
          id: 'test-1',
          title: 'Test Todo 1',
          description: 'Description 1',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        final todo2 = TodoDTO(
          id: 'test-2',
          title: 'Test Todo 2',
          description: 'Description 2',
          isCompleted: true,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        await storageService.saveTodo(todo1);
        await storageService.saveTodo(todo2);

        final todos = await storageService.getAllTodos();
        expect(todos.length, 2);
      });

      test('getTodoById should return correct todo', () async {
        final todo = TodoDTO(
          id: 'test-1',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        await storageService.saveTodo(todo);

        final retrieved = await storageService.getTodoById('test-1');
        expect(retrieved, isNotNull);
        expect(retrieved!.id, 'test-1');
        expect(retrieved.title, 'Test Todo');
      });

      test('getTodoById should return null for non-existent todo', () async {
        final retrieved = await storageService.getTodoById('non-existent');
        expect(retrieved, isNull);
      });

      test('updateTodo should update existing todo', () async {
        final original = TodoDTO(
          id: 'test-1',
          title: 'Original Title',
          description: 'Original Description',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        await storageService.saveTodo(original);

        final updated = TodoDTO(
          id: 'test-1',
          title: 'Updated Title',
          description: 'Updated Description',
          isCompleted: true,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        await storageService.updateTodo(updated);

        final retrieved = await storageService.getTodoById('test-1');
        expect(retrieved!.title, 'Updated Title');
        expect(retrieved.description, 'Updated Description');
        expect(retrieved.isCompleted, true);
      });

      test('updateTodo should throw exception for non-existent todo', () async {
        final todo = TodoDTO(
          id: 'non-existent',
          title: 'Test',
          description: 'Test',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        expect(
          () => storageService.updateTodo(todo),
          throwsA(isA<StorageException>()),
        );
      });

      test('deleteTodo should remove todo', () async {
        final todo = TodoDTO(
          id: 'test-1',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        await storageService.saveTodo(todo);
        expect((await storageService.getAllTodos()).length, 1);

        await storageService.deleteTodo('test-1');
        expect((await storageService.getAllTodos()).length, 0);
      });

      test('deleteTodo should not throw for non-existent id', () async {
        await storageService.deleteTodo('non-existent');
        // Should complete without error
      });

      test('deleteAllTodos should clear all todos', () async {
        final todo1 = TodoDTO(
          id: 'test-1',
          title: 'Test Todo 1',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        final todo2 = TodoDTO(
          id: 'test-2',
          title: 'Test Todo 2',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        await storageService.saveTodo(todo1);
        await storageService.saveTodo(todo2);
        expect((await storageService.getAllTodos()).length, 2);

        await storageService.deleteAllTodos();
        expect((await storageService.getAllTodos()).length, 0);
      });
    });

    group('Additional Operations', () {
      test('getTodoCount should return correct count', () async {
        expect(await storageService.getTodoCount(), 0);

        final todo1 = TodoDTO(
          id: 'test-1',
          title: 'Test Todo 1',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        await storageService.saveTodo(todo1);
        expect(await storageService.getTodoCount(), 1);

        final todo2 = TodoDTO(
          id: 'test-2',
          title: 'Test Todo 2',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        await storageService.saveTodo(todo2);
        expect(await storageService.getTodoCount(), 2);
      });

      test('watchTodos should emit updates', () async {
        final stream = storageService.watchTodos();

        final todo = TodoDTO(
          id: 'test-1',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        // Start listening
        final future = stream.first;

        // Add todo
        await storageService.saveTodo(todo);

        // Should receive update
        final todos = await future;
        expect(todos.length, 1);
        expect(todos.first.id, 'test-1');
      });

      test('compact should execute without error', () async {
        final todo = TodoDTO(
          id: 'test-1',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        await storageService.saveTodo(todo);
        await storageService.compact();

        // Should still be able to access data
        final todos = await storageService.getAllTodos();
        expect(todos.length, 1);
      });

      test('close should close the box', () async {
        await storageService.close();

        // Trying to use after close should fail
        expect(
          () => storageService.getAllTodos(),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('Error Handling', () {
      test('StorageException should have message', () {
        final exception = StorageException('Test error');
        expect(exception.message, 'Test error');
        expect(exception.toString(), contains('Test error'));
      });
    });

    group('Edge Cases', () {
      test('should handle empty description', () async {
        final todo = TodoDTO(
          id: 'test-1',
          title: 'Test Todo',
          description: '',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        await storageService.saveTodo(todo);
        final retrieved = await storageService.getTodoById('test-1');
        expect(retrieved!.description, '');
      });

      test('should handle null updatedAt', () async {
        final todo = TodoDTO(
          id: 'test-1',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
          updatedAt: null,
        );

        await storageService.saveTodo(todo);
        final retrieved = await storageService.getTodoById('test-1');
        expect(retrieved!.updatedAt, isNull);
      });

      test('should overwrite todo with same id', () async {
        final todo1 = TodoDTO(
          id: 'test-1',
          title: 'First Version',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        final todo2 = TodoDTO(
          id: 'test-1',
          title: 'Second Version',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        await storageService.saveTodo(todo1);
        await storageService.saveTodo(todo2);

        final todos = await storageService.getAllTodos();
        expect(todos.length, 1);
        expect(todos.first.title, 'Second Version');
      });

      test('should handle large number of todos', () async {
        // Add 100 todos
        for (int i = 0; i < 100; i++) {
          final todo = TodoDTO(
            id: 'test-$i',
            title: 'Test Todo $i',
            description: 'Description $i',
            isCompleted: i % 2 == 0,
            createdAt: testDate.millisecondsSinceEpoch,
          );
          await storageService.saveTodo(todo);
        }

        final todos = await storageService.getAllTodos();
        expect(todos.length, 100);
        expect(await storageService.getTodoCount(), 100);
      });
    });
  });
}
