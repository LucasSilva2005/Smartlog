import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream para monitorar o estado da autenticação (logado ou não)
  Stream<User?> get usuarioStatus => _auth.authStateChanges();

  // Login com Email e Senha
  Future<UserCredential> loginComEmailESenha(String email, String senha) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: senha);
    } on FirebaseAuthException catch (e) {
      throw _tratarErroAuth(e);
    }
  }

  // Cadastro de Novo Usuário (Salva no Auth e cria o perfil na coleção 'users')
  Future<UserCredential> cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String tipo, // Administrador, Motorista, Cliente
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      if (cred.user != null) {
        // Cria o documento do usuário na coleção especificada no escopo do projeto
        await _db.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'nome': nome,
          'email': email,
          'tipo': tipo,
        });
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      throw _tratarErroAuth(e);
    }
  }

  // Buscar dados adicionais do usuário logado (para saber o perfil/tipo)
  Future<DocumentSnapshot> buscarDadosUsuario(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }

  // Logout
  Future<void> deslogar() async {
    await _auth.signOut();
  }

  // Recuperação de Senha
  Future<void> resetarSenha(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _tratarErroAuth(e);
    }
  }

  // Helper amigável para tratamento de erros em português
  String _tratarErroAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Nenhum usuário encontrado com este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta. Tente novamente.';
      case 'email-already-in-use':
        return 'Este e-mail já está sendo utilizado.';
      case 'weak-password':
        return 'A senha digitada é muito fraca.';
      case 'invalid-email':
        return 'O formato do e-mail digitado é inválido.';
      default:
        return 'Ocorreu um erro inesperado: ${e.message}';
    }
  }
}