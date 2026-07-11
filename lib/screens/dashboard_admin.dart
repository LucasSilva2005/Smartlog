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
  final _rotaFormKey = GlobalKey<FormState>();

  // 🔥 Trava de segurança para impedir que a tela busque dados infinitamente
  bool _dadosInicializados = false;

  // 📝 Estado de Navegação Interno para Roteirização Anti-Overflow
  bool _criandoNovaRotaView = false;

  // 📝 Estado Dual e Controllers para Edição Dinâmica do Perfil ERP
  bool _editandoPerfil = false;
  final _nomeAdminCtrl = TextEditingController();
  final _funcaoCtrl = TextEditingController();
  final _nomeEmpresaCtrl = TextEditingController();
  final _razaoSocialCtrl = TextEditingController();
  final _nomeFantasiaCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _siteCtrl = TextEditingController();

  // Controllers locais para a criação de rotas
  final _clienteRotaCtrl = TextEditingController();
  final List<TextEditingController> _enderecoRotaCtrls = List.generate(5, (_) => TextEditingController());
  String _regiaoRotaSelecionada = "Zona Norte";
  Map<String, dynamic>? _motoristaRotaSelecionado;

  @override
  void dispose() {
    _nomeAdminCtrl.dispose();
    _funcaoCtrl.dispose();
    _nomeEmpresaCtrl.dispose();
    _razaoSocialCtrl.dispose();
    _nomeFantasiaCtrl.dispose();
    _cnpjCtrl.dispose();
    _enderecoCtrl.dispose();
    _telefoneCtrl.dispose();
    _siteCtrl.dispose();

    _clienteRotaCtrl.dispose();
    for (var ctrl in _enderecoRotaCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

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
            _itemMenu(Icons.map, "Rotas"),
            _itemMenu(Icons.person, "Perfil"),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _renderizarConteudo(controller, authController),
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
          // Reseta o estado interno de criação ao trocar de abas principais
          if (titulo != "Rotas") _criandoNovaRotaView = false;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _renderizarConteudo(DashboardController controller, AuthController authController) {
    switch (_abaAtual) {
      case "Dashboard":
        return _buildDashboardPrincipal(controller);
      case "Entregas":
        return _buildAbaEntregas(controller);
      case "Motoristas":
        return _buildAbaMotoristas(controller);
      case "Clientes":
        return _buildAbaClientes(controller);
      case "Rotas":
        return _buildAbaRotas(controller, authController);
      case "Perfil":
        return _buildAbaPerfil(controller, authController);
      default:
        return _buildDashboardPrincipal(controller);
    }
  }

  // 1. DASHBOARD PRINCIPAL
  Widget _buildDashboardPrincipal(DashboardController controller) {
    final int totalEntregas = controller.totalEntregas;
    final int totalMotoristas = controller.totalMotoristasAtivos;
    final int totalClientes = controller.totalClientesCadastrados;

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

          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
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
                _zonaRow("Zona Sul", "${controller.entregas.where((e) => e['regiao'] == 'Zona Sul').length} rotas", Colors.orange),
                _zonaRow("Zona Norte", "${controller.entregas.where((e) => e['regiao'] == 'Zona Norte').length} rotas", Colors.blue),
                _zonaRow("Zona Leste", "${controller.entregas.where((e) => e['regiao'] == 'Zona Leste').length} rotas", Colors.green),
                _zonaRow("Zona Oeste", "${controller.entregas.where((e) => e['regiao'] == 'Zona Oeste').length} rotas", Colors.red),
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

  // 3. ABA MOTORISTAS
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
    final senhaCtrl = TextEditingController();
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
                    "Defina as credenciais corporativas do motorista parceiro. Ele utilizará esses dados para acessar as rotas.",
                    style: TextStyle(color: Colors.grey, fontSize: 13)
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Nome", border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? "Preencha o nome" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "E-mail", border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? "Insira um e-mail válido" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: senhaCtrl,
                  decoration: const InputDecoration(labelText: "Senha Inicial Operacional", border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6) ? "A senha deve ter pelo menos 6 caracteres" : null,
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
                                senha: senhaCtrl.text.trim(),
                                empresaId: empresaIdDoAdmin,
                              );

                              if (sucesso && mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Motorista cadastrado e ativo com sucesso!'),
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

  // 4. ABA CLIENTES OPERACIONAL (DADOS REAIS + ESTEIRA DE CONVITES)
  Widget _buildAbaClientes(DashboardController controller) {
    return Padding(
      key: const ValueKey("ClientesView"),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Clientes Cadastrados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff0F172A))),
              ElevatedButton.icon(
                onPressed: () => _modalCadastroCliente(context, controller),
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: const Text("Convidar Cliente"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff0F172A), foregroundColor: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: controller.clientes.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text("Nenhum cliente listado.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  Text("Clique em Convidar Cliente para iniciar.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
                : ListView.builder(
              itemCount: controller.clientes.length,
              itemBuilder: (context, index) {
                final cliente = controller.clientes[index];
                return Card(
                  color: Colors.white,
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: Icon(Icons.business, color: Colors.white, size: 20)
                    ),
                    title: Text(cliente['nome'] ?? 'Sem Nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("E-mail: ${cliente['email'] ?? 'Sem e-mail'}\nStatus: ${cliente['statusAtivacao'] ?? 'Aguardando Verificação'}"),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (cliente['statusAtivacao'] == 'Ativo') ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        cliente['statusAtivacao'] == 'Ativo' ? "Ativo" : "Pendente",
                        style: TextStyle(
                            color: (cliente['statusAtivacao'] == 'Ativo') ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 11
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // MODAL INJETOR DE CONVITES PARA CLIENTES
  void _modalCadastroCliente(BuildContext context, DashboardController controller) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final senhaCtrl = TextEditingController();
    final _clienteFormKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
        child: SingleChildScrollView(
          child: Form(
            key: _clienteFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Convidar Novo Cliente", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff0F172A))),
                const SizedBox(height: 8),
                const Text(
                    "O cliente corporativo receberá um e-mail de verificação oficial para ativar seu login no painel SmartLog.",
                    style: TextStyle(color: Colors.grey, fontSize: 13)
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Nome / Razão Social do Cliente", border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? "Preencha o nome do cliente" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "E-mail Corporativo do Cliente", border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? "Insira um e-mail válido" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: senhaCtrl,
                  decoration: const InputDecoration(labelText: "Senha Inicial do Cliente", border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6) ? "A senha precisa ter pelo menos 6 caracteres" : null,
                ),
                const SizedBox(height: 24),
                ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff0F172A), padding: const EdgeInsets.all(16)),
                          onPressed: controller.carregando
                              ? null
                              : () async {
                            if (_clienteFormKey.currentState!.validate()) {
                              final authCtrl = context.read<AuthController>();
                              String empresaIdDoAdmin = authCtrl.empresaIdLogada ??
                                  FirebaseAuth.instance.currentUser?.uid ??
                                  "empresa_padrao";

                              bool sucesso = await controller.cadastrarClientePorConvite(
                                nome: nameCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                senha: senhaCtrl.text.trim(),
                                empresaId: empresaIdDoAdmin,
                              );

                              if (sucesso && mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Convite enviado! O cliente recebeu o e-mail de verificação.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Falha ao enviar convite. Verifique se o e-mail já está cadastrado.'),
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

  // 🗺️ ABA DE ROTAS AVANÇADA (CADASTRO EM LOTE MULTI-ENDEREÇOS REAL)
  Widget _buildAbaRotas(DashboardController controller, AuthController authController) {
    if (_criandoNovaRotaView) {
      return _buildFormularioCriarRotaCheia(controller, authController);
    }

    return Padding(
      key: const ValueKey("RotasView"),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Rotas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff0F172A))),
                  SizedBox(height: 4),
                  Text("Entregas otimizadas por região", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _criandoNovaRotaView = true;
                  });
                },
                icon: const Icon(Icons.add_road, size: 16),
                label: const Text("Criar Nova Rota"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0F172A),
                    foregroundColor: Colors.white
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: controller.entregas.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text("Nenhuma rota ou entrega ativa no sistema.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
            )
                : ListView.builder(
              itemCount: controller.entregas.length,
              itemBuilder: (context, index) {
                final entrega = controller.entregas[index];
                return Card(
                  color: Colors.white,
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.15),
                      child: Text("#${entrega['ordemEntrega'] ?? '1'}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(entrega['endereco'] ?? 'Endereço não informado', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Cliente: ${entrega['cliente'] ?? 'Geral'} • Motorista: ${entrega['motorista']}"),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xff0F172A), borderRadius: BorderRadius.circular(8)),
                      child: Text(entrega['regiao'] ?? 'Zona Norte', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // 📝 FORMULÁRIO EM TELA CHEIA 100% ANTI-OVERFLOW (CORRIGIDO SEM LISTVIEW INTERNO)
  Widget _buildFormularioCriarRotaCheia(DashboardController controller, AuthController authController) {
    return Scaffold(
      key: const ValueKey("FormRotaScaffold"),
      backgroundColor: const Color(0xffF5F7FA),
      resizeToAvoidBottomInset: true, // Crucial para o Scaffold se ajustar ao teclado
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff0F172A),
        elevation: 0,
        title: const Text("Nova Rota Operacional", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _criandoNovaRotaView = false;
            });
          },
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // Fecha o teclado ao tocar fora
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 40),
            child: Form(
              key: _rotaFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Dados da Operação", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _clienteRotaCtrl,
                    decoration: const InputDecoration(labelText: "Nome do Cliente / Contrato Solicitante", border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                    validator: (v) => (v == null || v.isEmpty) ? "Informe o cliente corporativo" : null,
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _regiaoRotaSelecionada,
                    decoration: const InputDecoration(labelText: "Região de Entrega", border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                    items: ["Zona Norte", "Zona Sul", "Zona Leste", "Zona Oeste"].map((z) {
                      return DropdownMenuItem(value: z, child: Text(z));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _regiaoRotaSelecionada = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _motoristaRotaSelecionado,
                    decoration: const InputDecoration(labelText: "Selecionar Motorista Responsável", border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                    hint: const Text("Selecione um motorista parceiro"),
                    items: controller.motoristas.map((m) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: m,
                        child: Text("${m['nome']} (${m['regiaoDesignada'] ?? 'Livre'})"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _motoristaRotaSelecionado = val;
                      });
                    },
                    validator: (v) => v == null ? "É obrigatório delegar um motorista" : null,
                  ),

                  const SizedBox(height: 24),
                  const Text("Paradas Sequenciadas (Lote)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),

                  // 🔥 CORREÇÃO VISUAL: Injetando os campos direto na Column via spread operator (...), eliminando o ListView.builder
                  ...List.generate(5, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: TextFormField(
                        controller: _enderecoRotaCtrls[index],
                        decoration: InputDecoration(
                            labelText: "Parada #${index + 1} - Endereço completo",
                            prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Colors.orange),
                            border: const OutlineInputBorder(),
                            fillColor: Colors.white,
                            filled: true
                        ),
                        validator: (index == 0)
                            ? (v) => (v == null || v.isEmpty) ? "A primeira parada é obrigatória" : null
                            : null,
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.all(16)),
                        onPressed: controller.carregando
                            ? null
                            : () async {
                          if (_rotaFormKey.currentState!.validate() && _motoristaRotaSelecionado != null) {
                            final List<String> listaEnderecos = _enderecoRotaCtrls.map((c) => c.text.trim()).toList();
                            final String empresaIdAdmin = authController.empresaIdLogada ?? FirebaseAuth.instance.currentUser?.uid ?? "";

                            bool ok = await controller.criarRotaComEntregas(
                              enderecos: listaEnderecos,
                              clienteNome: _clienteRotaCtrl.text.trim(),
                              regiao: _regiaoRotaSelecionada,
                              motoristaSelecionado: _motoristaRotaSelecionado!,
                              empresaId: empresaIdAdmin,
                            );

                            if (ok && mounted) {
                              setState(() {
                                _criandoNovaRotaView = false;
                                _clienteRotaCtrl.clear();
                                for (var ctrl in _enderecoRotaCtrls) {
                                  ctrl.clear();
                                }
                                _motoristaRotaSelecionado = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Rota e entregas geradas em lote com sucesso!"), backgroundColor: Colors.green),
                              );
                            }
                          }
                        },
                        child: controller.carregando
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Salvar e Atribuir Rota", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 5. ABA PERFIL DO ADMINISTRADOR DINÂMICA (SEM DADOS MOCKADOS)
  Widget _buildAbaPerfil(DashboardController controller, AuthController authController) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "";
    final empresaId = authController.empresaIdLogada ?? FirebaseAuth.instance.currentUser?.uid ?? "";

    // Sincroniza os controllers locais apenas quando NÃO estamos ativamente digitando/editando
    if (!_editandoPerfil) {
      _nomeAdminCtrl.text = controller.dadosEmpresa['nomeAdmin'] ?? "";
      _funcaoCtrl.text = controller.dadosEmpresa['funcaoAdmin'] ?? "";
      _nomeEmpresaCtrl.text = controller.dadosEmpresa['nomeEmpresa'] ?? "";
      _razaoSocialCtrl.text = controller.dadosEmpresa['razaoSocial'] ?? "";
      _nomeFantasiaCtrl.text = controller.dadosEmpresa['nomeFantasia'] ?? "";
      _cnpjCtrl.text = controller.dadosEmpresa['cnpj'] ?? "";
      _enderecoCtrl.text = controller.dadosEmpresa['endereco'] ?? "";
      _telefoneCtrl.text = controller.dadosEmpresa['telefone'] ?? "";
      _siteCtrl.text = controller.dadosEmpresa['site'] ?? "";
    }

    return SingleChildScrollView(
      key: const ValueKey("PerfilView"),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BARRA DE AÇÃO SUPERIOR: ALTERNAR ESTADO MODO LEITURA / MODO EDIÇÃO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _secaoPerfilTitulo(_editandoPerfil ? "Editando Configurações ERP" : "Perfil do Administrador", Icons.admin_panel_settings),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _editandoPerfil ? Colors.green : const Color(0xff0F172A),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (_editandoPerfil) {
                    Map<String, dynamic> mapaDados = {
                      'nomeAdmin': _nomeAdminCtrl.text.trim(),
                      'funcaoAdmin': _funcaoCtrl.text.trim(),
                      'nomeEmpresa': _nomeEmpresaCtrl.text.trim(),
                      'razaoSocial': _razaoSocialCtrl.text.trim(),
                      'nomeFantasia': _nomeFantasiaCtrl.text.trim(),
                      'cnpj': _cnpjCtrl.text.trim(),
                      'endereco': _enderecoCtrl.text.trim(),
                      'telefone': _telefoneCtrl.text.trim(),
                      'site': _siteCtrl.text.trim(),
                    };

                    bool sucesso = await controller.atualizarPerfilEmpresa(empresaId: empresaId, novosDados: mapaDados);
                    if (sucesso && mounted) {
                      setState(() => _editandoPerfil = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Perfil corporativo updated com sucesso!"), backgroundColor: Colors.green),
                      );
                    }
                  } else {
                    setState(() => _editandoPerfil = true);
                  }
                },
                icon: Icon(_editandoPerfil ? Icons.save : Icons.edit, size: 16),
                label: Text(_editandoPerfil ? "Salvar" : "Editar Dados"),
              )
            ],
          ),
          const SizedBox(height: 12),

          // HEADER PRINCIPAL DO ADMIN
          Card(
            color: const Color(0xff0F172A),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _renderCampoOuTexto(
                          isEditing: _editandoPerfil,
                          controller: _nomeAdminCtrl,
                          placeholder: "Nome do Admin",
                          estiloTexto: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        _renderCampoOuTexto(
                          isEditing: _editandoPerfil,
                          controller: _funcaoCtrl,
                          placeholder: "Função Administrativa",
                          estiloTexto: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(userEmail, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                            const SizedBox(width: 6),
                            Text("Online • Desde ${controller.dadosEmpresa['onlineDesde'] ?? '2026'}", style: const TextStyle(color: Colors.green, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // INFORMAÇÕES DA EMPRESA
          _secaoPerfilTitulo("Informações da Empresa", Icons.business),
          Card(
            elevation: 1,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _perfilInfoRowDinamico("Nome da Empresa", _nomeEmpresaCtrl, _editandoPerfil),
                  _perfilInfoRowDinamico("Razão Social", _razaoSocialCtrl, _editandoPerfil),
                  _perfilInfoRowDinamico("Nome Fantasia", _nomeFantasiaCtrl, _editandoPerfil),
                  _perfilInfoRowDinamico("CNPJ", _cnpjCtrl, _editandoPerfil),
                  _perfilInfoRowDinamico("Endereço", _enderecoCtrl, _editandoPerfil),
                  _perfilInfoRowDinamico("Telefone", _telefoneCtrl, _editandoPerfil),
                  _perfilInfoRowDinamico("Site", _siteCtrl, _editandoPerfil),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statusMiniFicha("Funcionários", "${controller.dadosEmpresa['qtdFuncionarios'] ?? '0'}", Icons.badge_outlined),
                      _statusMiniFicha("Motoristas", "${controller.totalMotoristasAtivos}", Icons.delivery_dining),
                      _statusMiniFicha("Veículos", "${controller.dadosEmpresa['qtdVeiculos'] ?? '0'}", Icons.local_shipping_outlined),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ESTATÍSTICAS RÁPIDAS
          _secaoPerfilTitulo("Estatísticas Rápidas de Operação", Icons.analytics_outlined),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _kpiPerfilCard("Total Entregas", "${controller.totalEntregas}", Colors.blue),
              _kpiPerfilCard("Concluídas", "${controller.entregas.where((e) => e['status'] == 'Entregue').length}", Colors.green),
              _kpiPerfilCard("Em Andamento", "${controller.entregas.where((e) => e['status'] == 'A Caminho').length}", Colors.orange),
              _kpiPerfilCard("Atrasadas", "${controller.entregas.where((e) => e['status'] == 'Atrasada').length}", Colors.red),
              _kpiPerfilCard("Clientes Parceiros", "${controller.totalClientesCadastrados}", Colors.purple),
              _kpiPerfilCard("Média Tempo", controller.totalEntregas == 0 ? "--" : "Calcular...", Colors.teal),
              _kpiPerfilCard("Taxa de Sucesso", controller.totalEntregas == 0 ? "0%" : "Calcular...", Colors.indigo),
            ],
          ),
          const SizedBox(height: 16),

          // PLANO CONTRATADO
          _secaoPerfilTitulo("Plano Corporativo", Icons.card_membership),
          Card(
            elevation: 1,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Plano Atual: ${controller.dadosEmpresa['planoAtual'] ?? 'Trial Gratuito'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Text("Ativo", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 12),
                  _perfilInfoRow("Renovação", controller.dadosEmpresa['planoVencimento'] ?? "30 dias"),
                  _perfilInfoRow("Limite de Usuários", "1 / 5"),
                  _perfilInfoRow("Limite de Motoristas", "${controller.totalMotoristasAtivos} / 10"),
                  _perfilInfoRow("Espaço em Nuvem utilizado", "0.1 GB / 5 GB"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // WIDGET COUPLER
  Widget _renderCampoOuTexto({required bool isEditing, required TextEditingController controller, required String placeholder, required TextStyle estiloTexto}) {
    if (isEditing) {
      return TextFormField(
        controller: controller,
        style: estiloTexto.copyWith(color: Colors.white),
        decoration: InputDecoration(
          labelText: placeholder,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
        ),
      );
    }
    return Text(controller.text, style: estiloTexto);
  }

  Widget _perfilInfoRowDinamico(String label, TextEditingController controller, bool isEditing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 20),
          Expanded(
            child: isEditing
                ? TextFormField(
              controller: controller,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
            )
                : Text(controller.text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _secaoPerfilTitulo(String titulo, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xff0F172A)),
          const SizedBox(width: 8),
          Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xff0F172A))),
        ],
      ),
    );
  }

  Widget _perfilInfoRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _perfilConfigSwitchRow(String label, bool ativo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        Switch(value: ativo, onChanged: (val) {}, activeColor: Colors.orange),
      ],
    );
  }

  Widget _statusMiniFicha(String t, String v, IconData i) {
    return Column(
      children: [
        Icon(i, color: Colors.grey[700], size: 20),
        const SizedBox(height: 4),
        Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(t, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _kpiPerfilCard(String t, String v, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: cor, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(t, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(v, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _tagPermissao(String text) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xff0F172A))),
      backgroundColor: const Color(0xffF1F5F9),
      side: BorderSide.none,
      padding: const EdgeInsets.all(4),
      visualDensity: VisualDensity.compact,
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