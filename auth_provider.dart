import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  AuthProvider() {
    _authService.user.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    User? user = await _authService.signInWithEmail(email, password);
    _user = user;
    _isLoading = false;
    if (user != null) {
      _successMessage = 'Welcome back!';
    } else {
      _errorMessage = 'Invalid email or password.';
    }
    notifyListeners();
    return user != null;
  }

  Future<bool> register(
    String name,
    String email,
    String password, {
    String? phone,
    String? gender,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    User? user = await _authService.registerWithEmail(email, password, name);
    _user = user;
    _isLoading = false;

    if (user != null) {
      // Save additional user data to Firestore
      if (phone != null || gender != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          if (phone != null) 'phone': phone,
          if (gender != null) 'gender': gender,
        }, SetOptions(merge: true));
      }
      _successMessage = 'Account created successfully! Welcome to GlowUp AI 🎉';
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Registration failed. Email might already be in use.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  // ✅ NEW: Public method to update user profile
  Future<void> updateUserProfile({String? displayName, String? phone}) async {
    if (_user == null) return;

    // 1. Update Firebase Auth displayName
    if (displayName != null && displayName.isNotEmpty) {
      await _user?.updateDisplayName(displayName);
    }

    // 2. Update phone number in Firestore (if provided)
    // Note: Firebase Auth does not have a standard setter for phone number on the User object.
    if (phone != null && phone.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'phone': phone,
      }, SetOptions(merge: true));
    }

    // 3. Trigger UI update
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
