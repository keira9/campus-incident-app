import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  StreamSubscription<User?>? _sub;

  User? _firebaseUser;
  AppUser? _profile;
  bool _initializing = true;
  bool _busy = false;
  String? _error;

  AuthProvider(this._service) {
    _sub = _service.userChanges.listen(_onUserChanged);
  }

  User? get firebaseUser => _firebaseUser;
  AppUser? get profile => _profile;
  bool get initializing => _initializing;
  bool get busy => _busy;
  String? get error => _error;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isVerified => _firebaseUser?.emailVerified ?? false;
  bool get isStaff => _profile?.isStaff ?? false;

  Future<void> _onUserChanged(User? user) async {
    _firebaseUser = user;
    _profile = user == null ? null : await _service.fetchProfile(user.uid);
    _initializing = false;
    notifyListeners();
  }

  Future<bool> register(String name, String email, String password) =>
      _run(() async {
        await _service.register(
            name: name, email: email.trim().toLowerCase(), password: password);
        _profile = await _service.fetchProfile(_service.currentUser!.uid);
      });

  Future<bool> login(String email, String password) => _run(
      () => _service.login(email.trim().toLowerCase(), password));

  Future<void> logout() => _service.logout();

  Future<void> resendVerification() => _service.resendVerification();

  Future<void> refreshVerification() async {
    await _service.reloadUser();
    _firebaseUser = _service.currentUser;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendly(e.code);
      return false;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _friendly(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Authentication failed ($code).';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}