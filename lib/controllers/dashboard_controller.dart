// lib/controllers/dashboard_controller.dart
import 'package:flutter/material.dart';

class DashboardController extends ChangeNotifier {
  // Simulação do banco de dados (Mocks baseados no seu cenário de SP)
  final List<Map<String, dynamic>> _motoristas = [
    {'id': 'm1', 'nome': 'Carlos Silva', 'regiao': 'Zona Sul', 'status': 'Em Rota', 'progresso': 0.4},
    {'id': 'm2', 'nome': 'Marcos Souza', 'regiao': 'Zona Norte', 'status': 'Aguardando IA', 'progresso': 0.0},
    {'id': 'm3', 'nome': 'Ana Oliveira', 'regiao': 'Zona Oeste', 'status': 'Em Rota', 'progresso': 0.4},
    {'id': 'm4', 'nome': 'Roberto Lima', 'regiao': 'Zona Leste', 'status': 'Concluído', 'progresso': 1.0},
  ];

  // 5 entregas fictícias por região (Total: 20 entregas) [cite: 13, 30]
  final List<Map<String, dynamic>> _entregas = [
    // ZONA SUL [cite: 13]
    {'id': 'E01', 'cliente': 'Hortifruti Nações', 'regiao': 'Zona Sul', 'status': 'Entregue', 'motorista': 'Carlos Silva'},
    {'id': 'E02', 'cliente': 'Supermercado Vila Sofia', 'regiao': 'Zona Sul', 'status': 'A Caminho', 'motorista': 'Carlos Silva'},
    {'id': 'E03', 'cliente': 'Varejo Interlagos', 'regiao': 'Zona Sul', 'status': 'Pendente', 'motorista': 'Carlos Silva'},
    {'id': 'E04', 'cliente': 'Lojista Santo Amaro', 'regiao': 'Zona Sul', 'status': 'Pendente', 'motorista': 'Carlos Silva'},
    {'id': 'E05', 'cliente': 'Mercado Grajaú', 'regiao': 'Zona Sul', 'status': 'Pendente', 'motorista': 'Carlos Silva'},
    // ZONA NORTE [cite: 13]
    {'id': 'E06', 'cliente': 'Supermercado Santana', 'regiao': 'Zona Norte', 'status': 'Pendente', 'motorista': 'Marcos Souza'},
    {'id': 'E07', 'cliente': 'Hortifruti Casa Verde', 'regiao': 'Zona Norte', 'status': 'Pendente', 'motorista': 'Marcos Souza'},
    {'id': 'E08', 'cliente': 'Lojista Tucuruvi', 'regiao': 'Zona Norte', 'status': 'Pendente', 'motorista': 'Marcos Souza'},
    {'id': 'E09', 'cliente': 'Varejo Vila Maria', 'regiao': 'Zona Norte', 'status': 'Pendente', 'motorista': 'Marcos Souza'},
    {'id': 'E10', 'cliente': 'Mercado Imirim', 'regiao': 'Zona Norte', 'status': 'Pendente', 'motorista': 'Marcos Souza'},
    // ZONA OESTE [cite: 13]
    {'id': 'E11', 'cliente': 'Hortifruti Pinheiros', 'regiao': 'Zona Oeste', 'status': 'Entregue', 'motorista': 'Ana Oliveira'},
    {'id': 'E12', 'cliente': 'Super Lapa', 'regiao': 'Zona Oeste', 'status': 'Entregue', 'motorista': 'Ana Oliveira'},
    {'id': 'E13', 'cliente': 'Varejo Perdizes', 'regiao': 'Zona Oeste', 'status': 'A Caminho', 'motorista': 'Ana Oliveira'},
    {'id': 'E14', 'cliente': 'Lojista Butantã', 'regiao': 'Zona Oeste', 'status': 'Pendente', 'motorista': 'Ana Oliveira'},
    {'id': 'E15', 'cliente': 'Mercado Pompeia', 'regiao': 'Zona Oeste', 'status': 'Pendente', 'motorista': 'Ana Oliveira'},
    // ZONA LESTE [cite: 13]
    {'id': 'E16', 'cliente': 'Supermercado Tatuapé', 'regiao': 'Zona Leste', 'status': 'Entregue', 'motorista': 'Roberto Lima'},
    {'id': 'E17', 'cliente': 'Hortifruti Mooca', 'regiao': 'Zona Leste', 'status': 'Entregue', 'motorista': 'Roberto Lima'},
    {'id': 'E18', 'cliente': 'Lojista Itaquera', 'regiao': 'Zona Leste', 'status': 'Entregue', 'motorista': 'Roberto Lima'},
    {'id': 'E19', 'cliente': 'Varejo Penha', 'regiao': 'Zona Leste', 'status': 'Entregue', 'motorista': 'Roberto Lima'},
    {'id': 'E20', 'cliente': 'Mercado Anália Franco', 'regiao': 'Zona Leste', 'status': 'Entregue', 'motorista': 'Roberto Lima'},
  ];

  // Getters para expor os dados com segurança
  List<Map<String, dynamic>> get motoristas => _motoristas;
  List<Map<String, dynamic>> get entregas => _entregas;

  // Métodos de contagem inteligente para os cards informativos
  int get totalEntregas => _entregas.length;
  int get totalMotoristasAtivos => _motoristas.where((m) => m['status'] != 'Inativo').length;
  int get entregasConcluidas => _entregas.where((e) => e['status'] == 'Entregue').length;

  // A FUNÇÃO CORRETIVA QUE ESTAVA FALTANDO AQUI: [cite: 34, 118]
  List<Map<String, dynamic>> filtrarPorRegiao(String regiao) {
    return _entregas.where((e) => e['regiao'].toString().toLowerCase() == regiao.toLowerCase()).toList();
  }
}