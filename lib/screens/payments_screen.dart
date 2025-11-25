import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  bool _loadingWorkers = true;
  bool _loadingPersonal = true;
  List<Map<String, dynamic>> _workerPayments = [];
  List<Map<String, dynamic>> _personalPayments = [];

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    // Workers
    try {
      final workers = await ApiService.getWorkerEntries();
      setState(() {
        _workerPayments = workers;
        _loadingWorkers = false;
      });
    } catch (e) {
      debugPrint('Failed to load worker payments: $e');
      setState(() {
        _loadingWorkers = false;
      });
    }

    // Personal
    try {
      final personal = await ApiService.getPersonalEntries();
      setState(() {
        _personalPayments = personal;
        _loadingPersonal = false;
      });
    } catch (e) {
      debugPrint('Failed to load personal payments: $e');
      setState(() {
        _loadingPersonal = false;
      });
    }
  }

  Future<void> _showEditWorkerDialog(Map<String, dynamic> worker) async {
    final id = worker['id'] as int;
    final nameController = TextEditingController(text: worker['workerName'] ?? '');
    final descController = TextEditingController(text: worker['description'] ?? '');
    final costController = TextEditingController(text: worker['cost']?.toString() ?? '');
    bool notReceived = (worker['notReceived'] == 1) || (worker['notReceived'] == true);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Worker Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Worker Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costController,
                  decoration: const InputDecoration(labelText: 'Cost', prefixText: '₹'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: Text(notReceived ? 'Not Paid' : 'Paid'),
                  value: notReceived,
                  activeColor: Colors.red,
                  onChanged: (value) {
                    setDialogState(() {
                      notReceived = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final data = {
                  'workerName': nameController.text,
                  'description': descController.text,
                  'cost': double.tryParse(costController.text) ?? 0.0,
                  'notReceived': notReceived ? 1 : 0,
                };
                await ApiService.updateWorkerEntry(id, data);
                navigator.pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _fetchPayments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Worker entry updated')),
        );
      }
    }
  }

  Future<void> _showEditPersonalDialog(Map<String, dynamic> personal) async {
    final id = personal['id'] as int;
    final nameController = TextEditingController(text: personal['name'] ?? '');
    final descController = TextEditingController(text: personal['description'] ?? '');
    final costController = TextEditingController(text: personal['cost']?.toString() ?? '');
    bool notReceived = (personal['notReceived'] == 1) || (personal['notReceived'] == true);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Personal Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costController,
                  decoration: const InputDecoration(labelText: 'Cost', prefixText: '₹'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: Text(notReceived ? 'Not Received' : 'Money Received'),
                  value: notReceived,
                  activeColor: Colors.red,
                  onChanged: (value) {
                    setDialogState(() {
                      notReceived = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final data = {
                  'name': nameController.text,
                  'description': descController.text,
                  'cost': double.tryParse(costController.text) ?? 0.0,
                  'notReceived': notReceived ? 1 : 0,
                };
                await ApiService.updatePersonalEntry(id, data);
                navigator.pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _fetchPayments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal entry updated')),
        );
      }
    }
  }

  Widget _buildWorkerList() {
    if (_loadingWorkers) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
    }
    if (_workerPayments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text('No worker payments')),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _workerPayments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final w = _workerPayments[i];
        final id = w['id'] as int;
        final name = w['workerName'] ?? w['name'] ?? 'Worker';
        final desc = w['description'] ?? '';
        final cost = w['cost'] != null ? '₹${w['cost']}' : '';
        final notReceived = (w['notReceived'] == 1) || (w['notReceived'] == true);
        final paid = !notReceived;
        
        return Dismissible(
          key: Key('worker_$id'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Entry'),
                content: const Text('Are you sure you want to delete this worker entry?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) async {
            final messenger = ScaffoldMessenger.of(context);
            await ApiService.deleteWorkerEntry(id);
            setState(() {
              _workerPayments.removeAt(i);
            });
            messenger.showSnackBar(
              const SnackBar(content: Text('Worker entry deleted')),
            );
          },
          child: ListTile(
            title: Text(name),
            subtitle: Text(desc),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(cost, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(paid ? 'Paid' : 'Pending', style: TextStyle(color: paid ? Colors.green : Colors.red)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditWorkerDialog(w),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalList() {
    if (_loadingPersonal) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
    }
    if (_personalPayments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text('No personal payments')),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _personalPayments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = _personalPayments[i];
        final id = p['id'] as int;
        final name = p['name'] ?? 'Entry';
        final desc = p['description'] ?? '';
        final cost = p['cost'] != null ? '₹${p['cost']}' : '';
        final notReceived = (p['notReceived'] == 1) || (p['notReceived'] == true);
        final paid = !notReceived;
        
        return Dismissible(
          key: Key('personal_$id'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Entry'),
                content: const Text('Are you sure you want to delete this personal entry?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) async {
            final messenger = ScaffoldMessenger.of(context);
            await ApiService.deletePersonalEntry(id);
            setState(() {
              _personalPayments.removeAt(i);
            });
            messenger.showSnackBar(
              const SnackBar(content: Text('Personal entry deleted')),
            );
          },
          child: ListTile(
            title: Text(name),
            subtitle: Text(desc),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(cost, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(paid ? 'Paid' : 'Pending', style: TextStyle(color: paid ? Colors.green : Colors.red)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditPersonalDialog(p),
                ),
              ],
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
        title: const Text('Payments'),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Worker Payments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildWorkerList(),
            const SizedBox(height: 24),
            const Text('Personal Entry Payments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPersonalList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
