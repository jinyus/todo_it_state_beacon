import 'package:flutter/material.dart';
import 'package:todoit/features/todos/managers/todo_manager.dart';
import 'package:watch_it/watch_it.dart';
import '../../models/todo.dart';

/// A widget representing a single todo item in the list
///
/// This widget displays a todo with its completion status,
/// title, and optional description. It provides interactions
/// for toggling completion and navigation to edit mode.
class TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const TodoItem({
    super.key,
    required this.todo,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final manager = di<TodoManager>();

    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => manager.deleteTodo(todo.id),
      confirmDismiss: (_) async {
        return showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete todo?'),
            content: Text('Are you sure you want to delete "${todo.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context, true);
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
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: colorScheme.error,
        child: Icon(Icons.delete_outline, color: colorScheme.onError, size: 28),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: todo.isCompleted ? 0 : 1,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Checkbox(
            value: todo.isCompleted,
            onChanged: (_) => onToggle(),
            shape: const CircleBorder(),
          ),
          title: Text(
            todo.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              decoration: todo.isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: todo.isCompleted
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurface,
            ),
          ),
          subtitle: todo.description.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    todo.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      decoration: todo.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : null,
          trailing: Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
