// lib/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _carregando = false;
  bool get carregando => _carregando;

  String? _erroMensagem;
  String? get erroMensagem => _erroMensagem;

  // Propriedade para guardar o ID da empresa do usuário logado na sessão
  String? _empresaIdLogada;
  String? get empresaIdLogada => _empresaIdLogada;

  // Nome cadastral do usuário logado (usado pelo painel do Cliente para localizar suas entregas)
  String? _nomeUsuarioLogado;
  String? get nomeUsuarioLogado => _nomeUsuarioLogado;

  void _setCarregando(bool valor) {
    _carregando = valor;
    notifyListeners();
  }

  // Realiza o fluxo de Login completo e retorna o tipo do usuário
  Future<String?> realizarLogin(String email, String senha) async {
    _setCarregando(true);
    _erroMensagem = null;

    try {
      UserCredential creds = await _authService.loginComEmailESenha(email, senha);

      if (creds.user != null) {
        var doc = await _authService.buscarDadosUsuario(creds.user!.uid);
        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> dados = doc.data() as Map<String, dynamic>;

          // Captura e salva o ID da empresa do usuário que acabou de logar
          _empresaIdLogada = dados['empresaId'];

          // Aproveita a MESMA leitura do documento para guardar o nome, sem nova consulta
          _nomeUsuarioLogado = dados['nome'];

          _setCarregando(false);
          // 🔥 Retorna 'tipoUsuario' padronizado em maiúsculo
          return dados['tipoUsuario'] ?? dados['tipo'];
        }
      }
      _setCarregando(false);
      return null;
    } catch (e) {
      _erroMensagem = e.toString();
      _setCarregando(false);
      return null;
    }
  }

  // Dispara o link oficial do Firebase para redefinição de senha
  Future<bool> recuperarSenhaPorEmail(String email) async {
    _setCarregando(true);
    _erroMensagem = null;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );
      _setCarregando(false);
      return true;
    } catch (e) {
      _erroMensagem = e.toString();
      _setCarregando(false);
      return false;
    }
  }

  // Realiza o cadastro do usuário e injeta o tenant/empresaId de forma automatizada
  Future<bool> registrarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String tipo,
    String? nomeDaEmpresa,
  }) async {
    _setCarregando(true);
    _erroMensagem = null;

    try {
      String empresaIdVinculada;
      final bool ehAdminNovo = tipo.toUpperCase() == 'ADMINISTRADOR';

      if (ehAdminNovo) {
        // Só reserva o ID — geração é local, ainda não escreve no Firestore
        empresaIdVinculada = _db.collection('empresas').doc().id;
      } else {
        if (_empresaIdLogada == null) {
          throw Exception("Ação não autorizada: Admin não está logado para vincular a empresa.");
        }
        empresaIdVinculada = _empresaIdLogada!;
      }

      // Cria a conta ANTES de gravar a empresa. createUserWithEmailAndPassword
      // já autentica a sessão, e as regras do Firestore exigem usuário logado
      // para escrever em 'empresas'. Na ordem inversa, o cadastro público
      // falharia com permission-denied.
      await _authService.cadastrarUsuario(
        nome: nome,
        email: email,
        senha: senha,
        tipo: tipo,
        empresaId: empresaIdVinculada,
      );

      if (ehAdminNovo) {
        // Agora autenticado: registra a empresa do novo administrador
        await _db.collection('empresas').doc(empresaIdVinculada).set({
          'id': empresaIdVinculada,
          'nomeFantasia': nomeDaEmpresa ?? "Nova Empresa Logística",
          'dataCriacao': FieldValue.serverTimestamp(),
        });
      }

      _setCarregando(false);
      return true;
    } catch (e) {
      _erroMensagem = e.toString();
      _setCarregando(false);
      return false;
    }
  }

  // Executa o logout limpando o estado da sessão
  Future<void> realizarLogout() async {
    await _authService.deslogar();
    _empresaIdLogada = null;
    _nomeUsuarioLogado = null;
    notifyListeners();
  }
}