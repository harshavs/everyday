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
  List<int> _selectedValues = []; // For daysOfWeek and daysOfMonth

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _name = widget.goal!.name;
      _frequencyType = widget.goal!.frequencyType;
      _selectedValues = List<int>.from(widget.goal!.frequencyValue);
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
    if (_frequencyType == FrequencyType.daysOfWeek || _frequencyType == FrequencyType.daysOfMonth) {
      frequencyValue = _selectedValues;
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

  Widget _buildDayOfWeekSelector() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Wrap(
      spacing: 8.0,
      children: List<Widget>.generate(7, (int index) {
        return FilterChip(
          label: Text(days[index]),
          selected: _selectedValues.contains(index + 1),
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedValues.add(index + 1);
              } else {
                _selectedValues.removeWhere((int day) => day == index + 1);
              }
              _selectedValues.sort();
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildDayOfMonthSelector() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: 31,
      itemBuilder: (context, index) {
        final day = index + 1;
        return InkWell(
          onTap: () {
            setState(() {
              if (_selectedValues.contains(day)) {
                _selectedValues.remove(day);
              } else {
                _selectedValues.add(day);
              }
              _selectedValues.sort();
            });
          },
          child: Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selectedValues.contains(day) ? Theme.of(context).primaryColor : Colors.transparent,
              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: _selectedValues.contains(day) ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ),
        );
      },
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
                    _selectedValues.clear();
                  });
                },
              ),
              if (_frequencyType == FrequencyType.daysOfWeek) ...[
                const SizedBox(height: 16),
                const Text('Select Days of the Week'),
                _buildDayOfWeekSelector(),
              ],
              if (_frequencyType == FrequencyType.daysOfMonth) ...[
                const SizedBox(height: 16),
                const Text('Select Days of the Month'),
                _buildDayOfMonthSelector(),
              ]
            ],
          ),
        ),
      ),
    );
  }
}