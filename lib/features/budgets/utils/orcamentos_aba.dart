/// Recorte da listagem de orçamentos: ativos, encerrados ou todos.
enum OrcamentosAba {
  ativos('Ativos'),
  encerrados('Encerrados'),
  todos('Todos');

  final String rotulo;
  const OrcamentosAba(this.rotulo);

  /// Valor do parâmetro `encerrado` da API; `null` traz todos.
  bool? get encerrado => switch (this) {
        OrcamentosAba.ativos => false,
        OrcamentosAba.encerrados => true,
        OrcamentosAba.todos => null,
      };
}
