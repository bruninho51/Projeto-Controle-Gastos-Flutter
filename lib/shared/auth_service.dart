import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({
    required FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _googleSignIn = googleSignIn;

  Future<User?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }

  User? get currentUser => _auth.currentUser;

  /// Emite o usuário assim que o Firebase termina de carregar a sessão
  /// persistida localmente (ou `null`, se não houver nenhuma). Ao contrário
  /// de [currentUser], que pode retornar `null` momentaneamente logo após o
  /// app iniciar (antes do Firebase restaurar a sessão do disco), este
  /// stream é a forma confiável de aguardar esse carregamento.
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}