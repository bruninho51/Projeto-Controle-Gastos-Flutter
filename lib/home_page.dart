import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:orcamentos_app/login_page.dart';
import 'dart:convert';
import 'orcamentos_page.dart';  // Agora importamos a tela de orçamentos
import 'investimentos_page.dart';  // Novo import
import 'dashboard_page.dart';  // Novo import para DashboardPage

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, this.user});

  final String title;
  final User? user;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0;
  String? _apiToken = '';
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    if (_user != null) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    await _fetchApiAccessToken((await _user?.getIdToken()) ?? '');
  }

  Future<void> _signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> _fetchApiAccessToken(String? idToken) async {
    if (idToken == null) return;

    final response = await http.post(
      Uri.parse('http://192.168.73.103:3000/api/v1/auth/google/verify'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'idToken': idToken,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      setState(() {
        _apiToken = json.decode(response.body)['access_token'];
      });
    }
  }

  Widget _buildProfilePage() {
    return Center(
      child: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Text('Erro: ${snapshot.error}');
          }

          if (snapshot.hasData) {
            User? user = snapshot.data;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                user!.photoURL != null
                    ? CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(user.photoURL!),
                      )
                    : const Icon(Icons.account_circle, size: 100),
                const SizedBox(height: 10),
                Text('Logado como ${user.displayName}'),
                ElevatedButton(
                  onPressed: _signOut,
                  child: const Text('Logout'),
                ),
              ],
            );
          }

          return ElevatedButton(
            onPressed: () async {
              print("Usuário logado: ${_user?.displayName}");
            },
            child: const Text('Login com Google'),
          );
        },
      ),
    );
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _apiToken != ''
              ? DashboardPage(apiToken: _apiToken!)
              : const Center(child: CircularProgressIndicator()),
          _apiToken != ''
              ? OrcamentosPage(apiToken: _apiToken!)
              : const Center(child: CircularProgressIndicator()),
          /*_apiToken != ''
              ? InvestimentosPage(apiToken: _apiToken!)
              : const Center(child: CircularProgressIndicator()),*/
          _buildProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onTabChanged,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Orçamentos',
          ),
          /*BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Investimentos',
          ),*/
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
