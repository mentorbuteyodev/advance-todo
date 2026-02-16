// Tasks Page - Main screen displaying the task list
// Features filter tabs, staggered animations, empty state, and progress header.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/task_item.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const _TasksBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => BlocProvider.value(
              value: context.read<TaskBloc>(),
              child: const AddTaskSheet(),
            ),
          );
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

class _TasksBody extends StatelessWidget {
  const _TasksBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.headerGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TaskFlow',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.search_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // ── Progress Indicator ──
                          if (state is TaskLoaded) ...[
                            _ProgressCard(
                              completedCount: state.completedCount,
                              totalCount: state.totalCount,
                              completionRate: state.completionRate,
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Filter Tabs ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _FilterTabs(
                  activeFilter: state is TaskLoaded
                      ? state.activeFilter
                      : TaskFilter.all,
                ),
              ),
            ),

            // ── Task List ──
            if (state is TaskLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state is TaskLoaded && state.filteredTasks.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(filter: state.activeFilter),
              )
            else if (state is TaskLoaded)
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: AnimationLimiter(
                  child: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final task = state.filteredTasks[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 40.0,
                          child: FadeInAnimation(
                            child: TaskItem(
                              task: task,
                              onToggle: () => context.read<TaskBloc>().add(
                                ToggleTaskStatus(task),
                              ),
                              onDelete: () => context.read<TaskBloc>().add(
                                DeleteTask(task.id),
                              ),
                              onTap: () => context.push('/tasks/${task.id}'),
                            ),
                          ),
                        ),
                      );
                    }, childCount: state.filteredTasks.length),
                  ),
                ),
              )
            else if (state is TaskError)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Something went wrong',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(state.message, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),

            // ── FAB spacer ──
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }
}

// ── Progress Card ──
class _ProgressCard extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final double completionRate;

  const _ProgressCard({
    required this.completedCount,
    required this.totalCount,
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Row(
        children: [
          // Circle progress
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: completionRate,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withAlpha(40),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Text(
                  '${(completionRate * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedCount of $totalCount tasks completed',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 13,
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

// ── Filter Tabs ──
class _FilterTabs extends StatefulWidget {
  final TaskFilter activeFilter;

  const _FilterTabs({required this.activeFilter});

  @override
  State<_FilterTabs> createState() => _FilterTabsState();
}

class _FilterTabsState extends State<_FilterTabs> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _chipKeys = List.generate(
    TaskFilter.values.length,
    (_) => GlobalKey(),
  );

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToChip(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyContext = _chipKeys[index].currentContext;
      if (keyContext == null) return;

      final box = keyContext.findRenderObject() as RenderBox;
      final chipWidth = box.size.width;
      final chipOffset = box.localToGlobal(Offset.zero).dx;

      final scrollViewBox =
          _scrollController.position.context.storageContext.findRenderObject()
              as RenderBox;
      final scrollViewWidth = scrollViewBox.size.width;
      final scrollViewOffset = scrollViewBox.localToGlobal(Offset.zero).dx;

      // Target: center the chip in the scroll view
      final chipRelativeOffset = chipOffset - scrollViewOffset;
      final targetScroll =
          _scrollController.offset +
          chipRelativeOffset -
          (scrollViewWidth / 2) +
          (chipWidth / 2);

      _scrollController.animateTo(
        targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TaskFilter.values.asMap().entries.map((entry) {
          final index = entry.key;
          final filter = entry.value;
          final isActive = filter == widget.activeFilter;
          final label = switch (filter) {
            TaskFilter.all => 'All Tasks',
            TaskFilter.today => 'Today',
            TaskFilter.upcoming => 'Upcoming',
            TaskFilter.completed => 'Done',
          };
          final icon = switch (filter) {
            TaskFilter.all => Icons.list_rounded,
            TaskFilter.today => Icons.today_rounded,
            TaskFilter.upcoming => Icons.upcoming_rounded,
            TaskFilter.completed => Icons.check_circle_rounded,
          };

          return Padding(
            key: _chipKeys[index],
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                selected: isActive,
                showCheckmark: false,
                avatar: Icon(
                  icon,
                  size: 16,
                  color: isActive
                      ? Colors.white
                      : theme.colorScheme.onSurface.withAlpha(120),
                ),
                label: Text(label),
                labelStyle: TextStyle(
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  color: isActive
                      ? Colors.white
                      : theme.colorScheme.onSurface.withAlpha(150),
                ),
                selectedColor: AppTheme.primaryColor,
                backgroundColor: theme.cardTheme.color,
                side: BorderSide(
                  color: isActive
                      ? AppTheme.primaryColor
                      : theme.dividerColor.withAlpha(60),
                ),
                onSelected: (_) {
                  context.read<TaskBloc>().add(FilterTasks(filter));
                  _scrollToChip(index);
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Empty State ──
class _EmptyState extends StatelessWidget {
  final TaskFilter filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, title, subtitle) = switch (filter) {
      TaskFilter.all => (
        Icons.inbox_rounded,
        'No tasks yet',
        'Tap + to create your first task',
      ),
      TaskFilter.today => (
        Icons.wb_sunny_rounded,
        'Nothing due today',
        'Enjoy your free time! 🎉',
      ),
      TaskFilter.upcoming => (
        Icons.event_rounded,
        'No upcoming tasks',
        'Set due dates to see tasks here',
      ),
      TaskFilter.completed => (
        Icons.emoji_events_rounded,
        'No completed tasks',
        'Complete some tasks to see them here',
      ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 40, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(120),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
