// lib/models/chat_mensagem.dart
//
// Modelo de uma única mensagem trocada no Assistente Logístico.
// Camada de dados pura: não conhece Flutter, Firebase nem regra de negócio.

enum AutorMensagem { usuario, assistente }

class Mensagem {
  final String texto;
  final AutorMensagem autor;
  final DateTime enviadaEm;

  /// Marca respostas que falharam (rede, função indisponível, etc.) para que a
  /// tela possa diferenciá-las visualmente de uma resposta legítima do assistente.
  final bool falhou;

  const Mensagem({
    required this.texto,
    required this.autor,
    required this.enviadaEm,
    this.falhou = false,
  });

  factory Mensagem.doUsuario(String texto, {DateTime? em}) {
    return Mensagem(
      texto: texto,
      autor: AutorMensagem.usuario,
      enviadaEm: em ?? DateTime.now(),
    );
  }

  factory Mensagem.doAssistente(String texto, {DateTime? em, bool falhou = false}) {
    return Mensagem(
      texto: texto,
      autor: AutorMensagem.assistente,
      enviadaEm: em ?? DateTime.now(),
      falhou: falhou,
    );
  }

  bool get ehDoUsuario => autor == AutorMensagem.usuario;

  Map<String, dynamic> toJson() => {
    'texto': texto,
    'autor': autor.name,
    'enviadaEm': enviadaEm.toIso8601String(),
    'falhou': falhou,
  };

  factory Mensagem.fromJson(Map<String, dynamic> json) {
    return Mensagem(
      texto: (json['texto'] ?? '').toString(),
      autor: (json['autor'] ?? 'assistente') == 'usuario'
          ? AutorMensagem.usuario
          : AutorMensagem.assistente,
      enviadaEm: DateTime.tryParse((json['enviadaEm'] ?? '').toString()) ?? DateTime.now(),
      falhou: json['falhou'] == true,
    );
  }
}
