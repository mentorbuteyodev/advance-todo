// Dependency Injection Setup
// Configures all dependencies using GetIt service locator.

import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import 'core/services/notification_service.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/tasks/data/datasources/remote_task_data_source.dart';
import 'features/tasks/data/datasources/task_local_data_source.dart';
import 'features/tasks/data/models/task_model.dart';
import 'features/tasks/data/repositories/task_repository_impl.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'core/theme/theme_cubit.dart';
import 'features/settings/presentation/bloc/settings_cubit.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // ── External ──
  final taskBox = await Hive.openBox<TaskModel>('tasks');
  sl.registerLazySingleton<Box<TaskModel>>(() => taskBox);

  // ── Services ──
  sl.registerLazySingleton<NotificationService>(() => NotificationService());

  // ── Repositories (Auth first — required by remote data source) ──
  sl.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository());

  // ── Data Sources ──
  sl.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(sl<Box<TaskModel>>()),
  );
  sl.registerLazySingleton<RemoteTaskDataSource>(
    () => RemoteTaskDataSourceImpl(authRepository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(
      localDataSource: sl<TaskLocalDataSource>(),
      remoteDataSource: sl<RemoteTaskDataSource>(),
    ),
  );

  // ── Blocs ──
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<TaskBloc>(
    () => TaskBloc(
      repository: sl<TaskRepository>(),
      notificationService: sl<NotificationService>(),
      settingsCubit: sl<SettingsCubit>(),
    ),
  );
  sl.registerFactory<ThemeCubit>(() => ThemeCubit());
  sl.registerLazySingleton<SettingsCubit>(() => SettingsCubit());
}
