import 'package:flutter/material.dart';

/// Estado da navegação principal: aba selecionada, barra lateral recolhida ou
/// expandida e a chave do [Navigator] raiz.
///
/// Fica acima do [Navigator] para que a barra lateral (web) permaneça visível
/// também nas telas empilhadas, como gastos fixos e variados.
class NavigationController extends ChangeNotifier {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Índice da aba de orçamentos em [kNavigationItems].
  static const int orcamentosIndex = 1;

  int _currentIndex = 0;
  bool _railExtended = true;

  int get currentIndex => _currentIndex;
  bool get railExtended => _railExtended;

  /// Seleciona uma aba e volta para a raiz, descartando telas empilhadas.
  void select(int index) {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    if (index == _currentIndex) return;
    _currentIndex = index;
    notifyListeners();
  }

  void toggleRail() {
    _railExtended = !_railExtended;
    notifyListeners();
  }
}
