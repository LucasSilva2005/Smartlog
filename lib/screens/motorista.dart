// lib/screens/motorista.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/auth_controller.dart';

class DashboardMotorista extends StatefulWidget {
  final String regiaoDesignada;

  const DashboardMotorista({
    super.key,
    this.regiaoDesignada = "Zona Sul",
  });

  @override
  State<DashboardMotorista> createState() => _DashboardMotoristaState();
}

class _DashboardMotoristaState extends State<DashboardMotorista> {
  bool _rotaIniciada = false;

  @override
  Widget build(BuildContext context) {
    final dashboardCtrl = context.watch<DashboardController>();
    final authCtrl = context.read<AuthController>();

    // Chama com segurança o método de filtragem do controller unificado
    final minhasEntregas = dashboardCtrl.filtrarPorRegiao(widget.regiaoDesignada);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xff0F172A),
        foregroundColor: Colors.white,
        title: Text("SmartLog - Motorista (${widget.regiaoDesignada})"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authCtrl.realizarLogout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Área do Mapa Integrado
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
                        Icon(Icons.map, size: 64, color: Color(0xff0F172A)),
                        SizedBox(height: 8),
                        Text(
                          "Google Maps integrado em tempo real",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Exibindo rota otimizada pela IA",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _rotaIniciada ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _rotaIniciada ? "EM ROTA" : "AGUARDANDO INÍCIO",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Painel Inferior de Paradas
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _rotaIniciada = !_rotaIniciada;
                        });
                      },
                      icon: Icon(_rotaIniciada ? Icons.stop : Icons.play_arrow),
                      label: Text(
                        _rotaIniciada ? "CONCLUIR PERCURSO" : "INICIAR ROTA DESIGNADA",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _rotaIniciada ? Colors.red : const Color(0xff0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Minhas Entregas (${minhasEntregas.length} paradas)",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff0F172A)),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: minhasEntregas.isEmpty
                        ? const Center(child: Text("Nenhuma entrega pendente para sua região."))
                        : ListView.builder(
                      itemCount: minhasEntregas.length,
                      itemBuilder: (context, index) {
                        final entrega = minhasEntregas[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xff0F172A).withOpacity(0.1),
                              child: Text(
                                "${index + 1}º",
                                style: const TextStyle(color: Color(0xff0F172A), fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              entrega['cliente']?.toString() ?? 'Cliente Oculto',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text("Status: ${entrega['status']?.toString() ?? 'Pendente'}"),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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