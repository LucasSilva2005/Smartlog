import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class DashboardController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _carregando = false;

  bool get carregando => _carregando;

  // Setter para encapsulamento correto do estado de loading
  set carregando(bool valor) {
    _carregando = valor;
    notifyListeners();
  }

  // 🏛️ Mapa para armazenar em tempo real as configurações e dados do ERP da Empresa
  Map<String, dynamic> dadosEmpresa = {};

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

  // 🔄 Função chamada assim que o Admin entra na tela para sincronizar os dados reais
  Future<void> inicializarDados(String empresaId) async {
    _carregando = true;
    notifyListeners();

    try {
      // 🚀 Inicializa o listener reativo dos dados corporativos do Perfil
      escutarDadosEmpresa(empresaId);

      // Carrega os motoristas vinculados à empresa logada
      final snapshotMotoristas = await _firestore
          .collection('usuarios')
          .where('empresaId', isEqualTo: empresaId)
          .where('tipoUsuario', isEqualTo: 'MOTORISTA')
          .get();

      _motoristas = snapshotMotoristas.docs.map((doc) => doc.data()).toList();

      // Carrega as entregas REAIS vinculadas à empresa logada
      final snapshotEntregas = await _firestore
          .collection('entregas')
          .where('empresaId', isEqualTo: empresaId)
          .get();

      _entregas = snapshotEntregas.docs.map((doc) => doc.data()).toList();

      // 👥 Carrega os clientes REAIS vinculados à empresa logada
      final snapshotClientes = await _firestore
          .collection('usuarios')
          .where('empresaId', isEqualTo: empresaId)
          .where('tipoUsuario', isEqualTo: 'CLIENTE')
          .get();

      _clientes = snapshotClientes.docs.map((doc) => doc.data()).toList();

    } catch (e) {
      debugPrint("Erro ao carregar dados do Firestore: $e");
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // 📡 Escuta reativa da empresa ativa para atualizar o Perfil do Admin dinamicamente
  void escutarDadosEmpresa(String empresaId) {
    _firestore.collection('empresas').doc(empresaId).snapshots().listen((doc) {
      if (doc.exists) {
        dadosEmpresa = doc.data() ?? {};
        notifyListeners();
      }
    });
  }

  // 💾 Salva ou modifica dados cadastrais da empresa no Firestore (Modo Edição)
  Future<bool> atualizarPerfilEmpresa({
    required String empresaId,
    required Map<String, dynamic> novosDados,
  }) async {
    try {
      _carregando = true;
      notifyListeners();

      await _firestore.collection('empresas').doc(empresaId).set(
        {
          ...novosDados,
          'onlineDesde': dadosEmpresa['onlineDesde'] ?? '2025', // Preserva se já existir
        },
        SetOptions(merge: true),
      );

      _carregando = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar perfil da empresa: $e");
      _carregando = false;
      notifyListeners();
      return false;
    }
  }

  List<Map<String, dynamic>> filtrarPorRegiao(String regiao) {
    return _entregas.where((e) =>
    e['regiao'].toString().toLowerCase() == regiao.toLowerCase()).toList();
  }

  // ✉️ Criação de Motorista no Auth com senha dinâmica e UID amarrado perfeitamente
  Future<bool> cadastrarMotoristaPorConvite({
    required String nome,
    required String email,
    required String regiao,
    required String senha,
    required String empresaId,
  }) async {
    _carregando = true;
    notifyListeners();

    FirebaseApp? appSecundario;
    bool resultadoSucesso = false;

    try {
      final emailTratado = email.trim().toLowerCase();

      // 1. Inicializa o ambiente temporário em memória RAM
      appSecundario = await Firebase.initializeApp(
        name: 'CriadorMotoristaTemp',
        options: Firebase.app().options,
      );

      FirebaseAuth authSecundario = FirebaseAuth.instanceFor(app: appSecundario);

      // 2. Cria a credencial legítima na barreira de segurança (Authentication)
      UserCredential userCredential = await authSecundario.createUserWithEmailAndPassword(
        email: emailTratado,
        password: senha,
      );

      // 🔥 CRÍTICO: Captura o UID real e exato criado pelo Authentication Secundário!
      final String uidGerado = userCredential.user!.uid;

      // 3. Grava no Firestore na coleção única usando o uidGerado como ID do Documento
      await _firestore.collection('usuarios').doc(uidGerado).set({
        'uid': uidGerado,
        'nome': nome,
        'email': emailTratado,
        'regiaoDesignada': regiao,
        'tipoUsuario': 'MOTORISTA', // 👈 Mantido em maiúsculo para bater com o login.dart
        'empresaId': empresaId,
        'statusAtivacao': 'Ativo', // Já ativa por padrão já que definimos a senha
        'dataCadastro': FieldValue.serverTimestamp(),
      });

      // 4. Tenta disparar o e-mail (opcional, já que você já sabe a senha)
      try {
        await userCredential.user!.sendEmailVerification();
      } catch (e) {
        debugPrint("Aviso: E-mail de verificação não pôde ser disparado: $e");
      }

      // Sincroniza na memória local para atualizar o painel do Admin na hora
      _motoristas.add({
        'uid': uidGerado,
        'nome': nome,
        'email': emailTratado,
        'regiaoDesignada': regiao,
        'tipoUsuario': 'MOTORISTA',
        'empresaId': empresaId,
        'statusAtivacao': 'Ativo',
      });

      resultadoSucesso = true;
    } catch (e) {
      debugPrint("Erro estrutural no cadastro de motorista: $e");
      resultadoSucesso = false;
    } finally {
      // 5. Destrói a instância secundária para não vazar memória ou deslogar o Admin
      if (appSecundario != null) {
        await appSecundario.delete();
      }
      _carregando = false;
      notifyListeners();
    }

    return resultadoSucesso;
  }

  // ✉️ Criação de Cliente no Auth com senha dinâmica definida pelo Admin
  Future<bool> cadastrarClientePorConvite({
    required String nome,
    required String email,
    required String senha, // 👈 Modificado: Recebe a senha vinda do formulário
    required String empresaId,
  }) async {
    _carregando = true;
    notifyListeners();

    FirebaseApp? appSecundario;
    bool resultadoSucesso = false;

    try {
      final emailTratado = email.trim().toLowerCase();

      appSecundario = await Firebase.initializeApp(
        name: 'CriadorClienteTemp',
        options: Firebase.app().options,
      );

      FirebaseAuth authSecundario = FirebaseAuth.instanceFor(app: appSecundario);

      UserCredential userCredential = await authSecundario.createUserWithEmailAndPassword(
        email: emailTratado,
        password: senha, // 👈 Usa a senha real digitada pelo Admin
      );

      final String uidGerado = userCredential.user!.uid;

      await _firestore.collection('usuarios').doc(uidGerado).set({
        'uid': uidGerado,
        'nome': nome,
        'email': emailTratado,
        'tipoUsuario': 'CLIENTE',
        'empresaId': empresaId,
        'statusAtivacao': 'Aguardando Verificação',
        'dataCadastro': FieldValue.serverTimestamp(),
      });

      await userCredential.user!.sendEmailVerification();

      _clientes.add({
        'uid': uidGerado,
        'nome': nome,
        'email': emailTratado,
        'tipoUsuario': 'CLIENTE',
        'empresaId': empresaId,
        'statusAtivacao': 'Aguardando Verificação',
      });

      resultadoSucesso = true;
    } catch (e) {
      debugPrint("Erro no cadastro e convite do cliente: $e");
      resultadoSucesso = false;
    } finally {
      if (appSecundario != null) {
        await appSecundario.delete();
      }
      _carregando = false;
      notifyListeners();
    }

    return resultadoSucesso;
  }

  // 🗺️ MÓDULO ENTERPRISE CORRIGIDO (Separação estrita de tipos locais vs remotos)
  Future<bool> criarRotaComEntregas({
    required List<String> enderecos,
    required String clienteNome,
    required String regiao,
    required Map<String, dynamic> motoristaSelecionado,
    required String empresaId,
  }) async {
    try {
      _carregando = true;
      notifyListeners();

      final WriteBatch batch = _firestore.batch();
      int ordemContador = 1;
      List<Map<String, dynamic>> novasEntregasLocais = [];

      for (var endereco in enderecos) {
        if (endereco.trim().isEmpty) continue;

        DocumentReference entregaRef = _firestore.collection('entregas').doc();

        final novaEntregaLocal = {
          'id': 'ENT-${entregaRef.id.substring(0, 5).toUpperCase()}',
          'cliente': clienteNome,
          'endereco': endereco.trim(),
          'regiao': regiao,
          'status': 'Pendente',
          'motorista': motoristaSelecionado['nome'] ?? 'Sem motorista',
          'motoristaUid': motoristaSelecionado['uid'] ?? '',
          'ordemEntrega': ordemContador++,
          'empresaId': empresaId,
          'dataCriacao': DateTime.now().toIso8601String(),
        };

        batch.set(entregaRef, {
          ...novaEntregaLocal,
          'dataCriacao': FieldValue.serverTimestamp(),
        });

        novasEntregasLocais.add(novaEntregaLocal);
      }

      await batch.commit();

      _entregas.addAll(novasEntregasLocais);

      _carregando = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Erro ao processar rota e entregas em lote: $e");
      _carregando = false;
      notifyListeners();
      return false;
    }
  }
}