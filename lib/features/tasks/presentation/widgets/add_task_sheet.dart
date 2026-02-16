// Add Task Bottom Sheet Widget
// Beautiful bottom sheet for creating new tasks with priority, date, and tags.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task_entity.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../../../../core/theme/app_theme.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  TaskPriority _selectedPriority = TaskPriority.none;
  DateTime? _selectedDate;
  String _selectedRecurrence = 'None';
  final List<String> _tags = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<TaskBloc>().add(
        AddTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _selectedPriority,
          dueDate: _selectedDate,
          tags: _tags,
          isRecurring: _selectedRecurrence != 'None',
          recurringPattern: _selectedRecurrence != 'None'
              ? _selectedRecurrence.toLowerCase()
              : null,
        ),
      );
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && mounted) {
      // Now pick time
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (!mounted) return;
      setState(() {
        if (time != null) {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Text(
                'New Task',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),

              // ── Title Field ──
              TextFormField(
                controller: _titleController,
                autofocus: true,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: 'What needs to be done?',
                  prefixIcon: Icon(Icons.edit_rounded),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 12),

              // ── Description Field ──
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Add description (optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 20),

              // ── Priority Selector ──
              Text(
                'Priority',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: TaskPriority.values.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  final color = AppTheme.priorityColor(priority.index);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPriority = priority),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withAlpha(40)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? color : theme.dividerColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          priority.name[0].toUpperCase() +
                              priority.name.substring(1),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? color
                                : theme.colorScheme.onSurface.withAlpha(150),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Recurrence Selector ──
              Text(
                'Repeat',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['None', 'Daily', 'Weekly', 'Monthly'].map((option) {
                  final isSelected = _selectedRecurrence == option;
                  final color = AppTheme.primaryColor;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRecurrence = option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withAlpha(40)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? color : theme.dividerColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          option,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? color
                                : theme.colorScheme.onSurface.withAlpha(150),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Due Date & Tags Row ──
              Row(
                children: [
                  // Date Button
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedDate != null
                              ? AppTheme.primaryColor.withAlpha(20)
                              : theme.inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(14),
                          border: _selectedDate != null
                              ? Border.all(
                                  color: AppTheme.primaryColor.withAlpha(100),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: _selectedDate != null
                                  ? AppTheme.primaryColor
                                  : theme.colorScheme.onSurface.withAlpha(120),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _selectedDate != null
                                    ? DateFormat(
                                        'MMM d, h:mm a',
                                      ).format(_selectedDate!)
                                    : 'Set date',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _selectedDate != null
                                      ? AppTheme.primaryColor
                                      : theme.colorScheme.onSurface.withAlpha(
                                          120,
                                        ),
                                  fontWeight: _selectedDate != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Tags Input ──
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        hintText: 'Add tag',
                        prefixIcon: Icon(Icons.tag_rounded),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addTag,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),

              // ── Submit Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Create Task',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
