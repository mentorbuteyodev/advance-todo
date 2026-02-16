// NLP Service - Local, rule-based parsing of task titles.

import '../../features/tasks/domain/entities/task_entity.dart';

class NLPResult {
  final String title;
  final DateTime? dueDate;
  final TaskPriority priority;
  final List<String> tags;

  NLPResult({
    required this.title,
    this.dueDate,
    this.priority = TaskPriority.none,
    this.tags = const [],
  });
}

class NLPService {
  static NLPResult parse(String input) {
    if (input.isEmpty) return NLPResult(title: '');

    String title = input;
    DateTime? dueDate;
    TaskPriority priority = TaskPriority.none;
    List<String> tags = [];

    // 1. Parse Priority (!high, !medium, !low, !urgent)
    final priorityRegex = RegExp(r'!(\w+)\b', caseSensitive: false);
    final priorityMatches = priorityRegex.allMatches(title);
    for (final match in priorityMatches) {
      final val = match.group(1)?.toLowerCase();
      if (val == 'high') priority = TaskPriority.high;
      if (val == 'medium') priority = TaskPriority.medium;
      if (val == 'low') priority = TaskPriority.low;
      if (val == 'urgent') priority = TaskPriority.urgent;
    }
    title = title.replaceAll(priorityRegex, '').trim();

    // 2. Parse Tags (#work, #grocery)
    final tagRegex = RegExp(r'#(\w+)\b', caseSensitive: false);
    final tagMatches = tagRegex.allMatches(title);
    for (final match in tagMatches) {
      final tag = match.group(1);
      if (tag != null) tags.add(tag);
    }
    title = title.replaceAll(tagRegex, '').trim();

    // 3. Parse Dates (today, tomorrow, next [day])
    final now = DateTime.now();

    // Check "today"
    if (RegExp(r'\btoday\b', caseSensitive: false).hasMatch(title)) {
      dueDate = DateTime(now.year, now.month, now.day, 23, 59);
      title = title
          .replaceFirst(RegExp(r'\btoday\b', caseSensitive: false), '')
          .trim();
    }
    // Check "tomorrow"
    else if (RegExp(r'\btomorrow\b', caseSensitive: false).hasMatch(title)) {
      final tomorrow = now.add(const Duration(days: 1));
      dueDate = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        9,
        0,
      ); // Default 9am
      title = title
          .replaceFirst(RegExp(r'\btomorrow\b', caseSensitive: false), '')
          .trim();
    }

    // 4. Parse Time (at 3pm, at 14:00, @10am)
    final timeRegex = RegExp(
      r'(@|at\s)(\d{1,2})(:(\d{2}))?(\s?(am|pm))?',
      caseSensitive: false,
    );
    final timeMatch = timeRegex.firstMatch(title);
    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(2)!);
      int minute = int.tryParse(timeMatch.group(4) ?? '0') ?? 0;
      final amPm = timeMatch.group(6)?.toLowerCase();

      if (amPm == 'pm' && hour < 12) hour += 12;
      if (amPm == 'am' && hour == 12) hour = 0;

      final baseDate = dueDate ?? now;
      dueDate = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        hour,
        minute,
      );
      title = title.replaceFirst(timeRegex, '').trim();
    }

    // Clean up leftover double spaces
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

    return NLPResult(
      title: title,
      dueDate: dueDate,
      priority: priority,
      tags: tags,
    );
  }
}
