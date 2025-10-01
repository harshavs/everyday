import 'package:everyday/models/goal.dart';
import 'package:everyday/providers/goal_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('Total', goal.totalCompletions),
                          _buildStatItem('Current Streak', goal.currentStreak),
                          _buildStatItem('Longest Streak', goal.longestStreak),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: _CompletionHeatmap(goal: goal),
                      ),
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

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _CompletionHeatmap extends StatelessWidget {
  final Goal goal;

  const _CompletionHeatmap({Key? key, required this.goal}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final completions = goal.completions.map((c) => DateTime(c.year, c.month, c.day)).toSet();
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    final data = <DateTime, int>{};

    for (int i = 0; i <= now.difference(oneYearAgo).inDays; i++) {
      final date = oneYearAgo.add(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (completions.contains(dateOnly)) {
        data[dateOnly] = 1;
      } else {
        data[dateOnly] = 0;
      }
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final date = oneYearAgo.add(Duration(days: groupIndex));
              final formattedDate = DateFormat.yMMMd().format(date);
              final status = rod.toY > 0 ? 'Completed' : 'Not Completed';
              return BarTooltipItem(
                '$formattedDate\n$status',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: data.entries.map((entry) {
          final x = data.keys.toList().indexOf(entry.key);
          final y = entry.value.toDouble();
          return BarChartGroupData(
            x: x,
            barRods: [
              BarChartRodData(
                toY: y,
                color: y > 0 ? Colors.green : Colors.grey[300],
                width: 5,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}