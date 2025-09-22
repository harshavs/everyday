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

  int get totalCompletions => completions.length;

  int get longestStreak {
    if (completions.isEmpty || frequencyType != FrequencyType.daily) return 0;

    final uniqueDates = completions.map((c) => DateTime(c.year, c.month, c.day)).toSet().toList();
    uniqueDates.sort();

    if (uniqueDates.isEmpty) return 0;

    int longest = 0;
    int current = 1;

    for (int i = 0; i < uniqueDates.length - 1; i++) {
      if (uniqueDates[i+1].difference(uniqueDates[i]).inDays == 1) {
        current++;
      } else {
        if (current > longest) {
          longest = current;
        }
        current = 1;
      }
    }
    if (current > longest) {
      longest = current;
    }

    return longest;
  }

  int get currentStreak {
    if (completions.isEmpty || frequencyType != FrequencyType.daily) return 0;

    final uniqueDates = completions.map((c) => DateTime(c.year, c.month, c.day)).toSet().toList();
    uniqueDates.sort((a, b) => b.compareTo(a)); // Sort descending

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (uniqueDates.isEmpty ||
        (uniqueDates.first.difference(todayDate).inDays.abs() > 1 && uniqueDates.first != todayDate) ) {
      return 0; // No completions or last completion was not today or yesterday
    }

    int current = 0;
    if (uniqueDates.first == todayDate || uniqueDates.first == todayDate.subtract(const Duration(days: 1))) {
        current = 1;
        for (int i = 0; i < uniqueDates.length - 1; i++) {
            if (uniqueDates[i].difference(uniqueDates[i+1]).inDays == 1) {
                current++;
            } else {
                break;
            }
        }
    }

    return current;
  }
}
