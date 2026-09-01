// lib/services/chat_service.dart
//
// Única porta de saída do app rumo ao Assistente Logístico (SmartLog).
//
// A chave da OpenAI NÃO existe neste projeto Flutter: este serviço apenas
// faz um POST autenticado para o Cloudflare Worker, que é quem detém a chave
// e orquestra com a OpenAI no servidor de forma segura.
//
// Autenticação: reaproveita o Firebase Authentication já existente no app.
// Enviamos o ID Token no header Authorization; o Worker verifica a assinatura
// criptograficamente e deriva a identidade dali.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/chat_resposta.dart';

class ChatService {
  /// Base do Worker publicado na Cloudflare.
  static const String baseUrl = 'https://smartlog-ai.smartlogopenai.workers.dev';

  /// Endpoint do assistente.
  static const String caminhoChat = '/chat';

  /// Limite de espera por resposta da IA.
  static const Duration tempoLimite = Duration(seconds: 60);

  final http.Client _client;
  final FirebaseAuth _auth;

  ChatService({http.Client? client, FirebaseAuth? auth})
      : _client = client ?? http.Client(),
        _auth = auth ?? FirebaseAuth.instance;

  /// Método consumido pelo ChatController
  Future<Resposta> perguntar({
    required String uid,
    required String perfil,
    required String pergunta,
    List<Map<String, String>> historico = const [],
  }) async {
    try {
      // ── Autenticação: sem usuário logado, não dispara a requisição ──
      final User? usuario = _auth.currentUser;
      if (usuario == null) {
        return Resposta.falha(
          'Entre na sua conta para usar o assistente.',
          codigo: 'nao-autenticado',
        );
      }

      final String? idToken = await usuario.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        return Resposta.falha(
          'Sua sessão expirou. Entre novamente para usar o assistente.',
          codigo: 'token-indisponivel',
        );
      }

      final Uri url = Uri.parse('$baseUrl$caminhoChat');

      final http.Response resposta = await _client
          .post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'pergunta': pergunta,
          'historico': historico,
        }),
      )
          .timeout(tempoLimite);

      // Decodificação garantida em UTF-8 para não corromper acentuação
      final String corpo = utf8.decode(resposta.bodyBytes);

      Map<String, dynamic>? json;
      try {
        final dynamic decodificado = jsonDecode(corpo);
        if (decodificado is Map<String, dynamic>) json = decodificado;
      } catch (_) {
        json = null;
      }

      if (resposta.statusCode == 200) {
        if (json == null) {
          return Resposta.falha(
            'O assistente devolveu um formato inesperado.',
            codigo: 'formato-invalido',
          );
        }
        return Resposta.fromMap(json);
      }

      return Resposta.falha(
        _mensagemAmigavel(resposta.statusCode, json),
        codigo: 'http-${resposta.statusCode}',
      );
    } on TimeoutException {
      return Resposta.falha(
        'O assistente demorou demais para responder. Tente uma pergunta mais direta.',
        codigo: 'deadline-exceeded',
      );
    } on FirebaseAuthException {
      return Resposta.falha(
        'Sua sessão expirou. Entre novamente para usar o assistente.',
        codigo: 'auth',
      );
    } on SocketException {
      return Resposta.falha(
        'Servidor do assistente inacessível. Verifique sua conexão e tente novamente.',
        codigo: 'offline',
      );
    } on http.ClientException {
      return Resposta.falha(
        'Não foi possível falar com o assistente agora. Verifique sua conexão e tente novamente.',
        codigo: 'conexao',
      );
    } catch (e) {
      return Resposta.falha(
        'Não foi possível falar com o assistente agora. Verifique sua conexão e tente novamente.',
        codigo: 'desconhecido',
      );
    }
  }

  /// Método simplificado consumido diretamente pelo DashboardAdmin
  Future<String> enviarMensagem(String prompt, {String? contexto}) async {
    final User? usuario = _auth.currentUser;
    final String uid = usuario?.uid ?? '';

    final Resposta resposta = await perguntar(
      uid: uid,
      perfil: 'ADMIN',
      pergunta: contexto != null && contexto.isNotEmpty
          ? "$prompt\n[Contexto Operacional: $contexto]"
          : prompt,
    );

    // No model Resposta, a mensagem (sucesso ou falha) fica no campo texto
    if (resposta.sucesso) {
      return resposta.texto;
    } else {
      return resposta.texto.isNotEmpty
          ? resposta.texto
          : 'Não foi possível obter resposta do assistente.';
    }
  }

  String _mensagemAmigavel(int status, Map<String, dynamic>? json) {
    // Retorna erro específico devolvido pelo Worker se houver
    final String? doServidor = json?['erro']?.toString() ?? json?['message']?.toString();
    if (status == 400 && doServidor != null && doServidor.isNotEmpty) {
      return doServidor;
    }

    switch (status) {
      case 400:
        return 'A pergunta enviada é inválida. Tente reformulá-la.';
      case 401:
        return 'Sua sessão expirou (HTTP 401). Entre novamente para usar o assistente.';
      case 403:
        return 'Acesso negado (HTTP 403): Seu perfil não tem autorização para este recurso.';
      case 404:
        return 'O assistente ainda não foi publicado. Faça o deploy do Worker para ativá-lo.';
      case 405:
        return 'O assistente recusou o formato da requisição.';
      case 413:
        return 'A conversa ficou grande demais. Limpe o histórico e tente novamente.';
      case 429:
        return 'Limite de uso do assistente atingido. Tente novamente mais tarde.';
      case 502:
        return 'O assistente não conseguiu responder agora (HTTP 502). Tente novamente.';
      case 503:
        return 'O assistente está sem a chave da OpenAI configurada no servidor (HTTP 503).';
      default:
        return 'O assistente não conseguiu responder agora (HTTP $status).';
    }
  }
}