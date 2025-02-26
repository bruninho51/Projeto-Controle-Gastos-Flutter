import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final GoogleSignIn _googleSignIn = GoogleSignIn();
    final FirebaseAuth _auth = FirebaseAuth.instance;

    Future<void> _signInWithGoogle() async {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage(user: _auth.currentUser, title: 'Orçamentos App')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue[50], // Cor de fundo suave
      appBar: AppBar(
        title: const Text('Entre'),
        backgroundColor: Colors.blue[50], // Cor da AppBar
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone do aplicativo (maior)
              Image.asset(
                'assets/icon.png',
                width: 150, // Logo maior
                height: 150,
              ),
              const SizedBox(height: 40), // Maior espaçamento entre o logo e o botão
              // Texto de boas-vindas (opcional)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  'Bem-vindo ao Orçamentos App! Faça login para começar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Botão de login com ícone do Google
              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: Image.asset(
                  'assets/google.png', // Ícone do Google
                  height: 30,
                ),
                label: const Text(
                  'Login com Google',
                  style: TextStyle(fontSize: 16), // Tamanho da fonte no botão
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Bordas arredondadas
                  ),
                  elevation: 5, // Sombra no botão
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
