import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce/hive.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  static const _boxName = 'settings';
  static const _keyNotifications = 'notifications_enabled';
  late Box _box;

  SettingsCubit() : super(const SettingsState()) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox(_boxName);
    final enabled = _box.get(_keyNotifications, defaultValue: true);
    emit(state.copyWith(notificationsEnabled: enabled));
  }

  Future<void> toggleNotifications(bool enabled) async {
    await _box.put(_keyNotifications, enabled);
    emit(state.copyWith(notificationsEnabled: enabled));
  }
}
