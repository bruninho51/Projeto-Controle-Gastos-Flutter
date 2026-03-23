import 'package:flutter/foundation.dart';

class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;

  AuthManager._internal();

  final ValueNotifier<bool> _isAuthenticated = ValueNotifier<bool>(true);
  bool _logoutInProgress = false;

  ValueListenable<bool> get isAuthenticatedListenable => _isAuthenticated;
  bool get isAuthenticated => _isAuthenticated.value;

  void setAuthenticated() {
    _isAuthenticated.value = true;
  }

  Future<void> logout() async {
    if (_logoutInProgress) return;
    _logoutInProgress = true;

    try {
      _isAuthenticated.value = false;
    } finally {
      _logoutInProgress = false;
    }
  }
}