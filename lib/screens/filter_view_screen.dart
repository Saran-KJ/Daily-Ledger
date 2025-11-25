import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterViewScreen extends StatefulWidget {
  const FilterViewScreen({super.key});

  @override
  State<FilterViewScreen> createState() => _FilterViewScreenState();
}

class _FilterViewScreenState extends State<FilterViewScreen> {
  final _nameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _paymentStatus;
  bool _isPersonalEntries = true;

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
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _applyFilter() {
    final filters = {
      'type': _isPersonalEntries ? 'personal' : 'workers',
      if (_nameController.text.isNotEmpty) 'name': _nameController.text,
      if (_startDate != null)
        'startDate': DateFormat('yyyy-MM-dd').format(_startDate!),
      if (_endDate != null) 'endDate': DateFormat('yyyy-MM-dd').format(_endDate!),
      if (_paymentStatus != null) 'paymentStatus': _paymentStatus,
    };

    Navigator.pop(context, filters);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Filter View'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Entry Type Toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Personal Entries'),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Workers'),
                ),
              ],
              selected: {_isPersonalEntries},
              onSelectionChanged: (Set<bool> selected) {
                setState(() {
                  _isPersonalEntries = selected.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Name Search
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: _isPersonalEntries ? 'Name' : 'Worker Name',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 24),

            // Date Range
            const Text('Start Date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context, true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDate(_startDate)),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text('End Date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context, false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDate(_endDate)),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Status
            const Text('Payment Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _paymentStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'paid', child: Text('Paid')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
              ],
              onChanged: (value) {
                setState(() {
                  _paymentStatus = value;
                });
              },
            ),
            const SizedBox(height: 32),

            // Apply Filter Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Apply Filter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}