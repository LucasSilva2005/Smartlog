import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class DashboardController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _carregando = false;

  bool get carregando => _carregando;

  // Listas locais alimentadas dinamicamente pelo banco de dados
  List<Map<String, dynamic>> _entregas = [];
  List<Map<String, dynamic>> _motoristas = [];
  List<Map<String, dynamic>> _clientes = [];

  List<Map<String, dynamic>> get entregas => _entregas;
  List<Map<String, dynamic>> get motoristas => _motoristas;
  List<Map<String, dynamic>> get clientes => _clientes;

  int get totalEntregas => _entregas.length;
  int get totalMotoristasAtivos => _motoristas.length;
  int get totalClientesCadastrados => _clientes.length;

  // 🔄 Função chamada assim que o Admin entra na tela para sincronizar os dados
  Future<void> inicializarDados(String empresaId) async {
    _carregando = true;
    notifyListeners();

    try {
      // Carrega os motoristas vinculados à empresa logada
      final snapshotMotoristas = await _firestore
          .collection('usuarios')
          .where('empresaId', isEqualTo: empresaId)
          .where('tipoUsuario', isEqualTo: 'MOTORISTA')
          .get();

      _motoristas = snapshotMotoristas.docs.map((doc) => doc.data()).toList();

      // Carrega as entregas vinculadas à empresa logada
      final snapshotEntregas = await _firestore
          .collection('entregas')
          .where('empresaId', isEqualTo: empresaId)
          .get();

      _entregas = snapshotEntregas.docs.map((doc) => doc.data()).toList();

      // Se a lista de entregas do banco estiver vazia, carrega o Mock inicial para testes
      if (_entregas.isEmpty) {
        _entregas = [
          {'id': 'E01', 'cliente': 'Hortifruti Nações', 'regiao': 'Zona Sul', 'status': 'Entregue', 'motorista': 'Carlos Silva', 'empresaId': empresaId},
          {'id': 'E02', 'cliente': 'Supermercado Vila Sofia', 'regiao': 'Zona Sul', 'status': 'A Caminho', 'motorista': 'Carlos Silva', 'empresaId': empresaId},
          {'id': 'E03', 'cliente': 'Varejo Interlagos', 'regiao': 'Zona Sul', 'status': 'Pendente', 'motorista': 'Carlos Silva', 'empresaId': empresaId},
          {'id': 'E04', 'cliente': 'Lojista Santo Amaro', 'regiao': 'Zona Sul', 'status': 'Pendente', 'motorista': 'Carlos Silva', 'empresaId': empresaId},
          {'id': 'E05', 'cliente': 'Mercado Grajaú', 'regiao': 'Zona Sul', 'status': 'Pendente', 'motorista': 'Carlos Silva', 'empresaId': empresaId},
        ];
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados do Firestore: $e");
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> filtrarPorRegiao(String regiao) {
    return _entregas.where((e) =>
    e['regiao'].toString().toLowerCase() == regiao.toLowerCase()).toList();
  }

  // ✉️ Criação no Auth com isolamento de App para NÃO deslogar o Admin
  Future<bool> cadastrarMotoristaPorConvite({
    required String nome,
    required String email,
    required String regiao,
    required String empresaId,
  }) async {
    _carregando = true;
    notifyListeners();

    // Cria uma instância secundária do Firebase em memória para processar a criação de terceiros
    FirebaseApp? appSecundario;
    bool resultadoSucesso = false;

    try {
      final emailTratado = email.trim().toLowerCase();
      const String senhaTemporaria = "SmartLog@123";

      // Inicializa o app secundário temporário usando as configurações do app atual
      appSecundario = await Firebase.initializeApp(
        name: 'CriadorMotoristaTemp',
        options: Firebase.app().options,
      );

      FirebaseAuth authSecundario = FirebaseAuth.instanceFor(app: appSecundario);

      // 1. Cria a credencial usando a instância isolada secundária
      UserCredential userCredential = await authSecundario.createUserWithEmailAndPassword(
        email: emailTratado,
        password: senhaTemporaria,
      );

      final String uidGerado = userCredential.user!.uid;

      // 2. Salva os dados complementares no Cloud Firestore com a instância principal
      await _firestore.collection('usuarios').doc(uidGerado).set({
        'uid': uidGerado,
        'nome': nome,
        'email': emailTratado,
        'regiaoDesignada': regiao,
        'tipoUsuario': 'MOTORISTA',
        'empresaId': empresaId,
        'statusAtivacao': 'Aguardando Verificação',
        'dataCadastro': FieldValue.serverTimestamp(),
      });

      // 3. Dispara o e-mail de verificação oficial do Firebase
      await userCredential.user!.sendEmailVerification();

      // 4. Atualiza a lista da memória reativamente (Sincronizado com as chaves do Firestore)
      _motoristas.add({
        'uid': uidGerado,
        'nome': nome,
        'email': emailTratado,
        'regiaoDesignada': regiao,
        'tipoUsuario': 'MOTORISTA',
        'empresaId': empresaId,
        'statusAtivacao': 'Aguardando Verificação',
      });

      resultadoSucesso = true;
    } catch (e) {
      debugPrint("Erro no cadastro e verificação de motorista: $e");
      resultadoSucesso = false;
    } finally {
      // Garante a exclusão do app secundário para liberar memória RAM e evitar conflitos posteriores
      if (appSecundario != null) {
        await appSecundario.delete();
      }
      _carregando = false;
      notifyListeners(); // Modifica o estado global da UI de uma vez só no final do processo
    }

    return resultadoSucesso;
  }
}