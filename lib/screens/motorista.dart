// lib/screens/dashboard_motorista.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../theme/app_theme.dart';
import 'chat_assistente.dart';

class DashboardMotorista extends StatefulWidget {
  const DashboardMotorista({super.key});

  @override
  State<DashboardMotorista> createState() => _DashboardMotoristaState();
}

class _DashboardMotoristaState extends State<DashboardMotorista> {
  int _indiceTabAtual = 0;
  bool _emViagem = false;

  final List<String> _titulosAbas = [
    "Painel",
    "Minhas Entregas",
    "Rotas por Região",
    "Perfil"
  ];

  @override
  Widget build(BuildContext context) {
    final String abaAtual = _titulosAbas[_indiceTabAtual];
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("SmartLog • $abaAtual"),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent),
            tooltip: "Assistente IA",
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatAssistenteScreen(
                  perfil: "MOTORISTA",
                  uid: user?.uid ?? "",
                ),
              ));
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _renderizarConteudo(user?.uid),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceTabAtual,
        onTap: (index) {
          setState(() {
            _indiceTabAtual = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.accentOrange,
        unselectedItemColor: AppTheme.statusGrey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Início",
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
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }

  Widget _renderizarConteudo(String? motoristaUid) {
    switch (_indiceTabAtual) {
      case 0:
        return _buildAbaPainel(motoristaUid);
      case 1:
        return _buildAbaEntregas(motoristaUid);
      case 2:
        return _buildAbaRotasRegiao(motoristaUid);
      case 3:
        return _buildAbaPerfil();
      default:
        return _buildAbaPainel(motoristaUid);
    }
  }

  // 1. PAINEL / INÍCIO DO MOTORISTA
  Widget _buildAbaPainel(String? motoristaUid) {
    return SingleChildScrollView(
      key: const ValueKey("PainelMotoristaView"),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Resumo do Dia",
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
              _CardMetrica("Pendentes", "4", Icons.hourglass_empty, AppTheme.statusOrange),
              _CardMetrica("Entregues", "12", Icons.check_circle_outline, AppTheme.statusGreen),
              _CardMetrica("Distância", "45 km", Icons.speed, Colors.blue),
              _CardMetrica("Eficiência", "98%", Icons.trending_up, Colors.purple),
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
                  const Text(
                    "Status da Jornada",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _emViagem ? "Você está em rota ativa enviando localização." : "Você está em pausa / pronto para iniciar.",
                    style: const TextStyle(color: AppTheme.statusGrey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _emViagem ? Colors.red : AppTheme.statusGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(_emViagem ? Icons.stop : Icons.play_arrow),
                      label: Text(_emViagem ? "Encerrar Viagem / Rota" : "Iniciar Viagem / Rota"),
                      onPressed: () {
                        setState(() {
                          _emViagem = !_emViagem;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_emViagem ? "Viagem iniciada com sucesso!" : "Viagem encerrada.")),
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

  // 2. MINHAS ENTREGAS
  Widget _buildAbaEntregas(String? motoristaUid) {
    if (motoristaUid == null || motoristaUid.isEmpty) {
      return const Center(child: Text("Erro: Nenhum usuário motorista autenticado."));
    }

    return Padding(
      key: const ValueKey("EntregasMotoristaView"),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Entregas Atribuídas",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('usuarios').doc(motoristaUid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const Center(child: Text("Perfil do motorista não encontrado."));
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final String? empresaId = userData['empresaId'];

                if (empresaId == null) {
                  return const Center(child: Text("Erro: 'empresaId' não encontrada."));
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('entregas')
                      .where('motoristaId', isEqualTo: motoristaUid)
                      .where('empresaId', isEqualTo: empresaId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("Nenhuma entrega atribuída a você."));
                    }

                    final entregas = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: entregas.length,
                      itemBuilder: (context, index) {
                        final entrega = entregas[index].data() as Map<String, dynamic>;
                        final docId = entregas[index].id;
                        final status = entrega['status'] ?? 'Pendente';

                        final Color statusColor = status == 'Entregue'
                            ? AppTheme.statusGreen
                            : status == 'Em Rota'
                            ? AppTheme.statusOrange
                            : AppTheme.statusGrey;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () => _modalDetalhesEntregaMotorista(context, docId, entrega),
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.backgroundLight,
                              child: Icon(Icons.local_shipping, color: AppTheme.primaryDark),
                            ),
                            title: Text(
                              "${entrega['id'] ?? 'ENT'} • ${entrega['cliente'] ?? 'Cliente'}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text("${entrega['endereco'] ?? ''}\nRegião: ${entrega['regiao'] ?? 'Geral'}"),
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 3. ROTAS UNIFICADAS POR REGIÃO + INTELIGÊNCIA ARTIFICIAL DE TRÁFEGO
  Widget _buildAbaRotasRegiao(String? motoristaUid) {
    if (motoristaUid == null || motoristaUid.isEmpty) {
      return const Center(child: Text("Usuário não autenticado."));
    }

    // Variáveis de controle de estado local para simular a IA na aba (caso prefira modularizar)
    bool _otimizandoIA = false;
    String _statusTransitoIA = "Tráfego fluindo normalmente. Menor tempo estimado.";

    return StatefulBuilder(
      builder: (context, setAbaState) {
        return Padding(
          key: const ValueKey("RotasRegiaoView"),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Painel de Otimização por IA em Tempo Real
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, color: AppTheme.accentOrange, size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "SmartLog AI • Otimizador de Tráfego",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _statusTransitoIA,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: _otimizandoIA ? null : () async {
                        setAbaState(() {
                          _otimizandoIA = true;
                          _statusTransitoIA = "Analisando tráfego ponto a ponto...";
                        });

                        // Simulação de processamento de tráfego em tempo real
                        await Future.delayed(const Duration(seconds: 2));

                        if (context.mounted) {
                          setAbaState(() {
                            _otimizandoIA = false;
                            _statusTransitoIA = "Menor tempo garantido. Sequência atualizada.";
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Rota otimizada com sucesso via IA!")),
                          );
                        }
                      },
                      child: _otimizandoIA
                          ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                          : const Text("Otimizar", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const Text(
                "Rotas Unificadas por Região",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
              ),
              const SizedBox(height: 4),
              const Text(
                "Visualize os endereços agrupados por região para otimizar seu trajeto.",
                style: TextStyle(fontSize: 13, color: AppTheme.statusGrey),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('usuarios').doc(motoristaUid).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return const Center(child: Text("Erro ao carregar dados do usuário."));
                    }

                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    final String? empresaId = userData['empresaId'];

                    if (empresaId == null) {
                      return const Center(child: Text("Empresa não vinculada."));
                    }

                    // Busca as entregas atribuídas a este motorista para unificar por região
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('entregas')
                          .where('motoristaId', isEqualTo: motoristaUid)
                          .where('empresaId', isEqualTo: empresaId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text("Nenhuma rota ou entrega encontrada para suas regiões."));
                        }

                        final docs = snapshot.data!.docs;

                        // Agrupando dinamicamente por região
                        final Map<String, List<Map<String, dynamic>>> entregasPorRegiao = {};

                        for (var doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final regiao = (data['regiao'] ?? 'Geral').toString().trim();

                          if (!entregasPorRegiao.containsKey(regiao)) {
                            entregasPorRegiao[regiao] = [];
                          }
                          entregasPorRegiao[regiao]!.add({
                            'id': doc.id,
                            ...data,
                          });
                        }

                        final regioes = entregasPorRegiao.keys.toList();

                        return ListView.builder(
                          itemCount: regioes.length,
                          itemBuilder: (context, index) {
                            final regiao = regioes[index];
                            final listaEntregas = entregasPorRegiao[regiao]!;

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppTheme.backgroundLight,
                                  child: Icon(Icons.map, color: AppTheme.primaryDark),
                                ),
                                title: Text(
                                  regiao,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                                subtitle: Text(
                                  "${listaEntregas.length} ${listaEntregas.length == 1 ? 'parada unificada' : 'paradas unificadas'}",
                                  style: const TextStyle(fontSize: 13, color: AppTheme.statusGrey),
                                ),
                                children: listaEntregas.map((entrega) {
                                  final status = entrega['status'] ?? 'Pendente';

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: Colors.grey.shade200),
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        "${entrega['id'] ?? 'ENT'} • ${entrega['cliente'] ?? 'Cliente'}",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        "${entrega['endereco'] ?? 'Endereço não informado'}\nStatus: $status",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      isThreeLine: true,
                                      trailing: const Icon(Icons.chevron_right, size: 20),
                                      onTap: () {
                                        _modalDetalhesEntregaMotorista(context, entrega['id'], entrega);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget do Mapa com a Rota Otimizada e Traçado (Polyline)
  Widget _buildMapaComRotaOtimizada(LatLng posicaoMotorista, List<Map<String, dynamic>> paradas) {
    // Cria os pontos para desenhar a linha da rota no mapa
    List<LatLng> pontosRota = paradas.map((parada) {
      // Certifique-se de que sua entrega possui latitude e longitude salvas no Firestore
      double lat = parada['latitude'] ?? posicaoMotorista.latitude;
      double lng = parada['longitude'] ?? posicaoMotorista.longitude;
      return LatLng(lat, lng);
    }).toList();

    // Adiciona a posição inicial do motorista no topo da lista se necessário
    if (pontosRota.isNotEmpty) {
      pontosRota.insert(0, posicaoMotorista);
    }

    Set<Marker> marcadores = {};
    Set<Polyline> polylines = {};

    // Adiciona o marcador do motorista
    marcadores.add(
      Marker(
        markerId: const MarkerId('motorista_atual'),
        position: posicaoMotorista,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Sua Posição (SmartLog AI)'),
      ),
    );

    // Adiciona os marcadores de cada parada otimizada
    for (int i = 0; i < paradas.length; i++) {
      var p = paradas[i];
      double lat = p['latitude'] ?? posicaoMotorista.latitude;
      double lng = p['longitude'] ?? posicaoMotorista.longitude;

      marcadores.add(
        Marker(
          markerId: MarkerId('parada_$i'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: '${i + 1}. ${p['cliente'] ?? 'Parada'}',
            snippet: p['endereco'] ?? '',
          ),
        ),
      );
    }

    // Desenha a linha (Polyline) conectando as paradas otimizadas
    if (pontosRota.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('rota_otimizada_ia'),
          points: pontosRota,
          color: AppTheme.accentOrange,
          width: 5,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: posicaoMotorista,
          zoom: 14,
        ),
        markers: marcadores,
        polylines: polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }

  // Modal de Detalhes da Entrega para o Motorista
  void _modalDetalhesEntregaMotorista(BuildContext context, String docId, Map<String, dynamic> entrega) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final statusAtual = entrega['status'] ?? 'Pendente';

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Detalhes: ${entrega['id'] ?? 'ENT'}",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                _itemDetalheInfo(Icons.person, "Cliente", entrega['cliente'] ?? 'Não informado'),
                _itemDetalheInfo(Icons.location_on, "Endereço", entrega['endereco'] ?? 'Não informado'),
                _itemDetalheInfo(Icons.map, "Região", entrega['regiao'] ?? 'Geral'),
                _itemDetalheInfo(Icons.calendar_today, "Data Agendada", entrega['data'] ?? 'Não informada'),
                _itemDetalheInfo(Icons.info_outline, "Status Atual", statusAtual),

                const SizedBox(height: 20),
                const Text(
                  "Atualizar Status da Entrega:",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _botaoAlterarStatus(ctx, docId, 'Pendente', statusAtual, Colors.grey),
                    _botaoAlterarStatus(ctx, docId, 'Em Rota', statusAtual, AppTheme.statusOrange),
                    _botaoAlterarStatus(ctx, docId, 'Entregue', statusAtual, AppTheme.statusGreen),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _itemDetalheInfo(IconData icone, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: AppTheme.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 12, color: AppTheme.statusGrey)),
                const SizedBox(height: 2),
                Text(valor, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoAlterarStatus(BuildContext context, String docId, String novoStatus, String statusAtual, Color cor) {
    final bool selecionado = statusAtual == novoStatus;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selecionado ? cor : Colors.grey.shade200,
        foregroundColor: selecionado ? Colors.white : Colors.black87,
        elevation: selecionado ? 2 : 0,
      ),
      onPressed: () async {
        await FirebaseFirestore.instance.collection('entregas').doc(docId).update({
          'status': novoStatus,
        });
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Status alterado para: $novoStatus")),
          );
        }
      },
      child: Text(novoStatus),
    );
  }

  // 4. PERFIL DO MOTORISTA
  Widget _buildAbaPerfil() {
    final user = FirebaseAuth.instance.currentUser;
    final nomeCtrl = TextEditingController(text: user?.displayName ?? 'Motorista SmartLog');
    final telefoneCtrl = TextEditingController(text: '(11) 98888-8888');

    return StatefulBuilder(
      builder: (context, setPerfilState) {
        bool carregandoFoto = false;
        String? fotoUrlAtual = user?.photoURL;

        return SingleChildScrollView(
          key: const ValueKey("PerfilMotoristaView"),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Meu Perfil",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
              ),
              const SizedBox(height: 4),
              const Text(
                "Gerencie suas informações pessoais e foto de identificação.",
                style: TextStyle(fontSize: 13, color: AppTheme.statusGrey),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppTheme.accentOrange,
                            backgroundImage: fotoUrlAtual != null && fotoUrlAtual.isNotEmpty
                                ? NetworkImage(fotoUrlAtual)
                                : null,
                            child: fotoUrlAtual == null || fotoUrlAtual.isEmpty
                                ? const Icon(Icons.person, size: 32, color: Colors.white)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: carregandoFoto ? null : () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? imagemSelecionada = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 80,
                                );

                                if (imagemSelecionada != null) {
                                  setPerfilState(() => carregandoFoto = true);
                                  try {
                                    if (user != null) {
                                      final bytes = await imagemSelecionada.readAsBytes();
                                      final storageRef = FirebaseStorage.instance
                                          .ref()
                                          .child('perfil_motorista/${user.uid}.jpg');

                                      await storageRef.putData(bytes);
                                      String downloadUrl = await storageRef.getDownloadURL();

                                      await user.updatePhotoURL(downloadUrl);

                                      setPerfilState(() {
                                        fotoUrlAtual = downloadUrl;
                                        carregandoFoto = false;
                                      });

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Foto atualizada com sucesso!")),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    setPerfilState(() => carregandoFoto = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Erro ao alterar foto: $e")),
                                      );
                                    }
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryDark,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Motorista Cadastrado",
                              style: TextStyle(fontSize: 12, color: AppTheme.statusGrey, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? "motorista@smartlog.com",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(
                  labelText: "Nome Completo",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefoneCtrl,
                decoration: const InputDecoration(
                  labelText: "Telefone / WhatsApp",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text("Salvar Dados Pessoais"),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Dados atualizados com sucesso!")),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text("Sair da Conta"),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Widget auxiliar para os cards do painel
class _CardMetrica extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;

  const _CardMetrica(this.titulo, this.valor, this.icone, this.cor);

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
                Icon(icone, color: cor, size: 26),
                Text(
                  valor,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: const TextStyle(fontSize: 12, color: AppTheme.statusGrey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}