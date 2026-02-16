// Dependency Injection Setup
// Configures all dependencies using GetIt service locator.

import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import 'core/services/notification_service.dart';
import 'features/tasks/data/datasources/task_local_data_source.dart';
import 'features/tasks/data/models/task_model.dart';
import 'features/tasks/data/repositories/task_repository_impl.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // ── External ──
  final taskBox = await Hive.openBox<TaskModel>('tasks');
  sl.registerLazySingleton<Box<TaskModel>>(() => taskBox);

  // ── Services ──
  sl.registerLazySingleton<NotificationService>(() => NotificationService());

  // ── Data Sources ──
  sl.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(sl<Box<TaskModel>>()),
  );

  // ── Repositories ──
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(localDataSource: sl<TaskLocalDataSource>()),
  );

  // ── Blocs ──
  sl.registerFactory<TaskBloc>(
    () => TaskBloc(
      repository: sl<TaskRepository>(),
      notificationService: sl<NotificationService>(),
    ),
  );
}
