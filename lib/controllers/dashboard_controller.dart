// lib/controllers/dashboard_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class DashboardController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? empresaId;
  bool _carregando = false;
  bool _descartado = false;
  String? _analiseIA;
  String? _erro;

  // Listas locais de dados
  List<Map<String, dynamic>> _entregas = [];
  List<Map<String, dynamic>> _motoristas = [];
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _rotas = [];
  Map<String, dynamic> _dadosEmpresa = {};

  DashboardController({this.empresaId});

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }

  // --- GETTERS DE ESTADO ---
  bool get carregando => _carregando;
  bool get isLoading => _carregando;
  String? get analiseIA => _analiseIA;
  String? get erro => _erro;

  // --- GETTERS EXPOSTOS DE LISTAS ---
  List<Map<String, dynamic>> get entregas => List.unmodifiable(_entregas);
  List<Map<String, dynamic>> get rotas => List.unmodifiable(_rotas);
  List<Map<String, dynamic>> get motoristas => List.unmodifiable(_motoristas);
  List<Map<String, dynamic>> get clientes => List.unmodifiable(_clientes);
  Map<String, dynamic> get dadosEmpresa => _dadosEmpresa;

  // --- CONTADORES PARA O DASHBOARD ---
  int get totalEntregas => _entregas.length;
  int get totalMotoristasAtivos => _motoristas.length;
  int get totalClientesCadastrados => _clientes.length;

  // --- INICIALIZAÇÃO DE DADOS ---
  Future<void> inicializarDados(String idEmpresa) async {
    empresaId = idEmpresa;
    _carregando = true;
    _erro = null;
    if (!_descartado) notifyListeners();

    try {
      await Future.wait([
        carregarEntregas(),
        carregarMotoristas(),
        carregarClientes(),
        carregarRotas(),
        carregarPerfilEmpresa(idEmpresa),
      ]);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _carregando = false;
      if (!_descartado) notifyListeners();
    }
  }

  // --- MÉTODOS DE CARREGAMENTO (FIRESTORE) ---
  Future<void> carregarEntregas() async {
    try {
      if (empresaId == null) {
        debugPrint("DEBUG: carregarEntregas abortado pois empresaId é nulo.");
        return;
      }

      final snapshot = await _firestore
          .collection('entregas')
          .where('empresaId', isEqualTo: empresaId)
          .get();

      _entregas = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      debugPrint("DEBUG: Carregadas ${_entregas.length} entregas para a empresa $empresaId.");

      if (!_descartado) notifyListeners();
    } catch (e) {
      _erro = e.toString();
      debugPrint("ERRO em carregarEntregas: $e");
    }
  }

  Future<void> carregarMotoristas() async {
    try {
      if (empresaId == null) return;
      final snapshot = await _firestore
          .collection('usuarios')
          .where('empresaId', isEqualTo: empresaId)
          .where('tipo', isEqualTo: 'MOTORISTA')
          .get();

      _motoristas = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      if (!_descartado) notifyListeners();
    } catch (e) {
      _erro = e.toString();
    }
  }

  Future<void> carregarClientes() async {
    try {
      if (empresaId == null) return;
      final snapshot = await _firestore
          .collection('usuarios')
          .where('empresaId', isEqualTo: empresaId)
          .where('tipo', isEqualTo: 'CLIENTE')
          .get();

      _clientes = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      if (!_descartado) notifyListeners();
    } catch (e) {
      _erro = e.toString();
    }
  }

  Future<void> carregarRotas() async {
    try {
      if (empresaId == null) return;
      final snapshot = await _firestore
          .collection('rotas')
          .where('empresaId', isEqualTo: empresaId)
          .get();

      _rotas = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      if (!_descartado) notifyListeners();
    } catch (e) {
      _erro = e.toString();
    }
  }

  // --- MÉTODO DE CADASTRO DE ENTREGA COM SINCRONIZAÇÃO AUTOMÁTICA DE CLIENTE ---
  Future<bool> cadastrarEntregaESincronizarCliente({
    required String clienteNome,
    required String clienteEmail,
    required String clienteTelefone,
    required String endereco,
    required String regiao,
    String? motoristaId,
    String? dataAgendada,
  }) async {
    try {
      if (empresaId == null) {
        debugPrint("ERRO: empresaId nulo ao cadastrar entrega.");
        return false;
      }

      // 1. Gerar chave única para o documento do cliente na coleção 'usuarios'
      final clienteIdKey = clienteEmail.trim().isNotEmpty
          ? clienteEmail.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')
          : clienteNome.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

      final clienteRef = _firestore.collection('usuarios').doc(clienteIdKey);
      final clienteSnapshot = await clienteRef.get();

      // 2. Cria ou atualiza o cliente na coleção 'usuarios'
      if (!clienteSnapshot.exists) {
        final novoClienteData = {
          'id': clienteIdKey,
          'empresaId': empresaId,
          'nome': clienteNome,
          'email': clienteEmail,
          'telefone': clienteTelefone,
          'enderecoPrincipal': endereco,
          'tipo': 'CLIENTE',
          'tipoUsuario': 'CLIENTE',
          'criadoEm': FieldValue.serverTimestamp(),
        };

        await clienteRef.set(novoClienteData);

        // Atualiza a lista local em memória
        _clientes.add({
          'id': clienteIdKey,
          ...novoClienteData,
        });
      } else {
        // Atualiza os dados de contato do cliente existente
        await clienteRef.update({
          'enderecoPrincipal': endereco,
          if (clienteTelefone.isNotEmpty) 'telefone': clienteTelefone,
        });
      }

      // 3. Cadastra a entrega vinculada ao cliente
      final novaEntregaData = {
        'empresaId': empresaId,
        'cliente': clienteNome,
        'emailCliente': clienteEmail,
        'clienteId': clienteIdKey,
        'telefoneCliente': clienteTelefone,
        'endereco': endereco,
        'regiao': regiao,
        'status': 'Pendente',
        'motoristaId': motoristaId ?? '',
        'data': dataAgendada ?? '',
        'criadoEm': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('entregas').add(novaEntregaData);

      // Adiciona na lista local de entregas
      _entregas.add({
        'id': docRef.id,
        ...novaEntregaData,
      });

      if (!_descartado) notifyListeners();
      debugPrint("Entrega cadastrada e cliente sincronizado com sucesso!");
      return true;
    } catch (e) {
      _erro = e.toString();
      debugPrint("ERRO ao cadastrar entrega e sincronizar cliente: $e");
      if (!_descartado) notifyListeners();
      return false;
    }
  }

  // --- CARREGAR PERFIL E DADOS DA EMPRESA ---
  Future<void> carregarPerfilEmpresa(String idEmpresa) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('empresas').doc(idEmpresa).get();
      if (doc.exists) {
        _dadosEmpresa = doc.data() as Map<String, dynamic>? ?? {};
        if (!_descartado) notifyListeners();
      }
    } catch (e) {
      debugPrint("ERRO ao carregar perfil da empresa: $e");
    }
  }

  // --- ATUALIZAR E SALVAR PERFIL E DADOS DA EMPRESA ---
  Future<void> atualizarPerfilEmpresa({
    required String empresaId,
    required Map<String, dynamic> novosDados,
  }) async {
    try {
      if (empresaId.isEmpty) return;

      await _firestore.collection('empresas').doc(empresaId).set(novosDados, SetOptions(merge: true));

      _dadosEmpresa = novosDados;
      if (!_descartado) notifyListeners();
    } catch (e) {
      _erro = e.toString();
      debugPrint("ERRO ao atualizar perfil da empresa: $e");
      rethrow;
    }
  }

  // --- MÉTODOS DE FILTRAGEM REQUISITADOS PELAS TELAS ---
  List<Map<String, dynamic>> filtrarPorRegiao(String regiao) {
    if (regiao.toLowerCase() == "todas") return _entregas;
    return _entregas.where((e) {
      final regItem = (e['regiao'] ?? '').toString().toLowerCase();
      return regItem.contains(regiao.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> filtrarPorCliente(String nomeCliente) {
    if (nomeCliente.isEmpty) return _entregas;
    return _entregas.where((e) {
      final cliente = (e['cliente'] ?? '').toString().toLowerCase();
      return cliente.contains(nomeCliente.toLowerCase());
    }).toList();
  }

  // --- MÉTODO DE CADASTRO DE MOTORISTA COM INSTÂNCIA SECUNDÁRIA ---
  Future<bool> cadastrarNovoMotorista({
    required String nome,
    required String email,
    required String regiao,
  }) async {
    try {
      const senhaProvisoria = "SmartLog@2026";

      FirebaseApp appSecundario = await Firebase.initializeApp(
        name: 'RegistroMotorista',
        options: Firebase.app().options,
      );

      FirebaseAuth authSecundario = FirebaseAuth.instanceFor(app: appSecundario);

      UserCredential userCredential = await authSecundario.createUserWithEmailAndPassword(
        email: email,
        password: senhaProvisoria,
      );

      final uidMotorista = userCredential.user?.uid;
      if (uidMotorista == null) throw Exception("Erro ao gerar ID de autenticação.");

      await userCredential.user?.sendEmailVerification();
      await appSecundario.delete();

      final novoMotoristaData = {
        'nome': nome,
        'email': email,
        'regiaoDesignada': regiao,
        'tipo': 'MOTORISTA',
        'tipoUsuario': 'MOTORISTA',
        'status': 'Ativo',
        if (empresaId != null) 'empresaId': empresaId,
        'criadoEm': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('usuarios').doc(uidMotorista).set(novoMotoristaData);

      _motoristas.add({
        'id': uidMotorista,
        ...novoMotoristaData,
      });

      if (!_descartado) notifyListeners();
      return true;
    } catch (e) {
      _erro = e.toString();
      if (!_descartado) notifyListeners();
      return false;
    }
  }

  // --- MÉTODO PARA GERAR ROTA AUTOMATICAMENTE COM LOGS DE DIAGNÓSTICO ---
  Future<bool> gerarRotaParaMotorista({
    required String motoristaId,
    required String motoristaNome,
    required String regiao,
    required String nomeRota,
  }) async {
    try {
      debugPrint("--- INÍCIO GERAR ROTA ---");
      debugPrint("EmpresaId atual: $empresaId");
      debugPrint("Região desejada: '$regiao'");

      if (empresaId == null) {
        debugPrint("ERRO: empresaId está nulo.");
        return false;
      }

      final snapshot = await _firestore
          .collection('entregas')
          .where('empresaId', isEqualTo: empresaId)
          .get();

      final entregasFiltradas = snapshot.docs.where((doc) {
        final data = doc.data();
        final statusDoc = (data['status'] ?? '').toString().trim().toLowerCase();
        final regiaoDoc = (data['regiao'] ?? '').toString().trim().toLowerCase();

        final bool ehPendente = statusDoc == 'pendente';
        final bool mesmaRegiao = regiaoDoc == regiao.trim().toLowerCase();

        return ehPendente && mesmaRegiao;
      }).toList();

      if (entregasFiltradas.isEmpty) return false;

      List<Map<String, dynamic>> listaEnderecos = entregasFiltradas.take(5).map((doc) {
        final data = doc.data();
        return {
          'entregaId': doc.id,
          'cliente': data['cliente'] ?? 'Cliente',
          'endereco': data['endereco'] ?? '',
        };
      }).toList();

      final novaRotaData = {
        'empresaId': empresaId,
        'motoristaId': motoristaId,
        'motoristaNome': motoristaNome,
        'nome': nomeRota,
        'regiao': regiao,
        'status': 'Pendente',
        'totalEnderecos': listaEnderecos.length,
        'enderecos': listaEnderecos,
        'criadoEm': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('rotas').add(novaRotaData);
      await carregarRotas();

      debugPrint("Rota gerada com sucesso!");
      return true;
    } catch (e) {
      _erro = e.toString();
      debugPrint("EXCEÇÃO em gerarRotaParaMotorista: $e");
      notifyListeners();
      return false;
    }
  }

  // --- MÉTODOS DE AÇÕES DO MOTORISTA ---
  Future<String?> registrarBipQRCode({
    required String entregaId,
    String? nomeRecebedor,
  }) async {
    try {
      final index = _entregas.indexWhere((e) => e['id'] == entregaId);
      if (index != -1) {
        if (_entregas[index]['status'] == 'Pendente') {
          _entregas[index]['status'] = 'Em Rota';
          notifyListeners();
          return "Status alterado para: Em Rota";
        } else if (_entregas[index]['status'] == 'Em Rota' || _entregas[index]['status'] == 'A Caminho') {
          _entregas[index]['status'] = 'Entregue';
          if (nomeRecebedor != null && nomeRecebedor.isNotEmpty) {
            _entregas[index]['recebedor'] = nomeRecebedor;
          }
          notifyListeners();
          return "Entrega concluída com sucesso!";
        } else {
          return "Esta entrega já foi finalizada.";
        }
      }
      return "Entrega não encontrada.";
    } catch (e) {
      return "Erro ao processar o QR Code.";
    }
  }
}