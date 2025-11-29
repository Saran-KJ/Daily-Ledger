import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'widgets/dashboard_card.dart';
import 'widgets/quick_action_button.dart';
import 'screens/add_worker_screen.dart';
import 'screens/add_personal_entry_screen.dart';
import 'screens/login_screen.dart';
import 'screens/entry_history_screen.dart';
import 'screens/payments_screen.dart';

import 'services/api_service.dart';
import 'services/database_helper.dart';
import 'services/auth_service.dart';
import 'services/pdf_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    debugPrint('🚀 App starting...');
    
    // Initialize sqflite based on platform
    if (kIsWeb) {
      debugPrint('📱 Platform: Web');
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      debugPrint('💻 Platform: Desktop (${Platform.operatingSystem})');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } else {
      debugPrint('📱 Platform: Mobile (${Platform.operatingSystem})');
      // For Android/iOS, use default sqflite (no initialization needed)
    }
    
    // Initialize database
    debugPrint('💾 Initializing database...');
    await DatabaseHelper.instance.database;
    debugPrint('✅ Database initialized successfully');
    
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('❌ Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Ledger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.instance.isLoggedIn(),
      builder: (context, snapshot) {
        // Show loading indicator while checking authentication
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('🔄 AuthCheck: Checking authentication status...');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }
        
        // Handle errors
        if (snapshot.hasError) {
          debugPrint('❌ AuthCheck: Error checking authentication: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Error checking authentication'),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry by rebuilding the widget
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthCheck()),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Navigate based on login status
        final isLoggedIn = snapshot.data ?? false;
        
        if (isLoggedIn) {
          debugPrint('✅ AuthCheck: User is logged in, showing Dashboard');
          return const DashboardScreen();
        } else {
          debugPrint('🔐 AuthCheck: User is NOT logged in, showing Login screen');
          return const LoginScreen();
        }
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double totalPaid = 0;
  double totalEarned = 0;
  double pendingPayments = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      final workers = await ApiService.getWorkerEntries();
      final personal = await ApiService.getPersonalEntries();

      double paid = 0;
      double pending = 0;
      double earned = 0;

      for (var w in workers) {
        final cost = (w['cost'] as num).toDouble();
        final notReceived = (w['notReceived'] == 1) || (w['notReceived'] == true);
        if (!notReceived) {
          paid += cost;
        } else {
          pending += cost;
        }
      }

      for (var p in personal) {
        final cost = (p['cost'] as num).toDouble();
        final notReceived = (p['notReceived'] == 1) || (p['notReceived'] == true);
        if (!notReceived) {
          earned += cost;
        } else {
          pending += cost;
        }
      }

      if (mounted) {
        setState(() {
          totalPaid = paid;
          pendingPayments = pending;
          totalEarned = earned;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showProfileDialog() async {
    final user = await AuthService.instance.getCurrentUser();
    
    if (!mounted) return;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load user profile')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.deepPurple,
              radius: 25,
              child: Text(
                (user['name'] as String).isNotEmpty 
                    ? (user['name'] as String)[0].toUpperCase() 
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text('Profile'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Name',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user['name'] as String? ?? 'N/A',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Email',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user['email'] as String? ?? 'N/A',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: _showProfileDialog,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: FutureBuilder<Map<String, dynamic>?>(
                future: AuthService.instance.getCurrentUser(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final userName = snapshot.data!['name'] as String? ?? 'U';
                    return Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    );
                  }
                  return const Icon(Icons.person, color: Colors.deepPurple);
                },
              ),
            ),
          ),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await AuthService.instance.logout();
                        if (mounted) {
                          navigator.pop(); // Close dialog
                          navigator.pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DashboardCard(
                          title: 'Total Paid',
                          amount: '₹${totalPaid.toStringAsFixed(2)}',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardCard(
                          title: 'Total Earned',
                          amount: '₹${totalEarned.toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DashboardCard(
                    title: 'Pending Payments',
                    amount: '₹${pendingPayments.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      QuickActionButton(
                        icon: Icons.person_add,
                        label: 'Add Worker',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddWorkerScreen()),
                          );
                          if (result == true) {
                            _fetchData();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      QuickActionButton(
                        icon: Icons.picture_as_pdf,
                        label: 'Export PDF',
                        onTap: () async {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Export PDF'),
                                content: const Text(
                                  'Choose how you want to export your Daily Ledger report:',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      try {
                                        final bytes = await PdfService.generatePdf();
                                        await PdfService.printPdf(bytes);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Opening share dialog...'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        debugPrint('Error sharing PDF: $e');
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error sharing PDF: $e')),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text('Share PDF'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      try {
                                        final bytes = await PdfService.generatePdf();
                                        final result = await PdfService.downloadPdf(bytes);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(result)),
                                          );
                                        }
                                      } catch (e) {
                                        debugPrint('Error saving PDF: $e');
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error saving PDF: $e')),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text('Save to Device'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      QuickActionButton(
                        icon: Icons.edit_note,
                        label: 'Add Personal Entry',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddPersonalEntryScreen()),
                          );
                          if (result == true) {
                            _fetchData();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      QuickActionButton(
                        icon: Icons.history,
                        label: 'Entry History',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EntryHistoryScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      QuickActionButton(
                        icon: Icons.payment,
                        label: 'Payments',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PaymentsScreen()),
                          );
                        },
                      ),

                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
