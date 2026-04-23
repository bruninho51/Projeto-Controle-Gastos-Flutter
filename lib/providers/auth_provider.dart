import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:orcamentos_app/shared/api_service.dart';
import 'package:orcamentos_app/shared/auth_service.dart';
import 'package:orcamentos_app/shared/push_service.dart';

class AuthState with ChangeNotifier {
  final AuthService authService;
  final ApiService api;
  final PushService pushService;

  String? _apiToken;
  User? _user;
  bool _isLoading = false;

  // ================= GETTERS =================

  bool get isLoggedIn => _apiToken != null;
  String? get apiToken => _apiToken;
  User? get user => _user;
  bool get isLoading => _isLoading;

  // ================= CONSTRUCTOR =================

  AuthState(this.authService, this.api, this.pushService) {
    _wireApiService();
  }

  void _wireApiService() {
    api.onTokenRequested(() => _apiToken);

    api.onUnauthorized(() async {
      await logout();
    });
  }

  // ================= LOGIN =================

  Future<void> login() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await authService.signInWithGoogle();

      if (user == null) return;

      _user = user;

      final idToken = await authService.getIdToken();

      if (idToken == null) return;

      final response = await api.verifyGoogle(idToken);

      _apiToken = response.accessToken;

      notifyListeners(); // <- importante: atualiza token antes de requests futuros

      await pushService.registerDevice(api);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================= LOGOUT =================

  Future<void> logout() async {
    await authService.logout();

    _apiToken = null;
    _user = null;

    notifyListeners();
  }
}