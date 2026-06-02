import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';
import 'package:orcamentos_app/features/auth/components/login_background_animation.dart';
import 'package:orcamentos_app/features/auth/components/login_logo.dart';
import 'package:orcamentos_app/features/auth/components/login_card.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _wave1;
  late final AnimationController _wave2;
  late final AnimationController _wave3;

  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final Animation<Offset> _slideCard;

  String _version = '';

  static const _dark  = Color(0xFF1A237E);
  static const _mid   = Color(0xFF283593);
  static const _light = Color(0xFF3949AB);

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _wave1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000))..repeat(reverse: true);
    _wave2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500))..repeat(reverse: true);
    _wave3 = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))..repeat(reverse: true);

    _fadeIn = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    _slideCard = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    _intro.forward();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final year = DateTime.now().year;
      setState(() {
        _version = 'Orçamentos App $year · Todos os direitos reservados · v${info.version}';
      });
    } catch (_) {
      setState(() => _version = '');
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _wave1.dispose();
    _wave2.dispose();
    _wave3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_dark, _mid, _light],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            LoginBackgroundAnimation(w1: _wave1, w2: _wave2, w3: _wave3),
            SafeArea(
              child: kIsWeb ? _buildWebLayout() : _buildMobileLayout(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Layout Web ────────────────────────────────────────

  Widget _buildWebLayout() {
    return Center(
      child: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LoginLogo(),
                    const SizedBox(height: 32),
                    _buildWelcomeText(),
                    const SizedBox(height: 12),
                    _buildDescriptionText(),
                    const SizedBox(height: 40),
                    SlideTransition(
                      position: _slideCard,
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _intro,
                          curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                        ),
                        child: Consumer<AuthState>(
                          builder: (context, auth, _) => LoginCard(
                            onSignIn: () => auth.login(),
                            isLoading: auth.isLoading,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _intro,
                        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
                      ),
                      child: _buildVersion(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Layout Mobile/Desktop ─────────────────────────────

  Widget _buildMobileLayout() {
    return Column(
      children: [
        const Spacer(flex: 2),
        FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: Column(
              children: [
                const LoginLogo(),
                const SizedBox(height: 32),
                _buildWelcomeText(),
                const SizedBox(height: 12),
                _buildDescriptionText(),
              ],
            ),
          ),
        ),
        const Spacer(flex: 2),
        SlideTransition(
          position: _slideCard,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _intro,
              curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
            ),
            child: Consumer<AuthState>(
              builder: (context, auth, _) => LoginCard(
                onSignIn: () => auth.login(),
                isLoading: auth.isLoading,
              ),
            ),
          ),
        ),
        const Spacer(),
        FadeTransition(
          opacity: CurvedAnimation(
            parent: _intro,
            curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
          ),
          child: _buildVersion(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Textos ────────────────────────────────────────────

  Widget _buildWelcomeText() {
    return const Column(
      children: [
        Text(
          'Bem-vindo ao',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white60,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Orçamentos App',
          style: TextStyle(
            fontSize: 30,
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionText() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 48),
      child: Text(
        'Gerencie seus orçamentos de forma simples e eficiente',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          color: Colors.white60,
          height: 1.5,
        ),
      ),
    );
  }

  // ── Versão ────────────────────────────────────────────

  Widget _buildVersion() {
    if (_version.isEmpty) return const SizedBox.shrink();
    return Text(
      _version,
      style: const TextStyle(
        fontSize: 11,
        color: Colors.white30,
        letterSpacing: 0.5,
      ),
    );
  }
}