import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 1)
enum FrequencyType {
  @HiveField(0)
  daily,

  @HiveField(1)
  weekly,

  @HiveField(2)
  daysOfWeek,

  @HiveField(3)
  daysOfMonth,
}

@HiveType(typeId: 0)
class Goal extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late FrequencyType frequencyType;

  @HiveField(3)
  late List<int> frequencyValue;

  @HiveField(4)
  late List<DateTime> completions;

  Goal({
    required this.id,
    required this.name,
    required this.frequencyType,
    this.frequencyValue = const [],
    List<DateTime>? completions,
  }) : completions = completions ?? [];

  // --- Helper Methods ---

  List<DateTime> get _uniqueCompletionDates {
    return completions.map((c) => DateTime(c.year, c.month, c.day)).toSet().toList();
  }

  // Finds the most recent date on or before `from` that matches the goal's frequency.
  DateTime? _findLastDueDate(DateTime from) {
    switch (frequencyType) {
      case FrequencyType.daily:
        return from;
      case FrequencyType.weekly:
        return from.subtract(Duration(days: from.weekday - 1)); // Start of the week (Monday)
      case FrequencyType.daysOfWeek:
        if (frequencyValue.isEmpty) return null;
        // Go back day by day until we find a weekday that is in our list
        for (int i = 0; i < 7; i++) {
          final date = from.subtract(Duration(days: i));
          if (frequencyValue.contains(date.weekday)) {
            return date;
          }
        }
        return null;
      case FrequencyType.daysOfMonth:
        if (frequencyValue.isEmpty) return null;
        // Go back day by day, potentially across month boundaries
        for (int i = 0; i < 60; i++) { // Check back up to 2 months
          final date = from.subtract(Duration(days: i));
          if (frequencyValue.contains(date.day)) {
            return date;
          }
        }
        return null;
    }
  }

  // --- Public Getters ---

  int get totalCompletions => completions.length;

  int get longestStreak {
    if (completions.isEmpty || frequencyType != FrequencyType.daily) return 0;
    final dates = _uniqueCompletionDates;
    dates.sort();
    if (dates.isEmpty) return 0;
    int longest = 0;
    int current = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      if (dates[i+1].difference(dates[i]).inDays == 1) {
        current++;
      } else {
        if (current > longest) longest = current;
        current = 1;
      }
    }
    return current > longest ? current : longest;
  }

  int get currentStreak {
    if (completions.isEmpty || frequencyType != FrequencyType.daily) return 0;
    final dates = _uniqueCompletionDates;
    dates.sort((a, b) => b.compareTo(a)); // Sort descending
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (dates.isEmpty || dates.first.difference(today).inDays.abs() > 1) {
      return 0;
    }
    int current = 0;
    if (dates.first == today || dates.first == today.subtract(const Duration(days: 1))) {
        current = 1;
        for (int i = 0; i < dates.length - 1; i++) {
            if (dates[i].difference(dates[i+1]).inDays == 1) {
                current++;
            } else {
                break;
            }
        }
    }
    return current;
  }

  bool get isCompletedForToday {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final lastDueDate = _findLastDueDate(today);
    if (lastDueDate == null) return false;

    return _uniqueCompletionDates.any((d) => !d.isBefore(lastDueDate));
  }

  bool get wasCompletedInPreviousPeriod {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final lastDueDate = _findLastDueDate(today);
    if (lastDueDate == null) return false;

    // Find the due date before the most recent one
    final previousDueDate = _findLastDueDate(lastDueDate.subtract(const Duration(days: 1)));
    if (previousDueDate == null) return false;

    // Check for any completions between the previous due date (inclusive) and the last due date (exclusive)
    return _uniqueCompletionDates.any((d) => !d.isBefore(previousDueDate) && d.isBefore(lastDueDate));
  }
}