import 'package:everyday/models/goal.dart';
import 'package:everyday/providers/goal_provider.dart';
import 'package:everyday/screens/add_edit_goal_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Consumer<GoalProvider>(
        builder: (context, goalProvider, child) {
          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final percentage = goalProvider.getCompletionPercentageForDate(day);
                    if (percentage > 0) {
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Color.lerp(Colors.green[100], Colors.green[900], percentage),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: _buildGoalList(goalProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGoalList(GoalProvider goalProvider) {
    if (_selectedDay == null) {
      return const Center(child: Text('Select a day to see your goals.'));
    }

    final activeGoals = goalProvider.getActiveGoalsForDate(_selectedDay!);

    if (activeGoals.isEmpty) {
      return const Center(child: Text('No goals for this day.'));
    }

    return ListView.builder(
      itemCount: activeGoals.length,
      itemBuilder: (context, index) {
        final goal = activeGoals[index];
        return ListTile(
          title: Text(goal.name),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => AddEditGoalScreen(goal: goal),
            ));
          },
          trailing: Checkbox(
            value: goal.isCompletedOnDate(_selectedDay!),
            onChanged: (bool? value) {
              goalProvider.toggleGoalCompletion(goal, _selectedDay!);
            },
          ),
        );
      },
    );
  }
}