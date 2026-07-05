// Salve em: lib/screens/dashboard_motorista.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/dashboard_controller.dart';

class DashboardMotorista extends StatefulWidget {
  final String nomeMotorista; // Passado dinamicamente após o login
  final String regiaoDesignada; // Ex: 'Zona Sul'

  const DashboardMotorista({
    super.key,
    this.nomeMotorista = "Carlos Silva",
    this.regiaoDesignada = "Zona Sul",
  });

  @override
  State<DashboardMotorista> createState() => _DashboardMotoristaState();
}

class _DashboardMotoristaState extends State<DashboardMotorista> {
  bool _rotaIniciada = false;

  @override
  Widget build(BuildContext context) {
    // Acessando as entregas globais do controlador
    final controller = context.watch<DashboardController>();

    // Filtrando estritamente as entregas pertencentes à região deste motorista
    final minhasEntregas = controller.filtrarPorRegiao(widget.regiaoDesignada);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xff0F172A),
        foregroundColor: Colors.white,
        title: Text("SmartLog — Rota ${widget.regiaoDesignada}"),
        actions: [
          Chip(
            label: Text(_rotaIniciada ? "EM ROTA" : "DISPONÍVEL"),
            backgroundColor: _rotaIniciada ? Colors.orange : Colors.green,
            labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // MAPA EM TELA CHEIA (Placeholder Visual do Percurso Regional)
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.grey[300],
              child: Stack(
                children: [
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.navigation, size: 60, color: Colors.blue),
                        SizedBox(height: 8),
                        Text(
                          "Google Maps Ativo",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          "Exibindo sequência otimizada de 5 entregas",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  // Indicador Flutuante da IA de Rota
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.psychology, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _rotaIniciada
                                  ? "IA: Siga pela rota calculada para evitar o trânsito regional."
                                  : "IA: Aguardando comando para iniciar sequência ideal.",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // SEÇÃO DE COMPONENTES DE AÇÃO E LISTAGEM DA ROTA
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.nomeMotorista,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Total: ${minhasEntregas.length} entregas agendadas",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      // BOTÕES DE AÇÃO RÁPIDA (Fáceis de tocar na rua)
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _rotaIniciada = !_rotaIniciada;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _rotaIniciada ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: Icon(_rotaIniciada ? Icons.stop : Icons.play_arrow),
                        label: Text(_rotaIniciada ? "Finalizar" : "Iniciar Rota"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Sequência de Entregas",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // LISTA FILTRADA DA OPERAÇÃO DO MOTORISTA
                  Expanded(
                    child: ListView.builder(
                      itemCount: minhasEntregas.length,
                      itemBuilder: (context, index) {
                        final entrega = minhasEntregas[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withAlpha(40),
                              child: Text("${index + 1}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(entrega['cliente']),
                            subtitle: Text("ID: ${entrega['id']} | Status: ${entrega['status']}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Colors.grey),
                              onPressed: _rotaIniciada ? () {
                                // Ação para simular a conclusão de uma entrega específica
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Entrega ${entrega['id']} concluída!")),
                                );
                              } : null, // Desabilitado se a rota global não tiver sido iniciada
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}