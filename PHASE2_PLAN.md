# Phase 2: Firebase Integration Plan

## Overview

This document outlines the implementation plan for Phase 2 of the TodoIt app, which adds Firebase backend services including authentication and cloud storage. This phase transforms the app from a local-only solution to a cloud-synchronized multi-device experience.

---

## Goals

### Primary Objectives
1. **User Authentication** - Email/password and Google Sign-In
2. **Cloud Storage** - Migrate from Hive to Cloud Firestore
3. **Offline-First** - Maintain full functionality without internet
4. **Real-time Sync** - Automatic synchronization across devices
5. **Data Migration** - Seamless transition from Hive to Firebase

### Non-Goals (Future Phases)
- Social features (sharing todos)
- Collaborative editing
- Advanced search
- Analytics dashboard
- Push notifications

---

## Architecture Changes

### Current Architecture (Phase 1)
```
Views (UI)
   ↓
Managers (Business Logic + Commands)
   ↓
HiveStorageService (Local Storage)
   ↓
Hive Database
```

### New Architecture (Phase 2)
```
Views (UI)
   ↓
Managers (Business Logic + Commands)
   ↓ ↓
   │ └─→ AuthService (Firebase Auth)
   │         ↓
   │     Firebase Authentication
   │
   └─→ FirestoreStorageService (Cloud Storage)
          ↓
      Cloud Firestore (with offline persistence)
```

### Key Changes
- **New Service Layer**: FirestoreStorageService implements StorageService interface
- **Authentication**: New AuthService for user management
- **Manager Updates**: TodoManager handles user-specific data
- **Migration**: Hive remains as backup/cache during transition
- **UI Updates**: Add login/signup screens

---

## Dependencies

### New Packages to Add

```yaml
dependencies:
  # Firebase Core
  firebase_core: ^3.10.0

  # Firebase Services
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.2

  # Google Sign-In
  google_sign_in: ^6.2.2

  # Connectivity checking
  connectivity_plus: ^6.1.2
```

---

## Implementation Steps

### Step 1: Firebase Project Setup
**Estimated Time**: 30 minutes

#### Tasks:
1. Create Firebase project at console.firebase.google.com
2. Add web app to Firebase project
3. Enable Authentication providers:
   - Email/Password
   - Google Sign-In
4. Create Cloud Firestore database
5. Setup security rules (see Security Rules section)
6. Download firebase_options.dart configuration

#### Deliverables:
- Firebase project created
- `lib/firebase_options.dart` file
- Authentication enabled
- Firestore database created

---

### Step 2: Firebase Initialization
**Estimated Time**: 20 minutes

#### Tasks:
1. Add Firebase dependencies to pubspec.yaml
2. Initialize Firebase in main.dart
3. Setup FlutterFire CLI configuration
4. Test Firebase connection

#### Files Modified:
- `pubspec.yaml`
- `lib/main.dart`

#### Code Changes:
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive (still needed for offline cache)
  await Hive.initFlutter();
  Hive.registerAdapter(TodoDTOAdapter());

  // Setup dependency injection
  setupLocator();

  // Initialize services
  await di<HiveStorageService>().init();

  runApp(const MyApp());
}
```

---

### Step 3: Create AuthService
**Estimated Time**: 2 hours

#### Tasks:
1. Create `lib/services/auth/auth_service.dart`
2. Implement email/password authentication
3. Implement Google Sign-In
4. Add user state management with ValueNotifier
5. Handle auth state persistence
6. Add error handling

#### Files Created:
- `lib/services/auth/auth_service.dart`
- `lib/services/auth/auth_exceptions.dart`

#### AuthService Interface:
```dart
class AuthService {
  // State
  final ValueNotifier<User?> currentUser = ValueNotifier(null);
  final ValueNotifier<bool> isAuthenticated = ValueNotifier(false);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  // Methods
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> updateProfile({String? displayName, String? photoUrl});

  // Lifecycle
  void dispose();
}
```

#### Features:
- Email/password authentication
- Google Sign-In integration
- Auth state persistence
- User profile management
- Password reset
- Error handling with custom exceptions

---

### Step 4: Create FirestoreStorageService
**Estimated Time**: 3 hours

#### Tasks:
1. Create `lib/services/storage/firestore_storage_service.dart`
2. Implement StorageService interface
3. Add offline persistence configuration
4. Setup real-time listeners
5. Handle merge conflicts
6. Add pagination support
7. Implement error handling

#### Files Created:
- `lib/services/storage/firestore_storage_service.dart`
- `lib/services/storage/storage_service.dart` (interface)

#### StorageService Interface:
```dart
abstract class StorageService {
  Future<void> init();
  Future<List<Todo>> getAllTodos();
  Future<Todo?> getTodoById(String id);
  Future<void> saveTodo(Todo todo);
  Future<void> updateTodo(Todo todo);
  Future<void> deleteTodo(String id);
  Stream<List<Todo>> watchTodos();
  Future<void> dispose();
}
```

#### Firestore Data Structure:
```
users (collection)
  ├─ {userId} (document)
      ├─ email: string
      ├─ displayName: string
      ├─ photoUrl: string
      └─ todos (subcollection)
          ├─ {todoId} (document)
              ├─ id: string
              ├─ title: string
              ├─ description: string
              ├─ isCompleted: boolean
              ├─ createdAt: timestamp
              └─ updatedAt: timestamp
```

#### Features:
- User-specific data isolation
- Real-time synchronization
- Offline persistence enabled
- Conflict resolution (last-write-wins)
- Batch operations for efficiency
- Error handling

---

### Step 5: Update TodoManager
**Estimated Time**: 1.5 hours

#### Tasks:
1. Modify TodoManager to use StorageService interface
2. Add authentication awareness
3. Handle storage service switching
4. Update commands for async operations
5. Add sync status indicators

#### Files Modified:
- `lib/features/todos/managers/todo_manager.dart`

#### Changes:
```dart
class TodoManager {
  final StorageService _storageService;  // Interface, not HiveStorageService
  final AuthService _authService;

  // New state
  final ValueNotifier<bool> isSyncing = ValueNotifier(false);
  final ValueNotifier<DateTime?> lastSyncTime = ValueNotifier(null);

  TodoManager(this._storageService, this._authService) {
    // Listen to auth state changes
    _authService.isAuthenticated.addListener(_onAuthStateChanged);
    loadTodosCommand();
  }

  void _onAuthStateChanged() {
    if (_authService.isAuthenticated.value) {
      // User logged in - reload todos
      loadTodosCommand();
    } else {
      // User logged out - clear todos
      todos.value = [];
    }
  }
}
```

---

### Step 6: Create Authentication UI
**Estimated Time**: 3 hours

#### Tasks:
1. Create login screen
2. Create signup screen
3. Create password reset screen
4. Add Google Sign-In button
5. Add form validation
6. Add loading states
7. Handle authentication errors

#### Files Created:
- `lib/features/auth/views/login_view.dart`
- `lib/features/auth/views/signup_view.dart`
- `lib/features/auth/views/forgot_password_view.dart`
- `lib/features/auth/views/widgets/auth_text_field.dart`
- `lib/features/auth/views/widgets/google_sign_in_button.dart`

#### Features:
- Material 3 design consistency
- Form validation (email format, password strength)
- Loading indicators during auth operations
- Error messages display
- Google Sign-In with branding
- Password visibility toggle
- "Remember me" option

---

### Step 7: Add Auth Flow to App
**Estimated Time**: 1 hour

#### Tasks:
1. Create AuthGate widget to control app entry
2. Update main.dart navigation
3. Add logout functionality to UI
4. Add user profile display
5. Handle deep linking (optional)

#### Files Modified:
- `lib/main.dart`

#### Files Created:
- `lib/features/auth/views/auth_gate.dart`

#### Auth Flow:
```dart
// lib/features/auth/views/auth_gate.dart
class AuthGate extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    final authService = di<AuthService>();
    final isAuthenticated = watch(authService.isAuthenticated);
    final isLoading = watch(authService.isLoading);

    if (isLoading.value) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return isAuthenticated.value
        ? const TodoListView()
        : const LoginView();
  }
}
```

---

### Step 8: Implement Offline-First Strategy
**Estimated Time**: 2 hours

#### Tasks:
1. Enable Firestore offline persistence
2. Add connectivity monitoring
3. Show sync status in UI
4. Handle offline operations gracefully
5. Add retry logic for failed syncs

#### Files Modified:
- `lib/services/storage/firestore_storage_service.dart`
- `lib/features/todos/views/todo_list_view.dart`

#### Files Created:
- `lib/services/connectivity/connectivity_service.dart`

#### Features:
- Automatic offline detection
- Queue operations when offline
- Sync indicator in app bar
- Automatic retry on reconnection
- Conflict resolution (last-write-wins)

#### Firestore Offline Configuration:
```dart
// In FirestoreStorageService.init()
await FirebaseFirestore.instance
    .enablePersistence(const PersistenceSettings(synchronizeTabs: true));
```

---

### Step 9: Data Migration Strategy
**Estimated Time**: 2 hours

#### Tasks:
1. Create migration service
2. Detect existing Hive data
3. Upload to Firestore on first login
4. Add migration progress UI
5. Handle migration errors
6. Keep Hive as fallback

#### Files Created:
- `lib/services/migration/migration_service.dart`
- `lib/features/auth/views/migration_view.dart`

#### Migration Flow:
```
1. User logs in for first time
2. Check if Hive has local data
3. If yes, show migration dialog
4. Upload all todos to Firestore
5. Mark migration complete
6. Continue to app
```

#### Migration Service:
```dart
class MigrationService {
  final HiveStorageService _hiveStorage;
  final FirestoreStorageService _firestoreStorage;

  final ValueNotifier<bool> isMigrating = ValueNotifier(false);
  final ValueNotifier<double> progress = ValueNotifier(0.0);

  Future<void> migrateData() async {
    isMigrating.value = true;

    try {
      final localTodos = await _hiveStorage.getAllTodos();

      for (var i = 0; i < localTodos.length; i++) {
        await _firestoreStorage.saveTodo(localTodos[i]);
        progress.value = (i + 1) / localTodos.length;
      }

      // Mark migration complete
      await _markMigrationComplete();
    } finally {
      isMigrating.value = false;
    }
  }
}
```

---

### Step 10: Security Rules
**Estimated Time**: 1 hour

#### Tasks:
1. Write Firestore security rules
2. Test rules with Firebase emulator
3. Deploy rules to production
4. Document security model

#### Firestore Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // User documents
    match /users/{userId} {
      allow read, write: if isOwner(userId);

      // Todo subcollection
      match /todos/{todoId} {
        allow read, write: if isOwner(userId);
      }
    }
  }
}
```

#### Security Principles:
- Users can only access their own data
- All operations require authentication
- No public read/write access
- Validate data structure on write (optional enhancement)

---

### Step 11: Update Dependency Injection
**Estimated Time**: 30 minutes

#### Tasks:
1. Register new services in locator
2. Update TodoManager dependencies
3. Add service lifecycle management
4. Test service resolution

#### Files Modified:
- `lib/locator.dart`

#### Updated Locator:
```dart
void setupLocator() {
  // Storage Services
  di.registerLazySingleton<HiveStorageService>(() => HiveStorageService());
  di.registerLazySingleton<FirestoreStorageService>(() => FirestoreStorageService());

  // Auth Service
  di.registerLazySingleton<AuthService>(() => AuthService());

  // Connectivity Service
  di.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  // Migration Service
  di.registerLazySingleton<MigrationService>(
    () => MigrationService(
      di<HiveStorageService>(),
      di<FirestoreStorageService>(),
    ),
  );

  // Todo Manager (now with auth awareness)
  di.registerLazySingleton<TodoManager>(
    () => TodoManager(
      di<FirestoreStorageService>(),  // Use Firestore now
      di<AuthService>(),
    ),
  );
}
```

---

### Step 12: Testing Strategy
**Estimated Time**: 3 hours

#### Unit Tests to Create:
1. `test/services/auth_service_test.dart`
   - Test email/password sign in/up
   - Test Google Sign-In (mocked)
   - Test auth state changes
   - Test error handling

2. `test/services/firestore_storage_service_test.dart`
   - Test CRUD operations (with fake Firestore)
   - Test offline behavior
   - Test real-time listeners
   - Test error handling

3. `test/services/migration_service_test.dart`
   - Test data migration
   - Test progress tracking
   - Test error recovery

4. Update `test/managers/todo_manager_test.dart`
   - Test auth-aware behavior
   - Test storage service switching
   - Test sync status

#### Integration Tests to Create:
1. `integration_test/auth_flow_test.dart`
   - Test complete login flow
   - Test signup flow
   - Test logout

2. `integration_test/sync_test.dart`
   - Test data synchronization
   - Test offline operations
   - Test conflict resolution

#### Mocking Strategy:
```dart
// Use firebase_auth_mocks package
dependencies:
  firebase_auth_mocks: ^0.14.1
  fake_cloud_firestore: ^3.2.1
```

---

### Step 13: UI Enhancements
**Estimated Time**: 2 hours

#### Tasks:
1. Add user profile menu
2. Add logout confirmation
3. Add sync status indicator
4. Add "last synced" timestamp
5. Add account settings screen
6. Update empty states for new users

#### Files Modified:
- `lib/features/todos/views/todo_list_view.dart`

#### Files Created:
- `lib/features/auth/views/profile_view.dart`
- `lib/features/auth/views/settings_view.dart`

#### New UI Features:
- User avatar in app bar
- Sync indicator (animated icon)
- "Last synced X minutes ago" text
- Profile screen with:
  - Display name
  - Email
  - Profile photo
  - Sign out button
  - Delete account option (optional)

---

### Step 14: Error Handling & Edge Cases
**Estimated Time**: 2 hours

#### Scenarios to Handle:
1. **Network Errors**
   - Graceful degradation
   - Retry logic
   - User feedback

2. **Authentication Errors**
   - Invalid credentials
   - Email already in use
   - Weak password
   - Network timeout

3. **Firestore Errors**
   - Permission denied
   - Quota exceeded
   - Document not found

4. **Migration Errors**
   - Partial migration failure
   - Duplicate data handling
   - Rollback strategy

#### Error Display Strategy:
```dart
// Consistent error handling
void handleError(BuildContext context, Exception error) {
  String message;

  if (error is FirebaseAuthException) {
    message = _getAuthErrorMessage(error.code);
  } else if (error is FirebaseException) {
    message = _getFirestoreErrorMessage(error.code);
  } else {
    message = 'An unexpected error occurred';
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
      action: SnackBarAction(
        label: 'Retry',
        onPressed: () => _retry(),
      ),
    ),
  );
}
```

---

### Step 15: Documentation
**Estimated Time**: 1 hour

#### Documents to Create/Update:
1. Update `README.md`
   - Add Firebase setup instructions
   - Add authentication documentation
   - Update screenshots

2. Create `FIREBASE_SETUP.md`
   - Step-by-step Firebase project setup
   - Configuration instructions
   - Security rules deployment

3. Update `ARCHITECTURE.md`
   - Document new service layer
   - Explain offline-first strategy
   - Diagram updated architecture

4. Create `PHASE2_PROGRESS.md`
   - Track implementation progress
   - Document decisions made
   - Record issues encountered

---

## Timeline

### Estimated Total Time: 20-25 hours

| Step | Task | Time |
|------|------|------|
| 1 | Firebase Project Setup | 30 min |
| 2 | Firebase Initialization | 20 min |
| 3 | Create AuthService | 2 hours |
| 4 | Create FirestoreStorageService | 3 hours |
| 5 | Update TodoManager | 1.5 hours |
| 6 | Create Authentication UI | 3 hours |
| 7 | Add Auth Flow to App | 1 hour |
| 8 | Implement Offline-First | 2 hours |
| 9 | Data Migration Strategy | 2 hours |
| 10 | Security Rules | 1 hour |
| 11 | Update Dependency Injection | 30 min |
| 12 | Testing Strategy | 3 hours |
| 13 | UI Enhancements | 2 hours |
| 14 | Error Handling | 2 hours |
| 15 | Documentation | 1 hour |

---

## Testing Plan

### Unit Tests (Target: 100% Coverage)
- AuthService: 20+ tests
- FirestoreStorageService: 25+ tests
- MigrationService: 15+ tests
- Updated TodoManager: 30+ tests

### Integration Tests
- Auth flow: 10+ tests
- Sync flow: 10+ tests
- Migration flow: 5+ tests

### Manual Testing
- [ ] Sign up with email/password
- [ ] Sign in with email/password
- [ ] Sign in with Google
- [ ] Create todo while online
- [ ] Create todo while offline
- [ ] Edit todo while offline
- [ ] Go online and verify sync
- [ ] Delete todo and verify sync
- [ ] Sign out and verify data cleared
- [ ] Sign in on second device
- [ ] Verify data synchronized
- [ ] Test migration from Hive data
- [ ] Test error scenarios

---

## Rollback Strategy

### If Firebase Integration Fails:
1. Keep Hive as primary storage
2. Disable Firebase services
3. Remove auth requirement
4. Continue with Phase 1 functionality

### Feature Flags:
```dart
// lib/config/feature_flags.dart
class FeatureFlags {
  static const bool useFirebase = true;  // Can be toggled
  static const bool requireAuth = true;
  static const bool enableGoogleSignIn = true;
}
```

---

## Security Considerations

### Authentication
- ✅ Strong password requirements (min 8 chars, mixed case, numbers)
- ✅ Email verification (optional enhancement)
- ✅ Rate limiting on auth endpoints (Firebase default)
- ✅ Secure token storage

### Data Protection
- ✅ User data isolation via security rules
- ✅ HTTPS only (Firebase enforced)
- ✅ No sensitive data in logs
- ✅ Proper error messages (no data leakage)

### Privacy
- ✅ Minimal data collection
- ✅ No third-party analytics (Phase 2)
- ✅ User can delete account
- ✅ Data export capability (future)

---

## Performance Considerations

### Firestore Optimization
1. **Indexes**: Auto-generated for simple queries
2. **Pagination**: Load todos in batches of 50
3. **Caching**: Use Firestore offline cache
4. **Batch Writes**: Group operations where possible

### Network Optimization
1. Minimize read operations (use cache)
2. Batch write operations
3. Compress large descriptions (future)
4. Use Firestore bundle for initial load (future)

### UI Optimization
1. Show cached data immediately
2. Background sync indicator
3. Optimistic updates
4. Lazy load profile images

---

## Monitoring & Analytics (Future)

### Metrics to Track:
- User sign-ups per day
- Active users (DAU/MAU)
- Todos created/completed per user
- Average session duration
- Sync success rate
- Error rates by type

### Tools:
- Firebase Analytics (future phase)
- Firebase Crashlytics (future phase)
- Firebase Performance Monitoring (future phase)

---

## Known Limitations

### Phase 2 Scope:
1. **No Email Verification** - Can be added later
2. **No Password Strength Meter** - Basic validation only
3. **No Social Sign-In** (except Google) - Apple, Facebook later
4. **No Collaborative Features** - Single user only
5. **No Advanced Conflict Resolution** - Last-write-wins only
6. **No Data Compression** - Large todos stored as-is
7. **No Search** - Basic filtering only

---

## Future Enhancements (Phase 3+)

### Potential Features:
1. **Social Features**
   - Share todos with others
   - Collaborative lists
   - Comments and mentions

2. **Advanced Features**
   - Recurring todos
   - Subtasks
   - Attachments
   - Rich text descriptions

3. **Integrations**
   - Calendar sync
   - Email notifications
   - Slack integration
   - API for third-party apps

4. **Mobile Apps**
   - iOS native app
   - Android native app
   - Push notifications

---

## Success Criteria

### Phase 2 is considered complete when:
- ✅ Users can sign up and sign in
- ✅ Users can sign in with Google
- ✅ Todos sync to Firestore
- ✅ Offline functionality works
- ✅ Data migrates from Hive
- ✅ Security rules deployed
- ✅ All tests passing (target: 90+ tests)
- ✅ Zero analysis errors
- ✅ Documentation complete
- ✅ Manual testing checklist passed

---

## Getting Started with Phase 2

### Prerequisites:
1. Phase 1 complete and working
2. Firebase account created
3. Git repository setup
4. Basic understanding of Firebase Auth and Firestore

### First Steps:
1. Create Firebase project
2. Add web app to Firebase
3. Download configuration
4. Run `flutter pub add firebase_core firebase_auth cloud_firestore`
5. Initialize Firebase in app
6. Start with Step 3 (AuthService)

---

## Questions & Decisions

### Technical Decisions to Make:
1. **Storage Strategy**: Firestore only, or Hive + Firestore?
   - **Decision**: Firestore primary, Hive for offline cache

2. **Auth Strategy**: Email/password only, or add Google?
   - **Decision**: Both for better UX

3. **Migration**: Automatic or manual?
   - **Decision**: Automatic with user consent

4. **Conflict Resolution**: Last-write-wins or custom?
   - **Decision**: Last-write-wins (simple for MVP)

5. **Offline Limits**: How long to queue offline operations?
   - **Decision**: No limit, Firebase handles it

---

## References

### Documentation:
- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Cloud Firestore](https://firebase.google.com/docs/firestore)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Offline Data with Firestore](https://firebase.google.com/docs/firestore/manage-data/enable-offline)

### Packages:
- [firebase_core](https://pub.dev/packages/firebase_core)
- [firebase_auth](https://pub.dev/packages/firebase_auth)
- [cloud_firestore](https://pub.dev/packages/cloud_firestore)
- [google_sign_in](https://pub.dev/packages/google_sign_in)

---

**Last Updated**: October 31, 2025
**Status**: 📋 **PLANNING PHASE**
**Ready to Start**: Step 1 - Firebase Project Setup

---

## Appendix: Code Snippets

### A. FirestoreStorageService Basic Structure
```dart
class FirestoreStorageService implements StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';
  CollectionReference get _todosCollection =>
      _firestore.collection('users').doc(_userId).collection('todos');

  @override
  Future<void> init() async {
    await _firestore.enablePersistence(
      const PersistenceSettings(synchronizeTabs: true),
    );
  }

  @override
  Future<List<Todo>> getAllTodos() async {
    final snapshot = await _todosCollection.get();
    return snapshot.docs
        .map((doc) => Todo.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<Todo>> watchTodos() {
    return _todosCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Todo.fromJson(doc.data() as Map<String, dynamic>))
          .toList(),
    );
  }

  // ... other methods
}
```

### B. AuthService Basic Structure
```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final ValueNotifier<User?> currentUser = ValueNotifier(null);
  final ValueNotifier<bool> isAuthenticated = ValueNotifier(false);

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      currentUser.value = user;
      isAuthenticated.value = user != null;
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign in failed');
    }
  }

  // ... other methods
}
```

---

**End of Phase 2 Plan**
