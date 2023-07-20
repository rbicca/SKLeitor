class DadosBoleto {
  String valor;
  DateTime vencimento;

  DadosBoleto(this.valor, this.vencimento);

  @override
  String toString() {
    return 'DadosBoleto {\nvalor: $valor, \nvencimento: $vencimento\n}';
  }
}
