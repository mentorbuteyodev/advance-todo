// Add Task Bottom Sheet Widget
// Beautiful bottom sheet for creating new tasks with priority, date, and tags.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task_entity.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/nlp_service.dart';
import '../../../../core/services/smart_suggestion_service.dart';

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

  // AI/NLP State
  DateTime? _suggestedDate;
  TaskPriority? _suggestedPriority;
  List<String> _suggestedTags = [];
  bool _isAutoParsing = true;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_isAutoParsing) return;

    final title = _titleController.text;
    final desc = _descriptionController.text;

    // 1. NLP Parse for Date/Time/Priority from Title
    final nlp = NLPService.parse(title);

    // 2. Smart Suggestions for Tags/Priority from Both
    final smartPri = SmartSuggestionService.suggestPriority(title, desc);
    final smartTags = SmartSuggestionService.suggestTags(title, desc);

    setState(() {
      _suggestedDate = nlp.dueDate;
      _suggestedPriority = nlp.priority != TaskPriority.none
          ? nlp.priority
          : smartPri;

      // Combine NLP tags and Smart Suggestions, filtering out already added tags
      final allSuggestedTags = {
        ...nlp.tags,
        ...smartTags,
      }.where((t) => !_tags.contains(t)).toList();

      _suggestedTags = allSuggestedTags;
    });
  }

  void _applySuggestion({DateTime? date, TaskPriority? priority, String? tag}) {
    // If auto-parsing is on, we want to update the title to the "cleaned" version
    // that NLPService provides, but only for the parts we are applying.
    final currentTitle = _titleController.text;
    final nlp = NLPService.parse(currentTitle);

    setState(() {
      if (date != null) {
        _selectedDate = date;
        _suggestedDate = null;
        // If the date was parsed from NLP, we can use the cleaned title
        if (nlp.dueDate != null) {
          _titleController.text = nlp.title;
          _titleController.selection = TextSelection.fromPosition(
            TextPosition(offset: _titleController.text.length),
          );
        }
      }

      if (priority != null) {
        _selectedPriority = priority;
        _suggestedPriority = null;
        // If priority was parsed from NLP, update title
        if (nlp.priority != TaskPriority.none) {
          _titleController.text = nlp.title;
          _titleController.selection = TextSelection.fromPosition(
            TextPosition(offset: _titleController.text.length),
          );
        }
      }

      if (tag != null && !_tags.contains(tag)) {
        _tags.add(tag);
        _suggestedTags.remove(tag);
        // Surgical removal of the tag from the title if it exists as a #tag
        final tagRegex = RegExp('#$tag\\b', caseSensitive: false);
        if (currentTitle.contains(tagRegex)) {
          _titleController.text = currentTitle
              .replaceFirst(tagRegex, '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          // Maintain cursor at the end
          _titleController.selection = TextSelection.fromPosition(
            TextPosition(offset: _titleController.text.length),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      String title = _titleController.text.trim();
      DateTime? dueDate = _selectedDate;
      TaskPriority priority = _selectedPriority;
      List<String> tags = List.from(_tags);

      // Final NLP pass if auto-parsing is enabled to catch any unapplied chips
      if (_isAutoParsing) {
        final nlp = NLPService.parse(title);
        title = nlp.title;
        if (dueDate == null) dueDate = nlp.dueDate;
        if (priority == TaskPriority.none) priority = nlp.priority;
        for (final tag in nlp.tags) {
          if (!tags.contains(tag)) tags.add(tag);
        }
      }

      context.read<TaskBloc>().add(
        AddTask(
          title: title,
          description: _descriptionController.text.trim(),
          priority: priority,
          dueDate: dueDate,
          tags: tags,
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

              // ── AI Suggestions Bar ──
              if (_suggestedDate != null ||
                  _suggestedPriority != null ||
                  _suggestedTags.isNotEmpty)
                _buildAISuggestions(theme),

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

  Widget _buildAISuggestions(ThemeData theme) {
    return Container(
      width: double.infinity,
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
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Suggestions',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _isAutoParsing = !_isAutoParsing),
                child: Icon(
                  _isAutoParsing
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  size: 16,
                  color: AppTheme.primaryColor.withAlpha(100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (_suggestedDate != null)
                  _SuggestionChip(
                    icon: Icons.calendar_today_rounded,
                    label: DateFormat('MMM d, h:mm a').format(_suggestedDate!),
                    onTap: () => _applySuggestion(date: _suggestedDate),
                  ),
                if (_suggestedPriority != null)
                  _SuggestionChip(
                    icon: Icons.flag_rounded,
                    label: _suggestedPriority!.name.toUpperCase(),
                    color: AppTheme.priorityColor(_suggestedPriority!.index),
                    onTap: () => _applySuggestion(priority: _suggestedPriority),
                  ),
                ..._suggestedTags.map(
                  (tag) => _SuggestionChip(
                    icon: Icons.tag_rounded,
                    label: tag,
                    onTap: () => _applySuggestion(tag: tag),
                  ),
                ),
              ],
            ),
          ),
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
