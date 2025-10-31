import 'package:flutter/material.dart';
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
    final filteredTodos = manager.filteredTodos;
    final currentFilter = watch(manager.currentFilter);
    final isLoading = watch(manager.loadTodosCommand.isExecuting);
    final activeTodoCount = manager.activeTodoCount;
    final hasCompletedTodos = manager.hasCompletedTodos;

    // Register error handler for commands
    registerHandler(
      select: (TodoManager m) => m.deleteTodoCommand.errors,
      handler: (context, error, cancel) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting todo: ${error.error}'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
    );

    registerHandler(
      select: (TodoManager m) => m.toggleTodoCommand.errors,
      handler: (context, error, cancel) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating todo: ${error.error}'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('TodoIt'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [
          if (hasCompletedTodos)
            IconButton(
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
                          manager.clearCompletedCommand();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              // Navigate to settings (Phase 1B - Step 12)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: _FilterChip(
                    label: 'All',
                    count: filteredTodos.length,
                    isSelected: currentFilter.value == TodoFilter.all,
                    onSelected: () => manager.setFilter(TodoFilter.all),
                  ),
                ),
                Expanded(
                  child: _FilterChip(
                    label: 'Active',
                    count: activeTodoCount,
                    isSelected: currentFilter.value == TodoFilter.active,
                    onSelected: () => manager.setFilter(TodoFilter.active),
                  ),
                ),
                Expanded(
                  child: _FilterChip(
                    label: 'Completed',
                    count: filteredTodos
                        .where((t) => t.isCompleted)
                        .length,
                    isSelected: currentFilter.value == TodoFilter.completed,
                    onSelected: () => manager.setFilter(TodoFilter.completed),
                  ),
                ),
              ],
            ),
          ),

          // Todo list
          Expanded(
            child: isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : filteredTodos.isEmpty
                    ? _buildEmptyState(context, currentFilter.value)
                    : RefreshIndicator(
                        onRefresh: () async {
                          manager.loadTodosCommand();
                          // Wait a bit for command to complete
                          await Future.delayed(const Duration(milliseconds: 500));
                        },
                        child: ListView.builder(
                          itemCount: filteredTodos.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final todo = filteredTodos[index];
                            return TodoItem(
                              todo: todo,
                              onTap: () => _navigateToEditTodo(context, todo),
                              onToggle: () => manager.toggleTodoCommand(todo.id),
                              onDelete: () => _confirmDelete(context, manager, todo),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddTodo(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Todo'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, TodoFilter filter) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String message;
    IconData icon;

    switch (filter) {
      case TodoFilter.all:
        message = 'No todos yet.\nTap the button below to create one!';
        icon = Icons.inbox_outlined;
        break;
      case TodoFilter.active:
        message = 'No active todos.\nAll done!';
        icon = Icons.check_circle_outline;
        break;
      case TodoFilter.completed:
        message = 'No completed todos yet.\nKeep working!';
        icon = Icons.pending_actions_outlined;
        break;
    }

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

  void _navigateToAddTodo(BuildContext context) {
    Navigator.pushNamed(context, '/add');
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
              manager.deleteTodoCommand(todo.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "${todo.title}"'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      // Undo functionality (add back the todo)
                      manager.addTodoCommand(TodoInput(
                        title: todo.title,
                        description: todo.description,
                      ));
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
