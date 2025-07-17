import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orcamentos_app/utils/http.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '1004439512234-mqqb1622hk1f9tlomi5r83gmh14b9bno.apps.googleusercontent.com' : null,
  );

  User? _user;
  String _apiToken = '';

  User? get user => _user;
  String get apiToken => _apiToken;
  bool get isLoggedIn => _user != null && _apiToken.isNotEmpty;

  Future<void> loadCurrentUser() async {
    _user = _auth.currentUser;
    if (_user != null) {
      await _fetchApiToken();
    }
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
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
        notifyListeners();
        return;
      }

      final client = await MyHttpClient.create();
      final response = await client.post(
        'auth/google/verify',
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': idToken}),
      );

      if (response.statusCode == 403) {
        await logout();
        return;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _apiToken = json.decode(response.body)['access_token'] ?? '';
      } else {
        _apiToken = '';
      }
    } catch (e) {
      _apiToken = '';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _user = null;
      _apiToken = '';
    } finally {
      notifyListeners();
    }
  }
}