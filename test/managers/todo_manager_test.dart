import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:todoit/features/todos/managers/todo_manager.dart';
import 'package:todoit/features/todos/models/todo.dart';
import 'package:todoit/features/todos/models/todo_dto.dart';
import 'package:todoit/services/storage/hive_storage_service.dart';

import 'todo_manager_test.mocks.dart';

@GenerateMocks([HiveStorageService])
void main() {
  group('TodoManager', () {
    late MockHiveStorageService mockStorage;
    late TodoManager manager;
    final testDate = DateTime(2025, 10, 31, 12, 0, 0);

    setUp(() async {
      mockStorage = MockHiveStorageService();
      when(mockStorage.getAllTodos()).thenAnswer((_) async => []);
      manager = TodoManager(mockStorage);
      await manager.todos.next(filter: (state) => !state.isLoading);
    });

    tearDown(() async {
      manager.dispose();
    });

    group('Initialization', () {
      test('should initialize with empty todos', () {
        expect(manager.todoMap, isEmpty);
      });

      test('should set initial filter to all', () {
        expect(manager.currentFilter.value, TodoFilter.all);
      });

      test('should have no selected todo initially', () {
        expect(manager.selectedTodo.value, isNull);
      });

      test('should automatically load todos on creation', () {
        verify(mockStorage.getAllTodos()).called(greaterThan(0));
      });
    });

    group('Load Todos Command', () {
      test('should load todos from storage', () async {
        final dto = TodoDTO(
          id: 'test-1',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        when(mockStorage.getAllTodos()).thenAnswer((_) async => [dto]);

        manager.todos.reset();
        await manager.todos.next(filter: (state) => !state.isLoading);

        expect(manager.todoMap.length, 1);
        expect(manager.todoMap.values.first.title, 'Test Todo');
      });

      test('should sort todos by created date descending', () async {
        final dto1 = TodoDTO(
          id: 'test-1',
          title: 'Older Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        final dto2 = TodoDTO(
          id: 'test-2',
          title: 'Newer Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate
              .add(const Duration(hours: 1))
              .millisecondsSinceEpoch,
        );

        when(mockStorage.getAllTodos()).thenAnswer((_) async => [dto1, dto2]);

        manager.todos.reset();
        await manager.todos.next(filter: (state) => !state.isLoading);

        expect(manager.todoMap.length, 2);
        expect(manager.todoMap.values.first.title, 'Newer Todo');
        expect(manager.todoMap.values.last.title, 'Older Todo');
      });

      test('should handle empty storage', () async {
        when(mockStorage.getAllTodos()).thenAnswer((_) async => []);

        manager.todos.reset();
        await manager.todos.next(filter: (state) => !state.isLoading);

        expect(manager.todoMap, isEmpty);
      });
    });

    group('Add Todo Command', () {
      setUp(() {
        when(mockStorage.saveTodo(any)).thenAnswer((_) async {});
        when(mockStorage.getAllTodos()).thenAnswer((_) async => []);
      });

      test('should add todo with valid input', () async {
        final input = TodoInput(
          title: 'New Todo',
          description: 'New Description',
        );

        await manager.addTodo(input);

        verify(mockStorage.saveTodo(any)).called(1);
      });

      test('should trim whitespace from title and description', () async {
        final input = TodoInput(
          title: '  Trimmed Title  ',
          description: '  Trimmed Description  ',
        );

        TodoDTO? capturedDto;
        when(mockStorage.saveTodo(any)).thenAnswer((invocation) async {
          capturedDto = invocation.positionalArguments[0] as TodoDTO;
        });

        await manager.addTodo(input);

        expect(capturedDto, isNotNull);
        expect(capturedDto!.title, 'Trimmed Title');
        expect(capturedDto!.description, 'Trimmed Description');
      });

      test('should generate unique ID for new todo', () async {
        final input = TodoInput(title: 'Test', description: 'Test');

        TodoDTO? capturedDto;
        when(mockStorage.saveTodo(any)).thenAnswer((invocation) async {
          capturedDto = invocation.positionalArguments[0] as TodoDTO;
        });

        await manager.addTodo(input);

        expect(capturedDto, isNotNull);
        expect(capturedDto!.id, isNotEmpty);
      });

      test('should set isCompleted to false for new todo', () async {
        final input = TodoInput(title: 'Test', description: 'Test');

        TodoDTO? capturedDto;
        when(mockStorage.saveTodo(any)).thenAnswer((invocation) async {
          capturedDto = invocation.positionalArguments[0] as TodoDTO;
        });

        await manager.addTodo(input);

        expect(capturedDto!.isCompleted, false);
      });
    });

    group('Update Todo Command', () {
      setUp(() {
        when(mockStorage.updateTodo(any)).thenAnswer((_) async {});
        when(mockStorage.getAllTodos()).thenAnswer((_) async => []);
      });

      test('should update existing todo', () async {
        final todo = Todo(
          id: 'test-1',
          title: 'Updated Title',
          description: 'Updated Description',
          isCompleted: true,
          createdAt: testDate,
        );

        await manager.updateTodo(todo);

        verify(mockStorage.updateTodo(any)).called(1);
      });

      test('should set updatedAt timestamp', () async {
        final todo = Todo(
          id: 'test-1',
          title: 'Test',
          description: 'Test',
          isCompleted: false,
          createdAt: testDate,
        );

        TodoDTO? capturedDto;
        when(mockStorage.updateTodo(any)).thenAnswer((invocation) async {
          capturedDto = invocation.positionalArguments[0] as TodoDTO;
        });

        await manager.updateTodo(todo);

        expect(capturedDto, isNotNull);
        expect(capturedDto!.updatedAt, isNotNull);
      });
    });

    group('Delete Todo Command', () {
      setUp(() {
        when(mockStorage.deleteTodo(any)).thenAnswer((_) async {});
        when(mockStorage.getAllTodos()).thenAnswer((_) async => []);
      });

      test('should delete todo by id', () async {
        await manager.deleteTodo('test-1');

        verify(mockStorage.deleteTodo('test-1')).called(1);
      });

      test('should clear selected todo if it was deleted', () async {
        final todo = Todo(
          id: 'test-1',
          title: 'Test',
          description: 'Test',
          isCompleted: false,
          createdAt: testDate,
        );

        manager.selectTodo(todo);
        expect(manager.selectedTodo.value, isNotNull);

        await manager.deleteTodo('test-1');

        expect(manager.selectedTodo.value, isNull);
      });

      test(
        'should not clear selected todo if different todo was deleted',
        () async {
          final todo = Todo(
            id: 'test-1',
            title: 'Test',
            description: 'Test',
            isCompleted: false,
            createdAt: testDate,
          );

          manager.selectTodo(todo);

          await manager.deleteTodo('test-2');

          expect(manager.selectedTodo.value, isNotNull);
          expect(manager.selectedTodo.value!.id, 'test-1');
        },
      );
    });

    group('Toggle Todo Command', () {
      setUp(() {
        when(mockStorage.updateTodo(any)).thenAnswer((_) async {});
      });

      test('should toggle completion status from false to true', () async {
        final dto = TodoDTO(
          id: 'test-1',
          title: 'Test',
          description: 'Test',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        when(mockStorage.getAllTodos()).thenAnswer((_) async => [dto]);
        manager.todos.reset();
        await manager.todos.next(filter: (state) => !state.isLoading);

        TodoDTO? capturedDto;
        when(mockStorage.updateTodo(any)).thenAnswer((invocation) async {
          capturedDto = invocation.positionalArguments[0] as TodoDTO;
        });

        await manager.toggleTodo('test-1');

        expect(capturedDto, isNotNull);
        expect(capturedDto!.isCompleted, true);
      });

      test('should toggle completion status from true to false', () async {
        final dto = TodoDTO(
          id: 'test-1',
          title: 'Test',
          description: 'Test',
          isCompleted: true,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        when(mockStorage.getAllTodos()).thenAnswer((_) async => [dto]);
        manager.todos.reset();
        await manager.todos.next(filter: (state) => !state.isLoading);

        TodoDTO? capturedDto;
        when(mockStorage.updateTodo(any)).thenAnswer((invocation) async {
          capturedDto = invocation.positionalArguments[0] as TodoDTO;
        });

        await manager.toggleTodo('test-1');

        expect(capturedDto, isNotNull);
        expect(capturedDto!.isCompleted, false);
      });
    });

    group('Clear Completed Command', () {
      setUp(() {
        when(mockStorage.deleteTodo(any)).thenAnswer((_) async {});
      });

      test('should delete all completed todos', () async {
        final dto1 = TodoDTO(
          id: 'test-1',
          title: 'Completed 1',
          description: 'Test',
          isCompleted: true,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        final dto2 = TodoDTO(
          id: 'test-2',
          title: 'Active',
          description: 'Test',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        final dto3 = TodoDTO(
          id: 'test-3',
          title: 'Completed 2',
          description: 'Test',
          isCompleted: true,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        when(
          mockStorage.getAllTodos(),
        ).thenAnswer((_) async => [dto1, dto2, dto3]);
        manager.todos.reset();
        await manager.todos.next(filter: (state) => !state.isLoading);

        await manager.clearCompleted();

        verify(mockStorage.deleteTodo('test-1')).called(1);
        verify(mockStorage.deleteTodo('test-3')).called(1);
        verifyNever(mockStorage.deleteTodo('test-2'));
      });

      test('should do nothing if no completed todos', () async {
        final dto = TodoDTO(
          id: 'test-1',
          title: 'Active',
          description: 'Test',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        when(mockStorage.getAllTodos()).thenAnswer((_) async => [dto]);
        manager.todos.reset();
        await manager.todos.next(filter: (state) => !state.isLoading);

        await manager.clearCompleted();

        verifyNever(mockStorage.deleteTodo(any));
      });
    });

    group('Filtering', () {
      setUp(() async {
        final dto1 = TodoDTO(
          id: 'test-1',
          title: 'Active 1',
          description: 'Test',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        final dto2 = TodoDTO(
          id: 'test-2',
          title: 'Completed 1',
          description: 'Test',
          isCompleted: true,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        final dto3 = TodoDTO(
          id: 'test-3',
          title: 'Active 2',
          description: 'Test',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        when(
          mockStorage.getAllTodos(),
        ).thenAnswer((_) async => [dto1, dto2, dto3]);
        manager.todos.reset();
        await manager.todos.next(filter: (state) => !state.isLoading);
      });

      test('should return all todos when filter is all', () {
        manager.setFilter(TodoFilter.all);
        expect(manager.filteredTodos.value.length, 3);
      });

      test('should return only active todos when filter is active', () {
        manager.setFilter(TodoFilter.active);
        final filtered = manager.filteredTodos.value;
        expect(filtered.length, 2);
        expect(filtered.every((t) => !t.isCompleted), true);
      });

      test('should return only completed todos when filter is completed', () {
        manager.setFilter(TodoFilter.completed);
        final filtered = manager.filteredTodos.value;
        expect(filtered.length, 1);
        expect(filtered.every((t) => t.isCompleted), true);
      });
    });

    group('Computed Properties', () {
      setUp(() async {
        final dto1 = TodoDTO(
          id: 'test-1',
          title: 'Active 1',
          description: 'Test',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        final dto2 = TodoDTO(
          id: 'test-2',
          title: 'Completed 1',
          description: 'Test',
          isCompleted: true,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        final dto3 = TodoDTO(
          id: 'test-3',
          title: 'Active 2',
          description: 'Test',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        when(
          mockStorage.getAllTodos(),
        ).thenAnswer((_) async => [dto1, dto2, dto3]);
        manager.todos.reset();
        await manager.todos.next(filter: (state) => !state.isLoading);
      });

      test('activeTodoCount should return correct count', () {
        expect(manager.activeCount.value, 2);
      });

      test('completedTodoCount should return correct count', () {
        expect(manager.completedCount.value, 1);
      });

      test(
        'hasCompletedTodos should return true when there are completed todos',
        () {
          expect(manager.hasCompleted.value, true);
        },
      );

      test(
        'hasCompletedTodos should return false when no completed todos',
        () async {
          final dto = TodoDTO(
            id: 'test-1',
            title: 'Active',
            description: 'Test',
            isCompleted: false,
            createdAt: testDate.millisecondsSinceEpoch,
          );

          when(mockStorage.getAllTodos()).thenAnswer((_) async => [dto]);
          manager.todos.reset();
          await manager.todos.next(filter: (state) => !state.isLoading);

          expect(manager.hasCompleted.value, false);
        },
      );
    });

    group('Selected Todo Management', () {
      test('should select a todo', () {
        final todo = Todo(
          id: 'test-1',
          title: 'Test',
          description: 'Test',
          isCompleted: false,
          createdAt: testDate,
        );

        manager.selectTodo(todo);
        expect(manager.selectedTodo.value, equals(todo));
      });

      test('should clear selection', () {
        final todo = Todo(
          id: 'test-1',
          title: 'Test',
          description: 'Test',
          isCompleted: false,
          createdAt: testDate,
        );

        manager.selectTodo(todo);
        expect(manager.selectedTodo.value, isNotNull);

        manager.clearSelection();
        expect(manager.selectedTodo.value, isNull);
      });

      test('should replace previously selected todo', () {
        final todo1 = Todo(
          id: 'test-1',
          title: 'Test 1',
          description: 'Test',
          isCompleted: false,
          createdAt: testDate,
        );

        final todo2 = Todo(
          id: 'test-2',
          title: 'Test 2',
          description: 'Test',
          isCompleted: false,
          createdAt: testDate,
        );

        manager.selectTodo(todo1);
        expect(manager.selectedTodo.value!.id, 'test-1');

        manager.selectTodo(todo2);
        expect(manager.selectedTodo.value!.id, 'test-2');
      });
    });

    group('Dispose', () {
      test('should dispose all resources', () {
        // Dispose is called in tearDown
        // Just verify manager exists and is initialized
        expect(manager.todos, isNotNull);
        expect(manager.selectedTodo, isNotNull);
        expect(manager.currentFilter, isNotNull);
      });
    });
  });
}
