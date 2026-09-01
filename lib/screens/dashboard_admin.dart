// lib/screens/dashboard_admin.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/dashboard_controller.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  String _abaAtual = "Dashboard";
  bool _dadosInicializados = false;

  // Estados e Controllers para a Edição Dinâmica do Perfil do Administrador/Empresa
  bool _editandoPerfil = false;
  final _formPerfilKey = GlobalKey<FormState>();

  final TextEditingController _nomeAdminCtrl = TextEditingController();
  final TextEditingController _funcaoCtrl = TextEditingController();
  final TextEditingController _emailAdminCtrl = TextEditingController();
  final TextEditingController _nomeEmpresaCtrl = TextEditingController();
  final TextEditingController _razaoSocialCtrl = TextEditingController();
  final TextEditingController _nomeFantasiaCtrl = TextEditingController();
  final TextEditingController _cnpjCtrl = TextEditingController();
  final TextEditingController _enderecoCtrl = TextEditingController();
  final TextEditingController _telefoneCtrl = TextEditingController();
  final TextEditingController _siteCtrl = TextEditingController();

  final TextEditingController _promptController = TextEditingController();
  final ChatService _chatService = ChatService();
  String _respostaIA = "";
  bool _carregandoIA = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().carregarEntregas();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dadosInicializados) {
      final controller = context.read<DashboardController>();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        controller.inicializarDados(user.uid);
        controller.escutarDadosEmpresa(user.uid);
      }
      _dadosInicializados = true;
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _nomeAdminCtrl.dispose();
    _funcaoCtrl.dispose();
    _emailAdminCtrl.dispose();
    _nomeEmpresaCtrl.dispose();
    _razaoSocialCtrl.dispose();
    _nomeFantasiaCtrl.dispose();
    _cnpjCtrl.dispose();
    _enderecoCtrl.dispose();
    _telefoneCtrl.dispose();
    _siteCtrl.dispose();
    super.dispose();
  }

  void _preencherControllersPerfil(Map<String, dynamic> dados) {
    _nomeAdminCtrl.text = dados['nomeAdmin'] ?? 'Carlos Henrique';
    _funcaoCtrl.text = dados['funcao'] ?? 'Administrador Geral';
    _emailAdminCtrl.text = dados['email'] ?? FirebaseAuth.instance.currentUser?.email ?? 'admin@smartlog.com.br';
    _nomeEmpresaCtrl.text = dados['nomeEmpresa'] ?? 'SmartLog Online';
    _razaoSocialCtrl.text = dados['razaoSocial'] ?? '';
    _nomeFantasiaCtrl.text = dados['nomeFantasia'] ?? '';
    _cnpjCtrl.text = dados['cnpj'] ?? '';
    _enderecoCtrl.text = dados['endereco'] ?? '';
    _telefoneCtrl.text = dados['telefone'] ?? '';
    _siteCtrl.text = dados['site'] ?? '';
  }

  Future<void> _perguntarIA(DashboardController controller) async {
    final pergunta = _promptController.text.trim();
    if (pergunta.isEmpty) return;

    setState(() {
      _carregandoIA = true;
      _respostaIA = "";
    });

    try {
      final resposta = await _chatService.enviarMensagem(pergunta);
      setState(() {
        _respostaIA = resposta;
      });
    } catch (e) {
      setState(() {
        _respostaIA = "Erro ao consultar assistente: $e";
      });
    } finally {
      setState(() {
        _carregandoIA = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("SmartLog • $_abaAtual"),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Recarregar Entregas",
            onPressed: () => controller.carregarEntregas(),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _renderizarConteudo(controller),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _obterIndexAbaAtual(),
        onTap: (index) {
          setState(() {
            _abaAtual = _obterNomeAbaPorIndex(index);
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.accentOrange,
        unselectedItemColor: AppTheme.statusGrey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: "Entregas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: "Rotas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge_outlined),
            activeIcon: Icon(Icons.badge),
            label: "Motoristas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }

  int _obterIndexAbaAtual() {
    switch (_abaAtual) {
      case "Dashboard": return 0;
      case "Entregas": return 1;
      case "Rotas": return 2;
      case "Motoristas": return 3;
      case "Perfil": return 4;
      default: return 0;
    }
  }

  String _obterNomeAbaPorIndex(int index) {
    switch (index) {
      case 0: return "Dashboard";
      case 1: return "Entregas";
      case 2: return "Rotas";
      case 3: return "Motoristas";
      case 4: return "Perfil";
      default: return "Dashboard";
    }
  }

  Widget _renderizarConteudo(DashboardController controller) {
    switch (_abaAtual) {
      case "Dashboard":
        return _buildDashboardPrincipal(controller);
      case "Entregas":
        return _buildAbaEntregas(controller);
      case "Rotas":
        return _buildAbaRotas(controller);
      case "Motoristas":
        return _buildAbaMotoristas(controller);
      case "Perfil":
        return _buildAbaPerfil(controller);
      default:
        return _buildDashboardPrincipal(controller);
    }
  }

  // 1. DASHBOARD PRINCIPAL
  Widget _buildDashboardPrincipal(DashboardController controller) {
    return SingleChildScrollView(
      key: const ValueKey("DashboardView"),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Visão Geral da Operação",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _Card("Total Entregas", controller.totalEntregas.toString(), Icons.inventory_2_outlined, Colors.blue),
              _Card("Motoristas Ativos", controller.totalMotoristasAtivos.toString(), Icons.delivery_dining_outlined, AppTheme.statusGreen),
              _Card("Clientes Parceiros", controller.totalClientesCadastrados.toString(), Icons.people_outline, Colors.purple),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppTheme.accentOrange, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "Copiloto IA Logístico",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _promptController,
                    decoration: InputDecoration(
                      hintText: "Ex: Como está a distribuição regional da frota?",
                      suffixIcon: IconButton(
                        icon: _carregandoIA
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.send, color: AppTheme.primaryDark),
                        onPressed: _carregandoIA ? null : () => _perguntarIA(controller),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onSubmitted: (_) => _perguntarIA(controller),
                  ),
                  if (_respostaIA.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.statusGrey.withOpacity(0.3)),
                      ),
                      child: Text(
                        _respostaIA,
                        style: const TextStyle(fontSize: 13, color: AppTheme.primaryDark),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. ENTREGAS (Com o único botão centralizado de cadastro simplificado)
  Widget _buildAbaEntregas(DashboardController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      key: const ValueKey("EntregasView"),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Gestão de Entregas",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff0F172A)),
              ),
              ElevatedButton.icon(
                onPressed: () => _modalCadastroEntrega(context, controller),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Nova Entrega"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0F172A),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: controller.entregas.isEmpty
                ? const Center(child: Text("Nenhuma entrega cadastrada."))
                : ListView.builder(
              itemCount: controller.entregas.length,
              itemBuilder: (context, index) {
                final entrega = controller.entregas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(entrega['nome'] ?? 'Cliente', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(entrega['endereco'] ?? ''),
                    trailing: Chip(
                      label: Text(entrega['status'] ?? 'Pendente', style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Modal Único de Cadastro de Entrega Simplificada
  void _modalCadastroEntrega(BuildContext context, DashboardController controller) {
    final nomeCtrl = TextEditingController();
    final enderecoCtrl = TextEditingController();
    final telefoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 24,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Nova Entrega Simplificada",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff0F172A)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nomeCtrl,
                  decoration: const InputDecoration(
                    labelText: "Nome do Destinatário",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: enderecoCtrl,
                  decoration: const InputDecoration(
                    labelText: "Endereço de Entrega",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telefoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Telefone / WhatsApp",
                    hintText: "Ex: 11999998888",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "E-mail do Cliente",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final nome = nomeCtrl.text.trim();
                      final endereco = enderecoCtrl.text.trim();
                      final telefone = telefoneCtrl.text.trim();
                      final email = emailCtrl.text.trim();

                      if (nome.isEmpty || endereco.isEmpty || telefone.isEmpty || email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Preencha todos os campos.")),
                        );
                        return;
                      }

                      final sucesso = await controller.cadastrarEntregaSimplificada(
                        nome: nome,
                        endereco: endereco,
                        telefone: telefone,
                        email: email,
                      );

                      if (ctx.mounted) Navigator.pop(ctx);

                      if (sucesso && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Entrega salva! Link de rastreio gerado para $telefone"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: const Text("Salvar e Gerar Link de Rastreio", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 3. ROTAS
  Widget _buildAbaRotas(DashboardController controller) {
    return Padding(
      key: const ValueKey("RotasView"),
      padding: const EdgeInsets.all(16),
      child: controller.rotas.isEmpty
          ? const Center(child: Text("Nenhuma rota cadastrada."))
          : ListView.builder(
        itemCount: controller.rotas.length,
        itemBuilder: (context, index) {
          final rota = controller.rotas[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.backgroundLight,
                child: Icon(Icons.alt_route, color: AppTheme.accentOrange),
              ),
              title: Text(rota['nome'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Motorista: ${rota['motorista'] ?? 'Não alocado'}\nVeículo: ${rota['veiculo'] ?? 'N/D'}"),
              trailing: Chip(
                label: Text(rota['status'] ?? 'Pendente', style: const TextStyle(fontSize: 11, color: AppTheme.primaryDark)),
                backgroundColor: AppTheme.backgroundLight,
              ),
            ),
          );
        },
      ),
    );
  }

  // 4. MOTORISTAS
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
              const Text(
                "Equipe de Motoristas",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
              ),
              ElevatedButton.icon(
                onPressed: () => _modalCadastroMotorista(context, controller),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Cadastrar"),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: controller.motoristas.isEmpty
                ? const Center(child: Text("Nenhum motorista cadastrado."))
                : ListView.builder(
              itemCount: controller.motoristas.length,
              itemBuilder: (context, index) {
                final m = controller.motoristas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.accentOrange,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(m['nome'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${m['email'] ?? ''} • Região: ${m['regiaoDesignada'] ?? m['regiao'] ?? ''}"),
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
    String zonaSelecionadaModal = "Zona Sul";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
                top: 24,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Cadastrar Novo Motorista",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Nome Completo", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: "E-mail de Acesso", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: zonaSelecionadaModal,
                      decoration: const InputDecoration(labelText: "Região Deslocada", border: OutlineInputBorder()),
                      items: ["Zona Sul", "Zona Norte", "Zona Leste", "Zona Oeste"]
                          .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => zonaSelecionadaModal = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                            await controller.cadastrarNovoMotorista(
                              nome: nameCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              regiao: zonaSelecionadaModal,
                            );
                            if (modalContext.mounted) {
                              Navigator.pop(modalContext);
                            }
                          }
                        },
                        child: const Text("Salvar Registro"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 5. ABA PERFIL DO ADMINISTRADOR E DA EMPRESA
  Widget _buildAbaPerfil(DashboardController controller) {
    final dados = controller.dadosEmpresa;

    if (!_editandoPerfil) {
      _preencherControllersPerfil(dados);
    }

    return SingleChildScrollView(
      key: const ValueKey("PerfilView"),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formPerfilKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Perfil",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_editandoPerfil) {
                      if (_formPerfilKey.currentState!.validate()) {
                        final novosDados = {
                          'nomeAdmin': _nomeAdminCtrl.text.trim(),
                          'funcao': _funcaoCtrl.text.trim(),
                          'email': _emailAdminCtrl.text.trim(),
                          'nomeEmpresa': _nomeEmpresaCtrl.text.trim(),
                          'razaoSocial': _razaoSocialCtrl.text.trim(),
                          'nomeFantasia': _nomeFantasiaCtrl.text.trim(),
                          'cnpj': _cnpjCtrl.text.trim(),
                          'endereco': _enderecoCtrl.text.trim(),
                          'telefone': _telefoneCtrl.text.trim(),
                          'site': _siteCtrl.text.trim(),
                        };

                        final userUid = FirebaseAuth.instance.currentUser?.uid ?? "";
                        final sucesso = await controller.atualizarPerfilEmpresa(
                          empresaId: userUid,
                          novosDados: novosDados,
                        );

                        if (sucesso && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Perfil atualizado com sucesso!")),
                          );
                          setState(() {
                            _editandoPerfil = false;
                          });
                        }
                      }
                    } else {
                      setState(() {
                        _editandoPerfil = true;
                      });
                    }
                  },
                  icon: Icon(_editandoPerfil ? Icons.save : Icons.edit),
                  label: Text(_editandoPerfil ? "Salvar Alterações" : "Editar Dados"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _editandoPerfil ? AppTheme.statusGreen : AppTheme.primaryDark,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cabeçalho do Administrador
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: AppTheme.primaryDark,
                      child: Icon(Icons.admin_panel_settings, color: AppTheme.accentOrange, size: 35),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _editandoPerfil
                              ? TextFormField(
                            controller: _nomeAdminCtrl,
                            decoration: const InputDecoration(labelText: "Nome do Administrador"),
                            validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                          )
                              : Text(
                            dados['nomeAdmin'] ?? "Carlos Henrique",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                          ),
                          const SizedBox(height: 4),
                          _editandoPerfil
                              ? TextFormField(
                            controller: _funcaoCtrl,
                            decoration: const InputDecoration(labelText: "Função / Cargo"),
                          )
                              : Text(
                            dados['funcao'] ?? "Administrador Geral",
                            style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          _editandoPerfil
                              ? TextFormField(
                            controller: _emailAdminCtrl,
                            decoration: const InputDecoration(labelText: "E-mail de Contato"),
                          )
                              : Text(
                            dados['email'] ?? FirebaseAuth.instance.currentUser?.email ?? "admin@smartlog.com.br",
                            style: const TextStyle(color: AppTheme.statusGrey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Informações da Empresa
            const Text(
              "Informações da Empresa",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _editandoPerfil
                        ? TextFormField(
                      controller: _nomeEmpresaCtrl,
                      decoration: const InputDecoration(labelText: "Nome da Empresa"),
                    )
                        : _linhaDetalhePerfil("Nome da Empresa", dados['nomeEmpresa'] ?? "SmartLog Online", Icons.business),
                    const Divider(height: 24),
                    _editandoPerfil
                        ? TextFormField(
                      controller: _razaoSocialCtrl,
                      decoration: const InputDecoration(labelText: "Razão Social"),
                    )
                        : _linhaDetalhePerfil("Razão Social", dados['razaoSocial'] ?? "Não informada", Icons.badge),
                    const Divider(height: 24),
                    _editandoPerfil
                        ? TextFormField(
                      controller: _nomeFantasiaCtrl,
                      decoration: const InputDecoration(labelText: "Nome Fantasia"),
                    )
                        : _linhaDetalhePerfil("Nome Fantasia", dados['nomeFantasia'] ?? "Não informado", Icons.store),
                    const Divider(height: 24),
                    _editandoPerfil
                        ? TextFormField(
                      controller: _cnpjCtrl,
                      decoration: const InputDecoration(labelText: "CNPJ"),
                    )
                        : _linhaDetalhePerfil("CNPJ", dados['cnpj'] ?? "00.000.000/0001-00", Icons.pin),
                    const Divider(height: 24),
                    _editandoPerfil
                        ? TextFormField(
                      controller: _enderecoCtrl,
                      decoration: const InputDecoration(labelText: "Endereço"),
                    )
                        : _linhaDetalhePerfil("Endereço", dados['endereco'] ?? "São Paulo - SP", Icons.location_on),
                    const Divider(height: 24),
                    _editandoPerfil
                        ? TextFormField(
                      controller: _telefoneCtrl,
                      decoration: const InputDecoration(labelText: "Telefone"),
                    )
                        : _linhaDetalhePerfil("Telefone", dados['telefone'] ?? "(11) 99999-9999", Icons.phone),
                    const Divider(height: 24),
                    _editandoPerfil
                        ? TextFormField(
                      controller: _siteCtrl,
                      decoration: const InputDecoration(labelText: "Site"),
                    )
                        : _linhaDetalhePerfil("Site", dados['site'] ?? "www.smartlog.com.br", Icons.language),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _linhaDetalhePerfil(String titulo, String valor, IconData icone) {
    return Row(
      children: [
        Icon(icone, size: 20, color: AppTheme.statusGrey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 12, color: AppTheme.statusGrey)),
              const SizedBox(height: 2),
              Text(valor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;

  const _Card(this.titulo, this.valor, this.icone, this.cor);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icone, color: cor, size: 24),
                Text(
                  valor,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: const TextStyle(fontSize: 12, color: AppTheme.statusGrey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}