void main() {
  // Teste do regex para detectar múltiplos animais
  final regex = RegExp(r'^(\d+)\s+(.+)$');
  
  List<String> testes = [
    '10 Gorilas',
    '5 Pandas', 
    '1 Leão',
    'Gorila',
    '3 Tigres',
    '15 Elefantes'
  ];
  
  for (String teste in testes) {
    final match = regex.firstMatch(teste);
    if (match != null) {
      int quantidade = int.parse(match.group(1)!);
      String nomeBase = match.group(2)!;
      print('✅ "$teste" -> Quantidade: $quantidade, Nome: "$nomeBase"');
    } else {
      print('❌ "$teste" -> Não detectou número');
    }
  }
} 