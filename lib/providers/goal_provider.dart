import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:everyday/models/goal.dart';

class GoalProvider with ChangeNotifier {
  final String _boxName = 'goals_box';
  List<Goal> _goals = [];

  List<Goal> get goals => _goals;

  Future<void> loadGoals() async {
    final box = await Hive.openBox<Goal>(_boxName);
    _goals = box.values.toList();
    notifyListeners();
  }

  Future<void> addGoal(String name, FrequencyType frequencyType, {List<int> frequencyValue = const []}) async {
    final newGoal = Goal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      frequencyType: frequencyType,
      frequencyValue: frequencyValue,
      completions: [],
    );

    final box = Hive.box<Goal>(_boxName);
    await box.put(newGoal.id, newGoal);
    _goals.add(newGoal);
    notifyListeners();
  }

  Future<void> toggleGoalCompletion(Goal goal, DateTime date) async {
    final goalIndex = _goals.indexWhere((g) => g.id == goal.id);
    if (goalIndex != -1) {
      final today = DateTime(date.year, date.month, date.day);
      final existingCompletionIndex = goal.completions.indexWhere((c) =>
          c.year == today.year && c.month == today.month && c.day == today.day);

      if (existingCompletionIndex != -1) {
        goal.completions.removeAt(existingCompletionIndex);
      } else {
        goal.completions.add(today);
      }

      await goal.save();
      notifyListeners();
    }
  }

  Future<void> deleteGoal(Goal goal) async {
    final goalIndex = _goals.indexWhere((g) => g.id == goal.id);
    if (goalIndex != -1) {
      await goal.delete();
      _goals.removeAt(goalIndex);
      notifyListeners();
    }
  }

  Future<void> updateGoal(Goal goal, String name, FrequencyType frequencyType, {List<int> frequencyValue = const []}) async {
    goal.name = name;
    goal.frequencyType = frequencyType;
    goal.frequencyValue = frequencyValue;

    await goal.save();
    notifyListeners();
  }
}
