// Salve em: lib/screens/dashboard_admin.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importante para conectar com o Controller
import '../controllers/dashboard_controller.dart';

class DashboardAdmin extends StatelessWidget {
  const DashboardAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    // Escutando o controller de dados logísticos
    final controller = context.watch<DashboardController>();

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xff0F172A),
        foregroundColor: Colors.white,
        title: const Text("SmartLog - Administrador"),
      ),
      drawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Color(0xff0F172A)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_shipping, size: 48, color: Colors.orange),
                  SizedBox(height: 12),
                  Text("SmartLog",
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text("Painel Administrativo",
                      style: TextStyle(color: Colors.white70))
                ],
              ),
            ),
            ListTile(leading: Icon(Icons.dashboard), title: Text("Dashboard")),
            ListTile(leading: Icon(Icons.inventory), title: Text("Entregas")),
            ListTile(leading: Icon(Icons.local_shipping), title: Text("motoristas")),
            ListTile(leading: Icon(Icons.people), title: Text("Clientes")),
            ListTile(leading: Icon(Icons.route), title: Text("Rotas")),
            ListTile(leading: Icon(Icons.person), title: Text("Perfil")),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dashboard",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // GRID DE CARDS COM DADOS RENDERIZADOS DO CONTROLLER
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4, // Ajustado ligeiramente para evitar quebra de texto
              children: [
                _Card("Entregas Totais", "${controller.totalEntregas} (SP)", Icons.inventory, Colors.orange),
                _Card("Entregas Concluídas", "${controller.entregasConcluidas}", Icons.check_circle, Colors.green),
                _Card("Motoristas por Região", "${controller.totalMotoristasAtivos} Ativos", Icons.local_shipping, Colors.blue),
                _Card("Regiões Atendidas", "4 Zonas", Icons.map, Colors.purple),
              ],
            ),

            const SizedBox(height: 25),

            // GOOGLE MAPS PLACEHOLDER
            Card(
              child: SizedBox(
                height: 220,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.map, size: 70, color: Colors.orange),
                      SizedBox(height: 10),
                      Text("Google Maps — Hub SP",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text("Mostrando rotas completas das 4 regiões")
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Status dos Motoristas e Regiões",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // LISTA DINÂMICA BASEADA NAS 4 REGIÕES DO SEU CENÁRIO
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.motoristas.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  // Certifique-se de que está exatamente em minúsculo: 'motorista'
                  final motorista = controller.motoristas[index];

                  // Definindo uma cor lógica para o status de cada um
                  Color statusColor = Colors.orange;
                  if (motorista['status'] == 'Concluído') statusColor = Colors.green;
                  if (motorista['status'] == 'Aguardando IA') statusColor = Colors.grey;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withAlpha(40),
                      child: Icon(Icons.person, color: statusColor),
                    ),
                    title: Text("${motorista['nome']} (${motorista['regiao']})"),
                    subtitle: Text("Status da rota: ${motorista['status']}"),
                    trailing: Text(
                      "Progresso: ${(motorista['progresso'] * 100).toInt()}%",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "AI Logistics (Insights de SP)",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Card(
              color: const Color(0xffEEF6FF),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.psychology, color: Colors.blue),
                      title: Text("Melhor sequência gerada"),
                      subtitle: Text("20 entregas clusterizadas e ordenadas em 4 rotas de menor tempo."),
                    ),
                    ListTile(
                      leading: Icon(Icons.access_time, color: Colors.orange),
                      title: Text("Previsão de Atraso na Zona Sul"),
                      subtitle: Text("Trânsito pesado na Av. Interlagos afetando a 3ª entrega do Carlos."),
                    ),
                    ListTile(
                      leading: Icon(Icons.traffic, color: Colors.red),
                      title: Text("Alerta de Tráfego em SP"),
                      subtitle: Text("Marginal Pinheiros com lentidão. Motoristas instruídos a desviar."),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icon;
  final Color color;

  const _Card(this.titulo, this.valor, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(icon, color: color, size: 32),
            Text(valor,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}