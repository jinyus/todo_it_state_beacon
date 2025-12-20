import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:todoit/features/todos/views/todo_form_view.dart';

import 'features/todos/views/todo_list_view.dart';
import 'locator.dart';

void main() async {
  await startUp();
  // Run the app
  runApp(LiteRefScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: Builder(
        builder: (context) {
          final manager = todoManagerRef.of(context);

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
          return const TodoListView();
        },
      ),
      routes: {
        '/add': (context) => const TodoFormView(),
        '/edit': (context) => const TodoFormView(),
      },
    );
  }
}
