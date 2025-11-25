import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String _keyUserId = 'logged_in_user_id';
  static const String _keyIsLoggedIn = 'is_logged_in';

  AuthService._init();

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Register a new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String securityPin,
  }) async {
    try {
      debugPrint('🔐 AuthService: Starting registration for email: $email');
      
      // Check if user already exists
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null) {
        debugPrint('❌ AuthService: User already exists with email: $email');
        return {
          'success': false,
          'message': 'An account with this email already exists',
        };
      }

      // Hash password
      final passwordHash = _hashPassword(password);

      // Create user
      final userId = await _dbHelper.insertUser({
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'securityPin': securityPin,
      });

      if (userId > 0) {
        // Set as current user in database
        await _dbHelper.setCurrentUser(userId);
        
        // Save to SharedPreferences for persistent login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_keyUserId, userId);
        await prefs.setBool(_keyIsLoggedIn, true);
        
        debugPrint('✅ AuthService: User registered successfully - ID: $userId, Email: $email');
        debugPrint('💾 AuthService: Login state saved to SharedPreferences');
        
        return {
          'success': true,
          'message': 'Account created successfully',
          'userId': userId,
        };
      } else {
        debugPrint('❌ AuthService: Failed to create user account');
        return {
          'success': false,
          'message': 'Failed to create account',
        };
      }
    } catch (e) {
      debugPrint('❌ AuthService: Error during registration: $e');
      return {
        'success': false,
        'message': 'An error occurred during registration',
      };
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String securityPin,
    required String newPassword,
  }) async {
    try {
      debugPrint('🔐 AuthService: Starting password reset for email: $email');
      
      // Get user by email
      final user = await _dbHelper.getUserByEmail(email);
      
      if (user == null) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      // Verify security PIN
      if (user['securityPin'] != securityPin) {
        return {
          'success': false,
          'message': 'Invalid security PIN',
        };
      }

      // Update password
      final newPasswordHash = _hashPassword(newPassword);
      await _dbHelper.updateUser(user['id'] as int, {'passwordHash': newPasswordHash});
      
      debugPrint('✅ AuthService: Password reset successfully');
      return {
        'success': true,
        'message': 'Password reset successfully',
      };
    } catch (e) {
      debugPrint('❌ AuthService: Error during password reset: $e');
      return {
        'success': false,
        'message': 'An error occurred during password reset',
      };
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 AuthService: Starting login for email: $email');
      
      // Get user by email
      final user = await _dbHelper.getUserByEmail(email);
      
      if (user == null) {
        debugPrint('❌ AuthService: User not found with email: $email');
        return {
          'success': false,
          'message': 'Invalid email or password',
        };
      }

      // Verify password
      final passwordHash = _hashPassword(password);
      if (user['passwordHash'] != passwordHash) {
        debugPrint('❌ AuthService: Invalid password for email: $email');
        return {
          'success': false,
          'message': 'Invalid email or password',
        };
      }

      final userId = user['id'] as int;
      
      // Set as current user in database
      await _dbHelper.setCurrentUser(userId);
      
      // Save to SharedPreferences for persistent login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyUserId, userId);
      await prefs.setBool(_keyIsLoggedIn, true);
      
      debugPrint('✅ AuthService: User logged in successfully - ID: $userId, Email: $email');
      debugPrint('💾 AuthService: Login state saved to SharedPreferences');
      
      return {
        'success': true,
        'message': 'Login successful',
        'userId': userId,
        'user': user,
      };
    } catch (e) {
      debugPrint('❌ AuthService: Error during login: $e');
      return {
        'success': false,
        'message': 'An error occurred during login',
      };
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      debugPrint('🔐 AuthService: Starting logout');
      
      // Clear database login state
      await _dbHelper.clearCurrentUser();
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      await prefs.setBool(_keyIsLoggedIn, false);
      
      debugPrint('✅ AuthService: User logged out successfully');
      debugPrint('💾 AuthService: Login state cleared from SharedPreferences');
    } catch (e) {
      debugPrint('❌ AuthService: Error during logout: $e');
    }
  }

  // Get current logged-in user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      // First check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final userId = prefs.getInt(_keyUserId);
      
      debugPrint('🔍 AuthService: Checking current user - SharedPrefs isLoggedIn: $isLoggedIn, userId: $userId');
      
      if (!isLoggedIn || userId == null) {
        debugPrint('❌ AuthService: No logged-in user in SharedPreferences');
        return null;
      }
      
      // Get user from database
      final user = await _dbHelper.getCurrentUser();
      
      if (user != null) {
        debugPrint('✅ AuthService: Current user found - ID: ${user['id']}, Email: ${user['email']}');
      } else {
        debugPrint('⚠️ AuthService: User in SharedPrefs but not in database, clearing session');
        // Clear invalid session
        await prefs.remove(_keyUserId);
        await prefs.setBool(_keyIsLoggedIn, false);
      }
      
      return user;
    } catch (e) {
      debugPrint('❌ AuthService: Error getting current user: $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      debugPrint('🔍 AuthService: Checking if user is logged in...');
      
      // Check SharedPreferences first (faster)
      final prefs = await SharedPreferences.getInstance();
      final isLoggedInPref = prefs.getBool(_keyIsLoggedIn) ?? false;
      final userId = prefs.getInt(_keyUserId);
      
      debugPrint('📱 AuthService: SharedPreferences - isLoggedIn: $isLoggedInPref, userId: $userId');
      
      if (!isLoggedInPref || userId == null) {
        debugPrint('❌ AuthService: User is NOT logged in (SharedPreferences)');
        return false;
      }
      
      // Verify with database
      final user = await _dbHelper.getCurrentUser();
      final isLoggedInDb = user != null;
      
      debugPrint('💾 AuthService: Database - user exists: $isLoggedInDb');
      
      if (!isLoggedInDb) {
        // Clear invalid session from SharedPreferences
        debugPrint('⚠️ AuthService: Session mismatch, clearing SharedPreferences');
        await prefs.remove(_keyUserId);
        await prefs.setBool(_keyIsLoggedIn, false);
        return false;
      }
      
      debugPrint('✅ AuthService: User IS logged in - ID: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ AuthService: Error checking login status: $e');
      return false;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    String? name,
    String? email,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (email != null) {
        // Check if email is already taken by another user
        final existingUser = await _dbHelper.getUserByEmail(email);
        if (existingUser != null && existingUser['id'] != userId) {
          return {
            'success': false,
            'message': 'Email is already in use',
          };
        }
        updates['email'] = email;
      }

      if (updates.isEmpty) {
        return {
          'success': false,
          'message': 'No updates provided',
        };
      }

      await _dbHelper.updateUser(userId, updates);
      
      debugPrint('User profile updated successfully');
      return {
        'success': true,
        'message': 'Profile updated successfully',
      };
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return {
        'success': false,
        'message': 'An error occurred while updating profile',
      };
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['id'] != userId) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      // Verify current password
      final currentPasswordHash = _hashPassword(currentPassword);
      if (user['passwordHash'] != currentPasswordHash) {
        return {
          'success': false,
          'message': 'Current password is incorrect',
        };
      }

      // Update password
      final newPasswordHash = _hashPassword(newPassword);
      await _dbHelper.updateUser(userId, {'passwordHash': newPasswordHash});
      
      debugPrint('Password changed successfully');
      return {
        'success': true,
        'message': 'Password changed successfully',
      };
    } catch (e) {
      debugPrint('Error changing password: $e');
      return {
        'success': false,
        'message': 'An error occurred while changing password',
      };
    }
  }
}
