import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AddPersonalEntryScreen extends StatefulWidget {
  const AddPersonalEntryScreen({super.key});

  @override
  State<AddPersonalEntryScreen> createState() => _AddPersonalEntryScreenState();
}

class _AddPersonalEntryScreenState extends State<AddPersonalEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  bool _isNotReceived = false;
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Processing Data...')),
        );

        final data = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'cost': double.parse(_costController.text),
          'notReceived': _isNotReceived,
          if (_startDate != null) 'startDate': _startDate!.toIso8601String(),
          if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
        };

        await ApiService.addPersonalEntry(data);
        
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Entry added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
        }
      }
    }
  }

  Future<void> _addWork() async {
    if (_formKey.currentState!.validate()) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Processing Data...')),
        );

        final data = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'cost': double.parse(_costController.text),
          'notReceived': _isNotReceived,
          if (_startDate != null) 'startDate': _startDate!.toIso8601String(),
          if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
        };

        await ApiService.addPersonalEntry(data);
        
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Work Added Successfully'),
                backgroundColor: Colors.green,
              ),
            );

          // Clear form
          _nameController.clear();
          _descriptionController.clear();
          _costController.clear();
          _startDateController.clear();
          _endDateController.clear();
          setState(() {
            _isNotReceived = false;
            _startDate = null;
            _endDate = null;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Personal Entry',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: UnderlineInputBorder(),
                  hintText: 'Enter name',
                ),
                autofillHints: const [AutofillHints.name],
                key: const Key('personal-name-field'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: UnderlineInputBorder(),
                  hintText: 'Enter description',
                ),
                key: const Key('personal-description-field'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Cost',
                  border: UnderlineInputBorder(),
                  prefixText: '₹',
                  hintText: 'Enter cost',
                ),
                key: const Key('personal-cost-field'),
                autofillHints: const [AutofillHints.transactionAmount],
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cost';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isNotReceived ? Colors.red.shade200 : Colors.green.shade200,
                    width: 1,
                  ),
                  color: _isNotReceived ? Colors.red.shade50 : Colors.green.shade50,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _isNotReceived,
                      activeColor: Colors.red,
                      onChanged: (bool? value) {
                        setState(() {
                          _isNotReceived = value ?? false;
                        });
                      },
                    ),
                    Text(
                      _isNotReceived ? 'Not Received' : 'Money Received',
                      style: TextStyle(
                        color: _isNotReceived ? Colors.red.shade700 : Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Date'),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _selectDate(context, true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.purple,
                            side: const BorderSide(color: Colors.purple),
                          ),
                          child: Text(
                            _startDate == null ? 'Select' : DateFormat('yyyy-MM-dd').format(_startDate!),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Date'),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _selectDate(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.purple,
                            side: const BorderSide(color: Colors.purple),
                          ),
                          child: Text(
                            _endDate == null ? 'Select' : DateFormat('yyyy-MM-dd').format(_endDate!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addWork,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Work'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
