import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:todoit/features/todos/views/widgets/action_buttons.dart';
import 'package:todoit/features/todos/views/widgets/empty_state.dart';
import 'package:todoit/features/todos/views/widgets/filter_tabs.dart';
import 'package:todoit/locator.dart';

import 'widgets/todo_item.dart';

/// Main view for displaying the list of todos
///
/// This view uses WatchingWidget to reactively update when todos change.
/// It provides filtering options and supports adding, editing, and deleting todos.
class TodoListView extends StatelessWidget {
  const TodoListView({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = todoManagerRef.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Watch reactive state
    final filteredTodos = manager.filteredTodos.watch(context);
    final isLoading = manager.todos.watch(context).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TodoIt'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [ClearCompletedButton(), SettingsButton()],
      ),
      body: Column(
        children: [
          // Filter tabs
          FilterTabs(),

          Expanded(
            child: switch ((isLoading, filteredTodos.isEmpty)) {
              (true, _) => const Center(child: CircularProgressIndicator()),
              (_, true) => const EmptyState(),
              _ => const TodoList(),
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/add');
          manager.clearSelection();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Todo'),
      ),
    );
  }
}

class TodoList extends StatelessWidget {
  const TodoList({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = todoManagerRef.of(context);
    final filteredTodos = manager.filteredTodos.watch(context);

    return RefreshIndicator(
      onRefresh: () async {
        manager.todos.reset();
        await manager.todos.next();
      },
      child: ListView.builder(
        itemCount: filteredTodos.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final todo = filteredTodos[index];
          return TodoItem(
            todo: todo,
            onTap: () async {
              manager.selectTodo(todo);
              await Navigator.pushNamed(context, '/edit');
              manager.clearSelection();
            },
            onToggle: () => manager.toggleTodo(todo.id),
          );
        },
      ),
    );
  }
}
