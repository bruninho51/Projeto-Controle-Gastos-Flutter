import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_settings/app_settings.dart';
import 'package:orcamentos_app/components/common/shared_appbar.dart';
import 'package:orcamentos_app/shared/device_registration_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissoesNotificacoesPage extends StatefulWidget {
  const PermissoesNotificacoesPage({super.key});

  @override
  State<PermissoesNotificacoesPage> createState() => _PermissoesNotificacoesPageState();
}

class _PermissoesNotificacoesPageState extends State<PermissoesNotificacoesPage>
    with WidgetsBindingObserver {
  static const _dark  = Color(0xFF1A237E);
  static const _mid   = Color(0xFF283593);
  static const _light = Color(0xFF3949AB);

  static const _gradientColors = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

  AuthorizationStatus _status = AuthorizationStatus.notDetermined;
  bool _appNotificationsEnabled = false;
  bool _loading                 = true;
  bool _waitingForSettings      = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForSettings) {
      _waitingForSettings = false;
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);

    final prefs    = await SharedPreferences.getInstance();
    final settings = await FirebaseMessaging.instance.getNotificationSettings();

    setState(() {
      _status                  = settings.authorizationStatus;
      _appNotificationsEnabled = _systemGranted &&
          (prefs.getBool('notificacoes_ativas') ?? false);
      _loading = false;
    });
  }

  bool get _systemGranted =>
      _status == AuthorizationStatus.authorized ||
          _status == AuthorizationStatus.provisional;

  bool get _systemPermanentlyDenied =>
      _status == AuthorizationStatus.denied;

  DeviceRegistrationService get _deviceService =>
      Provider.of<DeviceRegistrationService>(context, listen: false);

  // ── Ações ─────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    setState(() {
      _status = settings.authorizationStatus;
      _appNotificationsEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
    });
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _showDeniedSnack();
    }
  }

  void _openSystemSettings() {
    _waitingForSettings = true;
    AppSettings.openAppSettings();
  }

  Future<void> _toggleAppNotifications(bool value) async {
    if (!_systemGranted) {
      _showBlockedDialog();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificacoes_ativas', value);

    if (value) {
      await _deviceService.registerDevice();
    } else {
      await _deviceService.unregisterDevice();
    }

    setState(() => _appNotificationsEnabled = value);
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: SharedAppBar(
        title: 'Notificações',
        subtitle: 'Permissões de notificação',
        mainIcon: Icons.notifications_outlined,
        gradientColors: _gradientColors,
        showBackButton: true,
        onBack: () => Navigator.pop(context),
        showAvatar: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : RefreshIndicator(
        onRefresh: _loadStatus,
        color: _mid,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            _buildSectionLabel('Permissão do sistema'),
            _buildSystemCard(),
            const SizedBox(height: 20),
            _buildSectionLabel('Preferências do app'),
            _buildAppCard(),
            if (!_systemGranted) ...[
              const SizedBox(height: 12),
              _buildBlockedBanner(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Seção sistema ─────────────────────────────────────

  Widget _buildSystemCard() {
    return _PermissionCard(
      children: [
        _PermissionTile(
          icon: _systemGranted
              ? Icons.verified_rounded
              : Icons.block_rounded,
          iconColor: _systemGranted
              ? const Color(0xFF43A047)
              : _systemPermanentlyDenied
              ? const Color(0xFFE53935)
              : Colors.orange,
          title: 'Notificações do sistema',
          subtitle: _systemSubtitle,
          statusWidget: _StatusBadge(status: _status),
          action: _buildSystemAction(),
        ),
      ],
    );
  }

  String get _systemSubtitle {
    if (_systemGranted) return 'O sistema permite receber notificações';
    if (_systemPermanentlyDenied) return 'Permissão bloqueada nas configurações do sistema';
    return 'Permissão não solicitada ainda';
  }

  Widget? _buildSystemAction() {
    if (_systemPermanentlyDenied) {
      return _ActionButton(
        label: 'Abrir configurações',
        icon: Icons.open_in_new_rounded,
        color: const Color(0xFFE53935),
        onTap: _openSystemSettings,
      );
    }
    if (!_systemGranted) {
      return _ActionButton(
        label: 'Solicitar permissão',
        icon: Icons.notifications_outlined,
        color: _mid,
        onTap: _requestPermission,
      );
    }
    return null;
  }

  // ── Seção app ─────────────────────────────────────────

  Widget _buildAppCard() {
    return Opacity(
      opacity: _systemGranted ? 1.0 : 0.5,
      child: _PermissionCard(
        children: [
          _PermissionTile(
            icon: _appNotificationsEnabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            iconColor: _appNotificationsEnabled ? _light : Colors.grey,
            title: 'Notificações do app',
            subtitle: _appNotificationsEnabled
                ? 'Você receberá alertas e avisos do app'
                : 'As notificações estão desativadas no app',
            action: Switch(
              value: _appNotificationsEnabled,
              onChanged: _systemGranted ? _toggleAppNotifications : null,
              activeColor: Colors.white,
              activeTrackColor: _mid,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner de bloqueio ────────────────────────────────

  Widget _buildBlockedBanner() {
    final isPermanent = _systemPermanentlyDenied;
    final color       = isPermanent ? const Color(0xFFE53935) : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isPermanent
                ? Icons.error_outline_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isPermanent
                  ? 'A permissão de notificações está bloqueada. As preferências do app ficam inativas até você habilitá-la nas configurações do sistema.'
                  : 'Solicite a permissão do sistema para ativar as preferências de notificação.',
              style: TextStyle(fontSize: 12, color: color, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Label de seção ────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── Dialogs / Snacks ──────────────────────────────────

  void _showDeniedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Permissão negada pelo usuário.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showBlockedDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.block_rounded, color: Color(0xFFE53935), size: 26),
              ),
              const SizedBox(height: 16),
              const Text(
                'Permissão bloqueada',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _dark),
              ),
              const SizedBox(height: 8),
              Text(
                'A permissão de notificações está bloqueada. Habilite-a primeiro nas configurações do sistema.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _openSystemSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mid,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Abrir configurações',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────

class _PermissionCard extends StatelessWidget {
  final List<Widget> children;
  const _PermissionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          final isLast = e.key == children.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                Divider(height: 1, indent: 60, endIndent: 20, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData  icon;
  final Color     iconColor;
  final String    title;
  final String    subtitle;
  final Widget    action;
  final Widget?   statusWidget;
  final Widget?   _actionWidget;

  _PermissionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required Widget? action,
    this.statusWidget,
  })  : action        = action ?? const SizedBox.shrink(),
        _actionWidget = action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ),
                    if (statusWidget != null) statusWidget!,
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4)),
                if (_actionWidget != null) ...[
                  const SizedBox(height: 12),
                  _actionWidget!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AuthorizationStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      AuthorizationStatus.authorized  => ('Permitido',  const Color(0xFF43A047)),
      AuthorizationStatus.provisional => ('Provisório', Colors.orange),
      AuthorizationStatus.denied      => ('Bloqueado',  const Color(0xFFE53935)),
      _                               => ('Pendente',   Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;
  final bool         outlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: outlined
          ? OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      )
          : ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}