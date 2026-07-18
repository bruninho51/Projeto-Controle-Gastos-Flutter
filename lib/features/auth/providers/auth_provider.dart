import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:orcamentos_app/shared/api_service.dart';
import 'package:orcamentos_app/shared/auth_service.dart';

class AuthState with ChangeNotifier {
  final AuthService authService;
  final ApiService api;

  String? _apiToken;
  User? _user;
  bool _isLoading = true;

  final List<Future<void> Function()> _afterAuthHooks = [];

  // ================= GETTERS =================

  bool get isLoggedIn => _apiToken != null;
  String? get apiToken => _apiToken;
  User? get user => _user;
  bool get isLoading => _isLoading;

  // ================= CONSTRUCTOR =================

  AuthState(this.authService, this.api) {
    _wireApiService();
    _restoreSession();
  }

  void _wireApiService() {
    api.onTokenRequested(() => _apiToken);
    api.onTokenExpired(_renovarToken);

    api.onUnauthorized(() async {
      await logout();
    });
  }

  // ================= TROCA DE TOKEN (compartilhada) =================

  /// Troca o ID token do Firebase do [user] informado por um token da API
  /// (via [ApiService.verifyGoogle]), atualizando [_user]/[_apiToken].
  /// Usado tanto no login interativo quanto na restauração de sessão e na
  /// renovação automática — os três só diferem em *como* obtêm o [User] e
  /// em *quando* forçam um ID token novo.
  /// Retorna `false` se não houver ID token disponível.
  Future<bool> _trocarIdTokenPorApiToken(
    User user, {
    bool forceRefresh = false,
  }) async {
    final idToken = await authService.getIdToken(forceRefresh: forceRefresh);
    if (idToken == null) return false;

    final response = await api.verifyGoogle(idToken);
    _user = user;
    _apiToken = response.accessToken;
    return true;
  }

  // ================= RESTAURAÇÃO DE SESSÃO =================

  /// Aguarda o Firebase restaurar (ou não) a sessão persistida localmente e,
  /// se houver um usuário, troca o ID token do Firebase por um token da API
  /// — sem exigir que o usuário toque em "Entrar com Google" novamente.
  Future<void> _restoreSession() async {
    try {
      final user = await authService.authStateChanges.first;
      if (user == null) return;

      if (!await _trocarIdTokenPorApiToken(user)) return;

      await _runAfterAuthHooks();
    } catch (e) {
      _user = null;
      _apiToken = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================= RENOVAÇÃO DE TOKEN =================

  /// Chamado pelo [ApiService] quando uma requisição falha com 401/403.
  /// Força a renovação do ID token do Firebase e troca por um novo token
  /// da API. Retorna `null` se não houver sessão para renovar ou se a
  /// renovação falhar — nesse caso o [ApiService] desloga o usuário.
  Future<String?> _renovarToken() async {
    final user = authService.currentUser;
    if (user == null) return null;

    try {
      if (!await _trocarIdTokenPorApiToken(user, forceRefresh: true)) {
        return null;
      }
      notifyListeners();
      return _apiToken;
    } catch (_) {
      return null;
    }
  }

  // ================= HOOK API =================

  void addPostAuthAction(Future<void> Function() callback) {
    _afterAuthHooks.add(callback);
  }

  Future<void> _runAfterAuthHooks() async {
    for (final hook in _afterAuthHooks) {
      await hook();
    }
  }

  // ================= LOGIN =================

  Future<void> login() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await authService.signInWithGoogle();
      if (user == null) return;

      if (!await _trocarIdTokenPorApiToken(user)) return;

      notifyListeners();

      await _runAfterAuthHooks();
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