import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/config/pages/gastos_automaticos_page.dart';
import 'package:orcamentos_app/features/config/pages/permissoes_notificacoes_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:orcamentos_app/components/common/shared_appbar.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  static const _dark   = Color(0xFF1A237E);
  static const _mid    = Color(0xFF283593);
  static const _light  = Color(0xFF3949AB);
  static const _accent = Color(0xFF7986CB);

  static const _gradientColors = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() => _version = 'v${info.version}');
    } catch (_) {
      setState(() => _version = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: SharedAppBar(
        title: 'Configurações',
        subtitle: 'Gerencie as preferências do app',
        mainIcon: Icons.settings_outlined,
        gradientColors: _gradientColors,
        showAvatar: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          _buildSectionLabel('Notificações'),
          _buildCard([
            _buildTile(
              context,
              icon: Icons.notifications_outlined,
              color: _light,
              title: 'Notificações',
              subtitle: 'Permissões de notificação do sistema e do app',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PermissoesNotificacoesPage()),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSectionLabel('Automação'),
          _buildCard([
            _buildTile(
              context,
              icon: Icons.auto_awesome_outlined,
              color: _mid,
              title: 'Gastos Automáticos',
              subtitle: 'Captura notificações do banco em tempo real',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GastosAutomaticosPage()),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSectionLabel('Sobre'),
          _buildCard([
            _buildTile(
              context,
              icon: Icons.info_outline_rounded,
              color: _accent,
              title: 'Versão do app',
              subtitle: 'Informações da versão instalada',
              trailing: _version.isEmpty
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _light.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _version,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _light,
                  ),
                ),
              ),
              showArrow: false,
            ),
          ]),
        ],
      ),
    );
  }

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

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _dark.withOpacity(0.06),
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
                  color: Colors.grey.shade100,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTile(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String title,
        required String subtitle,
        VoidCallback? onTap,
        Widget? trailing,
        bool showArrow = true,
      }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.06),
        highlightColor: color.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (showArrow)
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}