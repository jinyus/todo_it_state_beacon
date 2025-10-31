import 'package:flutter_test/flutter_test.dart';
import 'package:todoit/features/todos/models/todo.dart';
import 'package:todoit/features/todos/models/todo_dto.dart';

void main() {
  group('Todo Model', () {
    late DateTime testDate;
    late DateTime updatedDate;

    setUp(() {
      testDate = DateTime(2025, 10, 31, 12, 0, 0);
      updatedDate = DateTime(2025, 10, 31, 13, 0, 0);
    });

    group('Constructor', () {
      test('should create a Todo with all properties', () {
        final todo = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Test Description',
          isCompleted: false,
          createdAt: testDate,
          updatedAt: updatedDate,
        );

        expect(todo.id, 'test-id');
        expect(todo.title, 'Test Todo');
        expect(todo.description, 'Test Description');
        expect(todo.isCompleted, false);
        expect(todo.createdAt, testDate);
        expect(todo.updatedAt, updatedDate);
      });

      test('should create a Todo without updatedAt', () {
        final todo = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Test Description',
          isCompleted: false,
          createdAt: testDate,
        );

        expect(todo.updatedAt, isNull);
      });
    });

    group('copyWith', () {
      test('should copy with updated title', () {
        final original = Todo(
          id: 'test-id',
          title: 'Original Title',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate,
        );

        final copy = original.copyWith(title: 'New Title');

        expect(copy.title, 'New Title');
        expect(copy.id, original.id);
        expect(copy.description, original.description);
        expect(copy.isCompleted, original.isCompleted);
        expect(copy.createdAt, original.createdAt);
      });

      test('should copy with updated completion status', () {
        final original = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate,
        );

        final copy = original.copyWith(isCompleted: true);

        expect(copy.isCompleted, true);
        expect(copy.title, original.title);
      });

      test('should copy with updated timestamp', () {
        final original = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate,
        );

        final copy = original.copyWith(updatedAt: updatedDate);

        expect(copy.updatedAt, updatedDate);
        expect(original.updatedAt, isNull);
      });

      test('should copy with all fields updated', () {
        final original = Todo(
          id: 'test-id',
          title: 'Original',
          description: 'Original Desc',
          isCompleted: false,
          createdAt: testDate,
        );

        final copy = original.copyWith(
          id: 'new-id',
          title: 'New Title',
          description: 'New Desc',
          isCompleted: true,
          createdAt: updatedDate,
          updatedAt: updatedDate,
        );

        expect(copy.id, 'new-id');
        expect(copy.title, 'New Title');
        expect(copy.description, 'New Desc');
        expect(copy.isCompleted, true);
        expect(copy.createdAt, updatedDate);
        expect(copy.updatedAt, updatedDate);
      });
    });

    group('DTO Conversion', () {
      test('should convert to DTO correctly', () {
        final todo = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Test Description',
          isCompleted: true,
          createdAt: testDate,
          updatedAt: updatedDate,
        );

        final dto = todo.toDTO();

        expect(dto.id, 'test-id');
        expect(dto.title, 'Test Todo');
        expect(dto.description, 'Test Description');
        expect(dto.isCompleted, true);
        expect(dto.createdAt, testDate.millisecondsSinceEpoch);
        expect(dto.updatedAt, updatedDate.millisecondsSinceEpoch);
      });

      test('should convert to DTO without updatedAt', () {
        final todo = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Test Description',
          isCompleted: false,
          createdAt: testDate,
        );

        final dto = todo.toDTO();

        expect(dto.updatedAt, isNull);
      });

      test('should create from DTO correctly', () {
        final dto = TodoDTO(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Test Description',
          isCompleted: true,
          createdAt: testDate.millisecondsSinceEpoch,
          updatedAt: updatedDate.millisecondsSinceEpoch,
        );

        final todo = Todo.fromDTO(dto);

        expect(todo.id, 'test-id');
        expect(todo.title, 'Test Todo');
        expect(todo.description, 'Test Description');
        expect(todo.isCompleted, true);
        expect(todo.createdAt, testDate);
        expect(todo.updatedAt, updatedDate);
      });

      test('should create from DTO without updatedAt', () {
        final dto = TodoDTO(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Test Description',
          isCompleted: false,
          createdAt: testDate.millisecondsSinceEpoch,
        );

        final todo = Todo.fromDTO(dto);

        expect(todo.updatedAt, isNull);
      });

      test('should round-trip convert between Todo and DTO', () {
        final original = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Test Description',
          isCompleted: true,
          createdAt: testDate,
          updatedAt: updatedDate,
        );

        final dto = original.toDTO();
        final converted = Todo.fromDTO(dto);

        expect(converted.id, original.id);
        expect(converted.title, original.title);
        expect(converted.description, original.description);
        expect(converted.isCompleted, original.isCompleted);
        expect(converted.createdAt, original.createdAt);
        expect(converted.updatedAt, original.updatedAt);
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        final todo1 = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate,
        );

        final todo2 = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate,
        );

        expect(todo1, equals(todo2));
        expect(todo1.hashCode, equals(todo2.hashCode));
      });

      test('should not be equal when id differs', () {
        final todo1 = Todo(
          id: 'test-id-1',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate,
        );

        final todo2 = Todo(
          id: 'test-id-2',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate,
        );

        expect(todo1, isNot(equals(todo2)));
      });

      test('should not be equal when title differs', () {
        final todo1 = Todo(
          id: 'test-id',
          title: 'Test Todo 1',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate,
        );

        final todo2 = Todo(
          id: 'test-id',
          title: 'Test Todo 2',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate,
        );

        expect(todo1, isNot(equals(todo2)));
      });

      test('should not be equal when completion status differs', () {
        final todo1 = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate,
        );

        final todo2 = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: true,
          createdAt: testDate,
        );

        expect(todo1, isNot(equals(todo2)));
      });

      test('should be equal to itself', () {
        final todo = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate,
        );

        expect(todo, equals(todo));
      });
    });

    group('toString', () {
      test('should produce readable string representation', () {
        final todo = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: testDate,
          updatedAt: updatedDate,
        );

        final string = todo.toString();

        expect(string, contains('test-id'));
        expect(string, contains('Test Todo'));
        expect(string, contains('Description'));
        expect(string, contains('false'));
      });
    });
  });
}
