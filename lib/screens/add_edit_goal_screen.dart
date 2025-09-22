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
  // TODO: Add state for frequency values

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _name = widget.goal!.name;
      _frequencyType = widget.goal!.frequencyType;
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
    if (widget.goal == null) {
      // Add new goal
      goalProvider.addGoal(_name, _frequencyType);
    } else {
      // Update existing goal
      goalProvider.updateGoal(widget.goal!, _name, _frequencyType);
    }

    Navigator.of(context).pop();
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
                  });
                },
              ),
              // TODO: Add UI for frequency values (e.g., day picker)
            ],
          ),
        ),
      ),
    );
  }
}
