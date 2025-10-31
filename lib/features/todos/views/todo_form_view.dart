import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../managers/todo_manager.dart';
import '../models/todo.dart';

/// Form view for adding or editing a todo
///
/// This view handles both creation and editing of todos.
/// It uses WatchingWidget to react to command execution states.
class TodoFormView extends WatchingWidget {
  final bool isEditing;

  const TodoFormView({
    super.key,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    final manager = di<TodoManager>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Watch command execution state
    final isExecuting = isEditing
        ? watch(manager.updateTodoCommand.isExecuting).value
        : watch(manager.addTodoCommand.isExecuting).value;

    // Get selected todo for editing
    final selectedTodo = isEditing
        ? watch(manager.selectedTodo).value
        : null;

    // Register error handler
    registerHandler(
      select: (TodoManager m) => isEditing
          ? m.updateTodoCommand.errors
          : m.addTodoCommand.errors,
      handler: (context, error, cancel) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.error}'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Todo' : 'New Todo'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: _TodoForm(
        isEditing: isEditing,
        initialTodo: selectedTodo,
        isExecuting: isExecuting,
        onSave: (title, description) => _saveTodo(
          context,
          manager,
          title,
          description,
          selectedTodo,
        ),
      ),
    );
  }

  void _saveTodo(
    BuildContext context,
    TodoManager manager,
    String title,
    String description,
    Todo? existingTodo,
  ) {
    if (isEditing && existingTodo != null) {
      // Update existing todo
      final updatedTodo = existingTodo.copyWith(
        title: title,
        description: description,
      );
      manager.updateTodoCommand(updatedTodo);
    } else {
      // Create new todo
      manager.addTodoCommand(TodoInput(
        title: title,
        description: description,
      ));
    }

    // Navigate back after a short delay to allow command to complete
    Future.delayed(const Duration(milliseconds: 300), () {
      if (context.mounted) {
        Navigator.pop(context);
      }
    });
  }
}

/// Internal form widget with state
class _TodoForm extends StatefulWidget {
  final bool isEditing;
  final Todo? initialTodo;
  final bool isExecuting;
  final void Function(String title, String description) onSave;

  const _TodoForm({
    required this.isEditing,
    required this.initialTodo,
    required this.isExecuting,
    required this.onSave,
  });

  @override
  State<_TodoForm> createState() => _TodoFormState();
}

class _TodoFormState extends State<_TodoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialTodo?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialTodo?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title field
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              hintText: 'Enter todo title',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.title),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
            ),
            textInputAction: TextInputAction.next,
            autofocus: !widget.isEditing,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Title is required';
              }
              return null;
            },
            enabled: !widget.isExecuting,
          ),

          const SizedBox(height: 16),

          // Description field
          TextFormField(
            controller: _descriptionController,
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
            enabled: !widget.isExecuting,
            onFieldSubmitted: (_) => _handleSubmit(),
          ),

          const SizedBox(height: 24),

          // Save button
          FilledButton.icon(
            onPressed: widget.isExecuting ? null : _handleSubmit,
            icon: widget.isExecuting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(widget.isEditing ? 'Update' : 'Create'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          const SizedBox(height: 8),

          // Cancel button
          OutlinedButton.icon(
            onPressed: widget.isExecuting
                ? null
                : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          if (widget.isEditing && widget.initialTodo != null) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Metadata
            _MetadataCard(
              title: 'Created',
              value: _formatDate(widget.initialTodo!.createdAt),
              icon: Icons.calendar_today,
            ),

            if (widget.initialTodo!.updatedAt != null) ...[
              const SizedBox(height: 8),
              _MetadataCard(
                title: 'Last Updated',
                value: _formatDate(widget.initialTodo!.updatedAt!),
                icon: Icons.update,
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        _titleController.text,
        _descriptionController.text,
      );
    }
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
            Icon(
              icon,
              size: 20,
              color: colorScheme.primary,
            ),
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
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
