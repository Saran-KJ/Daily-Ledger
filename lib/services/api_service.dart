import 'package:flutter/foundation.dart';
import 'database_helper.dart';

class ApiService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Personal Entries - Local database only
  static Future<void> addPersonalEntry(Map<String, dynamic> data) async {
    await _dbHelper.insertPersonalEntry(data);
    debugPrint('Personal entry saved locally');
  }

  static Future<List<Map<String, dynamic>>> getPersonalEntries() async {
    return await _dbHelper.getPersonalEntries();
  }

  static Future<void> updatePersonalEntry(int id, Map<String, dynamic> data) async {
    await _dbHelper.updatePersonalEntry(id, data);
    debugPrint('Personal entry updated locally');
  }

  static Future<void> deletePersonalEntry(int id) async {
    await _dbHelper.deletePersonalEntry(id);
    debugPrint('Personal entry deleted locally');
  }

  // Worker Entries - Local database only
  static Future<void> addWorkerEntry(Map<String, dynamic> data) async {
    await _dbHelper.insertWorkerEntry(data);
    debugPrint('Worker entry saved locally');
  }

  static Future<List<Map<String, dynamic>>> getWorkerEntries() async {
    return await _dbHelper.getWorkerEntries();
  }

  static Future<void> updateWorkerEntry(int id, Map<String, dynamic> data) async {
    await _dbHelper.updateWorkerEntry(id, data);
    debugPrint('Worker entry updated locally');
  }

  static Future<void> deleteWorkerEntry(int id) async {
    await _dbHelper.deleteWorkerEntry(id);
    debugPrint('Worker entry deleted locally');
  }
}