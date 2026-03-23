import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:orcamentos_app/shared/api_service.dart';
import 'package:orcamentos_app/shared/auth_manager.dart';

const _webClientId = '1004439512234-mqqb1622hk1f9tlomi5r83gmh14b9bno.apps.googleusercontent.com';

class AuthProvider with ChangeNotifier {
  // ================= DEPENDÊNCIAS =================
  final FirebaseAuth _auth = FirebaseAuth.instance;
  ApiService _api;

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
  );

  // ================= ESTADO =================
  User? _user;
  String _apiToken = '';
  bool _logoutInProgress = false;
  bool _isLoading = true;

  // ================= GETTERS =================
  User? get user => _user;
  String get apiToken => _apiToken;
  bool get isLoggedIn => _user != null && _apiToken.isNotEmpty;
  bool get isLoading => _isLoading;

  // ================= CONSTRUTOR =================
  AuthProvider(this._api) {
    AuthManager().isAuthenticatedListenable.addListener(_onAuthChanged);
  }

  void updateApiService(ApiService api) {
    _api = api;
  }

  ApiService get api => _api;

  // ================= LIFECYCLE =================
  @override
  void dispose() {
    AuthManager().isAuthenticatedListenable.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!AuthManager().isAuthenticated) {
      logout();
    }
  }

  // ================= AÇÕES =================

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    _user = _auth.currentUser;

    if (_user != null) {
      await _fetchApiToken();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      _user = _auth.currentUser;

      await _fetchApiToken();

      notifyListeners();
    } catch (e) {
      _apiToken = '';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _fetchApiToken() async {
    try {
      final idToken = await _user?.getIdToken();

      if (idToken == null) {
        _apiToken = '';
        return;
      }

      final response = await _api.verifyGoogle(idToken);
      _apiToken = response.accessToken;

      AuthManager().setAuthenticated();

    } catch (e) {
      _apiToken = '';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_logoutInProgress) return;
    _logoutInProgress = true;

    try {
      await _googleSignIn.signOut();
      await _auth.signOut();

      _user = null;
      _apiToken = '';

    } finally {
      _logoutInProgress = false;
      notifyListeners();
    }
  }
}