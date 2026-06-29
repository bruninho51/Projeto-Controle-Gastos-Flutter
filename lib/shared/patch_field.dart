/// Representa um campo em uma operação PATCH com três estados:
/// ausente (não alterar), presente com valor, presente com null (limpar).
sealed class PatchField<T> {
  const PatchField();

  /// Atalho para [Present]: campo presente com um valor concreto.
  const factory PatchField.value(T value) = Present<T>;

  /// Atalho para [Absent]: campo ausente do body (não altera o valor).
  const factory PatchField.absent() = Absent<T>;

  /// Atalho para [Nulled]: campo presente com null (limpa o valor).
  const factory PatchField.nullValue() = Nulled<T>;

  /// Adiciona este campo a [map] sob [key], respeitando o estado:
  /// [Absent] omite a chave, [Present] adiciona o valor, [Nulled] adiciona null.
  void addToMap(Map<String, dynamic> map, String key) {
    switch (this) {
      case Absent<T>():
        return;
      case Present<T>(value: final value):
        map[key] = value is DateTime ? value.toIso8601String() : value;
      case Nulled<T>():
        map[key] = null;
    }
  }
}

/// Campo não incluído no body — servidor não altera o valor.
final class Absent<T> extends PatchField<T> {
  const Absent();
}

/// Campo incluído no body com um valor concreto.
final class Present<T> extends PatchField<T> {
  final T value;
  const Present(this.value);
}

/// Campo incluído no body com null — servidor limpa o valor.
final class Nulled<T> extends PatchField<T> {
  const Nulled();
}
