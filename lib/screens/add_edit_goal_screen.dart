import 'package:everyday/models/goal.dart';
import 'package:everyday/providers/goal_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddEditGoalScreen extends StatefulWidget {
  final Goal? goal;

  const AddEditGoalScreen({Key? key, this.goal}) : super(key: key);

  @override
  _AddEditGoalScreenState createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late FrequencyType _frequencyType;
  List<int> _selectedDays = []; // For daysOfWeek

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _name = widget.goal!.name;
      _frequencyType = widget.goal!.frequencyType;
      _selectedDays = List<int>.from(widget.goal!.frequencyValue);
    } else {
      _name = '';
      _frequencyType = FrequencyType.daily;
    }
  }

  void _saveForm() {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    _formKey.currentState!.save();

    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    List<int> frequencyValue = [];
    if (_frequencyType == FrequencyType.daysOfWeek ||
        _frequencyType == FrequencyType.daysOfMonth) {
      frequencyValue = _selectedDays;
    }

    if (widget.goal == null) {
      // Add new goal
      goalProvider.addGoal(_name, _frequencyType, frequencyValue: frequencyValue);
    } else {
      // Update existing goal
      goalProvider.updateGoal(widget.goal!, _name, _frequencyType, frequencyValue: frequencyValue);
    }

    Navigator.of(context).pop();
  }

  Widget _buildDaySelector() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Wrap(
      spacing: 8.0,
      children: List<Widget>.generate(7, (int index) {
        return FilterChip(
          label: Text(days[index]),
          selected: _selectedDays.contains(index + 1),
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(index + 1);
              } else {
                _selectedDays.removeWhere((int day) => day == index + 1);
              }
              _selectedDays.sort();
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildMonthDaySelector() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: List<Widget>.generate(31, (int index) {
        final day = index + 1;
        return FilterChip(
          label: Text('$day'),
          selected: _selectedDays.contains(day),
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(day);
              } else {
                _selectedDays.removeWhere((int d) => d == day);
              }
              _selectedDays.sort();
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal == null ? 'Add Goal' : 'Edit Goal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Goal Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<FrequencyType>(
                value: _frequencyType,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: FrequencyType.values.map((FrequencyType type) {
                  return DropdownMenuItem<FrequencyType>(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (FrequencyType? newValue) {
                  setState(() {
                    _frequencyType = newValue!;
                    _selectedDays.clear();
                  });
                },
              ),
              if (_frequencyType == FrequencyType.daysOfWeek) ...[
                const SizedBox(height: 16),
                const Text('Select Days'),
                _buildDaySelector(),
              ],
              if (_frequencyType == FrequencyType.daysOfMonth) ...[
                const SizedBox(height: 16),
                const Text('Select Days of Month'),
                _buildMonthDaySelector(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}