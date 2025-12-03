import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:todoit/features/todos/managers/todo_manager.dart';
import 'package:watch_it/watch_it.dart';

import 'features/todos/models/todo_dto.dart';
import 'features/todos/views/todo_list_view.dart';
import 'features/todos/views/todo_form_view.dart';
import 'locator.dart';
import 'services/storage/hive_storage_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TodoDTOAdapter());

  // Setup dependency injection
  setupLocator();

  // Initialize storage service
  await di<HiveStorageService>().init();

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = di<TodoManager>();

    manager.todos.observe(context, (prev, next) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      if (next case AsyncError state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${state.error}'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    });
    return MaterialApp(
      title: 'TodoIt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const TodoListView(),
      routes: {
        '/add': (context) => const TodoFormView(isEditing: false),
        '/edit': (context) => const TodoFormView(isEditing: true),
      },
    );
  }
}
