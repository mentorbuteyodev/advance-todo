// Task Item Widget
// A beautifully animated task card with slide-to-delete, priority indicator,
// and micro-interaction on checkbox toggle.

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task_entity.dart';
import '../../../../core/theme/app_theme.dart';

class TaskItem extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const TaskItem({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityColor = AppTheme.priorityColor(task.priority.index);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Slidable(
        key: ValueKey(task.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.25,
          children: [
            CustomSlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_rounded, size: 24),
                  SizedBox(height: 2),
                  Text('Delete', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        child: _ScaleButton(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: task.isOverdue
                    ? AppTheme.errorColor.withAlpha(80)
                    : theme.dividerColor.withAlpha(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Priority Line (Hero) ──
                Hero(
                  tag: 'priority_${task.id}',
                  child: Container(
                    width: 4,
                    height: 44,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Checkbox (Animated) ──
                _ScaleButton(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(right: 12, top: 2),
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? AppTheme.successColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: task.isCompleted
                            ? AppTheme.successColor
                            : theme.dividerColor,
                        width: 2,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),

                // ── Content ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title (Hero)
                      Hero(
                        tag: 'title_${task.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: theme.textTheme.bodyLarge!.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? theme.colorScheme.onSurface.withAlpha(100)
                                  : theme.colorScheme.onSurface,
                            ),
                            child: Text(task.title),
                          ),
                        ),
                      ),

                      // Description
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(120),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // ── Meta Row ──
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (task.dueDate != null)
                            _MetaChip(
                              icon: Icons.schedule_rounded,
                              label: DateFormat('MMM d').format(task.dueDate!),
                              color: task.isOverdue
                                  ? AppTheme.errorColor
                                  : AppTheme.primaryColor,
                            ),
                          if (task.subtasks.isNotEmpty)
                            _MetaChip(
                              icon: Icons.subdirectory_arrow_right_rounded,
                              label:
                                  '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}',
                              color: AppTheme.secondaryColor,
                            ),
                          ...task.tags
                              .take(2)
                              .map(
                                (tag) => _MetaChip(
                                  icon: Icons.tag_rounded,
                                  label: tag,
                                  color: AppTheme.primaryLight,
                                ),
                              ),
                          if (task.tags.length > 2)
                            _MetaChip(
                              icon: Icons.more_horiz_rounded,
                              label: '+${task.tags.length - 2}',
                              color: AppTheme.primaryLight,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Scale Button (Micro-interaction) ──
class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _ScaleButton({required this.child, this.onTap});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Duration _duration = const Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.forward();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _controller, child: widget.child),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
