// lib/controllers/dashboard_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartlife/services/chat_service.dart';

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
    if (!_descartado) notifyListeners();

    try {
      await carregarEntregas();
      await carregarMotoristas();
      await carregarClientes();
    } catch (e) {
      _erro = e.toString();
    } finally {
      _carregando = false;
      if (!_descartado) notifyListeners();
    }
  }

  // --- MÉTODOS DE CARREGAMENTO (FIRESTORE COM MULTI-TENANT) ---
  Future<void> carregarEntregas() async {
    try {
      if (empresaId == null) return;

      final snapshot = await _firestore
          .collection('entregas')
          .where('empresaId', isEqualTo: empresaId)
          .get();

      _entregas = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (!_descartado) notifyListeners();
    } catch (e) {
      _erro = e.toString();
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

      _motoristas = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (!_descartado) notifyListeners();
    } catch (e) {
      _erro = e.toString();
    }
  }

  Future<void> carregarClientes() async {
    try {
      if (!_descartado) notifyListeners();
    } catch (e) {
      _erro = e.toString();
    }
  }

  // --- 🔥 MÉTODO ÚNICO DE CADASTRO DE ENTREGA SIMPLIFICADA ---
  Future<bool> cadastrarEntregaSimplificada({
    required String nome,
    required String endereco,
    required String telefone,
    required String email,
  }) async {
    _carregando = true;
    if (!_descartado) notifyListeners();

    try {
      final empresaAtual = empresaId ?? '';

      DocumentReference docRef = await _firestore.collection('entregas').add({
        'nome': nome,
        'cliente': nome,
        'endereco': endereco,
        'telefone': telefone,
        'email': email,
        'status': 'Pendente',
        'empresaId': empresaAtual,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      // Adiciona localmente na lista para refletir na UI imediatamente
      _entregas.add({
        'id': docRef.id,
        'nome': nome,
        'cliente': nome,
        'endereco': endereco,
        'telefone': telefone,
        'email': email,
        'status': 'Pendente',
        'empresaId': empresaAtual,
      });

      _carregando = false;
      if (!_descartado) notifyListeners();
      return true;
    } catch (e) {
      _erro = e.toString();
      _carregando = false;
      if (!_descartado) notifyListeners();
      return false;
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

  // --- GESTÃO DE PERFIL E EMPRESA ---
  void escutarDadosEmpresa(String uid) {
    _firestore.collection('empresas').doc(uid).snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        _dadosEmpresa = doc.data()!;
        if (!_descartado) notifyListeners();
      }
    });
  }

  Future<bool> atualizarPerfilEmpresa({
    required String empresaId,
    required Map<String, dynamic> novosDados,
  }) async {
    try {
      _carregando = true;
      if (!_descartado) notifyListeners();

      await _firestore.collection('empresas').doc(empresaId).set(novosDados, SetOptions(merge: true));
      _dadosEmpresa = novosDados;

      _carregando = false;
      if (!_descartado) notifyListeners();
      return true;
    } catch (e) {
      _carregando = false;
      if (!_descartado) notifyListeners();
      return false;
    }
  }

  Future<bool> cadastrarNovoMotorista({
    required String nome,
    required String email,
    required String regiao,
  }) async {
    try {
      _motoristas.add({
        'nome': nome,
        'email': email,
        'regiaoDesignada': regiao,
      });
      if (!_descartado) notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}