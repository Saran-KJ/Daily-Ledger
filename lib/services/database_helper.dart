import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    debugPrint('💾 DatabaseHelper: Initializing database at: $path');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        debugPrint('✅ DatabaseHelper: Database opened successfully');
        await _verifyDatabaseIntegrity(db);
      },
    );
  }

  Future<void> _verifyDatabaseIntegrity(Database db) async {
    try {
      // Check if all required tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('users', 'worker_entries', 'personal_entries')"
      );
      
      debugPrint('🔍 DatabaseHelper: Found ${tables.length} tables: ${tables.map((t) => t['name']).join(', ')}');
      
      if (tables.length == 3) {
        debugPrint('✅ DatabaseHelper: Database integrity verified - all tables present');
      } else {
        debugPrint('⚠️ DatabaseHelper: Missing tables detected');
      }
    } catch (e) {
      debugPrint('❌ DatabaseHelper: Error verifying database integrity: $e');
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint('💾 DatabaseHelper: Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // Migrate worker_entries table from version 1 to version 2
      debugPrint('📦 DatabaseHelper: Migrating worker_entries table...');
      
      // Check if table exists first
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='worker_entries'");
      if (tables.isNotEmpty) {
        // Create new table with correct schema
        await db.execute('''
          CREATE TABLE worker_entries_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            workerName TEXT NOT NULL,
            description TEXT NOT NULL,
            cost REAL NOT NULL,
            notReceived INTEGER NOT NULL,
            startDate TEXT,
            endDate TEXT,
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');
        
        // Copy data from old table to new table
        await db.execute('''
          INSERT INTO worker_entries_new (id, workerName, description, cost, notReceived, startDate, endDate, createdAt, updatedAt)
          SELECT id, name, description, cost, notReceived, date, date, createdAt, updatedAt
          FROM worker_entries
        ''');
        
        // Drop old table
        await db.execute('DROP TABLE worker_entries');
        
        // Rename new table
        await db.execute('ALTER TABLE worker_entries_new RENAME TO worker_entries');
        
        debugPrint('✅ DatabaseHelper: worker_entries table migration completed');
      }
    }

    if (oldVersion < 3) {
      // Migrate personal_entries table from version 2 to version 3
      debugPrint('📦 DatabaseHelper: Migrating personal_entries table...');
      
      // Check if table exists first
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='personal_entries'");
      if (tables.isNotEmpty) {
        // Create new table with correct schema
        await db.execute('''
          CREATE TABLE personal_entries_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            cost REAL NOT NULL,
            notReceived INTEGER NOT NULL,
            startDate TEXT,
            endDate TEXT,
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');
        
        // Copy data from old table to new table
        await db.execute('''
          INSERT INTO personal_entries_new (id, name, description, cost, notReceived, startDate, endDate, createdAt, updatedAt)
          SELECT id, '' as name, description, cost, notReceived, date as startDate, date as endDate, createdAt, updatedAt
          FROM personal_entries
        ''');
        
        // Drop old table
        await db.execute('DROP TABLE personal_entries');
        
        // Rename new table
        await db.execute('ALTER TABLE personal_entries_new RENAME TO personal_entries');
        
        debugPrint('✅ DatabaseHelper: personal_entries table migration completed');
      }
    }

    if (oldVersion < 4) {
      // Add securityPin column to users table
      debugPrint('📦 DatabaseHelper: Adding securityPin to users table...');
      try {
        await db.execute('ALTER TABLE users ADD COLUMN securityPin TEXT DEFAULT "0000"');
        debugPrint('✅ DatabaseHelper: securityPin column added successfully');
      } catch (e) {
        debugPrint('⚠️ DatabaseHelper: Error adding securityPin column (might already exist): $e');
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        name $textType,
        email $textType UNIQUE,
        passwordHash $textType,
        securityPin TEXT DEFAULT "0000",
        isLoggedIn $boolType DEFAULT 0,
        createdAt $textType,
        updatedAt $textType
      )
    ''');

    // Worker entries table
    await db.execute('''
      CREATE TABLE worker_entries (
        id $idType,
        workerName $textType,
        description $textType,
        cost $realType,
        notReceived $boolType,
        startDate TEXT,
        endDate TEXT,
        createdAt $textType,
        updatedAt $textType
      )
    ''');

    // Personal entries table
    await db.execute('''
      CREATE TABLE personal_entries (
        id $idType,
        name $textType,
        description $textType,
        cost $realType,
        notReceived $boolType,
        startDate TEXT,
        endDate TEXT,
        createdAt $textType,
        updatedAt $textType
      )
    ''');
  }
  Future<int> insertWorkerEntry(Map<String, dynamic> entry) async {
    final db = await database;
    entry['createdAt'] = DateTime.now().toIso8601String();
    entry['updatedAt'] = DateTime.now().toIso8601String();
    return await db.insert('worker_entries', entry);
  }

  Future<List<Map<String, dynamic>>> getWorkerEntries() async {
    final db = await database;
    return await db.query('worker_entries', orderBy: 'startDate DESC');
  }

  Future<int> updateWorkerEntry(int id, Map<String, dynamic> entry) async {
    final db = await database;
    entry['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update(
      'worker_entries',
      entry,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteWorkerEntry(int id) async {
    final db = await database;
    return await db.delete(
      'worker_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Personal Entry CRUD Operations
  Future<int> insertPersonalEntry(Map<String, dynamic> entry) async {
    final db = await database;
    entry['createdAt'] = DateTime.now().toIso8601String();
    entry['updatedAt'] = DateTime.now().toIso8601String();
    return await db.insert('personal_entries', entry);
  }

  Future<List<Map<String, dynamic>>> getPersonalEntries() async {
    final db = await database;
    return await db.query('personal_entries', orderBy: 'startDate DESC');
  }

  Future<int> updatePersonalEntry(int id, Map<String, dynamic> entry) async {
    final db = await database;
    entry['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update(
      'personal_entries',
      entry,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePersonalEntry(int id) async {
    final db = await database;
    return await db.delete(
      'personal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // User CRUD Operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    user['isLoggedIn'] = 0;
    user['createdAt'] = DateTime.now().toIso8601String();
    user['updatedAt'] = DateTime.now().toIso8601String();
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'isLoggedIn = ?',
      whereArgs: [1],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> setCurrentUser(int userId) async {
    final db = await database;
    debugPrint('💾 DatabaseHelper: Setting current user to ID: $userId');
    
    // First, clear all logged-in users
    await db.update(
      'users',
      {'isLoggedIn': 0},
    );
    
    // Then set the current user
    final result = await db.update(
      'users',
      {'isLoggedIn': 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    debugPrint('✅ DatabaseHelper: Current user set successfully');
    return result;
  }

  Future<int> clearCurrentUser() async {
    final db = await database;
    debugPrint('💾 DatabaseHelper: Clearing current user');
    
    final result = await db.update(
      'users',
      {'isLoggedIn': 0, 'updatedAt': DateTime.now().toIso8601String()},
    );
    
    debugPrint('✅ DatabaseHelper: Current user cleared');
    return result;
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await database;
    user['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clear all data (useful for logout)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('worker_entries');
    await db.delete('personal_entries');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
