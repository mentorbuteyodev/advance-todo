// App Router - GoRouter configuration with auth redirect

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../../features/tasks/presentation/pages/task_detail_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';

import '../../core/presentation/pages/splash_page.dart';

GoRouter createAppRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthNotifier(authBloc),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isLoggedIn = authState is Authenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isSplash = state.matchedLocation == '/splash';

      // Still loading — stay on splash
      if (authState is AuthInitial || authState is AuthLoading) {
        return isSplash ? null : '/splash';
      }

      // Not logged in
      if (!isLoggedIn) {
        // If trying to access auth routes, let them. Otherwise, login.
        return isAuthRoute ? null : '/login';
      }

      // Logged in
      if (isLoggedIn) {
        // If on splash or auth routes, go to home
        if (isSplash || isAuthRoute) return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
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
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );
}

/// Notifier that triggers GoRouter redirect when auth state changes.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(AuthBloc authBloc) {
    authBloc.stream.listen((_) => notifyListeners());
  }
}
