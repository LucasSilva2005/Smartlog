import 'dart:async';

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

  // 📡 Assinaturas ativas do Firestore. Guardadas para poderem ser canceladas
  // (evita listener duplicado a cada pull-to-refresh e vazamento no dispose)
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inscricaoEntregas;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _inscricaoEmpresa;

  // Empresa atualmente escutada — serve de trava contra reassinaturas redundantes
  String? _empresaEscutada;

  // Impede notifyListeners() depois que o controller já foi descartado
  bool _descartado = false;

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

      // 📡 Entregas agora chegam em tempo real via snapshots(), não mais por get()
      escutarEntregas(empresaId);

      _empresaEscutada = empresaId;

      // Carrega os motoristas vinculados à empresa logada
      final snapshotMotoristas = await _firestore
          .collection('usuarios')
          .where('empresaId', isEqualTo: empresaId)
          .where('tipoUsuario', isEqualTo: 'MOTORISTA')
          .get();

      _motoristas = snapshotMotoristas.docs.map((doc) => doc.data()).toList();

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
    // Trava anti-duplicação: rechamadas para a MESMA empresa (ex.: pull-to-refresh)
    // reaproveitam o listener existente em vez de empilhar um novo
    if (_inscricaoEmpresa != null && _empresaEscutada == empresaId) return;

    _inscricaoEmpresa?.cancel();
    _inscricaoEmpresa = _firestore
        .collection('empresas')
        .doc(empresaId)
        .snapshots()
        .listen(
          (doc) {
        if (_descartado) return;
        if (doc.exists) {
          dadosEmpresa = doc.data() ?? {};
          notifyListeners();
        }
      },
      onError: (Object e) => debugPrint("Erro no listener da empresa: $e"),
    );
  }

  // 📡 Sincronização em TEMPO REAL das entregas da empresa logada.
  // Substitui o antigo .get(): Admin, Motorista e Cliente passam a ver
  // mudanças de status assim que elas ocorrem, sem atualizar manualmente.
  void escutarEntregas(String empresaId) {
    // Mesma trava: um único listener de entregas por empresa
    if (_inscricaoEntregas != null && _empresaEscutada == empresaId) return;

    _inscricaoEntregas?.cancel();
    _inscricaoEntregas = _firestore
        .collection('entregas')
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .listen(
          (snapshot) {
        if (_descartado) return;
        // O snapshot é a fonte da verdade e substitui a lista inteira
        _entregas = snapshot.docs.map((doc) => doc.data()).toList();
        notifyListeners();
      },
      onError: (Object e) => debugPrint("Erro no listener de entregas: $e"),
    );
  }

  // 🧹 Encerra as assinaturas ativas. Chamado no dispose e ao trocar de empresa.
  Future<void> _cancelarInscricoes() async {
    await _inscricaoEntregas?.cancel();
    await _inscricaoEmpresa?.cancel();
    _inscricaoEntregas = null;
    _inscricaoEmpresa = null;
    _empresaEscutada = null;
  }

  @override
  void dispose() {
    // Marca antes de cancelar: qualquer evento em voo é ignorado em vez de
    // chamar notifyListeners() em um ChangeNotifier já descartado
    _descartado = true;
    _cancelarInscricoes();
    super.dispose();
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
    (e['regiao'] ?? '').toString().toLowerCase() == regiao.toLowerCase()).toList();
  }

  // ══════════════════════════════════════════════════════════════════════
  // 🧠 AI LOGISTICS EXTENSION
  // Camada de inteligência operacional 100% determinística, derivada apenas
  // das listas já carregadas por inicializarDados(). Sem consulta nova, sem
  // escrita, sem coleção nova e sem serviço externo. Mesmos dados ⇒ mesmo
  // resultado, sempre.
  // ══════════════════════════════════════════════════════════════════════

  // Entrega não concluída parada por mais que este tempo é tratada como atrasada
  static const int horasLimiteAtraso = 24;

  // Abaixo deste volume os indicadores são apresentados com ressalva de amostra pequena
  static const int amostraMinimaConfiavel = 3;

  // A base convive com dois formatos de data: Timestamp (lido do Firestore) e
  // String ISO8601 (cópia otimista gravada em memória por criarRotaComEntregas)
  DateTime? _lerData(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    if (valor is String) return DateTime.tryParse(valor);
    return null;
  }

  Map<String, dynamic> gerarInsightsOperacionais() {
    final int total = _entregas.length;

    if (total == 0) {
      return {
        'temDados': false,
        'amostraReduzida': false,
        'total': 0,
        'porStatus': <String, int>{},
        'percentualConcluidas': 0,
        'regiaoLider': null,
        'regiaoLiderQtd': 0,
        'regiaoLiderPercentual': 0,
        'motoristaSobrecarregado': null,
        'motoristaCargaAtiva': 0,
        'motoristasComCarga': 0,
        'atrasadas': 0,
        'semMotorista': 0,
        'semDataConfiavel': 0,
        'recomendacoes': <String>[
          "Nenhuma entrega cadastrada ainda. Crie uma rota na aba Rotas para que os indicadores passem a ser calculados.",
        ],
      };
    }

    final DateTime agora = DateTime.now();

    final Map<String, int> porStatus = {};
    final Map<String, int> porRegiao = {};
    final Map<String, int> cargaAtivaPorMotorista = {};
    final Map<String, String> nomeDoMotorista = {};

    int atrasadas = 0;
    int semMotorista = 0;
    int semDataConfiavel = 0;

    for (final e in _entregas) {
      final String status = (e['status'] ?? 'Pendente').toString().trim();
      final bool concluida = status == 'Entregue';

      porStatus[status] = (porStatus[status] ?? 0) + 1;

      final String regiao = (e['regiao'] ?? '').toString().trim();
      if (regiao.isNotEmpty) {
        porRegiao[regiao] = (porRegiao[regiao] ?? 0) + 1;
      }

      final String uid = (e['motoristaUid'] ?? '').toString().trim();
      final String nome = (e['motorista'] ?? '').toString().trim();
      // 'Sem motorista' é o literal gravado por criarRotaComEntregas quando não há responsável
      final bool temMotorista = nome.isNotEmpty && nome != 'Sem motorista';

      if (!temMotorista) {
        semMotorista++;
      } else if (!concluida) {
        // Carga ATIVA = o que ainda está na rua. Agrupa por UID e cai no nome se o UID faltar
        final String chave = uid.isNotEmpty ? uid : nome;
        cargaAtivaPorMotorista[chave] = (cargaAtivaPorMotorista[chave] ?? 0) + 1;
        nomeDoMotorista[chave] = nome;
      }

      if (status == 'Atrasada') {
        atrasadas++;
      } else if (!concluida) {
        final DateTime? criacao = _lerData(e['dataCriacao']);
        if (criacao == null) {
          semDataConfiavel++;
        } else if (agora.difference(criacao).inHours >= horasLimiteAtraso) {
          atrasadas++;
        }
      }
    }

    final int concluidas = porStatus['Entregue'] ?? 0;
    final int pendentes = porStatus['Pendente'] ?? 0;
    final int percentualConcluidas = ((concluidas / total) * 100).round();

    // Desempate alfabético para o resultado não depender da ordem de leitura do Firestore
    String? regiaoLider;
    int regiaoLiderQtd = 0;
    for (final item in porRegiao.entries) {
      if (item.value > regiaoLiderQtd ||
          (item.value == regiaoLiderQtd && regiaoLider != null && item.key.compareTo(regiaoLider) < 0)) {
        regiaoLiderQtd = item.value;
        regiaoLider = item.key;
      }
    }
    final int regiaoLiderPercentual = regiaoLiderQtd == 0 ? 0 : ((regiaoLiderQtd / total) * 100).round();

    String? chaveMotoristaTopo;
    int motoristaCargaAtiva = 0;
    for (final item in cargaAtivaPorMotorista.entries) {
      final String nomeAtual = nomeDoMotorista[item.key] ?? item.key;
      final String nomeTopo = chaveMotoristaTopo == null ? '' : (nomeDoMotorista[chaveMotoristaTopo] ?? chaveMotoristaTopo);
      if (item.value > motoristaCargaAtiva ||
          (item.value == motoristaCargaAtiva && chaveMotoristaTopo != null && nomeAtual.compareTo(nomeTopo) < 0)) {
        motoristaCargaAtiva = item.value;
        chaveMotoristaTopo = item.key;
      }
    }
    final String? motoristaSobrecarregado =
    chaveMotoristaTopo == null ? null : nomeDoMotorista[chaveMotoristaTopo];

    final int cargaAtivaTotal = cargaAtivaPorMotorista.values.fold(0, (a, b) => a + b);
    final int motoristasComCarga = cargaAtivaPorMotorista.length;
    final bool amostraReduzida = total < amostraMinimaConfiavel;

    // ── Recomendações: cada uma dispara SOMENTE se sua condição numérica for verdadeira ──
    final List<String> recomendacoes = [];

    if (atrasadas > 0) {
      recomendacoes.add(
          "$atrasadas entrega(s) sem baixa há mais de ${horasLimiteAtraso}h. Acione o motorista responsável para regularizar.");
    }

    if (semMotorista > 0) {
      recomendacoes.add(
          "$semMotorista entrega(s) sem motorista atribuído. Faça a atribuição na aba Rotas para liberar a operação.");
    }

    if (pendentes > 0 && totalMotoristasAtivos == 0) {
      recomendacoes.add(
          "Há $pendentes entrega(s) pendente(s) e nenhum motorista cadastrado. Cadastre a equipe na aba Motoristas.");
    }

    // Sobrecarga: carga ativa do topo acima de 1,5× a média da equipe em operação
    if (motoristasComCarga >= 2 && motoristaCargaAtiva >= 2) {
      final double media = cargaAtivaTotal / motoristasComCarga;
      if (motoristaCargaAtiva > media * 1.5) {
        final int percentualCarga = ((motoristaCargaAtiva / cargaAtivaTotal) * 100).round();
        recomendacoes.add(
            "$motoristaSobrecarregado concentra $motoristaCargaAtiva entregas ativas ($percentualCarga% da carga em rua). Avalie redistribuir entre a equipe.");
      }
    }

    if (regiaoLider != null && regiaoLiderPercentual >= 50 && total >= amostraMinimaConfiavel) {
      recomendacoes.add(
          "$regiaoLider concentra $regiaoLiderPercentual% das entregas. Avalie reforçar a equipe designada para essa região.");
    }

    if (percentualConcluidas >= 80) {
      recomendacoes.add(
          "Taxa de conclusão de $percentualConcluidas%. Operação dentro do esperado.");
    }

    if (recomendacoes.isEmpty) {
      recomendacoes.add(
          "Nenhum gargalo identificado nos dados atuais. Operação equilibrada entre regiões e motoristas.");
    }

    if (semDataConfiavel > 0) {
      recomendacoes.add(
          "$semDataConfiavel entrega(s) sem data de criação legível ficaram fora do cálculo de atraso.");
    }

    if (amostraReduzida) {
      recomendacoes.add(
          "Amostra pequena ($total entrega(s)). Os indicadores ganham precisão conforme novas entregas forem registradas.");
    }

    return {
      'temDados': true,
      'amostraReduzida': amostraReduzida,
      'total': total,
      'porStatus': porStatus,
      'percentualConcluidas': percentualConcluidas,
      'regiaoLider': regiaoLider,
      'regiaoLiderQtd': regiaoLiderQtd,
      'regiaoLiderPercentual': regiaoLiderPercentual,
      'motoristaSobrecarregado': motoristaSobrecarregado,
      'motoristaCargaAtiva': motoristaCargaAtiva,
      'motoristasComCarga': motoristasComCarga,
      'atrasadas': atrasadas,
      'semMotorista': semMotorista,
      'semDataConfiavel': semDataConfiavel,
      'recomendacoes': recomendacoes,
    };
  }

  // 👤 Entregas de um cliente específico, reaproveitando a lista já carregada por inicializarDados
  // Obs.: o vínculo é feito pelo NOME do contrato solicitante, único campo disponível em 'entregas'
  List<Map<String, dynamic>> filtrarPorCliente(String nomeCliente) {
    final String alvo = nomeCliente.trim().toLowerCase();
    if (alvo.isEmpty) return [];
    return _entregas.where((e) =>
    (e['cliente'] ?? '').toString().trim().toLowerCase() == alvo).toList();
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

      // ⚠️ Com o listener ativo, o Firestore aplica latency compensation e o snapshot
      // local já pode ter trazido estas entregas antes do commit retornar. Só adicionamos
      // o que ainda não está na lista — mantém o feedback otimista (útil offline) sem duplicar.
      for (final nova in novasEntregasLocais) {
        if (!_entregas.any((e) => e['id'] == nova['id'])) {
          _entregas.add(nova);
        }
      }

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
  // 📡 Processamento inteligente do Bip do QR Code (Máquina de Estados)
  // Retorna um String se precisar abrir modal para o recebedor, ou null se mudou de estado direto
  Future<String?> registrarBipQRCode({
    required String entregaId,
    String? nomeRecebedor,
  }) async {
    _carregando = true;
    notifyListeners();

    try {
      // 1. Localiza a entrega correspondente na memória local ou Firestore
      // Como o Admin cria gerando IDs dinâmicos, vamos buscar pelo campo id da entrega
      final querySnapshot = await _firestore
          .collection('entregas')
          .where('id', isEqualTo: entregaId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception("Código de Entrega inválido ou não encontrado.");
      }

      final docRef = querySnapshot.docs.first.reference;
      final dadosAtuais = querySnapshot.docs.first.data();
      final String statusAtual = dadosAtuais['status'] ?? 'Pendente';

      // ➔ BIP 1: Se estiver Pendente, passa automaticamente para "A Caminho"
      if (statusAtual == 'Pendente') {
        await docRef.update({
          'status': 'A Caminho',
          'dataAtualizacao': FieldValue.serverTimestamp(),
        });

        // Sincroniza a memória interna imediatamente
        int idx = _entregas.indexWhere((e) => e['id'] == entregaId);
        if (idx != -1) _entregas[idx]['status'] = 'A Caminho';

        _carregando = false;
        notifyListeners();
        return "EM_TRANSITO";
      }

      // ➔ BIP 2: Se já estiver "A Caminho" e não enviou o recebedor ainda, pede o nome
      if (statusAtual == 'A Caminho' && nomeRecebedor == null) {
        _carregando = false;
        notifyListeners();
        return "REQUISITAR_RECEBEDOR"; // Avisa a View para abrir o modal de digitação
      }

      // ➔ CONFIRMAÇÃO DO BIP 2: Se veio o nome do recebedor, finaliza a baixa do pacote
      if (statusAtual == 'A Caminho' && nomeRecebedor != null) {
        await docRef.update({
          'status': 'Entregue',
          'recebedor': nomeRecebedor,
          'dataEntrega': FieldValue.serverTimestamp(),
        });

        int idx = _entregas.indexWhere((e) => e['id'] == entregaId);
        if (idx != -1) {
          _entregas[idx]['status'] = 'Entregue';
          _entregas[idx]['recebedor'] = nomeRecebedor;
        }

        _carregando = false;
        notifyListeners();
        return "FINALIZADO";
      }

      _carregando = false;
      notifyListeners();
      return "JA_ENTREGUE";
    } catch (e) {
      debugPrint("Erro ao processar bip do QR Code: $e");
      _carregando = false;
      notifyListeners();
      return "ERRO";
    }
  }
}