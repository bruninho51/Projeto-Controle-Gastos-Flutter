import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _wave1;
  late final AnimationController _wave2;
  late final AnimationController _wave3;

  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final Animation<Offset> _slideCard;

  String _version = '';

  static const _dark   = Color(0xFF1A237E);
  static const _mid    = Color(0xFF283593);
  static const _light  = Color(0xFF3949AB);
  static const _accent = Color(0xFF7986CB);

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
            // Ondas de fundo
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_wave1, _wave2, _wave3]),
                builder: (_, __) => CustomPaint(
                  painter: _BackgroundWavePainter(
                    w1: _wave1.value,
                    w2: _wave2.value,
                    w3: _wave3.value,
                  ),
                ),
              ),
            ),
            // Conteúdo
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: Column(
                        children: [
                          _buildLogo(),
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
                      child: _buildCard(context),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logo ──────────────────────────────────────────────

  Widget _buildLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _dark.withOpacity(0.35),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Image.asset('assets/icon.png', width: 96, height: 96),
      ),
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

  // ── Card inferior ─────────────────────────────────────

  Widget _buildCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _dark.withOpacity(0.25),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Entrar na sua conta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _mid,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use sua conta Google para continuar',
            style: TextStyle(fontSize: 13, color: Colors.black38),
          ),
          const SizedBox(height: 28),
          _buildGoogleSignInButton(context),
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 20),
          _buildTermsText(),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Colors.black12, thickness: 0.8)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'acesso seguro',
            style: TextStyle(fontSize: 11, color: Colors.black26),
          ),
        ),
        Expanded(child: Divider(color: Colors.black12, thickness: 0.8)),
      ],
    );
  }

  // ── Botão Google ──────────────────────────────────────

  Widget _buildGoogleSignInButton(BuildContext context) {
    return Consumer<AuthState>(
      builder: (context, auth, _) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : () => _handleLogin(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _mid,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _accent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: auth.isLoading
                ? const SizedBox(
              height: 22, width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/google.png', height: 22),
                const SizedBox(width: 12),
                const Text(
                  'Entrar com Google',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    await context.read<AuthState>().login();
  }

  // ── Termos ────────────────────────────────────────────

  Widget _buildTermsText() {
    return const Text(
      'Ao continuar, você concorda com nossos\nTermos e Política de Privacidade',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        color: Colors.black38,
        height: 1.6,
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

// ── Ondas de fundo ────────────────────────────────────────

class _BackgroundWavePainter extends CustomPainter {
  final double w1, w2, w3;
  const _BackgroundWavePainter({
    required this.w1,
    required this.w2,
    required this.w3,
  });

  Path _wave(Size size, double t, double baseY, double amp, double freq) {
    final path = Path();
    path.moveTo(0, baseY + sin(t * pi) * amp);
    for (double x = 0; x <= size.width; x++) {
      final y = baseY + sin((x / size.width * freq * pi) + t * pi) * amp;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Onda superior — leve, suave, quase invisível
    canvas.drawPath(
      _wave(size, w1, size.height * 0.18, 28, 1.8),
      Paint()..color = const Color(0xFF3949AB).withOpacity(0.18),
    );
    // Onda média — flutua no meio da tela
    canvas.drawPath(
      _wave(size, w2, size.height * 0.38, 22, 2.2),
      Paint()..color = const Color(0xFF1A237E).withOpacity(0.20),
    );
    // Onda inferior — ancora o rodapé
    canvas.drawPath(
      _wave(size, w3, size.height * 0.72, 18, 1.5),
      Paint()..color = const Color(0xFF1A237E).withOpacity(0.28),
    );
  }

  @override
  bool shouldRepaint(_BackgroundWavePainter old) =>
      old.w1 != w1 || old.w2 != w2 || old.w3 != w3;
}