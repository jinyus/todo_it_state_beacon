import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:watch_it/watch_it.dart';

import '../managers/todo_manager.dart';
import '../models/todo.dart';
import 'widgets/todo_item.dart';

/// Main view for displaying the list of todos
///
/// This view uses WatchingWidget to reactively update when todos change.
/// It provides filtering options and supports adding, editing, and deleting todos.
class TodoListView extends WatchingWidget {
  const TodoListView({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = di<TodoManager>();
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
        onPressed: () => Navigator.pushNamed(context, '/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Todo'),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = di<TodoManager>();
    final filter = manager.currentFilter.watch(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (message, icon) = switch (filter) {
      TodoFilter.all => (
        'No todos yet.\nTap the button below to create one!',
        Icons.inbox_outlined,
      ),
      TodoFilter.active => (
        'No active todos.\nAll done!',
        Icons.check_circle_outline,
      ),
      TodoFilter.completed => (
        'No completed todos yet.\nKeep working!',
        Icons.pending_actions_outlined,
      ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TodoList extends StatelessWidget {
  const TodoList({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = di<TodoManager>();
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
            onTap: () => _navigateToEditTodo(context, todo),
            onToggle: () => manager.toggleTodo(todo.id),
            onDelete: () => _confirmDelete(context, manager, todo),
          );
        },
      ),
    );
  }

  void _navigateToEditTodo(BuildContext context, Todo todo) {
    di<TodoManager>().selectTodo(todo);
    Navigator.pushNamed(context, '/edit');
  }

  void _confirmDelete(BuildContext context, TodoManager manager, Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete todo?'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              manager.deleteTodo(todo.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "${todo.title}"'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      // Undo functionality (add back the todo)
                      manager.addTodo(
                        TodoInput(
                          title: todo.title,
                          description: todo.description,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class FilterTabs extends StatelessWidget {
  const FilterTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = di<TodoManager>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Watch reactive state
    final currentFilter = manager.currentFilter.watch(context);
    final activeTodoCount = manager.activeCount.watch(context);
    final completeCount = manager.completedCount.watch(context);

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        children: TodoFilter.values.map((filter) {
          return Expanded(
            child: _FilterChip(
              label: filter.name.toUpperCase(),
              count: switch (filter) {
                TodoFilter.all => activeTodoCount + completeCount,
                TodoFilter.active => activeTodoCount,
                TodoFilter.completed => completeCount,
              },
              isSelected: currentFilter == filter,
              onSelected: () => manager.setFilter(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: 'Settings',
      onPressed: () {
        // Navigate to settings (Phase 1B - Step 12)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings coming soon!')));
      },
    );
  }
}

class ClearCompletedButton extends StatelessWidget {
  const ClearCompletedButton({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = di<TodoManager>();
    final hasCompletedTodos = manager.hasCompleted.watch(context);

    if (!hasCompletedTodos) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.delete_sweep),
      tooltip: 'Clear completed',
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear completed todos?'),
            content: const Text(
              'This will permanently delete all completed todos.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  manager.clearCompleted();
                  Navigator.pop(context);
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Filter chip widget for the filter bar
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
