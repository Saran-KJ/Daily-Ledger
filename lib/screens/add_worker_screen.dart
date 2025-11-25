import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AddWorkerScreen extends StatefulWidget {
  const AddWorkerScreen({super.key});

  @override
  State<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends State<AddWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<WorkerForm> _workerForms = [];
  
  @override
  void initState() {
    super.initState();
    // Add initial form
    _addNewWorkerForm();
  }

  void _addNewWorkerForm() {
    setState(() {
      _workerForms.add(WorkerForm(
        key: GlobalKey<WorkerFormState>(),
        onRemove: _removeWorkerForm,
      ));
    });
  }

  void _removeWorkerForm(Key key) {
    setState(() {
      _workerForms.removeWhere((form) => form.key == key);
    });
  }

  Future<void> _submitForms() async {
    bool isValid = true;
    for (final form in _workerForms) {
      if (!form.validate()) {
        isValid = false;
        break;
      }
    }

    if (isValid) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Processing Data...')),
        );

        // Submit each worker form
        for (final form in _workerForms) {
          final state = form.state;
          final data = {
            'workerName': state._nameController.text,
            'description': state._descriptionController.text,
            'cost': double.parse(state._costController.text),
            'notReceived': !state._isPaid,
            'startDate': state._startDate?.toIso8601String(),
            'endDate': state._endDate?.toIso8601String(),
          };

          debugPrint('📝 Submitting worker data: $data');
          await ApiService.addWorkerEntry(data);
          debugPrint('✅ Worker entry saved successfully');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All entries added successfully')),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        debugPrint('❌ Error submitting worker: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Worker'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ..._workerForms,
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addNewWorkerForm,
                icon: const Icon(Icons.add),
                label: const Text('Add Another Worker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[100],
                  foregroundColor: Colors.purple[700],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForms,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Submit All'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkerForm extends StatefulWidget {
  final Function(Key) onRemove;

  const WorkerForm({
    required GlobalKey<WorkerFormState> key,
    required this.onRemove,
  }) : super(key: key);

  WorkerFormState get state => (key as GlobalKey<WorkerFormState>).currentState!;

  bool validate() => state.validate();

  @override
  State<WorkerForm> createState() => WorkerFormState();
}

class WorkerFormState extends State<WorkerForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  bool _isPaid = false;
  DateTime? _startDate;
  DateTime? _endDate;

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Worker Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_nameController.text.isEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => widget.onRemove(widget.key!),
                    color: Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Worker Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter worker name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Cost',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
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
                  color: _isPaid ? Colors.green.shade200 : Colors.red.shade200,
                  width: 1,
                ),
                color: _isPaid ? Colors.green.shade50 : Colors.red.shade50,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _isPaid,
                    activeColor: Colors.green,
                    onChanged: (bool? value) {
                      setState(() {
                        _isPaid = value ?? false;
                      });
                    },
                  ),
                  Text(
                    _isPaid ? 'Paid' : 'Not Paid',
                    style: TextStyle(
                      color: _isPaid ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _startDateController,
              decoration: InputDecoration(
                labelText: 'Start Date',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, true),
                ),
              ),
              readOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select start date';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endDateController,
              decoration: InputDecoration(
                labelText: 'End Date',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, false),
                ),
              ),
              readOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select end date';
                }
                if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
                  return 'End date must be after start date';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    ),
  );
  }
}