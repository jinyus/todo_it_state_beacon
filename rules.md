# TODO App Architecture Rules - PFA with watch_it & command_it

## Architecture Overview: Practical Flutter Architecture (PFA)

PFA emphasizes pragmatism over dogma, focusing on deliverable apps with easy exploration, testability, scalability, and minimal boilerplate while keeping Flutter code recognizable.

### Core Principle
**"Flutter code should still look like Flutter code"** - avoid over-engineering and maintain Flutter's natural patterns.

## Three-Layer Architecture

### 1. Services Layer
**Purpose**: Encapsulate external dependencies (APIs, databases, OS services, hardware)

**Rules**:
- Convert data formats between external sources and app domain
- NEVER independently modify app state
- Pure data transformation and I/O operations
- Examples: `ApiService`, `HiveStorageService`, `FirebaseService`

**Example**:
```dart
class HiveStorageService {
  Future<List<TodoDTO>> getAllTodos() async { ... }
  Future<void> saveTodo(TodoDTO todo) async { ... }
  Future<void> deleteTodo(String id) async { ... }
}
```

### 2. Managers Layer
**Purpose**: Semantically-grouped business logic

**Rules**:
- Implement CRUD operations and business rules
- Use Services or other Managers
- Expose Commands (using command_it) for state-modifying operations
- Expose ValueListenables/Streams for reactive data
- Accessed via service locator (get_it)
- Examples: `TodoManager`, `AuthManager`, `SyncManager`

**Example**:
```dart
class TodoManager {
  final HiveStorageService _storage;

  // Reactive data
  final ValueNotifier<List<Todo>> todos = ValueNotifier([]);

  // Commands for operations
  late Command<Todo, void> addTodoCommand;
  late Command<String, void> deleteTodoCommand;
  late Command<Todo, void> updateTodoCommand;

  TodoManager(this._storage) {
    addTodoCommand = Command.createAsync(_addTodo);
    deleteTodoCommand = Command.createAsync(_deleteTodo);
    updateTodoCommand = Command.createAsync(_updateTodo);
  }

  Future<void> _addTodo(Todo todo) async {
    await _storage.saveTodo(todo.toDTO());
    await _loadTodos();
  }
}
```

### 3. Views Layer
**Purpose**: Full-page widgets that are "self-responsible"

**Rules**:
- Know what data they need
- Read data from Managers/Services
- Modify state ONLY through Manager-provided Commands
- Use `WatchingWidget` from watch_it for reactive rebuilds
- Avoid unrelated state changes
- Examples: `TodoListView`, `TodoDetailView`, `SettingsView`

**Example**:
```dart
class TodoListView extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    // Watch reactive data
    final todos = watchPropertyValue((TodoManager m) => m.todos.value);
    final isLoading = watchValue((TodoManager m) => m.loadTodosCommand.isExecuting);

    // Access command for operations
    final deleteCommand = di<TodoManager>().deleteTodoCommand;

    return Scaffold(
      body: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          final todo = todos[index];
          return ListTile(
            title: Text(todo.title),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => deleteCommand(todo.id),
            ),
          );
        },
      ),
    );
  }
}
```

## State Management with watch_it

### Core Concepts
- Built on top of get_it service locator
- Enables reactive rebuilds in StatelessWidgets
- Eliminates verbose builder patterns
- Observes Listenable, ValueListenable, Stream, and Future

### Watch Methods

| Method | Use Case |
|--------|----------|
| `watch()` | Observe any Listenable directly |
| `watchIt()` | Observe Listenable registered in get_it |
| `watchValue()` | Target ValueListenable properties in get_it objects |
| `watchPropertyValue()` | Watch specific properties (most efficient) |
| `watchStream()` | Observe Stream emissions |
| `watchFuture()` | Observe Future completion |

### Critical Rules for watch_it

1. **ONLY call watch methods within `build()`**
2. **Call in the SAME ORDER every build** (no conditionals around watch calls)
3. **NEVER use inside nested builders**
4. Use `WatchingWidget` base class for all reactive views

### Event Handlers (Side Effects without Rebuilds)

```dart
registerHandler(
  select: (TodoManager m) => m.addTodoCommand.errors,
  handler: (context, error, cancel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${error.error}')),
    );
  }
);
```

## Command Pattern with command_it

### Purpose
Wrap functions with automatic state tracking (execution state, errors, results)

### Command Features
- **isExecuting**: Tracks if function is running (for loading indicators)
- **canExecute**: Enables/disables based on conditions
- **results**: Complete execution results including parameters, output, errors
- **errors**: Exception handling

### Command Types

```dart
// Sync with no parameters
Command.createSyncNoParam(() { ... }, initialValue);

// Sync with parameter
Command.createSync((param) { ... }, initialValue);

// Async with no parameters
Command.createAsyncNoParam(() async { ... }, initialValue);

// Async with parameter
Command.createAsync((param) async { ... }, initialValue);
```

### UI Integration with CommandBuilder

```dart
CommandBuilder<String, List<Todo>>(
  command: todoManager.loadTodosCommand,
  whileExecuting: (context, _) => CircularProgressIndicator(),
  onData: (context, todos, _) => TodoList(todos: todos),
  onError: (context, error, _) => ErrorWidget(error: error),
)
```

## Data Objects

### Domain Objects
Represent real-world concepts with business logic:
```dart
class Todo {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;

  Todo copyWith({...}) { ... }
  TodoDTO toDTO() { ... }
}
```

### DTOs (Data Transfer Objects)
Generated from storage schemas (Hive, Firebase):
```dart
@HiveType(typeId: 0)
class TodoDTO {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  Todo toDomain() { ... }
}
```

## Dependency Injection with get_it

### Setup (locator.dart)

```dart
import 'package:get_it/get_it.dart';
import 'package:watch_it/watch_it.dart';

// watch_it provides 'di' as global GetIt instance
// final di = GetIt.instance; // Already provided by watch_it

void setupLocator() {
  // Services (Singletons)
  di.registerLazySingleton<HiveStorageService>(() => HiveStorageService());

  // Managers (Singletons with dependencies)
  di.registerLazySingleton<TodoManager>(
    () => TodoManager(di<HiveStorageService>()),
  );

  // For testing, use di.pushNewScope() and register fakes
}
```

### Accessing Dependencies

```dart
// In code
final todoManager = di<TodoManager>();

// In widgets with watch_it
final todos = watchPropertyValue((TodoManager m) => m.todos.value);
```

## Project Structure (Feature-Based)

```
lib/
├── main.dart
├── locator.dart                    # Dependency injection setup
├── features/
│   ├── todos/
│   │   ├── views/
│   │   │   ├── todo_list_view.dart
│   │   │   ├── todo_detail_view.dart
│   │   │   └── widgets/
│   │   │       ├── todo_item.dart
│   │   │       └── todo_form.dart
│   │   ├── managers/
│   │   │   └── todo_manager.dart
│   │   └── models/
│   │       ├── todo.dart
│   │       └── todo_dto.dart
│   ├── settings/
│   │   ├── views/
│   │   │   └── settings_view.dart
│   │   └── managers/
│   │       └── settings_manager.dart
├── services/
│   ├── storage/
│   │   ├── hive_storage_service.dart
│   │   └── firebase_storage_service.dart
│   └── sync/
│       └── sync_service.dart
└── shared/
    ├── widgets/
    │   └── loading_indicator.dart
    └── utils/
        └── extensions.dart
```

## Best Practices

### 1. State Modification
- **ALWAYS** modify state through Commands
- **NEVER** directly modify state from widgets
- Use `canExecute` to prevent invalid operations

### 2. Error Handling
```dart
// In Manager
addTodoCommand = Command.createAsync(
  _addTodo,
  catchAlways: true, // Catch all exceptions
);

// In View
registerHandler(
  select: (TodoManager m) => m.addTodoCommand.errors,
  handler: (context, error, cancel) {
    // Show error to user without rebuilding widget
    showErrorDialog(context, error.error);
  },
);
```

### 3. Loading States
```dart
// Watch command execution state
final isLoading = watchValue((TodoManager m) => m.loadTodosCommand.isExecuting);

if (isLoading) {
  return CircularProgressIndicator();
}
```

### 4. Testing
```dart
void main() {
  setUp(() {
    // Create test scope
    di.pushNewScope();

    // Register mocks
    di.registerSingleton<HiveStorageService>(MockHiveService());
    di.registerSingleton<TodoManager>(TodoManager(di()));
  });

  tearDown(() {
    di.popScope();
  });

  test('Adding todo should update list', () async {
    final manager = di<TodoManager>();
    await manager.addTodoCommand(Todo(...));
    expect(manager.todos.value.length, 1);
  });
}
```

### 5. Async Initialization
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox<TodoDTO>('todos');

  // Setup dependency injection
  setupLocator();

  // Wait for async dependencies
  await di.allReady();

  runApp(MyApp());
}
```

## Migration Path: Hive → Firebase

### Phase 1: Hive (Local Storage)
```dart
class HiveStorageService {
  final Box<TodoDTO> _box = Hive.box('todos');

  Future<List<TodoDTO>> getAllTodos() async {
    return _box.values.toList();
  }
}
```

### Phase 2: Abstract Storage Interface
```dart
abstract class StorageService {
  Future<List<TodoDTO>> getAllTodos();
  Future<void> saveTodo(TodoDTO todo);
  Future<void> deleteTodo(String id);
}

class HiveStorageService implements StorageService { ... }
class FirebaseStorageService implements StorageService { ... }
```

### Phase 3: Switch Implementation
```dart
// In locator.dart
void setupLocator() {
  // Switch between implementations
  di.registerLazySingleton<StorageService>(
    () => FirebaseStorageService(), // Was: HiveStorageService()
  );
}
```

## Security Considerations

1. **Never commit sensitive data**
2. **Use environment variables for API keys**
3. **Validate all user inputs**
4. **Sanitize data before storage**
5. **Implement proper authentication with Firebase Auth**

## Performance Tips

1. **Use `watchPropertyValue()` for fine-grained reactivity** (most efficient)
2. **Lazy load with `registerLazySingleton()`**
3. **Dispose commands and notifiers properly**
4. **Use `const` constructors where possible**
5. **Implement pagination for large lists**

## Common Pitfalls to Avoid

1. ❌ Calling watch methods outside `build()`
2. ❌ Conditional watch calls (breaks order requirement)
3. ❌ Directly modifying state from widgets
4. ❌ Forgetting to call `notifyListeners()` in managers
5. ❌ Mixing state management approaches
6. ❌ Creating commands inside `build()` method
7. ❌ Not handling command errors
8. ❌ Forgetting to initialize async dependencies before app starts
