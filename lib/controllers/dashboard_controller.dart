// lib/controllers/dashboard_controller.dart
import 'package:flutter/material.dart';

class DashboardController extends ChangeNotifier {
  String? empresaId;
  bool _carregando = false;
  String? _analiseIA;

  DashboardController({this.empresaId});

  // --- GETTERS DE ESTADO ---
  bool get carregando => _carregando;
  bool get isLoading => _carregando;

  void inicializarDados(String idEmpresa) {
    empresaId = idEmpresa;
    notifyListeners();
  }

  // --- DADOS MOCKADOS: 80 ENTREGAS (20 PARA CADA REGIÃO COM DATAS) ---
  final List<Map<String, dynamic>> _entregas = [
    // ================= ZONA NORTE (20 Entregas) =================
    {'id': 'ENT-N01', 'cliente': 'Leroy Merlin Marginal', 'endereco': 'Av. Otto Baumgart, 500', 'regiao': 'Norte', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-N02', 'cliente': 'Distribuidora Santana', 'endereco': 'R. Voluntários da Pátria, 1200', 'regiao': 'Norte', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-N03', 'cliente': 'Depósito Tucuruvi', 'endereco': 'Av. Mazzei, 450', 'regiao': 'Norte', 'status': 'Entregue', 'data': '2026-07-24'},
    {'id': 'ENT-N04', 'cliente': 'Comércio Casa Verde', 'endereco': 'Rua Dr. Cesar, 88', 'regiao': 'Norte', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-N05', 'cliente': 'Mega Center Tremembé', 'endereco': 'Av. Nova Cantareira, 2100', 'regiao': 'Norte', 'status': 'Pendente', 'data': '2026-07-23'},
    {'id': 'ENT-N06', 'cliente': 'Eletro Jaçanã', 'endereco': 'Av. Guapira, 1800', 'regiao': 'Norte', 'status': 'Entregue', 'data': '2026-07-22'},
    {'id': 'ENT-N07', 'cliente': 'Ferragens Mandaqui', 'endereco': 'Rua Voluntários da Pátria, 3500', 'regiao': 'Norte', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-N08', 'cliente': 'Comercial Vila Maria', 'endereco': 'Av. Guilherme Cotching, 1100', 'regiao': 'Norte', 'status': 'Entregue', 'data': '2026-07-24'},
    {'id': 'ENT-N09', 'cliente': 'Materiais Limão', 'endereco': 'Av. Celestino Bourroul, 700', 'regiao': 'Norte', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-N10', 'cliente': 'Supermercado Imirim', 'endereco': 'Av. Imirim, 2300', 'regiao': 'Norte', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-N11', 'cliente': 'Lojas Cachoeirinha', 'endereco': 'Av. Parada Pinto, 800', 'regiao': 'Norte', 'status': 'Entregue', 'data': '2026-07-23'},
    {'id': 'ENT-N12', 'cliente': 'Construtora Lauzane', 'endereco': 'Av. Conselheiro Moreira de Barros, 2900', 'regiao': 'Norte', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-N13', 'cliente': 'Atacado Vila Guilherme', 'endereco': 'Rua Joaquina Ramalho, 900', 'regiao': 'Norte', 'status': 'Entregue', 'data': '2026-07-21'},
    {'id': 'ENT-N14', 'cliente': 'Centro Logístico Anhembi', 'endereco': 'Av. Olavo Fontoura, 1200', 'regiao': 'Norte', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-N15', 'cliente': 'Auto Peças Cantareira', 'endereco': 'Rua Maestro João Gomes de Araújo, 150', 'regiao': 'Norte', 'status': 'Entregue', 'data': '2026-07-24'},
    {'id': 'ENT-N16', 'cliente': 'Depósito Brasilândia', 'endereco': 'Av. Deputado Cantídio Sampaio, 1400', 'regiao': 'Norte', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-N17', 'cliente': 'Madeireira Freguesia', 'endereco': 'Av. Itaberaba, 2100', 'regiao': 'Norte', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-N18', 'cliente': 'Tintas Bairro do Limão', 'endereco': 'Rua Clávio, 320', 'regiao': 'Norte', 'status': 'Entregue', 'data': '2026-07-22'},
    {'id': 'ENT-N19', 'cliente': 'Plásticos Chácara Cintra', 'endereco': 'Rua Maria Curupaiti, 410', 'regiao': 'Norte', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-N20', 'cliente': 'Distribuidora Parada Inglesa', 'endereco': 'Av. Luiz Dumont Villares, 1500', 'regiao': 'Norte', 'status': 'Entregue', 'data': '2026-07-24'},

    // ================= ZONA SUL (20 Entregas) =================
    {'id': 'ENT-S01', 'cliente': 'Leroy Merlin Interlagos', 'endereco': 'Av. Interlagos, 2255', 'regiao': 'Sul', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-S02', 'cliente': 'Centro Logístico Santo Amaro', 'endereco': 'Rua Amador Bueno, 300', 'regiao': 'Sul', 'status': 'Entregue', 'data': '2026-07-25'},
    {'id': 'ENT-S03', 'cliente': 'Eletro Moema', 'endereco': 'Alameda dos Maracatins, 900', 'regiao': 'Sul', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-S04', 'cliente': 'Marmoraria Morumbi', 'endereco': 'Av. Giovanni Gronchi, 3000', 'regiao': 'Sul', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-S05', 'cliente': 'Construtora Jabaquara', 'endereco': 'Av. Jabaquara, 1500', 'regiao': 'Sul', 'status': 'Entregue', 'data': '2026-07-24'},
    {'id': 'ENT-S06', 'cliente': 'Ferragens Saúde', 'endereco': 'Av. das Enseadas, 120', 'regiao': 'Sul', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-S07', 'cliente': 'Atacado Vila Mariana', 'endereco': 'Rua Domingos de Morais, 1800', 'regiao': 'Sul', 'status': 'Entregue', 'data': '2026-07-23'},
    {'id': 'ENT-S08', 'cliente': 'Home Center Campo Belo', 'endereco': 'Av. Vereador José Diniz, 2400', 'regiao': 'Sul', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-S09', 'cliente': 'Depósito Brooklin', 'endereco': 'Av. Engenheiro Luís Carlos Berrini, 500', 'regiao': 'Sul', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-S10', 'cliente': 'Distribuidora Pedreira', 'endereco': 'Estrada do Alvarenga, 1200', 'regiao': 'Sul', 'status': 'Entregue', 'data': '2026-07-22'},
    {'id': 'ENT-S11', 'cliente': 'Comercial Grajaú', 'endereco': 'Av. Dona Belmira Marin, 2100', 'regiao': 'Sul', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-S12', 'cliente': 'Materiais Cidade Dutra', 'endereco': 'Av. Senador Teotônio Vilela, 3100', 'regiao': 'Sul', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-S13', 'cliente': 'Lojas Ipiranga', 'endereco': 'Rua Silva Bueno, 1500', 'regiao': 'Sul', 'status': 'Entregue', 'data': '2026-07-24'},
    {'id': 'ENT-S14', 'cliente': 'Eletro Socorro', 'endereco': 'Av. Atlântica, 900', 'regiao': 'Sul', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-S15', 'cliente': 'Mega Depósito Campo Limpo', 'endereco': 'Estrada do Campo Limpo, 1800', 'regiao': 'Sul', 'status': 'Entregue', 'data': '2026-07-21'},
    {'id': 'ENT-S16', 'cliente': 'Auto Peças Capão Redondo', 'endereco': 'Av. Comendador Sant\'Anna, 1200', 'regiao': 'Sul', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-S17', 'cliente': 'Madeireira Vila Andrade', 'endereco': 'Rua Doutor Luiz Migliano, 800', 'regiao': 'Sul', 'status': 'Entregue', 'data': '2026-07-23'},
    {'id': 'ENT-S18', 'cliente': 'Tintas Sacomã', 'endereco': 'Rua Greenfeld, 250', 'regiao': 'Sul', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-S19', 'cliente': 'Comércio Cursino', 'endereco': 'Av. do Cursino, 1900', 'regiao': 'Sul', 'status': 'Entregue', 'data': '2026-07-24'},
    {'id': 'ENT-S20', 'cliente': 'Distribuidora Aeroporto', 'endereco': 'Av. Washington Luís, 4500', 'regiao': 'Sul', 'status': 'Em Rota', 'data': '2026-07-25'},

    // ================= ZONA LESTE (20 Entregas) =================
    {'id': 'ENT-L01', 'cliente': 'Leroy Merlin Aricanduva', 'endereco': 'Av. Aricanduva, 5555', 'regiao': 'Leste', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-L02', 'cliente': 'Materiais Tatuapé', 'endereco': 'Rua Tuiuti, 1800', 'regiao': 'Leste', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-L03', 'cliente': 'Atacado Mooca', 'endereco': 'Rua da Mooca, 2500', 'regiao': 'Leste', 'status': 'Entregue', 'data': '2026-07-24'},
    {'id': 'ENT-L04', 'cliente': 'Distribuidora Itaquera', 'endereco': 'Av. Campanella, 900', 'regiao': 'Leste', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-L05', 'cliente': 'Ferragens Penha', 'endereco': 'Rua Penha de França, 400', 'regiao': 'Leste', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-L06', 'cliente': 'Comercial São Mateus', 'endereco': 'Av. Mateo Bei, 2200', 'regiao': 'Leste', 'status': 'Entregue', 'data': '2026-07-23'},
    {'id': 'ENT-L07', 'cliente': 'Depósito Vila Formosa', 'endereco': 'Av. Doutor Eduardo Cotching, 1400', 'regiao': 'Leste', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-L08', 'cliente': 'Eletro Anália Franco', 'endereco': 'Rua Eleonora Cintra, 600', 'regiao': 'Leste', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-L09', 'cliente': 'Home Center Belém', 'endereco': 'Rua Belém, 350', 'regiao': 'Leste', 'status': 'Entregue', 'data': '2026-07-22'},
    {'id': 'ENT-L10', 'cliente': 'Construtora Ermelino', 'endereco': 'Av. Paranaguá, 1500', 'regiao': 'Leste', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-L11', 'cliente': 'Auto Peças São Miguel', 'endereco': 'Av. Marechal Tito, 2800', 'regiao': 'Leste', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-L12', 'cliente': 'Distribuidora Itaim Paulista', 'endereco': 'Av. Marechal Tito, 4500', 'regiao': 'Leste', 'status': 'Entregue', 'data': '2026-07-24'},
    {'id': 'ENT-L13', 'cliente': 'Lojas Guaianases', 'endereco': 'Rua Salvador Gianetti, 800', 'regiao': 'Leste', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-L14', 'cliente': 'Madeireira Cidade Tiradentes', 'endereco': 'Av. Metalúrgicos, 1900', 'regiao': 'Leste', 'status': 'Entregue', 'data': '2026-07-21'},
    {'id': 'ENT-L15', 'cliente': 'Tintas Vila Prudente', 'endereco': 'Av. Paes de Barros, 3100', 'regiao': 'Leste', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-L16', 'cliente': 'Ferragens Água Rasa', 'endereco': 'Av. Regente Feijó, 1200', 'regiao': 'Leste', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-L17', 'cliente': 'Depósito Artur Alvim', 'endereco': 'Av. Maciel Monteiro, 500', 'regiao': 'Leste', 'status': 'Entregue', 'data': '2026-07-24'},
    {'id': 'ENT-L18', 'cliente': 'Plásticos Vila Carrão', 'endereco': 'Av. Conselheiro Carrão, 1800', 'regiao': 'Leste', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-L19', 'cliente': 'Comércio Sapopemba', 'endereco': 'Av. Sapopemba, 7000', 'regiao': 'Leste', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-L20', 'cliente': 'Centro Logístico Parque do Carmo', 'endereco': 'Av. Afonso de Sampaio e Sousa, 900', 'regiao': 'Leste', 'status': 'Entregue', 'data': '2026-07-23'},

    // ================= ZONA OESTE (20 Entregas) =================
    {'id': 'ENT-O01', 'cliente': 'Leroy Merlin Raposo', 'endereco': 'Rod. Raposo Tavares, Km 14', 'regiao': 'Oeste', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-O02', 'cliente': 'Home Center Pinheiros', 'endereco': 'Rua Teodoro Sampaio, 1400', 'regiao': 'Oeste', 'status': 'Entregue', 'data': '2026-07-25'},
    {'id': 'ENT-O03', 'cliente': 'Depositão Lapa', 'endereco': 'Rua Clélia, 800', 'regiao': 'Oeste', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-O04', 'cliente': 'Madeireira Perdizes', 'endereco': 'Av. Sumaré, 1100', 'regiao': 'Oeste', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-O05', 'cliente': 'Tintas Jaguaré', 'endereco': 'Av. Jaguaré, 600', 'regiao': 'Oeste', 'status': 'Pendente', 'data': '2026-07-23'},
    {'id': 'ENT-O06', 'cliente': 'Comercial Butantã', 'endereco': 'Av. Vital Brasil, 950', 'regiao': 'Oeste', 'status': 'Entregue', 'data': '2026-07-24'},
    {'id': 'ENT-O07', 'cliente': 'Eletro Vila Leopoldina', 'endereco': 'Rua Carlos Weber, 700', 'regiao': 'Oeste', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-O08', 'cliente': 'Ferragens Alto de Pinheiros', 'endereco': 'Av. Pedroso de Morais, 1200', 'regiao': 'Oeste', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-O09', 'cliente': 'Atacado Rio Pequeno', 'endereco': 'Av. do Rio Pequeno, 1500', 'regiao': 'Oeste', 'status': 'Entregue', 'data': '2026-07-22'},
    {'id': 'ENT-O10', 'cliente': 'Materiais Pirituba', 'endereco': 'Av. Mutinga, 2100', 'regiao': 'Oeste', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-O11', 'cliente': 'Distribuidora Jaraguá', 'endereco': 'Estrada de Taipas, 1200', 'regiao': 'Oeste', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-O12', 'cliente': 'Lojas Pompéia', 'endereco': 'Av. Alfonso Bovero, 850', 'regiao': 'Oeste', 'status': 'Entregue', 'data': '2026-07-24'},
    {'id': 'ENT-O13', 'cliente': 'Auto Peças Barra Funda', 'endereco': 'Rua das Perdizes, 300', 'regiao': 'Oeste', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-O14', 'cliente': 'Depósito Vila Madalena', 'endereco': 'Rua Harmonia, 500', 'regiao': 'Oeste', 'status': 'Entregue', 'data': '2026-07-21'},
    {'id': 'ENT-O15', 'cliente': 'Construtora Osasco Divisa', 'endereco': 'Av. Autonomistas, 3500', 'regiao': 'Oeste', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-O16', 'cliente': 'Mega Depósito Raposo', 'endereco': 'Rod. Raposo Tavares, Km 18', 'regiao': 'Oeste', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-O17', 'cliente': 'Centro Logístico Anhanguera', 'endereco': 'Via Anhanguera, Km 15', 'regiao': 'Oeste', 'status': 'Entregue', 'data': '2026-07-24'},
    {'id': 'ENT-O18', 'cliente': 'Tintas Vila Sônia', 'endereco': 'Av. Prof. Francisco Morato, 2800', 'regiao': 'Oeste', 'status': 'Pendente', 'data': '2026-07-25'},
    {'id': 'ENT-O19', 'cliente': 'Plásticos Ceasa', 'endereco': 'Av. Dr. Gastão Vidigal, 1900', 'regiao': 'Oeste', 'status': 'Em Rota', 'data': '2026-07-25'},
    {'id': 'ENT-O20', 'cliente': 'Ferragens Jaguara', 'endereco': 'Rua Cândido Portinari, 400', 'regiao': 'Oeste', 'status': 'Entregue', 'data': '2026-07-23'},
  ];

  // --- DADOS MOCKADOS: ROTAS ---
  final List<Map<String, dynamic>> _rotas = [
    {
      'id': 'ROT-001',
      'nome': 'Rota 01 - Express Zona Norte',
      'regiao': 'Norte',
      'motorista': 'Marcos Souza',
      'veiculo': 'Furgão Mercedes Sprinter',
      'status': 'Em Andamento',
    },
    {
      'id': 'ROT-002',
      'nome': 'Rota 02 - Corredor Zona Sul',
      'regiao': 'Sul',
      'motorista': 'Carlos Silva',
      'veiculo': 'Caminhão VW Delivery',
      'status': 'Em Andamento',
    },
    {
      'id': 'ROT-003',
      'nome': 'Rota 03 - Radial Zona Leste',
      'regiao': 'Leste',
      'motorista': 'Roberto Lima',
      'veiculo': 'Furgão Renault Master',
      'status': 'Aguardando',
    },
    {
      'id': 'ROT-004',
      'nome': 'Rota 04 - Eixo Zona Oeste',
      'regiao': 'Oeste',
      'motorista': 'Ana Oliveira',
      'veiculo': 'Hyundai HR',
      'status': 'Em Andamento',
    },
    {
      'id': 'ROT-005',
      'nome': 'Rota 05 - Express Centro',
      'regiao': 'Central',
      'motorista': 'Fernando Prado',
      'veiculo': 'Fiat Ducato',
      'status': 'Concluída',
    },
  ];

  // --- DADOS MOCKADOS: MOTORISTAS ---
  final List<Map<String, dynamic>> _motoristas = [
    {'nome': 'Marcos Souza', 'email': 'marcos@smartlog.com', 'regiao': 'Zona Norte', 'status': 'Ativo'},
    {'nome': 'Carlos Silva', 'email': 'carlos@smartlog.com', 'regiao': 'Zona Sul', 'status': 'Ativo'},
    {'nome': 'Roberto Lima', 'email': 'roberto@smartlog.com', 'regiao': 'Zona Leste', 'status': 'Ativo'},
    {'nome': 'Ana Oliveira', 'email': 'ana@smartlog.com', 'regiao': 'Zona Oeste', 'status': 'Ativo'},
  ];

  // --- DADOS MOCKADOS: CLIENTES ---
  final List<Map<String, dynamic>> _clientes = [
    {'nome': 'Leroy Merlin Brasil', 'tipo': 'Corporativo', 'cidade': 'São Paulo'},
    {'nome': 'Distribuidora Santana', 'tipo': 'Varejo', 'cidade': 'São Paulo'},
    {'nome': 'Atacado Mooca', 'tipo': 'Atacado', 'cidade': 'São Paulo'},
    {'nome': 'Home Center Pinheiros', 'tipo': 'Varejo', 'cidade': 'São Paulo'},
  ];

  // --- GETTERS EXPOSTOS ---
  List<Map<String, dynamic>> get entregas => List.unmodifiable(_entregas);
  List<Map<String, dynamic>> get rotas => List.unmodifiable(_rotas);
  List<Map<String, dynamic>> get motoristas => List.unmodifiable(_motoristas);
  List<Map<String, dynamic>> get clientes => List.unmodifiable(_clientes);

  int get totalEntregas => _entregas.length;
  int get totalMotoristasAtivos => _motoristas.where((m) => m['status'] == 'Ativo').length;
  int get totalClientesCadastrados => _clientes.length;

  // --- MÉTODOS DE AÇÃO DO SISTEMA ---
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
        } else if (_entregas[index]['status'] == 'Em Rota') {
          _entregas[index]['status'] = 'Entregue';
          if (nomeRecebedor != null) {
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

  Future<void> cadastrarNovoMotorista({
    required String nome,
    required String email,
    required String regiao,
  }) async {
    _motoristas.add({
      'nome': nome,
      'email': email,
      'regiao': regiao,
      'status': 'Ativo',
    });
    notifyListeners();
  }
}