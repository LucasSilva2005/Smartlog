// lib/screens/motorista.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/auth_controller.dart';

class DashboardMotorista extends StatefulWidget {
  final String regiaoDesignada; // Adicionado para receber o parâmetro do login

  const DashboardMotorista({super.key, this.regiaoDesignada = "Zona Sul"});

  @override
  State<DashboardMotorista> createState() => _DashboardMotoristaState();
}

class _DashboardMotoristaState extends State<DashboardMotorista> {
  int _indiceAba = 0;
  String _statusDisponibilidade = "Disponível"; // Disponível, Em rota, Em pausa, Offline
  bool _rotaIniciada = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();
    final authController = context.read<AuthController>();
    final userUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    // Filtra as entregas reais da memória atribuídas especificamente a este motorista
    final minhasEntregas = controller.entregas
        .where((e) => e['motoristaUid'] == userUid)
        .toList();

    // Ordena as entregas pela sequência correta da rota gerada pelo Admin
    minhasEntregas.sort((a, b) => (a['ordemEntrega'] ?? 1).compareTo(b['ordemEntrega'] ?? 1));

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xff0F172A),
        foregroundColor: Colors.white,
        title: const Text("SmartLog - Motorista", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          // Seletor de Status Operacional rápido no Topo
          PopupMenuButton<String>(
            initialValue: _statusDisponibilidade,
            onSelected: (String novoStatus) {
              setState(() => _statusDisponibilidade = novoStatus);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _obterCorStatus(_statusDisponibilidade).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _obterCorStatus(_statusDisponibilidade), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _obterCorStatus(_statusDisponibilidade)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusDisponibilidade,
                    style: TextStyle(color: _obterCorStatus(_statusDisponibilidade), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                ],
              ),
            ),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'Disponível', child: Text('🟢 Disponível')),
              const PopupMenuItem<String>(value: 'Em rota', child: Text('🚚 Em rota')),
              const PopupMenuItem<String>(value: 'Em pausa', child: Text('⏸️ Em pausa')),
              const PopupMenuItem<String>(value: 'Offline', child: Text('🔴 Offline')),
            ],
          ),
        ],
      ),
      body: _renderizarAba(minhasEntregas, controller),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAba,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _indiceAba = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Rota Atual'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil & Carro'),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Segurança'),
        ],
      ),
    );
  }

  Widget _renderizarAba(List<Map<String, dynamic>> minhasEntregas, DashboardController controller) {
    switch (_indiceAba) {
      case 0:
        return _buildAbaRotaAtual(minhasEntregas, controller);
      case 1:
        return _buildAbaPerfilEVeiculo(minhasEntregas);
      case 2:
        return _buildAbaSegurancaEHistorico();
      default:
        return _buildAbaRotaAtual(minhasEntregas, controller);
    }
  }

  // ==========================================
  // 🚚 ABA 1: ROTA ATUAL & OPERAÇÃO DE CAMPO
  // ==========================================
  Widget _buildAbaRotaAtual(List<Map<String, dynamic>> entregas, DashboardController controller) {
    final pendentes = entregas.where((e) => e['status'] == 'Pendente' || e['status'] == 'A Caminho').toList();
    final proximaEntrega = pendentes.isNotEmpty ? pendentes.first : null;

    return Column(
      children: [
        // 🎫 BANNER PRÓXIMA ENTREGA / PRÓXIMO ALVO DO MAPA
        if (proximaEntrega != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xff0F172A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("PRÓXIMA PARADA OPERACIONAL", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                      child: Text("Ordem #${proximaEntrega['ordemEntrega'] ?? '1'}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(proximaEntrega['endereco'] ?? 'Sem endereço', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Cliente: ${proximaEntrega['cliente'] ?? 'Geral'}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 16),

                // Botões de Ação Industrial Grandes
                Row(
                  children: [
                    if (!_rotaIniciada)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                          onPressed: () {
                            setState(() {
                              _rotaIniciada = true;
                              _statusDisponibilidade = "Em rota";
                              proximaEntrega['status'] = 'A Caminho';
                            });
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text("Iniciar Rota", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                          onPressed: () async {
                            // Lógica reativa para dar baixa e atualizar status no banco
                            _modalConfirmarEntregaFinal(proximaEntrega);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text("Concluir Entrega", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),

        // 📋 LISTA COMPLETA DAS ENTREGAS RESTANTES DA ROTA DO MOTORISTA
        Expanded(
          child: entregas.isEmpty
              ? const Center(child: Text("Nenhuma entrega atribuída para você hoje."))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: entregas.length,
            itemBuilder: (context, index) {
              final e = entregas[index];
              bool isAtual = e['id'] == proximaEntrega?['id'];

              return Card(
                color: isAtual ? Colors.orange.withOpacity(0.05) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: isAtual ? const BorderSide(color: Colors.orange, width: 1) : BorderSide.none,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _obterCorBadgeStatus(e['status']),
                    child: Text("${e['ordemEntrega'] ?? index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(e['endereco'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("Cliente: ${e['cliente']} • Código: ${e['id']}"),
                  trailing: Icon(
                    e['status'] == 'Entregue' ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: e['status'] == 'Entregue' ? Colors.green : Colors.grey,
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  // ==========================================
  // 👤 ABA 2: DADOS PESSOAIS & FICHA DO VEÍCULO
  // ==========================================
  Widget _buildAbaPerfilEVeiculo(List<Map<String, dynamic>> entregas) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "joao.silva@smartlog.com";
    final concluidas = entregas.where((e) => e['status'] == 'Entregue').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER DO PERFIL DO MOTORISTA
          Card(
            color: const Color(0xff0F172A),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(radius: 32, backgroundColor: Colors.orange, child: Icon(Icons.delivery_dining, size: 36, color: Colors.white)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("João Silva", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text("Motorista Parceiro", style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(userEmail, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text("4.9 (42 avaliações)", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. DETALHAMENTO DE KPI LOGÍSTICOS
          const Text("Estatísticas de Performance", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff0F172A))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _miniCardKpiMotorista("Total Rotas", "${entregas.length}", Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _miniCardKpiMotorista("Concluídas", "$concluidas", Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _miniCardKpiMotorista("KM Rodados", "1.420 km", Colors.purple)),
            ],
          ),
          const SizedBox(height: 16),

          // 3. FICHA CADASTRAL DO VEÍCULO DA COOP
          const Text("Informações do Veículo Atribuído", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff0F172A))),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _perfilInfoRow("Modelo/Marca", "Fiorino Endurance - Fiat"),
                  _perfilInfoRow("Ano / Cor", "2023 • Branca"),
                  _perfilInfoRow("Placa Mercosul", "LOG-3M26"),
                  _perfilInfoRow("Capacidade Operacional", "650 kg / 3.3 m³"),
                  _perfilInfoRow("Km Atual do Painel", "24.510 km"),
                  const Divider(height: 24),
                  _perfilInfoRow("Última Manutenção preventiva", "15/12/2025"),
                  _perfilInfoRow("Próxima Manutenção / Troca Óleo", "25.000 km"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. CARTEIRA DE DOCUMENTOS DIGITAIS
          const Text("Documentos e Certificados Regulamentares", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff0F172A))),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                _documentoFichaRow("CNH Digital - Categoria B", "Válida até 12/2028", true),
                _documentoFichaRow("CRLV - Documento do Veículo", "Exercício 2026 Pago", true),
                _documentoFichaRow("Apólice do Seguro de Carga", "Ativa Leroy Merlin", true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🛡️ ABA 3: SEGURANÇA (SOS) & HISTÓRICO EVENTOS
  // ==========================================
  Widget _buildAbaSegurancaEHistorico() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🚨 BOTÃO DE SOS PANIC EMERGENCY
          Card(
            color: Colors.red[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.gpp_maybe, color: Colors.red, size: 24),
                      SizedBox(width: 8),
                      Text("Central de Segurança & SOS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text("Em caso de quebra mecânica, sinistro ou sinistro operacional, acione o botão abaixo para alertar o Admin em tempo real.", style: TextStyle(fontSize: 12, color: Colors.black87)),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 4),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("🚨 ALERTA SOS ENVIADO! A central e o Admin foram notificados via push."), backgroundColor: Colors.red, duration: Duration(seconds: 4)),
                        );
                      },
                      icon: const Icon(Icons.warning_amber, size: 24),
                      label: const Text("DISPARAR ALERTA SOS DE EMERGÊNCIA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text("Contatos Rápidos de Suporte", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff0F172A))),
          const SizedBox(height: 8),
          const Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(leading: Icon(Icons.headset_mic, color: Colors.blue), title: Text("Guincho & Seguradora 24h"), subtitle: Text("0800-777-1234")),
                  Divider(height: 1),
                  ListTile(leading: Icon(Icons.supervisor_account, color: Colors.blue), title: Text("Gerente Operacional (Admin)"), subtitle: Text("(11) 99999-8888")),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // ==========================================
  // WIDGETS AUXILIARES E INTERATIVOS
  // ==========================================
  Color _obterCorStatus(String s) {
    if (s == "Disponível") return Colors.green;
    if (s == "Em rota") return Colors.orange;
    if (s == "Em pausa") return Colors.blue;
    return Colors.grey;
  }

  Color _obterCorBadgeStatus(dynamic status) {
    if (status == 'Entregue') return Colors.green;
    if (status == 'A Caminho') return Colors.orange;
    return Colors.blueGrey;
  }

  Widget _perfilInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _miniCardKpiMotorista(String label, String val, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: cor, width: 4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _documentoFichaRow(String t, String sub, bool ok) {
    return ListTile(
      leading: Icon(Icons.file_present, color: ok ? Colors.green : Colors.grey),
      title: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
      trailing: const Text("Visualizar", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  // MODAL CONFIRMADOR DE BAIXAS DE ENTREGA NO FIRESTORE
  void _modalConfirmarEntregaFinal(Map<String, dynamic> entrega) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Entrega"),
        content: Text("Deseja dar baixa definitiva na entrega de código ${entrega['id']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              // 🔄 Baixa atômica real no documento do Firestore
              final String idDoc = entrega['id'].toString().replaceAll("ENT-", "");

              // Localiza o ID real gerado por doc() procurando no banco ou por correspondência
              final query = await FirebaseFirestore.instance
                  .collection('entregas')
                  .where('id', isEqualTo: entrega['id'])
                  .get();

              if (query.docs.isNotEmpty) {
                await query.docs.first.reference.update({
                  'status': 'Entregue',
                  'dataFim': FieldValue.serverTimestamp(),
                });
              }

              // Sincroniza localmente
              setState(() {
                entrega['status'] = 'Entregue';
                _rotaIniciada = false; // Permite iniciar a próxima parada
              });

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Sucesso! Baixa de entrega realizada."), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text("Confirmar Baixa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}