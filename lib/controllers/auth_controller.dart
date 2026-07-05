import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _carregando = false;
  bool get carregando => _carregando;

  String? _erroMensagem;
  String? get erroMensagem => _erroMensagem;

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
          _setCarregando(false);
          return dados['tipo']; // Retorna 'Administrador', 'Motorista' ou 'Cliente'
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

  // NOVO: Realiza o cadastro do usuário e salva no Firestore
  // Ajustado para conversar perfeitamente com o seu AuthService
  Future<bool> registrarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String tipo,
  }) async {
    _setCarregando(true);
    _erroMensagem = null;

    try {
      // Chama a função direto do seu AuthService, passando todos os parâmetros
      UserCredential creds = await _authService.cadastrarUsuario(
        nome: nome,
        email: email,
        senha: senha,
        tipo: tipo,
      );

      if (creds.user != null) {
        _setCarregando(false);
        return true;
      }

      _setCarregando(false);
      return false;
    } catch (e) {
      // Aqui ele já captura a mensagem em português tratada pelo seu Service!
      _erroMensagem = e.toString();
      _setCarregando(false);
      return false;
    }
  }

  // Executa o logout
  Future<void> realizarLogout() async {
    await _authService.deslogar();
  }
}