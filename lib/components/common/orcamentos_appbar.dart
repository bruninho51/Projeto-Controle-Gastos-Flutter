import 'package:flutter/material.dart';

class OrcamentosAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController? tabController;
  final List<Tab>? tabs;
  final List<Widget>? actions;
  final bool isWeb;
  final Widget? userAvatar;
  final String appTitle;
  final Color mobileBackgroundColor;
  final Color webBackgroundColor;
  final List<Widget>? webNavItems;

  const OrcamentosAppBar({
    super.key,
    this.tabController,
    this.tabs,
    required this.isWeb,
    this.actions,
    this.userAvatar,
    this.appTitle = 'Orçamentos App',
    this.mobileBackgroundColor = const Color(0xFF283593),
    this.webBackgroundColor = Colors.white,
    this.webNavItems,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 0);

  @override
  Widget build(BuildContext context) {
    if (!isWeb) {
      return _buildMobileAppBar();
    } else {
      return _buildWebAppBar(context);
    }
  }

  AppBar _buildMobileAppBar() {
    final hasTabs = tabs != null && tabs!.isNotEmpty && tabController != null;

    return AppBar(
      backgroundColor: mobileBackgroundColor,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [...?actions, const SizedBox(width: 8)],
      elevation: 4,
      title: Text(
        appTitle,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      bottom: hasTabs
          ? PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: mobileBackgroundColor,
                child: TabBar(
                  controller: tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.amber[400],
                  indicatorWeight: 4,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: tabs!,
                ),
              ),
            )
          : null, // 👈 se não tiver tabs, o AppBar volta ao tamanho normal
    );
  }


  AppBar _buildWebAppBar(BuildContext context) {
    final avatarWidget = userAvatar ??
      CircleAvatar(
        backgroundColor: Colors.indigo[100],
        radius: 20,
        child: Icon(Icons.person, color: Colors.indigo[700]),
      );

    return AppBar(
      backgroundColor: webBackgroundColor,
      elevation: 1,
      actions: [...?actions, const SizedBox(width: 8), avatarWidget, const SizedBox(width: 24)],
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          children: [
            Text(
              appTitle,
              style: TextStyle(
                color: Colors.indigo[700],
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const Spacer(),
            if (webNavItems != null && webNavItems!.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: webNavItems!,
              ),
            const SizedBox(width: 24),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: tabs != null ? TabBar(
            controller: tabController,
            labelColor: Colors.indigo[700],
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.indigo[700],
            indicatorWeight: 3,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 24),
            tabs: tabs ?? [],
          ) : null,
        ),
      ),
    );
  }
}

// Componente auxiliar para itens de navegação web (opcional)
class WebNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;

  const WebNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
    this.selectedColor = Colors.indigo,
    this.unselectedColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.indigo.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: isSelected
                ? Border(
                    bottom: BorderSide(
                      color: selectedColor,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? selectedColor : unselectedColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? selectedColor : unselectedColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}