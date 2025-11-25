import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'filter_view_screen.dart';

class EntryHistoryScreen extends StatefulWidget {
  const EntryHistoryScreen({super.key});

  @override
  State<EntryHistoryScreen> createState() => _EntryHistoryScreenState();
}

class _EntryHistoryScreenState extends State<EntryHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingPersonal = true;
  bool _isLoadingWorkers = true;
  List<Map<String, dynamic>> _personalEntries = [];
  List<Map<String, dynamic>> _workerEntries = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData({Map<String, dynamic>? filters}) async {
    setState(() {
      _isLoadingPersonal = true;
      _isLoadingWorkers = true;
    });

    // Determine which tab to show based on filter
    if (filters != null && filters['type'] != null) {
      final isPersonal = filters['type'] == 'personal';
      _tabController.animateTo(isPersonal ? 0 : 1);
    }

    // Load personal entries
    try {
      var entries = await ApiService.getPersonalEntries();
      
      // Apply filters
      if (filters != null && filters['type'] == 'personal') {
        entries = entries.where((e) {
          bool matches = true;
          
          // Name filter
          if (filters['name'] != null) {
            final name = (e['name'] ?? '').toString().toLowerCase();
            final query = filters['name'].toString().toLowerCase();
            if (!name.contains(query)) matches = false;
          }
          
          // Date range filter
          if (filters['startDate'] != null || filters['endDate'] != null) {
            final dateStr = e['startDate'] ?? e['createdAt'];
            if (dateStr != null) {
              final date = DateTime.tryParse(dateStr);
              if (date != null) {
                if (filters['startDate'] != null) {
                  final start = DateTime.parse(filters['startDate']);
                  if (date.isBefore(start)) matches = false;
                }
                if (filters['endDate'] != null) {
                  final end = DateTime.parse(filters['endDate']).add(const Duration(days: 1));
                  if (date.isAfter(end)) matches = false;
                }
              }
            }
          }
          
          // Payment status filter
          if (filters['paymentStatus'] != null) {
            final notReceived = (e['notReceived'] == 1) || (e['notReceived'] == true);
            final isPending = notReceived;
            if (filters['paymentStatus'] == 'paid' && isPending) matches = false;
            if (filters['paymentStatus'] == 'pending' && !isPending) matches = false;
          }
          
          return matches;
        }).toList();
      }

      _personalEntries = entries.map((e) {
        return {
          'name': e['name'] ?? 'Entry',
          'desc': e['description'] ?? '',
          'cost': e['cost'] != null ? '₹${e['cost']}' : '',
          'date': (e['startDate'] ?? e['createdAt'] ?? '').toString().split('T')[0]
        };
      }).toList();
    } catch (e) {
      debugPrint('Failed to load personal entries: $e');
    } finally {
      setState(() {
        _isLoadingPersonal = false;
      });
    }

    // Load worker entries
    try {
      var entries = await ApiService.getWorkerEntries();
      
      // Apply filters
      if (filters != null && filters['type'] == 'workers') {
        entries = entries.where((e) {
          bool matches = true;
          
          // Name filter
          if (filters['name'] != null) {
            final name = (e['workerName'] ?? '').toString().toLowerCase();
            final query = filters['name'].toString().toLowerCase();
            if (!name.contains(query)) matches = false;
          }
          
          // Date range filter
          if (filters['startDate'] != null || filters['endDate'] != null) {
            final dateStr = e['startDate'] ?? e['createdAt'];
            if (dateStr != null) {
              final date = DateTime.tryParse(dateStr);
              if (date != null) {
                if (filters['startDate'] != null) {
                  final start = DateTime.parse(filters['startDate']);
                  if (date.isBefore(start)) matches = false;
                }
                if (filters['endDate'] != null) {
                  final end = DateTime.parse(filters['endDate']).add(const Duration(days: 1));
                  if (date.isAfter(end)) matches = false;
                }
              }
            }
          }
          
          // Payment status filter
          if (filters['paymentStatus'] != null) {
            final notReceived = (e['notReceived'] == 1) || (e['notReceived'] == true);
            final isPending = notReceived;
            if (filters['paymentStatus'] == 'paid' && isPending) matches = false;
            if (filters['paymentStatus'] == 'pending' && !isPending) matches = false;
          }
          
          return matches;
        }).toList();
      }

      _workerEntries = entries.map((e) {
        return {
          'name': e['workerName'] ?? 'Worker',
          'desc': e['description'] ?? '',
          'cost': e['cost'] != null ? '₹${e['cost']}' : '',
          'date': (e['startDate'] ?? e['createdAt'] ?? '').toString().split('T')[0]
        };
      }).toList();
    } catch (e) {
      debugPrint('Failed to load worker entries: $e');
    } finally {
      setState(() {
        _isLoadingWorkers = false;
      });
    }
  }

  Widget _buildList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 64.0),
          child: Text('No entries found', style: TextStyle(color: Colors.black54)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            title: Text(item['name'] ?? ''),
            subtitle: Text(item['desc'] ?? ''),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item['cost'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(item['date'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Entry History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilter,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: 'Personal Entries'),
            Tab(text: 'Workers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isLoadingPersonal
              ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
              : _buildList(_personalEntries),
          _isLoadingWorkers
              ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
              : _buildList(_workerEntries),
        ],
      ),
    );
  }

  Future<void> _openFilter() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FilterViewScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      _loadData(filters: result);
    }
  }
}
