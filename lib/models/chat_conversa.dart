// lib/models/chat_conversa.dart
//
// Agrega o histórico de mensagens de uma sessão do Assistente Logístico.
// Mantém apenas estrutura de dados — quem orquestra o envio é o ChatController.

import 'chat_mensagem.dart';

class Conversa {
  /// Perfil do usuário desta sessão: ADMINISTRADOR, MOTORISTA ou CLIENTE.
  final String perfil;

  final List<Mensagem> _mensagens = [];

  Conversa({required this.perfil});

  /// Cópia imutável — impede que a tela altere o histórico por engano.
  List<Mensagem> get mensagens => List.unmodifiable(_mensagens);

  bool get vazia => _mensagens.isEmpty;
  int get total => _mensagens.length;

  void adicionar(Mensagem mensagem) => _mensagens.add(mensagem);

  void limpar() => _mensagens.clear();

  /// Últimas trocas em formato enxuto, para dar continuidade à conversa sem
  /// enviar o histórico inteiro (controla custo de token na Cloud Function).
  List<Map<String, String>> historicoRecente({int limite = 6}) {
    final int inicio = _mensagens.length > limite ? _mensagens.length - limite : 0;
    return _mensagens
        .sublist(inicio)
        .where((m) => !m.falhou)
        .map((m) => {
      'autor': m.ehDoUsuario ? 'usuario' : 'assistente',
      'texto': m.texto,
    })
        .toList();
  }
}
