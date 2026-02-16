import 'package:equatable/equatable.dart';

enum AppThemeMode { light, dark, system }

class ThemeState extends Equatable {
  final AppThemeMode themeMode;

  const ThemeState(this.themeMode);

  @override
  List<Object> get props => [themeMode];
}
