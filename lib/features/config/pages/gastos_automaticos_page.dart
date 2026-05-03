// lib/features/configuracoes/gastos_automaticos_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_settings/app_settings.dart';
import 'package:orcamentos_app/components/common/shared_appbar.dart';

class GastosAutomaticosPage extends StatefulWidget {
  const GastosAutomaticosPage({super.key});

  @override
  State<GastosAutomaticosPage> createState() => _GastosAutomaticosPageState();
}

class _GastosAutomaticosPageState extends State<GastosAutomaticosPage>
    with WidgetsBindingObserver {
  static const _dark   = Color(0xFF1A237E);
  static const _mid    = Color(0xFF283593);
  static const _light  = Color(0xFF3949AB);
  static const _accent = Color(0xFF7986CB);

  static const _gradientColors = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

  // Canal nativo para verificar permissão de notificação listener
  static const _channel = MethodChannel('orcamentos_app/notification_listener');

  bool _listenerEnabled = false;
  bool _serviceRunning  = false;
  bool _loading         = true;
  bool _waitingForSettings = false;

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
    try {
      final enabled = await _channel.invokeMethod<bool>('isNotificationListenerEnabled') ?? false;
      final running = await _channel.invokeMethod<bool>('isServiceRunning') ?? false;
      setState(() {
        _listenerEnabled = enabled;
        _serviceRunning  = running;
      });
    } on PlatformException {
      // Canal não implementado ainda — trata graciosamente
      setState(() {
        _listenerEnabled = false;
        _serviceRunning  = false;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleService(bool value) async {
    if (!_listenerEnabled) {
      _showPermissionRequiredDialog();
      return;
    }
    try {
      if (value) {
        await _channel.invokeMethod('startService');
      } else {
        await _channel.invokeMethod('stopService');
      }
      setState(() => _serviceRunning = value);
    } on PlatformException catch (e) {
      _showErrorSnack(e.message ?? 'Erro ao alterar o serviço.');
    }
  }

  void _openNotificationListenerSettings() {
    _waitingForSettings = true;
    AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: SharedAppBar(
        title: 'Gastos Automáticos',
        subtitle: 'Captura de notificações bancárias',
        mainIcon: Icons.auto_awesome_outlined,
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
            _buildInfoBanner(),
            const SizedBox(height: 20),
            _buildSectionLabel('Permissão do sistema'),
            _buildListenerCard(),
            const SizedBox(height: 20),
            _buildSectionLabel('Serviço em foreground'),
            _buildServiceCard(),
            if (!_listenerEnabled) ...[
              const SizedBox(height: 12),
              _buildBlockedBanner(),
            ],
            const SizedBox(height: 20),
            _buildSectionLabel('Como funciona'),
            _buildHowItWorksCard(),
          ],
        ),
      ),
    );
  }

  // ── Banner informativo ────────────────────────────────

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_mid.withOpacity(0.08), _light.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _light.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _light.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_outlined, color: _light, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cadastro automático',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'O app lê notificações dos seus bancos e cadastra os gastos automaticamente no orçamento ativo.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Card de permissão listener ────────────────────────

  Widget _buildListenerCard() {
    return _Card(children: [
      _PermissionTile(
        icon: _listenerEnabled
            ? Icons.notifications_active_outlined
            : Icons.notifications_off_outlined,
        iconColor: _listenerEnabled
            ? const Color(0xFF43A047)
            : const Color(0xFFE53935),
        title: 'Acesso a notificações',
        subtitle: _listenerEnabled
            ? 'O app pode ler notificações de outros aplicativos'
            : 'Necessário para capturar notificações dos bancos',
        statusWidget: _StatusBadge(
          label: _listenerEnabled ? 'Permitido' : 'Bloqueado',
          color: _listenerEnabled
              ? const Color(0xFF43A047)
              : const Color(0xFFE53935),
        ),
        action: _listenerEnabled
            ? null
            : _ActionButton(
          label: 'Conceder acesso',
          icon: Icons.open_in_new_rounded,
          color: _mid,
          onTap: _openNotificationListenerSettings,
        ),
      ),
    ]);
  }

  // ── Card do serviço ───────────────────────────────────

  Widget _buildServiceCard() {
    return Opacity(
      opacity: _listenerEnabled ? 1.0 : 0.5,
      child: _Card(children: [
        _PermissionTile(
          icon: _serviceRunning
              ? Icons.play_circle_outline_rounded
              : Icons.pause_circle_outline_rounded,
          iconColor: _serviceRunning ? _light : Colors.grey,
          title: 'Serviço em foreground',
          subtitle: _serviceRunning
              ? 'Rodando em segundo plano — capturando notificações'
              : 'Serviço parado — nenhuma notificação será capturada',
          statusWidget: _StatusBadge(
            label: _serviceRunning ? 'Ativo' : 'Inativo',
            color: _serviceRunning ? _light : Colors.grey,
          ),
          action: Switch(
            value: _serviceRunning,
            onChanged: _listenerEnabled ? _toggleService : null,
            activeColor: Colors.white,
            activeTrackColor: _mid,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ),
      ]),
    );
  }

  // ── Banner de bloqueio ────────────────────────────────

  Widget _buildBlockedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE53935).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFE53935), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Conceda o acesso a notificações para ativar o serviço de captura automática.',
              style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFFE53935),
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Como funciona ─────────────────────────────────────

  Widget _buildHowItWorksCard() {
    const steps = [
      (Icons.notifications_outlined,   'Notificação recebida',   'Seu banco envia uma notificação de débito ou compra'),
      (Icons.search_outlined,          'Leitura automática',     'O serviço em foreground lê e interpreta o valor e descrição'),
      (Icons.add_circle_outline,       'Cadastro no orçamento',  'O gasto é cadastrado automaticamente no orçamento ativo'),
      (Icons.check_circle_outline,     'Revisão disponível',     'Você pode revisar ou excluir qualquer gasto capturado'),
    ];

    return _Card(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final (icon, title, desc) = e.value;
        final isLast = i == steps.length - 1;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: _light.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: _light, size: 18),
                      ),
                      if (!isLast) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 1.5, height: 16,
                          color: _light.withOpacity(0.2),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            desc,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
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

  // ── Snacks / Dialogs ──────────────────────────────────

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showPermissionRequiredDialog() {
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
                child: const Icon(Icons.block_rounded,
                    color: Color(0xFFE53935), size: 26),
              ),
              const SizedBox(height: 16),
              const Text(
                'Acesso necessário',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: _dark),
              ),
              const SizedBox(height: 8),
              Text(
                'Conceda o acesso a notificações antes de ativar o serviço.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[500], height: 1.5),
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
                      child: Text('Cancelar',
                          style: TextStyle(color: Colors.grey[600])),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _openNotificationListenerSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mid,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Conceder',
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

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

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
                Divider(
                    height: 1,
                    indent: 60,
                    endIndent: 20,
                    color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? statusWidget;
  final Widget? action;

  const _PermissionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.statusWidget,
    this.action,
  });

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
                Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[500], height: 1.4),
                ),
                if (action != null) ...[
                  const SizedBox(height: 12),
                  action!,
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
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}