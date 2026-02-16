// Task Detail Page - View, edit, and manage subtasks for a single task.
// Reached by tapping a task in the list. Supports inline editing,
// priority/date changes, and subtask CRUD.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../../../../core/services/smart_suggestion_service.dart';
import '../../../../core/services/nlp_service.dart';

class TaskDetailPage extends StatefulWidget {
  final String taskId;

  const TaskDetailPage({super.key, required this.taskId});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final _subtaskController = TextEditingController();
  final _tagController = TextEditingController();
  bool _isEditingTitle = false;
  bool _isEditingDescription = false;
  @override
  void initState() {
    super.initState();
    // Controllers will be updated when task is loaded in build,
    // but initialized here to avoid re-creation in build
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  TaskEntity? _findTask(TaskState state) {
    if (state is TaskLoaded) {
      try {
        return state.tasks.firstWhere((t) => t.id == widget.taskId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void _saveTitle(TaskEntity task) {
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty && newTitle != task.title) {
      context.read<TaskBloc>().add(UpdateTask(task.copyWith(title: newTitle)));
    }
    setState(() => _isEditingTitle = false);
  }

  void _saveDescription(TaskEntity task) {
    final newDesc = _descriptionController.text.trim();
    if (newDesc != task.description) {
      context.read<TaskBloc>().add(
        UpdateTask(task.copyWith(description: newDesc)),
      );
    }
    setState(() => _isEditingDescription = false);
  }

  void _changePriority(TaskEntity task, TaskPriority priority) {
    context.read<TaskBloc>().add(UpdateTask(task.copyWith(priority: priority)));
  }

  Future<void> _changeDueDate(TaskEntity task) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: task.dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: task.dueDate != null
            ? TimeOfDay.fromDateTime(task.dueDate!)
            : TimeOfDay.now(),
      );
      final newDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
      if (mounted) {
        context.read<TaskBloc>().add(
          UpdateTask(task.copyWith(dueDate: newDate)),
        );
      }
    }
  }

  void _addTag(TaskEntity task) {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !task.tags.contains(tag)) {
      final updatedTags = [...task.tags, tag];
      context.read<TaskBloc>().add(
        UpdateTask(task.copyWith(tags: updatedTags)),
      );
      _tagController.clear();
    }
  }

  void _removeTag(TaskEntity task, String tag) {
    final updatedTags = task.tags.where((t) => t != tag).toList();
    context.read<TaskBloc>().add(UpdateTask(task.copyWith(tags: updatedTags)));
  }

  void _addSubtask(TaskEntity parentTask) {
    final title = _subtaskController.text.trim();
    if (title.isNotEmpty) {
      context.read<TaskBloc>().add(
        AddSubtask(parentId: parentTask.id, title: title),
      );
      _subtaskController.clear();
    }
  }

  void _deleteTask(TaskEntity task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text(
          'Are you sure you want to delete "${task.title}"? This will also delete all subtasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TaskBloc>().add(DeleteTask(task.id));
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        final task = _findTask(state);

        if (task == null) {
          return Scaffold(
            appBar: AppBar(leading: const BackButton()),
            body: const Center(child: Text('Task not found')),
          );
        }

        // Update controllers if not editing to reflect latest task state
        if (!_isEditingTitle && _titleController.text != task.title) {
          _titleController.text = task.title;
        }
        if (!_isEditingDescription &&
            _descriptionController.text != task.description) {
          _descriptionController.text = task.description;
        }

        final theme = Theme.of(context);
        final priorityColor = AppTheme.priorityColor(task.priority.index);

        return Scaffold(
          backgroundColor: priorityColor,
          body: Stack(
            children: [
              // ── Background Hero ──
              // Kept from refactor to fix Hero Nesting Bug
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 300,
                child: Hero(
                  tag: 'priority_${task.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          priorityColor.withAlpha(220),
                          priorityColor.withAlpha(160),
                          AppTheme.primaryColor.withAlpha(180),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),

              Column(
                children: [
                  // ── Content Header (SafeArea) ──
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Navigation Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => context.pop(),
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withAlpha(30),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _deleteTask(task),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withAlpha(30),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Status Indication
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(50),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              task.isCompleted
                                  ? '✓ Completed'
                                  : task.isOverdue
                                  ? '⚠ Overdue'
                                  : '● In Progress',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Title Hero (Sibling to background hero)
                          Hero(
                            tag: 'title_${task.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                task.title,
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Floating Sheet with Original Body Content ──
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── RESTORED ORIGINAL CONTENT DESIGN ──

                              // Title Edit
                              _SectionHeader(
                                icon: Icons.edit_rounded,
                                title: 'Title',
                                onTap: () =>
                                    setState(() => _isEditingTitle = true),
                              ),
                              const SizedBox(height: 8),
                              if (_isEditingTitle)
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _titleController,
                                        autofocus: true,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        decoration: const InputDecoration(
                                          hintText: 'Task title',
                                          isDense: true,
                                        ),
                                        onSubmitted: (_) => _saveTitle(task),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.check_rounded),
                                      color: AppTheme.successColor,
                                      onPressed: () => _saveTitle(task),
                                    ),
                                  ],
                                )
                              else
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _isEditingTitle = true),
                                  child: Text(
                                    task.title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),

                              // Description
                              _SectionHeader(
                                icon: Icons.notes_rounded,
                                title: 'Description',
                                onTap: () => setState(
                                  () => _isEditingDescription = true,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_isEditingDescription)
                                Column(
                                  children: [
                                    TextField(
                                      controller: _descriptionController,
                                      autofocus: true,
                                      maxLines: 4,
                                      minLines: 2,
                                      decoration: const InputDecoration(
                                        hintText: 'Add a description...',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () => _saveDescription(task),
                                        icon: const Icon(
                                          Icons.check_rounded,
                                          size: 18,
                                        ),
                                        label: const Text('Save'),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _isEditingDescription = true,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.inputDecorationTheme.fillColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      task.description.isEmpty
                                          ? 'Tap to add a description...'
                                          : task.description,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: task.description.isEmpty
                                                ? theme.colorScheme.onSurface
                                                      .withAlpha(100)
                                                : theme.colorScheme.onSurface,
                                            height: 1.5,
                                          ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),

                              // Priority
                              _SectionHeader(
                                icon: Icons.flag_rounded,
                                title: 'Priority',
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: TaskPriority.values.map((p) {
                                    final isSelected = task.priority == p;
                                    final color = AppTheme.priorityColor(
                                      p.index,
                                    );
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: GestureDetector(
                                        onTap: () => _changePriority(task, p),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? color.withAlpha(40)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? color
                                                  : theme.dividerColor,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: Text(
                                            p.name[0].toUpperCase() +
                                                p.name.substring(1),
                                            style: TextStyle(
                                              color: isSelected
                                                  ? color
                                                  : theme.colorScheme.onSurface
                                                        .withAlpha(150),
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
                              ),
                              const SizedBox(height: 24),

                              // Smart Priority Suggestion
                              if (task.priority == TaskPriority.none)
                                _buildAISuggestionSection(
                                  theme,
                                  title: 'Suggested Priority',
                                  child: _SuggestionChip(
                                    icon: Icons.flag_rounded,
                                    label:
                                        (SmartSuggestionService.suggestPriority(
                                                  task.title,
                                                  task.description,
                                                ) ??
                                                TaskPriority.medium)
                                            .name
                                            .toUpperCase(),
                                    onTap: () => _changePriority(
                                      task,
                                      SmartSuggestionService.suggestPriority(
                                            task.title,
                                            task.description,
                                          ) ??
                                          TaskPriority.medium,
                                    ),
                                    color: AppTheme.priorityColor(
                                      (SmartSuggestionService.suggestPriority(
                                                task.title,
                                                task.description,
                                              ) ??
                                              TaskPriority.medium)
                                          .index,
                                    ),
                                  ),
                                ),

                              // Due Date
                              _SectionHeader(
                                icon: Icons.calendar_today_rounded,
                                title: 'Due Date',
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _changeDueDate(task),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: task.dueDate != null
                                        ? (task.isOverdue
                                              ? AppTheme.errorColor.withAlpha(
                                                  20,
                                                )
                                              : AppTheme.primaryColor.withAlpha(
                                                  20,
                                                ))
                                        : theme.inputDecorationTheme.fillColor,
                                    borderRadius: BorderRadius.circular(14),
                                    border: task.dueDate != null
                                        ? Border.all(
                                            color: task.isOverdue
                                                ? AppTheme.errorColor.withAlpha(
                                                    100,
                                                  )
                                                : AppTheme.primaryColor
                                                      .withAlpha(100),
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 18,
                                        color: task.dueDate != null
                                            ? (task.isOverdue
                                                  ? AppTheme.errorColor
                                                  : AppTheme.primaryColor)
                                            : theme.colorScheme.onSurface
                                                  .withAlpha(120),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        task.dueDate != null
                                            ? DateFormat(
                                                'EEEE, MMM d, yyyy • h:mm a',
                                              ).format(task.dueDate!)
                                            : 'Tap to set a due date',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: task.dueDate != null
                                                  ? (task.isOverdue
                                                        ? AppTheme.errorColor
                                                        : AppTheme.primaryColor)
                                                  : theme.colorScheme.onSurface
                                                        .withAlpha(120),
                                              fontWeight: task.dueDate != null
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Tags
                              _SectionHeader(
                                icon: Icons.tag_rounded,
                                title: 'Tags',
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: task.tags.map((tag) {
                                  return Chip(
                                    label: Text(tag),
                                    visualDensity: VisualDensity.compact,
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 14,
                                    ),
                                    onDeleted: () => _removeTag(task, tag),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _tagController,
                                      decoration: const InputDecoration(
                                        hintText: 'Add a tag...',
                                        prefixIcon: Icon(
                                          Icons.tag_rounded,
                                          size: 18,
                                        ),
                                        isDense: true,
                                      ),
                                      onSubmitted: (_) => _addTag(task),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _addTag(task),
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 20,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor
                                          .withAlpha(20),
                                      foregroundColor: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              (() {
                                final allSuggestedTags = {
                                  ...NLPService.parse(
                                    _titleController.text,
                                  ).tags,
                                  ...SmartSuggestionService.suggestTags(
                                    task.title,
                                    task.description,
                                  ),
                                }.where((t) => !task.tags.contains(t)).toList();

                                if (allSuggestedTags.isEmpty)
                                  return const SizedBox.shrink();

                                return _buildAISuggestionSection(
                                  theme,
                                  title: 'Suggested Tags',
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: allSuggestedTags
                                          .map(
                                            (tag) => _SuggestionChip(
                                              icon: Icons.tag_rounded,
                                              label: tag,
                                              onTap: () {
                                                final currentTitle =
                                                    _titleController.text;
                                                final tagRegex = RegExp(
                                                  '#$tag\\b',
                                                  caseSensitive: false,
                                                );

                                                if (currentTitle.contains(
                                                  tagRegex,
                                                )) {
                                                  _titleController.text =
                                                      currentTitle
                                                          .replaceFirst(
                                                            tagRegex,
                                                            '',
                                                          )
                                                          .replaceAll(
                                                            RegExp(r'\s+'),
                                                            ' ',
                                                          )
                                                          .trim();
                                                  // Maintain cursor
                                                  _titleController.selection =
                                                      TextSelection.fromPosition(
                                                        TextPosition(
                                                          offset:
                                                              _titleController
                                                                  .text
                                                                  .length,
                                                        ),
                                                      );
                                                  // Save the new title too
                                                  _saveTitle(task);
                                                }

                                                context.read<TaskBloc>().add(
                                                  UpdateTask(
                                                    task.copyWith(
                                                      tags: [...task.tags, tag],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                );
                              })(),
                              const SizedBox(height: 24),

                              // Subtasks
                              _SectionHeader(
                                icon: Icons.checklist_rounded,
                                title:
                                    'Subtasks (${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length})',
                              ),
                              const SizedBox(height: 8),

                              // Subtask progress bar
                              if (task.subtasks.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: task.subtasks.isEmpty
                                        ? 0
                                        : task.subtasks
                                                  .where((s) => s.isCompleted)
                                                  .length /
                                              task.subtasks.length,
                                    minHeight: 6,
                                    backgroundColor: AppTheme.primaryColor
                                        .withAlpha(30),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppTheme.successColor,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Subtask list
                              ...task.subtasks.map(
                                (subtask) => _SubtaskItem(
                                  subtask: subtask,
                                  onToggle: () => context.read<TaskBloc>().add(
                                    ToggleTaskStatus(subtask),
                                  ),
                                  onDelete: () => context.read<TaskBloc>().add(
                                    DeleteTask(subtask.id),
                                  ),
                                ),
                              ),

                              // Add subtask input
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _subtaskController,
                                      decoration: const InputDecoration(
                                        hintText: 'Add a subtask...',
                                        prefixIcon: Icon(
                                          Icons.add_rounded,
                                          size: 20,
                                        ),
                                        isDense: true,
                                      ),
                                      onSubmitted: (_) => _addSubtask(task),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _addSubtask(task),
                                    icon: const Icon(
                                      Icons.send_rounded,
                                      size: 20,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor
                                          .withAlpha(20),
                                      foregroundColor: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                context.read<TaskBloc>().add(ToggleTaskStatus(task)),
            icon: Icon(
              task.isCompleted ? Icons.replay_rounded : Icons.check_rounded,
            ),
            label: Text(task.isCompleted ? 'Reopen' : 'Complete'),
            backgroundColor: task.isCompleted
                ? AppTheme.warningColor
                : AppTheme.successColor,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildAISuggestionSection(
    ThemeData theme, {
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SuggestionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = color ?? AppTheme.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 14, color: activeColor),
        label: Text(label),
        onPressed: onTap,
        labelStyle: theme.textTheme.bodySmall?.copyWith(
          color: activeColor,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: activeColor.withAlpha(20),
        side: BorderSide(color: activeColor.withAlpha(50)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ── Shared Widgets (Restored from Original) ──

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _SectionHeader({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(150),
            letterSpacing: 0.5,
          ),
        ),
        if (onTap != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: onTap,
            child: Icon(
              Icons.edit_outlined,
              size: 14,
              color: theme.colorScheme.onSurface.withAlpha(100),
            ),
          ),
        ],
      ],
    );
  }
}

class _SubtaskItem extends StatelessWidget {
  final TaskEntity subtask;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SubtaskItem({
    required this.subtask,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withAlpha(40)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: subtask.isCompleted
                      ? AppTheme.successColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: subtask.isCompleted
                        ? AppTheme.successColor
                        : theme.dividerColor,
                    width: 2,
                  ),
                ),
                child: subtask.isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: theme.textTheme.bodyMedium!.copyWith(
                  decoration: subtask.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: subtask.isCompleted
                      ? theme.colorScheme.onSurface.withAlpha(100)
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                child: Text(subtask.title),
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withAlpha(80),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
