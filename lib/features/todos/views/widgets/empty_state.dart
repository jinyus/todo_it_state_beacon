import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:todoit/features/todos/managers/todo_manager.dart';
import 'package:todoit/locator.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = todoManagerRef.of(context);
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
