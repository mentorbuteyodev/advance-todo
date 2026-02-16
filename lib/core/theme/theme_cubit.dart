import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static const String _boxName = 'theme_settings';
  static const String _key = 'theme_mode';

  ThemeCubit() : super(const ThemeState(AppThemeMode.system)) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final box = await Hive.openBox(_boxName);
    final savedMode = box.get(_key, defaultValue: 'system') as String;

    final mode = AppThemeMode.values.firstWhere(
      (e) => e.name == savedMode,
      orElse: () => AppThemeMode.system,
    );

    emit(ThemeState(mode));
  }

  Future<void> updateTheme(AppThemeMode mode) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_key, mode.name);
    emit(ThemeState(mode));
  }
}
