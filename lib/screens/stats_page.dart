import 'package:everyday/providers/goal_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: Consumer<GoalProvider>(
        builder: (context, goalProvider, child) {
          if (goalProvider.goals.isEmpty) {
            return const Center(
              child: Text('No stats to show yet.'),
            );
          }
          return ListView.builder(
            itemCount: goalProvider.goals.length,
            itemBuilder: (context, index) {
              final goal = goalProvider.goals[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Total Completions: ${goal.totalCompletions}'),
                      const SizedBox(height: 8),
                      Text('Current Streak: ${goal.currentStreak} days'),
                      const SizedBox(height: 8),
                      Text('Longest Streak: ${goal.longestStreak} days'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}