// lib/models/chat_resposta.dart
//
// Resultado de uma consulta ao Assistente Logístico.
// É o contrato de retorno da Cloud Function, traduzido para o app.

class Resposta {
  final String texto;
  final bool sucesso;

  /// Código técnico do erro (ex.: 'unauthenticated', 'sem-configuracao').
  /// Serve para diagnóstico; o usuário final vê apenas [texto].
  final String? codigoErro;

  const Resposta({
    required this.texto,
    required this.sucesso,
    this.codigoErro,
  });

  /// A Cloud Function devolve `{ resposta: "...", perfil: "...", baseadoEm: {...} }`.
  /// Só o campo `resposta` é obrigatório aqui.
  factory Resposta.fromMap(Map<String, dynamic> mapa) {
    final String texto = (mapa['resposta'] ?? '').toString().trim();

    if (texto.isEmpty) {
      return const Resposta(
        texto: 'O assistente não retornou conteúdo para esta pergunta.',
        sucesso: false,
        codigoErro: 'resposta-vazia',
      );
    }

    return Resposta(texto: texto, sucesso: true);
  }

  factory Resposta.falha(String mensagem, {String? codigo}) {
    return Resposta(texto: mensagem, sucesso: false, codigoErro: codigo);
  }
}
