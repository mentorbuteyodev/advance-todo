// Tasks Page - Main screen displaying the task list
// Features filter tabs, staggered animations, empty state, and progress header.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/task_item.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // allow gradient to show
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

class _TasksBody extends StatefulWidget {
  const _TasksBody();

  @override
  State<_TasksBody> createState() => _TasksBodyState();
}

class _TasksBodyState extends State<_TasksBody> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Header Animation State
  double _headerOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    // Cap the offset at 100 which is roughly the height we want to collapse by
    if (offset < 0) {
      if (_headerOffset != 0) setState(() => _headerOffset = 0);
    } else if (offset <= 100) {
      setState(() => _headerOffset = offset);
    } else if (_headerOffset != 100) {
      setState(() => _headerOffset = 100);
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        context.read<TaskBloc>().add(const SearchQueryChanged(''));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate animation values
    // as we scroll down (offset goes up), progress card opacity goes down
    final double progressOpacity = (1.0 - (_headerOffset / 80)).clamp(0.0, 1.0);
    final double headerHeightReduction = _headerOffset.clamp(0.0, 80.0);

    // Main Gradient Container acting as the substantial background
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Trigger a fresh load (which includes sync) when user logs in
          context.read<TaskBloc>().add(LoadTasks());
        }
      },
      child: Container(
        decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        child: SafeArea(
          bottom: false, // Let the sheet go to the bottom
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Fixed Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row (Animated Title/Search Swap + Profile)
                    SizedBox(
                      height: 56,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.2, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: _isSearching
                                  ? PhysicalModel(
                                      key: const ValueKey('search_field'),
                                      color: Colors.white,
                                      elevation: 4,
                                      shadowColor: Colors.black.withAlpha(50),
                                      borderRadius: BorderRadius.circular(30),
                                      child: TextField(
                                        controller: _searchController,
                                        autofocus: true,
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF2D3436),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        cursorColor: theme.primaryColor,
                                        decoration: InputDecoration(
                                          fillColor: Colors.white,
                                          filled: true,
                                          hintText: 'Search tasks...',
                                          hintStyle: GoogleFonts.inter(
                                            color: const Color(0xFFB2BEC3),
                                            fontSize: 15,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.search_rounded,
                                            color: theme.primaryColor,
                                            size: 22,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              color: Color(0xFF636E72),
                                              size: 20,
                                            ),
                                            onPressed: _toggleSearch,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFDFE6E9),
                                              width: 1.5,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 14,
                                              ),
                                        ),
                                        onChanged: (value) {
                                          context.read<TaskBloc>().add(
                                            SearchQueryChanged(value),
                                          );
                                        },
                                      ),
                                    )
                                  : Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'TaskFlow',
                                        key: const ValueKey('app_title'),
                                        style: theme.textTheme.headlineLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -1,
                                            ),
                                      ),
                                    ),
                            ),
                          ),

                          // Right Side Icons
                          Row(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: !_isSearching
                                    ? Row(
                                        key: const ValueKey('header_actions'),
                                        children: [
                                          IconButton(
                                            onPressed: _toggleSearch,
                                            icon: const Icon(
                                              Icons.search_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      )
                                    : const SizedBox(
                                        key: ValueKey('header_spacer'),
                                        width: 8,
                                      ),
                              ),
                              Hero(
                                tag: 'profile_btn',
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => context.push('/profile'),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(30),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Progress Card (Animated Height Collapse)
                    BlocBuilder<TaskBloc, TaskState>(
                      builder: (context, state) {
                        // Determine target height: 0 if searching, else based on scroll
                        // Check for loading state to avoid jank
                        final shouldShow = state is TaskLoaded && !_isSearching;
                        final double targetHeight = shouldShow
                            ? (90 - headerHeightReduction).clamp(0.0, 90.0)
                            : 0.0;

                        // Also animate margin to 0 when collapsed
                        final double targetMargin = shouldShow
                            ? (24 - (headerHeightReduction / 3)).clamp(
                                0.0,
                                24.0,
                              )
                            : 0.0;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          height: targetHeight,
                          margin: EdgeInsets.only(
                            top: shouldShow ? targetMargin : 0,
                            bottom: shouldShow ? targetMargin : 16,
                          ),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: state is TaskLoaded
                                ? Opacity(
                                    // Opacity is also driven by scroll, but force 0 if searching
                                    opacity: _isSearching
                                        ? 0.0
                                        : progressOpacity,
                                    child: _ProgressCard(
                                      completedCount: state.completedCount,
                                      totalCount: state.totalCount,
                                      completionRate: state.completionRate,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Floating Sheet ──
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: BlocBuilder<TaskBloc, TaskState>(
                    builder: (context, state) {
                      return CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // Filter Tabs (Pinned to top of sheet?)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                24,
                                16,
                                16,
                              ),
                              child: _FilterTabs(
                                activeFilter: state is TaskLoaded
                                    ? state.activeFilter
                                    : TaskFilter.all,
                              ),
                            ),
                          ),

                          // List Content
                          if (state is TaskLoading)
                            const SliverFillRemaining(
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (state is TaskLoaded &&
                              state.filteredTasks.isEmpty)
                            SliverFillRemaining(
                              child: _EmptyState(filter: state.activeFilter),
                            )
                          else if (state is TaskLoaded)
                            SliverPadding(
                              padding: const EdgeInsets.only(bottom: 100),
                              // Key forces re-animation when filter changes
                              sliver: AnimationLimiter(
                                key: ValueKey(
                                  '${state.activeFilter}_${state.filteredTasks.length}',
                                ),
                                child: SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final task = state.filteredTasks[index];
                                    return AnimationConfiguration.staggeredList(
                                      position: index,
                                      duration: const Duration(
                                        milliseconds: 375,
                                      ),
                                      child: SlideAnimation(
                                        verticalOffset: 50.0,
                                        child: FadeInAnimation(
                                          child: ScaleAnimation(
                                            scale: 0.95,
                                            child: TaskItem(
                                              task: task,
                                              onToggle: () => context
                                                  .read<TaskBloc>()
                                                  .add(ToggleTaskStatus(task)),
                                              onDelete: () => context
                                                  .read<TaskBloc>()
                                                  .add(DeleteTask(task.id)),
                                              onTap: () => context.push(
                                                '/tasks/${task.id}',
                                              ),
                                            ),
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
                                    Text(
                                      state.message,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
      // Fixed height to avoid jumps during opacity transition handled by parent
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              mainAxisAlignment: MainAxisAlignment.center,
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
