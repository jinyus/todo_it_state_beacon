import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:todoit/features/todos/models/todo.dart';
import 'package:watch_it/watch_it.dart';

import '../managers/todo_manager.dart';

/// Form view for adding or editing a todo
///
/// This view handles both creation and editing of todos.
/// It uses WatchingWidget to react to command execution states.
class TodoFormView extends WatchingWidget {
  const TodoFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTodo = di<TodoManager>().selectedTodo.watch(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedTodo == null ? 'New Todo' : 'Edit Todo'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: _TodoForm(selectedTodo),
    );
  }
}

/// Internal form widget with state
class _TodoForm extends StatelessWidget {
  const _TodoForm(this.selectedTodo);

  final Todo? selectedTodo;

  @override
  Widget build(BuildContext context) {
    final manager = di<TodoManager>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isEditing = selectedTodo != null;
    final isLoading = manager.todos.watch(context).isLoading;
    final titleFieldError = manager.titleFieldValid.watch(context);

    Future<void> submitForm() async {
      if (titleFieldError != null) return;
      await manager.submitForm();
      if (context.mounted) {
        Navigator.pop(context);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Title field
        TextFormField(
          forceErrorText: titleFieldError,
          controller: manager.titleField.controller,
          decoration: InputDecoration(
            labelText: 'Title',
            hintText: 'Enter todo title',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.title),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
          ),
          textInputAction: TextInputAction.next,
          autofocus: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Title is required';
            }
            return null;
          },
          enabled: !isLoading,
        ),

        const SizedBox(height: 16),

        // Description field
        TextFormField(
          controller: manager.descriptionField.controller,
          decoration: InputDecoration(
            labelText: 'Description (optional)',
            hintText: 'Enter todo description',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.notes),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            alignLabelWithHint: true,
          ),
          textInputAction: TextInputAction.done,
          maxLines: 5,
          minLines: 3,
          enabled: !isLoading,
          onFieldSubmitted: (_) => submitForm(),
        ),

        const SizedBox(height: 24),

        // Save button
        FilledButton.icon(
          onPressed: isLoading ? null : submitForm,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check),
          label: Text(isEditing ? 'Update' : 'Create'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        const SizedBox(height: 8),

        // Cancel button
        OutlinedButton.icon(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          label: const Text('Cancel'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        if (isEditing) ...[
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Metadata
          _MetadataCard(
            title: 'Created',
            value: _formatDate(selectedTodo!.createdAt),
            icon: Icons.calendar_today,
          ),

          if (selectedTodo!.updatedAt != null) ...[
            const SizedBox(height: 8),
            _MetadataCard(
              title: 'Last Updated',
              value: _formatDate(selectedTodo!.updatedAt!),
              icon: Icons.update,
            ),
          ],
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Metadata card widget
class _MetadataCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetadataCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
