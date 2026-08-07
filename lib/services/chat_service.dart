// lib/services/chat_service.dart
//
// Única porta de saída do app rumo ao Assistente Logístico.
//
// A chave da OpenAI NÃO existe neste projeto Flutter: este serviço apenas
// invoca a Cloud Function 'assistenteLogistico', que é quem detém a chave,
// consulta o Firestore e conversa com a OpenAI no servidor.

import 'package:cloud_functions/cloud_functions.dart';

import '../models/chat_resposta.dart';

class ChatService {
  /// Precisa bater com a região usada no deploy da function.
  static const String regiaoPadrao = 'us-central1';

  /// Nome da Cloud Function exportada em functions/index.js
  static const String nomeFuncao = 'assistenteLogistico';

  final FirebaseFunctions _functions;

  ChatService({FirebaseFunctions? functions, String regiao = regiaoPadrao})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: regiao);

  Future<Resposta> perguntar({
    required String uid,
    required String perfil,
    required String pergunta,
    List<Map<String, String>> historico = const [],
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable(
        nomeFuncao,
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );

      final HttpsCallableResult resultado = await callable.call<dynamic>({
        'uid': uid,
        'perfil': perfil,
        'pergunta': pergunta,
        'historico': historico,
      });

      final dynamic dados = resultado.data;
      if (dados is! Map) {
        return Resposta.falha(
          'O assistente devolveu um formato inesperado.',
          codigo: 'formato-invalido',
        );
      }

      // No Android o payload chega como Map<Object?, Object?>; normaliza antes de ler
      return Resposta.fromMap(
        dados.map((chave, valor) => MapEntry(chave.toString(), valor)),
      );
    } on FirebaseFunctionsException catch (e) {
      return Resposta.falha(_mensagemAmigavel(e), codigo: e.code);
    } catch (e) {
      return Resposta.falha(
        'Não foi possível falar com o assistente agora. Verifique sua conexão e tente novamente.',
        codigo: 'desconhecido',
      );
    }
  }

  String _mensagemAmigavel(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Sua sessão expirou. Entre novamente para usar o assistente.';
      case 'permission-denied':
        return 'Seu perfil não tem permissão para consultar estes dados.';
      case 'not-found':
        return 'O assistente ainda não foi publicado no Firebase. Faça o deploy da Cloud Function para ativá-lo.';
      case 'failed-precondition':
        return 'O assistente está sem a chave da OpenAI configurada no servidor.';
      case 'resource-exhausted':
        return 'Limite de uso do assistente atingido. Tente novamente mais tarde.';
      case 'deadline-exceeded':
        return 'O assistente demorou demais para responder. Tente uma pergunta mais direta.';
      default:
        return 'O assistente não conseguiu responder agora (${e.code}).';
    }
  }
}
