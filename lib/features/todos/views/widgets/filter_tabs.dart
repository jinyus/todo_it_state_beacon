import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:todoit/features/todos/managers/todo_manager.dart';
import 'package:watch_it/watch_it.dart';

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
