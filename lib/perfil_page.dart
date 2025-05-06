import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'gastos_variados_page/auth_provider.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAppLogo(),
                const SizedBox(height: 40),
                _buildProfileCard(auth),
              ],
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
        width: 120,
        height: 120,
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildUserAvatar(auth),
            const SizedBox(height: 24),
            _buildUserInfo(auth),
            const SizedBox(height: 32),
            _buildLogoutButton(auth),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(AuthProvider auth) {
    return auth.user?.photoURL != null
        ? CircleAvatar(
            radius: 60,
            backgroundColor: Colors.indigo[100],
            backgroundImage: NetworkImage(auth.user!.photoURL!),
          )
        : CircleAvatar(
            radius: 60,
            backgroundColor: Colors.indigo[100],
            child: const Icon(
              Icons.person,
              size: 60,
              color: Colors.indigo,
            ),
          );
  }

  Widget _buildUserInfo(AuthProvider auth) {
    return Column(
      children: [
        Text(
          auth.user?.displayName ?? 'Usuário',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          auth.user?.email ?? '',
          style: TextStyle(
            fontSize: 16,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Sair da conta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}