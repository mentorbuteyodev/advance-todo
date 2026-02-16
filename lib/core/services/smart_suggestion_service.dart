// Smart Suggestion Service - Recommends features based on task content.

import '../../features/tasks/domain/entities/task_entity.dart';

class SmartSuggestionService {
  static const Map<String, List<String>> _tagMap = {
    'shopping': ['buy', 'shop', 'grocery', 'order', 'store'],
    'work': ['meeting', 'call', 'zoom', 'email', 'report', 'office', 'project'],
    'health': ['gym', 'run', 'workout', 'doctor', 'med', 'exercise', 'water'],
    'personal': ['book', 'read', 'watch', 'clean', 'home', 'family'],
    'finance': ['pay', 'bill', 'bank', 'rent', 'tax', 'invoice'],
  };

  static const Map<TaskPriority, List<String>> _priorityMap = {
    TaskPriority.urgent: ['urgent', 'asap', 'critical', 'immediately'],
    TaskPriority.high: ['important', 'must', 'deadline', 'priority'],
    TaskPriority.low: ['maybe', 'later', 'eventually', 'low'],
  };

  static List<String> suggestTags(String title, String description) {
    final suggestions = <String>[];
    final combined = '$title $description'.toLowerCase();

    _tagMap.forEach((tag, keywords) {
      if (keywords.any((k) => combined.contains(k))) {
        suggestions.add(tag);
      }
    });

    return suggestions;
  }

  static TaskPriority? suggestPriority(String title, String description) {
    final combined = '$title $description'.toLowerCase();

    for (var entry in _priorityMap.entries) {
      if (entry.value.any((k) => combined.contains(k))) {
        return entry.key;
      }
    }

    return null;
  }
}
