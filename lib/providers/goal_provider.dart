import 'package:everyday/services/google_auth_service.dart';
import 'package:everyday/services/google_drive_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:everyday/models/goal.dart';

class GoalProvider with ChangeNotifier {
  final String _boxName = 'goals_box';
  List<Goal> _goals = [];

  GoogleAuthService? _authService;
  GoogleDriveService? _driveService;
  bool _isSyncing = false;

  List<Goal> get goals => _goals;
  bool get isSyncing => _isSyncing;

  GoalProvider() {
    loadGoals();
  }

  void setAuth(GoogleAuthService authService) {
    if (_authService == authService) return;

    _authService = authService;
    _driveService = GoogleDriveService(_authService!);
    _authService!.addListener(_handleAuthChange);

    _handleAuthChange();
  }

  void _handleAuthChange() {
    if (_authService?.currentUser != null) {
      syncWithDrive();
    } else {
      loadGoals();
    }
  }

  Future<void> syncWithDrive() async {
    if (_authService?.currentUser == null || _driveService == null || _isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    final driveGoals = await _driveService!.downloadGoals();

    if (driveGoals != null) {
      final box = await Hive.openBox<Goal>(_boxName);
      await box.clear();
      for (final goal in driveGoals) {
        await box.put(goal.id, goal);
      }
      _goals = box.values.toList();

      if (driveGoals.isEmpty && _goals.isNotEmpty) {
          await _driveService?.uploadGoals(_goals);
      }
    }

    _isSyncing = false;
    notifyListeners();
  }

  Future<void> _uploadGoals() async {
    if (_authService?.currentUser != null && _driveService != null) {
      await _driveService!.uploadGoals(_goals);
    }
  }

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
    await _uploadGoals();
  }

  Future<void> toggleGoalCompletion(Goal goal, DateTime date) async {
    final goalIndex = _goals.indexWhere((g) => g.id == goal.id);
    if (goalIndex != -1) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final existingCompletionIndex = goal.completions.indexWhere((c) =>
          c.year == dateOnly.year && c.month == dateOnly.month && c.day == dateOnly.day);

      if (existingCompletionIndex != -1) {
        goal.completions.removeAt(existingCompletionIndex);
      } else {
        goal.completions.add(dateOnly);
      }

      await goal.save();
      notifyListeners();
      await _uploadGoals();
    }
  }

  Future<void> deleteGoal(Goal goal) async {
    final goalIndex = _goals.indexWhere((g) => g.id == goal.id);
    if (goalIndex != -1) {
      await goal.delete();
      _goals.removeAt(goalIndex);
      notifyListeners();
      await _uploadGoals();
    }
  }

  Future<void> updateGoal(Goal goal, String name, FrequencyType frequencyType, {List<int> frequencyValue = const []}) async {
    goal.name = name;
    goal.frequencyType = frequencyType;
    goal.frequencyValue = frequencyValue;

    await goal.save();
    notifyListeners();
    await _uploadGoals();
  }

  List<Goal> getActiveGoalsForDate(DateTime date) {
    return _goals.where((goal) => goal.isActiveForDate(date)).toList();
  }

  double getCompletionPercentageForDate(DateTime date) {
    final activeGoals = getActiveGoalsForDate(date);
    if (activeGoals.isEmpty) {
      return 0.0;
    }
    final completedGoals = activeGoals.where((goal) => goal.isConsideredCompleteForDate(date)).length;
    return completedGoals / activeGoals.length;
  }

  @override
  void dispose() {
    _authService?.removeListener(_handleAuthChange);
    super.dispose();
  }
}