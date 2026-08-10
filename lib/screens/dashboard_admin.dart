// lib/screens/dashboard_admin.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/dashboard_controller.dart';
import '../theme/app_theme.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  String _abaAtual = "Dashboard";
  String _zonaSelecionada = "TODAS";
  DateTime? _dataSelecionada;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();

    return Scaffold(
      appBar: AppBar(
        title: Text("SmartLog • $_abaAtual"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: AppTheme.primaryDark),
              accountName: Text(
                "Administrador Geral",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text("admin@smartlog.com.br"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppTheme.accentOrange,
                child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
              ),
            ),
            _itemMenu(Icons.dashboard_outlined, Icons.dashboard, "Dashboard"),
            _itemMenu(Icons.local_shipping_outlined, Icons.local_shipping, "Entregas"),
            _itemMenu(Icons.map_outlined, Icons.map, "Rotas"),
            _itemMenu(Icons.badge_outlined, Icons.badge, "Motoristas"),
            _itemMenu(Icons.store_outlined, Icons.store, "Clientes"),
            _itemMenu(Icons.person_outline, Icons.person, "Perfil"),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _renderizarConteudo(controller),
      ),
    );
  }

  Widget _itemMenu(IconData iconInativo, IconData iconAtivo, String titulo) {
    final bool selecionado = _abaAtual == titulo;
    return ListTile(
      leading: Icon(
        selecionado ? iconAtivo : iconInativo,
        color: selecionado ? AppTheme.accentOrange : AppTheme.statusGrey,
      ),
      title: Text(
        titulo,
        style: TextStyle(
          fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
          color: selecionado ? AppTheme.primaryDark : Colors.black87,
        ),
      ),
      selected: selecionado,
      selectedTileColor: AppTheme.accentOrange.withOpacity(0.08),
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
      case "Rotas":
        return _buildAbaRotas(controller);
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

  // 1. DASHBOARD PRINCIPAL (COM COPILOTO IA CORRIGIDO)
  Widget _buildDashboardPrincipal(DashboardController controller) {
    return SingleChildScrollView(
      key: const ValueKey("DashboardView"),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Visão Geral da Operação",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDark,
            ),
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 2. ENTREGAS (COM DATA E REGIÃO)
  Widget _buildAbaEntregas(DashboardController controller) {
    final entregasFiltradas = controller.entregas.where((e) {
      final bool bateRegiao = _zonaSelecionada == "TODAS" ||
          e['regiao'].toString().toLowerCase() == _zonaSelecionada.toLowerCase();

      bool bateData = true;
      if (_dataSelecionada != null) {
        final String dataFormatada =
            "${_dataSelecionada!.year}-${_dataSelecionada!.month.toString().padLeft(2, '0')}-${_dataSelecionada!.day.toString().padLeft(2, '0')}";
        bateData = e['data'] == dataFormatada;
      }

      return bateRegiao && bateData;
    }).toList();

    return Padding(
      key: const ValueKey("EntregasView"),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FILTRO POR DATA
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 20, color: AppTheme.primaryDark),
                      const SizedBox(width: 8),
                      Text(
                        _dataSelecionada == null
                            ? "Todas as Datas"
                            : "Data: ${_dataSelecionada!.day.toString().padLeft(2, '0')}/${_dataSelecionada!.month.toString().padLeft(2, '0')}/${_dataSelecionada!.year}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (_dataSelecionada != null)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => _dataSelecionada = null),
                        ),
                      ElevatedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dataSelecionada ?? DateTime(2026, 7, 25),
                            firstDate: DateTime(2026, 1, 1),
                            lastDate: DateTime(2026, 12, 31),
                          );
                          if (picked != null) {
                            setState(() => _dataSelecionada = picked);
                          }
                        },
                        child: const Text("Filtrar Data"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),

          // FILTRO POR REGIÃO (CHIPS)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["TODAS", "Norte", "Sul", "Leste", "Oeste"].map((zona) {
                final isSelected = _zonaSelecionada == zona;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(zona),
                    selected: isSelected,
                    selectedColor: AppTheme.accentOrange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.primaryDark,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _zonaSelecionada = zona);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            "Exibindo ${entregasFiltradas.length} entregas",
            style: const TextStyle(color: AppTheme.statusGrey, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: entregasFiltradas.isEmpty
                ? const Center(child: Text("Nenhuma entrega encontrada."))
                : ListView.builder(
              itemCount: entregasFiltradas.length,
              itemBuilder: (context, index) {
                final entrega = entregasFiltradas[index];
                final status = entrega['status'];

                final Color statusColor = status == 'Entregue'
                    ? AppTheme.statusGreen
                    : status == 'Em Rota'
                    ? AppTheme.statusOrange
                    : AppTheme.statusGrey;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.backgroundLight,
                      child: Icon(Icons.local_shipping, color: AppTheme.primaryDark),
                    ),
                    title: Text(
                      "${entrega['id']} • ${entrega['cliente']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${entrega['endereco']}\nRegião: ${entrega['regiao']} | Data: ${entrega['data']}"),
                    isThreeLine: true,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
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

  // 3. ROTAS
  Widget _buildAbaRotas(DashboardController controller) {
    return Padding(
      key: const ValueKey("RotasView"),
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
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
              title: Text(rota['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Motorista: ${rota['motorista']}\nVeículo: ${rota['veiculo']}"),
              trailing: Chip(
                label: Text(rota['status'], style: const TextStyle(fontSize: 11, color: AppTheme.primaryDark)),
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
            child: ListView.builder(
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
                    title: Text(m['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${m['email']} • Região: ${m['regiao']}"),
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
                      initialValue: zonaSelecionadaModal,
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

  // 5. CLIENTES
  Widget _buildAbaClientes(DashboardController controller) {
    return Padding(
      key: const ValueKey("ClientesView"),
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: controller.clientes.length,
        itemBuilder: (context, index) {
          final cliente = controller.clientes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.backgroundLight,
                child: Icon(Icons.store, color: AppTheme.primaryDark),
              ),
              title: Text(cliente['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Tipo: ${cliente['tipo']} | Cidade: ${cliente['cidade']}"),
            ),
          );
        },
      ),
    );
  }

  // 6. PERFIL
  Widget _buildAbaPerfil() {
    return const Center(
      key: ValueKey("PerfilView"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: AppTheme.primaryDark,
            child: Icon(Icons.admin_panel_settings, color: AppTheme.accentOrange, size: 45),
          ),
          SizedBox(height: 12),
          Text(
            "Administrador SmartLog",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
          ),
          Text("admin@smartlog.com.br", style: TextStyle(color: AppTheme.statusGrey)),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(icon, color: color, size: 28),
            Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
            Text(titulo, style: const TextStyle(color: AppTheme.statusGrey, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}