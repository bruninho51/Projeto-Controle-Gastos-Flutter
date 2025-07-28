import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final bool isWeb = kIsWeb;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.indigo.shade700,
            Colors.indigo.shade500,
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isWeb ? 40.0 : 24.0), // Aumenta padding na web
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWeb ? 600 : double.infinity, // Limita largura na web
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAppLogo(), // Passa a flag isWeb
                  SizedBox(height: isWeb ? 60 : 40), // Maior espaçamento na web
                  _buildProfileCard(auth), // Passa a flag isWeb
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Image.asset(
        'assets/icon.png',
        width: kIsWeb ? 150 : 120, // Ícone maior na web
        height: kIsWeb ? 150 : 120,
      ),
    );
  }

  Widget _buildProfileCard(AuthProvider auth) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(kIsWeb ? 32.0 : 24.0), // Mais padding na web
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildUserAvatar(auth), // Passa a flag
            SizedBox(height: kIsWeb ? 32 : 24), // Espaçamento maior
            _buildUserInfo(auth), // Passa a flag
            SizedBox(height: kIsWeb ? 40 : 32),
            _buildLogoutButton(auth), // Passa a flag
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(AuthProvider auth) {
    return auth.user?.photoURL != null
        ? CircleAvatar(
            radius: kIsWeb ? 80 : 60, // Avatar maior na web
            backgroundColor: Colors.indigo[100],
            backgroundImage: NetworkImage(auth.user!.photoURL!),
          )
        : CircleAvatar(
            radius: kIsWeb ? 80 : 60,
            backgroundColor: Colors.indigo[100],
            child: Icon(
              Icons.person,
              size: kIsWeb ? 80 : 60,
              color: Colors.indigo,
            ),
          );
  }

  Widget _buildUserInfo(AuthProvider auth) {
    return Column(
      children: [
        Text(
          auth.user?.displayName ?? 'Usuário',
          style: TextStyle(
            fontSize: kIsWeb ? 28 : 24, // Fonte maior
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          auth.user?.email ?? '',
          style: TextStyle(
            fontSize: kIsWeb ? 18 : 16, // Fonte maior
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: auth.logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo[700],
          padding: EdgeInsets.symmetric(
            vertical: kIsWeb ? 18 : 16, // Botão mais alto
            horizontal: kIsWeb ? 24 : 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(Icons.logout, color: Colors.white),
        label: Text(
          'Sair da conta',
          style: TextStyle(
            color: Colors.white,
            fontSize: kIsWeb ? 18 : 16, // Texto maior
          ),
        ),
      ),
    );
  }
}