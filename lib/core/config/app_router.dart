// App Router - GoRouter configuration

import 'package:go_router/go_router.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../../features/tasks/presentation/pages/task_detail_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'tasks',
      builder: (context, state) => const TasksPage(),
    ),
    GoRoute(
      path: '/tasks/:taskId',
      name: 'taskDetail',
      builder: (context, state) {
        final taskId = state.pathParameters['taskId']!;
        return TaskDetailPage(taskId: taskId);
      },
    ),
  ],
);
