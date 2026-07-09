// lib/screens/dashboard_admin.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/auth_controller.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  String _abaAtual = "Dashboard";
  String _zonaSelecionada = "TODAS";
  final _formKey = GlobalKey<FormState>();

  // 🔥 Trava de segurança para impedir que a tela busque dados infinitamente e cancele o cadastro
  bool _dadosInicializados = false;

  @override
  Widget build(BuildContext context) {
    final DashboardController? controller = context.watch<DashboardController?>();
    final authController = context.read<AuthController>();

    if (controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 🔄 GATILHO SEGURO: Só busca do Firestore UMA ÚNICA VEZ ao abrir o app
    if (!_dadosInicializados && !controller.carregando) {
      _dadosInicializados = true; // Bloqueia novos gatilhos automáticos
      WidgetsBinding.instance.addPostFrameCallback((_) {
        String? empresaId = authController.empresaIdLogada ?? FirebaseAuth.instance.currentUser?.uid;
        if (empresaId != null) {
          controller.inicializarDados(empresaId);
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xff0F172A),
        foregroundColor: Colors.white,
        title: Text("SmartLog - $_abaAtual"),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xff0F172A)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_shipping, size: 48, color: Colors.orange),
                  SizedBox(height: 12),
                  Text("SmartLog", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text("Painel Administrativo", style: TextStyle(color: Colors.white70))
                ],
              ),
            ),
            _itemMenu(Icons.dashboard, "Dashboard"),
            _itemMenu(Icons.inventory, "Entregas"),
            _itemMenu(Icons.local_shipping, "Motoristas"),
            _itemMenu(Icons.people, "Clientes"),
            _itemMenu(Icons.person, "Perfil"),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _renderizarConteudo(controller),
      ),
    );
  }

  Widget _itemMenu(IconData icon, String titulo) {
    bool selecionado = _abaAtual == titulo;
    return ListTile(
      leading: Icon(icon, color: selecionado ? Colors.orange : Colors.grey),
      title: Text(titulo, style: TextStyle(fontWeight: selecionado ? FontWeight.bold : FontWeight.normal)),
      selected: selecionado,
      onTap: () {
        setState(() {
          _abaAtual = titulo;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _renderizarConteudo(DashboardController controller) {
    switch (_abaAtual) {
      case "Dashboard":
        return _buildDashboardPrincipal(controller);
      case "Entregas":
        return _buildAbaEntregas(controller);
      case "Motoristas":
        return _buildAbaMotoristas(controller);
      case "Clientes":
        return _buildAbaClientes(controller);
      case "Perfil":
        return _buildAbaPerfil();
      default:
        return _buildDashboardPrincipal(controller);
    }
  }

  // 1. DASHBOARD PRINCIPAL CORRIGIDO E EMPILHADO (SEM QUEBRAS VISUAIS)
  Widget _buildDashboardPrincipal(DashboardController controller) {
    final int totalEntregas = controller.totalEntregas;
    final int totalMotoristas = controller.totalMotoristasAtivos;
    final int totalClientes = controller.totalClientesCadastrados;

    // Métricas calculadas dinamicamente
    final int entregues = controller.entregas.where((e) => e['status'] == 'Entregue').length;
    final int aCaminho = controller.entregas.where((e) => e['status'] == 'A Caminho').length;
    final int pendentes = controller.entregas.where((e) => e['status'] == 'Pendente').length;

    return SingleChildScrollView(
      key: const ValueKey("DashboardView"),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              "Visão Geral da Operação",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff0F172A))
          ),
          const SizedBox(height: 16),

          // GRID 1: KPIs Principais do Ecossistema (Ajustado o AspectRatio para caber os números grandes)
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0, // Quadrado perfeito para não espremer texto
            children: [
              _Card("Entregas", "$totalEntregas", Icons.inventory, Colors.blue),
              _Card("Motoristas", "$totalMotoristas", Icons.delivery_dining, Colors.green),
              _Card("Clientes", "$totalClientes", Icons.people, Colors.purple),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
              "Status e Performance da Frota",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff0F172A))
          ),
          const SizedBox(height: 12),

          // ROW 2: Detalhamento Logístico da Memória/Banco
          Row(
            children: [
              Expanded(child: _miniStatusCard("Pendentes", "$pendentes", Colors.orangeAccent)),
              const SizedBox(width: 8),
              Expanded(child: _miniStatusCard("A Caminho", "$aCaminho", Colors.blueAccent)),
              const SizedBox(width: 8),
              Expanded(child: _miniStatusCard("Concluídas", "$entregues", Colors.green)),
            ],
          ),

          const SizedBox(height: 24),

          // 🔥 CORREÇÃO VISUAL: Em vez de Row, empilhamos na vertical para ficar lindo em mobile!
          const Text(
              "Distribuição por Regiões",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff0F172A))
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]
            ),
            child: Column(
              children: [
                _zonaRow("Zona Sul", "${controller.filtrarPorRegiao('Zona Sul').length} rotas", Colors.orange),
                _zonaRow("Zona Norte", "${controller.filtrarPorRegiao('Zona Norte').length} rotas", Colors.blue),
                _zonaRow("Zona Leste", "${controller.filtrarPorRegiao('Zona Leste').length} rotas", Colors.green),
                _zonaRow("Zona Oeste", "${controller.filtrarPorRegiao('Zona Oeste').length} rotas", Colors.red),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
              "Últimos Eventos do Sistema",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff0F172A))
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _logRow("Motorista cadastrado com e-mail enviado.", "Agora mesmo"),
                _logRow("Carga operacional registrada e integrada.", "Há 5 min"),
                _logRow("Admin realizou login corporativo.", "Há 12 min"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widgets Auxiliares de Componentização de Layout Rápido
  Widget _miniStatusCard(String status, String qtd, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: cor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(status, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(qtd, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _zonaRow(String nomeZona, String detalhes, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: cor)),
              const SizedBox(width: 8),
              Text(nomeZona, style: const TextStyle(fontSize: 13)),
            ],
          ),
          Text(detalhes, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _logRow(String texto, String tempo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texto, style: const TextStyle(fontSize: 12, color: Color(0xff334155))),
          Text(tempo, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const Divider(height: 8, thickness: 0.5),
        ],
      ),
    );
  }

  // 2. ABA ENTREGAS
  Widget _buildAbaEntregas(DashboardController controller) {
    return Padding(
      key: const ValueKey("EntregasView"),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["TODAS", "NORTE", "SUL", "LESTE", "OESTE"].map((zona) {
                bool ativo = _zonaSelecionada == zona;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(zona),
                    selected: ativo,
                    selectedColor: Colors.orange,
                    onSelected: (val) => setState(() => _zonaSelecionada = zona),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: Center(child: Text("Nenhuma entrega sincronizada nesta região.")),
          ),
        ],
      ),
    );
  }

  // 3. ABA MOTORISTAS CORRIGIDA
  Widget _buildAbaMotoristas(DashboardController controller) {
    return Padding(
      key: const ValueKey("MotoristasView"),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Equipe de Motoristas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _modalCadastroMotorista(context, controller),
                icon: const Icon(Icons.add),
                label: const Text("Cadastrar"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff0F172A), foregroundColor: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: controller.motoristas.isEmpty
                ? const Center(child: Text("Nenhum motorista listado. Clique em Cadastrar!"))
                : ListView.builder(
              itemCount: controller.motoristas.length,
              itemBuilder: (context, index) {
                final motorista = controller.motoristas[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.person, color: Colors.white)
                    ),
                    title: Text(motorista['nome'] ?? 'Sem Nome'),
                    subtitle: Text(
                        "Responsável pela: ${motorista['regiaoDesignada'] ?? 'Não Definida'}\n"
                            "Status: ${motorista['statusAtivacao'] ?? 'Aguardando Verificação'}"
                    ),
                    trailing: const Icon(Icons.mail_outline, color: Colors.blue),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _modalCadastroMotorista(BuildContext context, DashboardController controller) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String zonaSelecionada = "Sul";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Convidar Novo Motorista", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                    "O motorista receberá um link de ativação via e-mail para cadastrar sua própria senha com segurança.",
                    style: TextStyle(color: Colors.grey, fontSize: 13)
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Nome"),
                  validator: (v) => (v == null || v.isEmpty) ? "Preencha o nome" : null,
                ),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "E-mail"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? "Insira um e-mail válido" : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: zonaSelecionada,
                  decoration: const InputDecoration(
                    labelText: "Região Designada",
                    border: OutlineInputBorder(),
                  ),
                  items: ["Norte", "Sul", "Oeste", "Leste"].map((z) {
                    return DropdownMenuItem<String>(
                      value: z,
                      child: Text(z),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      zonaSelecionada = val;
                    }
                  },
                ),
                const SizedBox(height: 24),
                ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.all(16)),
                          onPressed: controller.carregando
                              ? null
                              : () async {
                            if (_formKey.currentState!.validate()) {
                              final authCtrl = context.read<AuthController>();
                              String empresaIdDoAdmin = authCtrl.empresaIdLogada ??
                                  FirebaseAuth.instance.currentUser?.uid ??
                                  "empresa_padrao";

                              bool sucesso = await controller.cadastrarMotoristaPorConvite(
                                nome: nameCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                regiao: zonaSelecionada,
                                empresaId: empresaIdDoAdmin,
                              );

                              if (sucesso && mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Convite enviado! Verifique o e-mail cadastrado.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Falha ao registrar convite. Verifique se o e-mail já existe.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                          child: controller.carregando
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Enviar Convite por E-mail", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAbaClientes(DashboardController controller) {
    return const Padding(
      key: ValueKey("ClientesView"),
      padding: EdgeInsets.all(16),
      child: Center(child: Text("Nenhum cliente cadastrado.")),
    );
  }

  Widget _buildAbaPerfil() {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "admin@smartlog.com.br";
    return Center(
      key: const ValueKey("PerfilView"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 40, backgroundColor: Color(0xff0F172A), child: Icon(Icons.admin_panel_settings, color: Colors.orange, size: 40)),
          const SizedBox(height: 12),
          const Text("Administrador SmartLog", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(userEmail, style: const TextStyle(color: Colors.grey)),
        ],
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(icon, color: color, size: 28),
            Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(titulo, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}