part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final bool notificationsEnabled;

  const SettingsState({this.notificationsEnabled = true});

  SettingsState copyWith({bool? notificationsEnabled}) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  List<Object> get props => [notificationsEnabled];
}
