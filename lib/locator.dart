import 'package:watch_it/watch_it.dart';

import 'services/storage/hive_storage_service.dart';
import 'features/todos/managers/todo_manager.dart';

/// Setup dependency injection using get_it
///
/// This function registers all services and managers as singletons.
/// Call this once during app initialization.
///
/// Note: watch_it provides the global 'di' instance (GetIt.instance)
void setupLocator() {
  // Services Layer
  // Register storage service as lazy singleton
  di.registerLazySingleton<HiveStorageService>(
    () => HiveStorageService(),
  );

  // Managers Layer
  // Register todo manager with storage service dependency
  di.registerLazySingleton<TodoManager>(
    () => TodoManager(di<HiveStorageService>()),
  );

  // Future managers can be added here:
  // di.registerLazySingleton<SettingsManager>(() => SettingsManager());
}

/// Reset dependency injection (useful for testing)
///
/// This clears all registered dependencies and allows re-registration.
Future<void> resetLocator() async {
  await di.reset();
}
