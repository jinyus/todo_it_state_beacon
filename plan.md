# TODO App Implementation Plan - PFA Architecture

## Project Overview
Building a TODO app using Flutter with PFA (Practical Flutter Architecture), featuring:
- State management: `watch_it` + `command_it`
- Dependency injection: `get_it`
- Local storage: `hive` (Phase 1)
- Cloud storage: `firebase` (Phase 2)

## Phase 1: Foundation & Local Storage (Hive)

### Step 1: Project Setup
**Goal**: Initialize Flutter project with required dependencies

**Tasks**:
1. Create new Flutter project: `flutter create todoit`
2. Update `pubspec.yaml` with dependencies:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     # State Management & DI
     watch_it: ^1.7.0
     command_it: ^8.0.0
     get_it: ^8.0.0
     # Local Storage
     hive: ^2.2.3
     hive_flutter: ^1.1.0
     # Utilities
     uuid: ^4.0.0
     intl: ^0.19.0

   dev_dependencies:
     flutter_test:
       sdk: flutter
     hive_generator: ^2.0.1
     build_runner: ^2.4.0
     flutter_lints: ^4.0.0
     mockito: ^5.4.0
   ```
3. Run: `flutter pub get`
4. Create project structure (folders)

**Deliverables**:
- Configured Flutter project
- All dependencies installed
- Folder structure created

---

### Step 2: Create Project Structure
**Goal**: Set up feature-based folder organization

**Tasks**:
1. Create folder structure:
   ```
   lib/
   ├── main.dart
   ├── locator.dart
   ├── features/
   │   ├── todos/
   │   │   ├── views/
   │   │   ├── managers/
   │   │   └── models/
   │   └── settings/
   │       ├── views/
   │       └── managers/
   ├── services/
   │   └── storage/
   └── shared/
       ├── widgets/
       └── utils/
   ```

**Deliverables**:
- Clean folder structure following PFA principles

---

### Step 3: Define Data Models
**Goal**: Create domain objects and DTOs for todos

**Files to create**:
- `lib/features/todos/models/todo.dart` - Domain model
- `lib/features/todos/models/todo_dto.dart` - Hive DTO with annotations

**Todo Model Properties**:
- `id`: String (UUID)
- `title`: String
- `description`: String
- `isCompleted`: bool
- `createdAt`: DateTime
- `updatedAt`: DateTime?

**Tasks**:
1. Create `Todo` domain class with:
   - Immutable properties
   - `copyWith()` method
   - `toDTO()` conversion
2. Create `TodoDTO` Hive class with:
   - `@HiveType` annotation
   - `@HiveField` annotations
   - `toDomain()` conversion
3. Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`

**Deliverables**:
- `todo.dart` with domain model
- `todo_dto.g.dart` generated
- `todo_dto.dart` with Hive annotations

---

### Step 4: Implement Storage Service Layer
**Goal**: Create Hive service for local storage

**Files to create**:
- `lib/services/storage/hive_storage_service.dart`

**Methods to implement**:
- `Future<void> init()` - Initialize Hive box
- `Future<List<TodoDTO>> getAllTodos()`
- `Future<TodoDTO?> getTodoById(String id)`
- `Future<void> saveTodo(TodoDTO todo)`
- `Future<void> updateTodo(TodoDTO todo)`
- `Future<void> deleteTodo(String id)`
- `Stream<List<TodoDTO>> watchTodos()` - For real-time updates

**Tasks**:
1. Implement `HiveStorageService` class
2. Handle box opening/closing
3. Implement CRUD operations
4. Add error handling
5. Test service independently

**Deliverables**:
- Fully functional `HiveStorageService`
- Error handling for storage operations

---

### Step 5: Create Todo Manager (Business Logic)
**Goal**: Implement business logic layer with Commands

**Files to create**:
- `lib/features/todos/managers/todo_manager.dart`

**Properties**:
- `ValueNotifier<List<Todo>> todos`
- `ValueNotifier<Todo?> selectedTodo`

**Commands**:
- `Command<void, List<Todo>> loadTodosCommand` - Load all todos
- `Command<Todo, void> addTodoCommand` - Add new todo
- `Command<Todo, void> updateTodoCommand` - Update existing
- `Command<String, void> deleteTodoCommand` - Delete by ID
- `Command<String, void> toggleTodoCommand` - Toggle completion

**Tasks**:
1. Create `TodoManager` class
2. Inject `HiveStorageService` dependency
3. Implement all commands with async operations
4. Update `todos` ValueNotifier after operations
5. Add error handling for each command
6. Implement filtering logic (all/active/completed)

**Deliverables**:
- `TodoManager` with full CRUD operations
- Commands for all todo operations
- Reactive state with ValueNotifiers

---

### Step 6: Setup Dependency Injection
**Goal**: Configure get_it service locator

**Files to create**:
- `lib/locator.dart`

**Tasks**:
1. Create `setupLocator()` function
2. Register `HiveStorageService` as lazy singleton
3. Register `TodoManager` as lazy singleton
4. Ensure proper dependency order
5. Add initialization in `main.dart`

**Code structure**:
```dart
void setupLocator() {
  // Services
  di.registerLazySingleton<HiveStorageService>(
    () => HiveStorageService(),
  );

  // Managers
  di.registerLazySingleton<TodoManager>(
    () => TodoManager(di<HiveStorageService>()),
  );
}
```

**Deliverables**:
- Configured dependency injection
- All services and managers registered

---

### Step 7: Initialize App with Hive
**Goal**: Setup Hive and dependencies in main.dart

**Files to modify**:
- `lib/main.dart`

**Tasks**:
1. Initialize Flutter bindings
2. Initialize Hive with `Hive.initFlutter()`
3. Register Hive adapters
4. Open Hive boxes
5. Call `setupLocator()`
6. Wait for async dependencies: `await di.allReady()`
7. Run app

**Code structure**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TodoDTOAdapter());
  await Hive.openBox<TodoDTO>('todos');

  // Setup DI
  setupLocator();

  // Wait for all async deps
  await di.allReady();

  runApp(const MyApp());
}
```

**Deliverables**:
- Properly initialized app
- Hive ready for use
- All dependencies available

---

### Step 8: Create Todo List View
**Goal**: Build main screen showing all todos

**Files to create**:
- `lib/features/todos/views/todo_list_view.dart`
- `lib/features/todos/views/widgets/todo_item.dart`

**Features**:
- Display todos in ListView
- Filter tabs: All / Active / Completed
- Loading indicator while fetching
- Empty state message
- FAB to add new todo
- Swipe to delete
- Tap to toggle completion
- Long press for edit

**Watch expressions**:
```dart
final todos = watchPropertyValue((TodoManager m) => m.todos.value);
final isLoading = watchValue((TodoManager m) => m.loadTodosCommand.isExecuting);
```

**Tasks**:
1. Create `TodoListView` extending `WatchingWidget`
2. Watch todos and loading state
3. Implement filter tabs (BottomNavigationBar or TabBar)
4. Create `TodoItem` widget for list items
5. Implement swipe-to-delete with Dismissible
6. Add FAB for creating todos
7. Handle empty states
8. Add error handler for delete/update commands

**Deliverables**:
- Functional todo list with reactive updates
- Filter functionality
- Interactive todo items

---

### Step 9: Create Todo Form (Add/Edit)
**Goal**: Build form for creating and editing todos

**Files to create**:
- `lib/features/todos/views/todo_form_view.dart`

**Form fields**:
- Title (required, TextFormField)
- Description (optional, TextFormField with multiple lines)
- Save/Cancel buttons

**Features**:
- Validate title is not empty
- Handle both add and edit modes
- Show loading indicator during save
- Navigate back on success
- Show error on failure

**Tasks**:
1. Create `TodoFormView` extending `WatchingWidget`
2. Create Form with GlobalKey
3. Implement TextFormFields with validation
4. Detect add vs edit mode (constructor parameter)
5. Watch command execution state
6. Call appropriate command (add or update)
7. Register error handler to show SnackBar
8. Navigate back on success

**Deliverables**:
- Working form for add/edit
- Validation
- Error handling

---

### Step 10: Implement Navigation
**Goal**: Setup navigation between screens

**Files to modify**:
- `lib/main.dart`

**Routes**:
- `/` - TodoListView
- `/add` - TodoFormView (add mode)
- `/edit/:id` - TodoFormView (edit mode)

**Tasks**:
1. Define MaterialApp routes or use named routes
2. Implement navigation from FAB to add screen
3. Implement navigation from todo item to edit screen
4. Handle back navigation after save

**Deliverables**:
- Working navigation flow
- Proper data passing between screens

---

### Step 11: Add Shared Widgets
**Goal**: Create reusable UI components

**Files to create**:
- `lib/shared/widgets/loading_indicator.dart`
- `lib/shared/widgets/empty_state.dart`
- `lib/shared/widgets/error_dialog.dart`

**Tasks**:
1. Create `LoadingIndicator` widget
2. Create `EmptyState` widget with icon and message
3. Create `ErrorDialog` utility function
4. Use throughout the app

**Deliverables**:
- Reusable widget library
- Consistent UI/UX

---

### Step 12: Settings & Theme Management
**Goal**: Add settings screen with theme toggle

**Files to create**:
- `lib/features/settings/managers/settings_manager.dart`
- `lib/features/settings/views/settings_view.dart`

**Features**:
- Dark mode toggle
- Clear all todos option
- About section
- Store settings in Hive

**Tasks**:
1. Create `SettingsManager` with:
   - `ValueNotifier<bool> isDarkMode`
   - `Command<bool, void> toggleThemeCommand`
   - `Command<void, void> clearAllTodosCommand`
2. Register in locator
3. Create `SettingsView` with switches
4. Update MaterialApp theme based on `isDarkMode`
5. Watch theme in main.dart

**Deliverables**:
- Working settings screen
- Theme persistence
- Clear all functionality

---

### Step 13: Testing - Unit Tests
**Goal**: Write unit tests for business logic

**Files to create**:
- `test/managers/todo_manager_test.dart`
- `test/services/hive_storage_service_test.dart`

**Test cases**:
- TodoManager:
  - Adding todo updates list
  - Deleting todo removes from list
  - Toggling completion changes state
  - Commands handle errors properly
- HiveStorageService:
  - CRUD operations work correctly
  - Error handling

**Tasks**:
1. Setup test dependencies (mockito)
2. Create mock services
3. Write unit tests for TodoManager
4. Write tests for storage service
5. Achieve >80% coverage for business logic

**Deliverables**:
- Comprehensive unit test suite
- Verified business logic

---

### Step 14: Testing - Widget Tests
**Goal**: Write widget tests for UI

**Files to create**:
- `test/views/todo_list_view_test.dart`
- `test/views/todo_form_view_test.dart`

**Test cases**:
- TodoListView:
  - Displays todos correctly
  - Shows loading indicator
  - Shows empty state
  - Filters work correctly
- TodoFormView:
  - Validates required fields
  - Saves correctly
  - Shows errors

**Tasks**:
1. Setup widget test harness
2. Mock TodoManager
3. Write widget tests
4. Test user interactions

**Deliverables**:
- Widget test coverage
- UI behavior verification

---

### Step 15: Polish & Edge Cases
**Goal**: Handle edge cases and improve UX

**Tasks**:
1. Add confirmation dialog for delete
2. Add confirmation for clear all
3. Implement undo after delete (SnackBar action)
4. Add pull-to-refresh
5. Improve loading states
6. Add animations (hero animation, list animations)
7. Handle keyboard properly in forms
8. Add focus management
9. Accessibility: Semantics labels
10. Test on different screen sizes

**Deliverables**:
- Polished user experience
- Edge cases handled
- Smooth animations

---

## Phase 2: Cloud Storage (Firebase)

### Step 16: Firebase Project Setup
**Goal**: Configure Firebase for the app

**Tasks**:
1. Create Firebase project at console.firebase.google.com
2. Add Android app (download google-services.json)
3. Add iOS app (download GoogleService-Info.plist)
4. Update pubspec.yaml with Firebase packages:
   ```yaml
   firebase_core: ^3.0.0
   cloud_firestore: ^5.0.0
   firebase_auth: ^5.0.0
   ```
5. Initialize Firebase in main.dart
6. Configure FlutterFire CLI

**Deliverables**:
- Firebase project configured
- Firebase SDK integrated

---

### Step 17: Create Firebase Storage Service
**Goal**: Implement cloud storage layer

**Files to create**:
- `lib/services/storage/firebase_storage_service.dart`
- `lib/services/storage/storage_service.dart` (abstract interface)

**Tasks**:
1. Create `StorageService` interface
2. Refactor `HiveStorageService` to implement interface
3. Create `FirebaseStorageService` implementing same interface:
   - Use Firestore collections
   - Implement same methods as Hive service
   - Add user-specific data (use Firebase Auth UID)
   - Real-time listeners with `snapshots()`
4. Update locator to support switching

**Deliverables**:
- Abstract storage interface
- Firebase storage implementation
- Both implementations compatible

---

### Step 18: Implement Firebase Authentication
**Goal**: Add user authentication

**Files to create**:
- `lib/features/auth/managers/auth_manager.dart`
- `lib/features/auth/views/login_view.dart`

**Features**:
- Email/password authentication
- Google Sign-In (optional)
- Anonymous authentication option
- Logout

**Commands**:
- `Command<LoginCredentials, User> loginCommand`
- `Command<void, User> loginAnonymouslyCommand`
- `Command<void, void> logoutCommand`

**Tasks**:
1. Create `AuthManager` with Firebase Auth
2. Register in locator
3. Create login screen
4. Add auth state listener
5. Protect todo routes (require authentication)
6. Update Firebase rules for user-specific data

**Deliverables**:
- Working authentication
- Protected data per user
- Login/logout flow

---

### Step 19: Implement Sync Strategy
**Goal**: Sync between local (Hive) and cloud (Firebase)

**Files to create**:
- `lib/services/sync/sync_service.dart`
- `lib/features/todos/managers/sync_manager.dart`

**Sync strategies**:
1. **Online-first**: Always use Firebase when online
2. **Offline-first**: Use Hive, sync to Firebase when online
3. **Hybrid**: Hive for reads, Firebase for writes with background sync

**Tasks**:
1. Choose sync strategy (recommend offline-first)
2. Implement `SyncService`:
   - Listen to network connectivity
   - Detect conflicts (last-write-wins or manual)
   - Queue operations when offline
   - Sync on reconnect
3. Update `TodoManager` to use sync service
4. Handle sync errors
5. Show sync status in UI

**Deliverables**:
- Offline capability
- Automatic sync
- Conflict resolution

---

### Step 20: Firestore Security Rules
**Goal**: Secure cloud data

**Tasks**:
1. Write Firestore security rules:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/todos/{todoId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```
2. Test rules with Firebase emulator
3. Deploy rules to production

**Deliverables**:
- Secure Firestore rules
- User data isolation

---

### Step 21: Migration Tool
**Goal**: Help users migrate from Hive to Firebase

**Files to create**:
- `lib/services/migration/migration_service.dart`

**Tasks**:
1. Create one-time migration function
2. Copy all Hive data to Firebase
3. Mark migration complete in shared preferences
4. Run on first launch after Firebase update

**Deliverables**:
- Smooth migration experience
- No data loss

---

### Step 22: Final Testing & Optimization
**Goal**: Ensure production readiness

**Tasks**:
1. Test offline mode extensively
2. Test sync conflicts
3. Test authentication flows
4. Performance testing (large datasets)
5. Memory profiling
6. Network usage optimization
7. Add analytics (Firebase Analytics)
8. Add crash reporting (Firebase Crashlytics)
9. Update tests for Firebase functionality

**Deliverables**:
- Production-ready app
- Performance optimized
- Monitoring in place

---

## Milestones

### Milestone 1: Basic Local App (Steps 1-11)
- ✅ Working todo app with Hive
- ✅ Full CRUD operations
- ✅ PFA architecture implemented
- ✅ No cloud dependency

**Timeline**: 2-3 days

---

### Milestone 2: Polished Local App (Steps 12-15)
- ✅ Settings and theme
- ✅ Tests written
- ✅ Polished UX
- ✅ Ready for users

**Timeline**: 1-2 days

---

### Milestone 3: Cloud Integration (Steps 16-22)
- ✅ Firebase integrated
- ✅ Authentication working
- ✅ Data syncing
- ✅ Production ready

**Timeline**: 3-5 days

---

## Development Order Priority

### Must Have (MVP)
1. ✅ Basic CRUD operations
2. ✅ Local storage (Hive)
3. ✅ Todo list display
4. ✅ Add/edit form

### Should Have
5. ✅ Filters (all/active/completed)
6. ✅ Dark mode
7. ✅ Settings screen
8. ✅ Error handling

### Nice to Have
9. Pull-to-refresh
10. Undo delete
11. Animations
12. Search functionality

### Future Features (Post-Firebase)
13. Sharing todos
14. Categories/tags
15. Due dates & reminders
16. Attachments
17. Collaboration

---

## Key Decision Points

### When to Switch from Hive to Firebase?
- **Option A**: Build complete local app first, then add Firebase (recommended)
  - Pros: Faster MVP, testable without network
  - Cons: Migration work later
- **Option B**: Build with Firebase from start
  - Pros: No migration
  - Cons: Slower development, network dependency

**Recommendation**: Follow Phase 1 completely, then Phase 2

---

### Storage Architecture Choice
- **Current Plan**: Hive first, Firebase later
- **Alternative**: SQLite → Firebase
- **Alternative**: Firebase only with offline persistence

**Recommendation**: Stick with Hive for Phase 1 (simpler, less setup)

---

## Testing Strategy

### Unit Tests
- All managers (100% coverage goal)
- All services
- All commands
- Domain models

### Widget Tests
- All views
- Key user flows
- Error states

### Integration Tests
- End-to-end flows
- Auth flow (Phase 2)
- Sync scenarios (Phase 2)

---

## Performance Targets

- App launch: < 2 seconds
- Todo list rendering: < 100ms for 1000 items
- CRUD operations: < 500ms
- Firebase sync: < 3 seconds
- Memory usage: < 100MB

---

## Next Steps

**To begin development:**
1. Run: `flutter create todoit`
2. Follow Step 1 (Project Setup)
3. Work through steps sequentially
4. Commit after each major step
5. Test frequently

**First commit checklist**:
- [ ] Project created
- [ ] Dependencies added
- [ ] Folder structure created
- [ ] README updated
- [ ] rules.md in project root
- [ ] plan.md in project root

---

## Resources

- [PFA Blog Post](https://blog.burkharts.net/practical-flutter-architecture)
- [watch_it Package](https://pub.dev/packages/watch_it)
- [command_it Package](https://pub.dev/packages/command_it)
- [get_it Package](https://pub.dev/packages/get_it)
- [Hive Documentation](https://docs.hivedb.dev/)
- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
