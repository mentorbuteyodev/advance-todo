// App Localizations — lightweight string lookup, no codegen needed.
// Reads from a static map of key→value pairs for the current locale.

import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [Locale('en')];

  // ─── Strings ────────────────────────────────────────────────

  String get appTitle => 'TaskFlow';

  // Auth
  String get login => 'Login';
  String get register => 'Register';
  String get email => 'Email';
  String get password => 'Password';
  String get confirmPassword => 'Confirm Password';
  String get displayName => 'Display Name';
  String get forgotPassword => 'Forgot Password?';
  String get dontHaveAccount => "Don't have an account?";
  String get alreadyHaveAccount => 'Already have an account?';
  String get signUp => 'Sign Up';
  String get signIn => 'Sign In';
  String get signOut => 'Sign Out';
  String get loginSubtitle => 'Welcome back! Sign in to continue.';
  String get registerSubtitle => 'Create an account to get started.';

  // Profile
  String get profile => 'Profile';
  String get editProfile => 'Edit Profile';
  String get changePassword => 'Change Password';
  String get currentPassword => 'Current Password';
  String get newPassword => 'New Password';
  String get darkMode => 'Dark Mode';
  String get notifications => 'Notifications';
  String get taskReminders => 'Task Reminders';
  String get appearance => 'Appearance';
  String get account => 'Account';

  // Actions
  String get save => 'Save';
  String get cancel => 'Cancel';
  String get delete => 'Delete';
  String get update => 'Update';

  // Tasks
  String get tasks => 'Tasks';
  String get addTask => 'Add Task';
  String get editTask => 'Edit Task';
  String get deleteTask => 'Delete Task';
  String get taskTitle => 'Task title';
  String get taskDescription => 'Description (optional)';
  String get dueDate => 'Due Date';
  String get priority => 'Priority';
  String get tags => 'Tags';
  String get addTag => 'Add tag';
  String get subtasks => 'Subtasks';
  String get addSubtask => 'Add subtask';
  String get noTasks => 'No tasks yet';
  String get noTasksSubtitle => 'Tap + to create your first task';
  String get searchTasks => 'Search tasks...';
  String get createTask => 'Create Task';

  // Filters
  String get filterAll => 'All';
  String get filterToday => 'Today';
  String get filterUpcoming => 'Upcoming';
  String get filterCompleted => 'Completed';

  // Priority
  String get priorityNone => 'None';
  String get priorityLow => 'Low';
  String get priorityMedium => 'Medium';
  String get priorityHigh => 'High';
  String get priorityUrgent => 'Urgent';

  // Status
  String get statusTodo => 'To Do';
  String get statusInProgress => 'In Progress';
  String get statusCompleted => 'Completed';

  // Parameterized
  String deleteConfirmMessage(String title) =>
      'Are you sure you want to delete "$title"? This will also delete all subtasks.';

  String completedProgress(int completed, int total) =>
      '$completed/$total completed';

  String taskDueIn30(String title) => '$title is due in 30 minutes';
  String taskDueNowBody(String title) => '$title is due right now';
  String reminderSetBody(String title) =>
      "You'll be reminded about \"$title\" 30 min before it's due";

  // Misc
  String get overdue => 'Overdue';
  String get inProgress => 'In Progress';
  String get completed => 'Completed';
  String get recurring => 'Recurring';
  String get daily => 'Daily';
  String get weekly => 'Weekly';
  String get monthly => 'Monthly';
}

// ─── Delegate ─────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .map((l) => l.languageCode)
      .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
