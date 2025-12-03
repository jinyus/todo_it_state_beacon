import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:todoit/features/todos/managers/todo_manager.dart';
import 'package:watch_it/watch_it.dart';

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
