# SmartLog — Sumário Executivo do Estado do Projeto

> Documento gerado em **06/08/2026** a partir de uma varredura completa do código na branch `main` (último commit: `f16bc9e — atualizacao 16-07`, de 16/07/2026).
> Objetivo: dar visão exata de **o que existe**, **o que é mock**, **o que está vazio** e **o que falta**, para quem precisa se reintegrar ao projeto.

---

## 1. Visão geral

**SmartLog** é um aplicativo Flutter (Android) de gestão logística multi-empresa (multi-tenant), com três perfis previstos: **Administrador**, **Motorista** e **Cliente**. O backend é 100% Firebase (Auth + Firestore), sem servidor próprio.

| Item | Situação |
|---|---|
| Etapa do projeto | **MVP funcional parcial** — 2 dos 3 perfis navegáveis |
| Perfil Administrador | ✅ Implementado (5 de 6 abas funcionais) |
| Perfil Motorista | ✅ Implementado (rota + scanner QR + histórico) |
| Perfil Cliente | ❌ **Não existe** — login mostra "Painel do cliente em desenvolvimento" |
| Backend | ✅ Firebase real, dados persistidos no Firestore |
| Testes | ❌ Inexistentes (só o template do Flutter, que **não compila**) |
| Único autor nos commits | Lucas da Silva (6 commits, de 13/06 a 16/07) |

**Ritmo de desenvolvimento:** 6 commits ao longo de ~1 mês, com grandes refatorações. O commit de 05/07 quebrou o `main.dart` monolítico (999 linhas) em arquitetura MVC. Os commits de 08/07 e 10/07 concentram a maior parte do trabalho (2.300+ linhas). O último commit (16/07) reescreveu a tela do motorista para adicionar o scanner de QR Code. **Nada foi commitado desde 16/07/2026** (~3 semanas de inatividade).

---

## 2. Stacks e dependências

### 2.1 Núcleo

| Tecnologia | Versão | Papel |
|---|---|---|
| **Flutter / Dart** | SDK `>=3.3.0 <4.0.0` | Framework do app |
| **Material 3** | `useMaterial3: true` | Design system (tema inline no `main.dart`, seed `#002F6C`) |
| **Provider** | `^6.1.5+1` | Gerência de estado (`ChangeNotifier` + `MultiProvider`) |

### 2.2 Firebase (projeto `smartlog-b9b37`)

| Pacote | Versão | Status de uso |
|---|---|---|
| `firebase_core` | `^3.15.2` | ✅ Em uso — inicialização + app secundário para criar usuários |
| `firebase_auth` | `^5.7.0` | ✅ Em uso — login, cadastro, reset de senha, verificação de e-mail |
| `cloud_firestore` | `^5.6.12` | ✅ Em uso — coleções `usuarios`, `empresas`, `entregas` |
| `firebase_messaging` | `^15.0.0` | ⚠️ **Declarado mas nunca importado** — push notifications não implementadas |

### 2.3 Demais dependências

| Pacote | Versão | Status de uso |
|---|---|---|
| `mobile_scanner` | `^6.0.0` | ✅ Em uso — leitura de QR Code pelo motorista |
| `google_maps_flutter` | `^2.12.3` | ⚠️ **Declarado mas nunca importado** — nenhum mapa na aplicação |
| `http` | `^1.5.0` | ⚠️ **Declarado mas nunca importado** |
| `cupertino_icons` | `^1.0.8` | ⚠️ Não utilizado |
| `flutter_lints` | `^6.0.0` | ✅ Ativo em `analysis_options.yaml` |
| `flutter_launcher_icons` | `^0.14.4` | ✅ Configurado com `assets/Smartlog.png` |

### 2.4 Plataformas

- **Android:** ✅ única plataforma configurada. `minSdk`/`targetSdk` herdados do Flutter, Java/Kotlin 17, `google-services.json` presente.
- **iOS, Web, macOS, Windows, Linux:** ❌ `firebase_options.dart` lança `UnsupportedError` para todas. Não existem sequer as pastas `ios/` e `web/`.
- Permissões declaradas no `AndroidManifest.xml`: `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` (localização declarada mas **nunca usada** no código). Chave da API do Google Maps presente no manifest.

---

## 3. Arquitetura

Padrão **MVC/MVVM simplificado** com Provider:

```
lib/
├── main.dart                        # Bootstrap Firebase + MultiProvider + MaterialApp
├── firebase_options.dart            # Gerado pelo FlutterFire CLI (só Android)
├── models/                          # ⚠️ Modelos existem mas NÃO são usados
├── controllers/                     # ChangeNotifiers — regra de negócio
├── services/                        # Camada de acesso ao Firebase
├── screens/                         # Telas
├── widgets/                         # ❌ Todos os arquivos VAZIOS
└── theme/                           # ❌ VAZIO
```

**Fluxo de navegação atual:**
```
TelaLogin ──┬─ tipoUsuario == ADMINISTRADOR/ADMIN ──▶ DashboardAdmin
            ├─ tipoUsuario == MOTORISTA           ──▶ DashboardMotorista
            └─ qualquer outro (CLIENTE)           ──▶ SnackBar "em desenvolvimento"
            
TelaLogin ──▶ CadastroScreen (auto-registro público)
```

**Modelo de dados no Firestore:**

| Coleção | Documento (id) | Campos principais |
|---|---|---|
| `usuarios` | UID do Auth | `uid`, `nome`, `email`, `tipoUsuario` (MAIÚSCULO), `empresaId`, `statusAtivacao`, `dataCadastro`, `regiaoDesignada` (motorista) |
| `empresas` | id gerado | `id`, `nomeFantasia`, `razaoSocial`, `cnpj`, `endereco`, `telefone`, `site`, `nomeAdmin`, `funcaoAdmin`, `dataCriacao` |
| `entregas` | id gerado | `id` (`ENT-XXXXX`), `cliente`, `endereco`, `regiao`, `status`, `motorista`, `motoristaUid`, `ordemEntrega`, `empresaId`, `dataCriacao` |

**Isolamento multi-tenant:** feito por campo `empresaId` em todas as queries. Um admin que se cadastra publicamente gera automaticamente um documento em `empresas` e vira dono do tenant. Motoristas e clientes herdam o `empresaId` de quem os convidou.

---

## 4. O que está IMPLEMENTADO e funcionando

### 4.1 Autenticação — [lib/services/auth_service.dart](lib/services/auth_service.dart), [lib/controllers/auth_controller.dart](lib/controllers/auth_controller.dart)

- ✅ Login com e-mail/senha (normalizado: `trim` + `toLowerCase`)
- ✅ Roteamento por `tipoUsuario` lido do Firestore
- ✅ Cadastro público com criação automática de empresa (tenant) para Administrador
- ✅ Disparo de e-mail de verificação nativo do Firebase
- ✅ Recuperação de senha ("Esqueci minha senha")
- ✅ Logout com limpeza do `empresaIdLogada`
- ✅ Tradução amigável dos erros do `FirebaseAuthException` para português

### 4.2 Painel do Administrador — [lib/screens/dashboard_admin.dart](lib/screens/dashboard_admin.dart) (1.279 linhas)

Drawer com 6 abas:

| Aba | Status | Observação |
|---|---|---|
| **Dashboard** | 🟡 Parcial | KPIs reais (total entregas/motoristas/clientes, contagem por status e por zona) + bloco "Últimos Eventos" **100% mockado** |
| **Entregas** | 🔴 **Casca vazia** | Chips de filtro por zona funcionam visualmente, mas o corpo sempre mostra "Nenhuma entrega sincronizada nesta região" — [dashboard_admin.dart:343-345](lib/screens/dashboard_admin.dart#L343-L345) |
| **Motoristas** | ✅ Funcional | Lista real + modal de cadastro com nome, e-mail, senha inicial e zona |
| **Clientes** | ✅ Funcional | Lista real + modal de convite com badge de status Ativo/Pendente |
| **Rotas** | ✅ Funcional | Lista as entregas + formulário em tela cheia para criar rota com até 5 paradas (gravação em `WriteBatch`) |
| **Perfil** | ✅ Funcional | Modo leitura/edição alternável; 9 campos da empresa salvos no Firestore com listener em tempo real (`snapshots()`) |

**Destaque técnico bem resolvido:** o cadastro de motorista/cliente ([dashboard_controller.dart:121-264](lib/controllers/dashboard_controller.dart#L121-L264)) inicializa uma **instância secundária do Firebase App** para criar a credencial no Auth sem deslogar o administrador logado, capturando o UID real e usando-o como ID do documento no Firestore. É a solução correta para esse problema no client-side.

### 4.3 Painel do Motorista — [lib/screens/motorista.dart](lib/screens/motorista.dart) (425 linhas)

| Aba | Status |
|---|---|
| **Minha Rota** | ✅ Filtra entregas por `motoristaUid`, ordena por `ordemEntrega`, contador de pendentes |
| **Histórico de Viagens** | ✅ Lista entregas com status `Entregue`, exibindo o recebedor |
| **Meu Perfil** | 🟡 Cabeçalho real (e-mail), ficha de dados **mockada** |

**Scanner QR Code (funcionalidade mais recente, 16/07):**
- ✅ Câmera em tempo real via `MobileScanner`, com flag anti-bipagem dupla
- ✅ Parser que extrai o ID do fim de uma URL (`https://.../ENT-A8F31` → `ENT-A8F31`)
- ✅ **Máquina de estados** em [dashboard_controller.dart:324-399](lib/controllers/dashboard_controller.dart#L324-L399):
  - Bip 1 (`Pendente`) → `A Caminho`
  - Bip 2 (`A Caminho`) → abre modal pedindo nome do recebedor → `Entregue` + timestamp
  - Bip em pacote já entregue → aviso
- ⚠️ **Nada no app gera os QR Codes** das entregas — eles teriam que ser produzidos externamente.

---

## 5. O que está MOCKADO / HARDCODED

| # | Local | O que está falso |
|---|---|---|
| 1 | [dashboard_admin.dart:255-258](lib/screens/dashboard_admin.dart#L255-L258) | Card **"Últimos Eventos do Sistema"** — três linhas fixas com timestamps falsos ("Agora mesmo", "Há 5 min", "Há 12 min"). Não há log de eventos no sistema. |
| 2 | [dashboard_admin.dart:1095-1096](lib/screens/dashboard_admin.dart#L1095-L1096) | KPIs **"Média Tempo"** e **"Taxa de Sucesso"** exibem literalmente a string `"Calcular..."` na tela |
| 3 | [dashboard_admin.dart:1119-1121](lib/screens/dashboard_admin.dart#L1119-L1121) | Bloco **"Plano Corporativo"**: `1 / 5` usuários, `/ 10` motoristas, `0.1 GB / 5 GB` de nuvem — números inventados, não há sistema de planos |
| 4 | [dashboard_admin.dart:1069, 1071](lib/screens/dashboard_admin.dart#L1069) | Fichas "Funcionários" e "Veículos" leem campos `qtdFuncionarios`/`qtdVeiculos` que **nunca são gravados** → sempre `0` |
| 5 | [motorista.dart:402-404](lib/screens/motorista.dart#L402-L404) | Ficha do perfil do motorista: `"Fiorino Furgão (Padrão Leroy Merlin)"`, `"Ativo na Frota"`, `"Isolamento Ativo por ID da Empresa"` — texto fixo |
| 6 | [login.dart:52](lib/screens/login.dart#L52) | `regiaoDesignada: "Zona Sul"` passado fixo ao abrir o painel do motorista — o valor real está no Firestore (`regiaoDesignada`) mas não é lido |
| 7 | [dashboard_controller.dart:99](lib/controllers/dashboard_controller.dart#L99) e [dashboard_admin.dart:1037](lib/screens/dashboard_admin.dart#L1037) | `onlineDesde` com fallbacks divergentes: `'2025'` no controller e `'2026'` na view |
| 8 | [dashboard_admin.dart:479, 657](lib/screens/dashboard_admin.dart#L479) | Fallback `empresaId = "empresa_padrao"` — se cair aqui, usuários de tenants diferentes se misturam |
| 9 | [dashboard_admin.dart:328](lib/screens/dashboard_admin.dart#L328) | Chips de zona usam `"NORTE"/"SUL"/...` enquanto o Firestore grava `"Zona Norte"/"Zona Sul"` — os filtros nunca casariam mesmo se estivessem ligados |

---

## 6. Arquivos VAZIOS (0 bytes) — esqueleto criado em 05/07 e nunca preenchido

São **14 arquivos** criados no commit de estruturação e abandonados:

**Telas nunca escritas:**
- `lib/screens/cliente.dart` — painel do cliente (perfil inteiro faltando)
- `lib/screens/entregas.dart`
- `lib/screens/rastreamento.dart`
- `lib/screens/mapa.dart` — justifica a dependência `google_maps_flutter`
- `lib/screens/alertas.dart`
- `lib/screens/historico.dart`
- `lib/screens/profile.dart`

**Serviços nunca escritos:**
- `lib/services/firestore_service.dart` — o acesso ao Firestore está espalhado nos controllers
- `lib/services/notification_service.dart` — justifica a dependência `firebase_messaging`

**Componentes nunca escritos:**
- `lib/widgets/dashboard/dashboard_card.dart`
- `lib/widgets/dashboard/delivery_card.dart`
- `lib/widgets/dashboard/info_card.dart`
- `lib/widgets/dashboard/side_menu.dart`
- `lib/theme/app_theme.dart`

**Model nunca escrito:**
- `lib/models/motorista.dart`

> Consequência: todos os cards, drawers e temas estão **duplicados inline** dentro de `dashboard_admin.dart` e `motorista.dart`, o que explica os 1.279 e 425 linhas dessas telas.

---

## 7. Código morto / não integrado

| Item | Situação |
|---|---|
| `lib/models/entrega.dart` (84 linhas) | Model completo com `fromJson`/`toJson`/`copyWith` — **nunca importado**. O app inteiro trafega `Map<String, dynamic>` cru. |
| `lib/models/cliente.dart` (70 linhas) | Idem — **nunca importado**. |
| `DashboardController.filtrarPorRegiao()` | Método implementado, **nunca chamado**. Ainda faria crash: `e['regiao'].toString()` sem null-check. |
| `_perfilConfigSwitchRow()` e `_tagPermissao()` | Widgets definidos em `dashboard_admin.dart`, **nunca usados** (warnings do analyzer). |
| `ChangeNotifierProxyProvider` em [main.dart:30-36](lib/main.dart#L30-L36) | O `update` só retorna o `previous` — funcionalmente idêntico a um `ChangeNotifierProvider` simples. Complexidade sem benefício. |
| `AuthService.usuarioStatus` (stream) | Getter exposto, **nunca consumido** — não há `AuthGate`/persistência de sessão. |

---

## 8. Problemas conhecidos, riscos e bugs

### 8.1 Bloqueantes / de correção prioritária

| Severidade | Problema |
|---|---|
| 🔴 **Erro de compilação** | [test/widget_test.dart:16](test/widget_test.dart#L16) referencia `MyApp`, que não existe (a classe é `SmartLogApp`). `flutter test` **falha**. É o template do contador que nunca foi removido. |
| 🔴 **Segurança** | Não existe arquivo `firestore.rules` no repositório. Se as regras do console estiverem em modo teste, **qualquer usuário autenticado lê e escreve dados de qualquer empresa**. Todo o isolamento multi-tenant existe apenas no cliente. |
| 🔴 **Segurança** | [dashboard_controller.dart:334-338](lib/controllers/dashboard_controller.dart#L334-L338) — `registrarBipQRCode` busca a entrega **sem filtrar por `empresaId`**. Um motorista pode dar baixa em entrega de outra empresa se souber o código. |
| 🟠 **Sessão** | Não há persistência de login. Ao reabrir o app, o usuário sempre cai na `TelaLogin`, mesmo com sessão válida no Firebase. Falta um `AuthGate` com `StreamBuilder` sobre `authStateChanges()`. |
| 🟠 **Dados stale** | `inicializarDados()` usa `.get()` uma única vez, travado por `_dadosInicializados`. O admin **não vê** o status atualizado pelo motorista sem reiniciar o app. Não há pull-to-refresh nem `snapshots()` para entregas. |

### 8.2 Qualidade de código (`dart analyze`: **33 issues** — 1 erro, 2 warnings, 30 infos)

- **13 ocorrências** de `use_build_context_synchronously` — uso de `BuildContext` após `await` guardado por `mounted` do State errado. Pode causar crash em navegação rápida.
- **9 ocorrências** de APIs depreciadas: `withOpacity` (usar `withValues`), `DropdownButtonFormField.value` (usar `initialValue`), `Switch.activeColor`.
- 2 declarações não referenciadas, 2 variáveis locais com underscore indevido.
- Efeito colateral dentro do `build`: [dashboard_admin.dart:938-948](lib/screens/dashboard_admin.dart#L938-L948) escreve em `TextEditingController`s durante a construção do widget.
- ⚠️ Nota de ambiente: `flutter analyze` **crasha** neste caminho por causa do caractere `º` em `3º/`. Contorno usado: rodar via symlink em caminho ASCII, ou renomear a pasta.

### 8.3 Identidade do projeto (herança de outro trabalho)

O projeto foi claramente clonado de um app anterior chamado "SmartLife" e o rebranding ficou incompleto:

- `pubspec.yaml`: `name: smartlife` → todos os imports são `package:smartlife/...`
- `android/app/build.gradle.kts`: `applicationId = "com.example.smartlife"` (ainda com `com.example`, **impede publicação na Play Store**)
- `AndroidManifest.xml`: `android:label="smartlife"` — nome exibido no launcher
- **`README.md` descreve "Sistema inteligente para monitoramento de hipertensão arterial"** — texto de outro projeto
- `build.gradle.kts` ainda usa a **chave de assinatura de debug** para o build de release

---

## 9. TO-DO — backlog priorizado

### 🔥 P0 — Bloqueia entrega/apresentação

1. **Escrever e publicar as regras do Firestore** (`firestore.rules`) validando `empresaId` e `tipoUsuario`. Sem isso, o multi-tenant é apenas cosmético.
2. **Corrigir `test/widget_test.dart`** — trocar `MyApp` por `SmartLogApp` ou deletar o arquivo. Hoje `flutter test` não roda.
3. **Implementar a aba Entregas do admin** — os dados já estão em `controller.entregas`; falta apenas renderizar a lista e ligar o filtro de zona (corrigindo `NORTE` vs `Zona Norte`).
4. **Corrigir o README** — ainda descreve um app de hipertensão arterial.
5. **Filtrar por `empresaId` no `registrarBipQRCode`**.

### ⚡ P1 — Funcionalidades centrais faltando

6. **Painel do Cliente** (`lib/screens/cliente.dart`) — perfil inteiro ausente; hoje o cliente loga e recebe um SnackBar. Deveria ver as próprias entregas e rastreamento.
7. **Geração de QR Code** — o motorista lê códigos que o sistema não produz. Adicionar `qr_flutter` e uma tela de impressão de etiquetas na aba Entregas.
8. **Persistência de sessão** — `AuthGate` com `StreamBuilder(authStateChanges)` no `home` do `MaterialApp`.
9. **Sincronização em tempo real** — trocar `.get()` por `.snapshots()` nas entregas, para o admin acompanhar as baixas do motorista ao vivo.
10. **CRUD completo** — hoje só existe Criar e Listar. Falta editar/excluir/inativar motoristas, clientes e entregas.
11. **Ler a `regiaoDesignada` real do motorista** no login, em vez do `"Zona Sul"` fixo.

### 📊 P2 — Substituir os mocks por dados reais

12. Coleção `logs`/`eventos` no Firestore para alimentar "Últimos Eventos do Sistema".
13. Calcular de fato **Média de Tempo** (`dataEntrega − dataCriacao`) e **Taxa de Sucesso** (`entregues / total`).
14. Campos `qtdFuncionarios` e `qtdVeiculos` editáveis no formulário de Perfil.
15. Ficha real do veículo do motorista (novo campo em `usuarios` ou coleção `veiculos`).
16. Definir o que fazer com o bloco "Plano Corporativo" — implementar planos de verdade ou remover.

### 🗺️ P3 — Recursos previstos pelas dependências mas nunca iniciados

17. **Mapa / rastreamento** — `google_maps_flutter` está instalado e as permissões de localização declaradas, mas `mapa.dart` e `rastreamento.dart` estão vazios. Faltaria também captura de GPS do motorista.
18. **Notificações push** — `firebase_messaging` instalado, `notification_service.dart` vazio. Casos de uso óbvios: avisar cliente que o pedido saiu para entrega; avisar motorista de nova rota atribuída.
19. **Alertas** (`alertas.dart`) — provavelmente entregas atrasadas. Note que o KPI "Atrasadas" já procura `status == 'Atrasada'`, um status que **nada no sistema jamais define**.

### 🧹 P4 — Dívida técnica

20. **Extrair os widgets duplicados** para `lib/widgets/dashboard/` (arquivos já criados e vazios) — reduziria drasticamente as 1.279 linhas de `dashboard_admin.dart`.
21. **Centralizar o tema** em `lib/theme/app_theme.dart` — as cores `0xff0F172A`, `0xffF5F7FA` e `Colors.orange` estão repetidas dezenas de vezes.
22. **Usar os models `Entrega` e `Cliente`** em vez de `Map<String, dynamic>` — eliminaria erros de digitação em chaves e os `?? ''` espalhados.
23. **Criar `firestore_service.dart`** e tirar as chamadas diretas ao Firestore dos controllers.
24. Corrigir os 13 `use_build_context_synchronously` e as 9 APIs depreciadas.
25. Renomear o pacote de `smartlife` para `smartlog` e trocar o `applicationId` de `com.example.smartlife` para um domínio real.
26. Configurar chave de assinatura de release.
27. Rota fixa em exatamente 5 paradas ([dashboard_admin.dart:41](lib/screens/dashboard_admin.dart#L41)) — tornar dinâmico (adicionar/remover paradas).
28. Escrever testes reais (widget tests das telas, unit tests dos controllers). Cobertura atual: **0%**.
29. Padronizar `statusAtivacao`: convivem `'PENDENTE'`, `'Ativo'` e `'Aguardando Verificação'` gravados em pontos diferentes do código.
30. Mensagens de UI com erros de digitação/idioma: `"Perfil corporativo updated com sucesso!"` ([dashboard_admin.dart:984](lib/screens/dashboard_admin.dart#L984)), `"GATILHO COMPERCIAL"` ([motorista.dart:91](lib/screens/motorista.dart#L91)).

---

## 10. Como rodar o projeto

```bash
# Pré-requisito: Flutter SDK + dispositivo/emulador Android
flutter pub get
flutter run

# ATENÇÃO: `flutter analyze` crasha neste caminho por causa do "º" em "3º/".
# Contorno: rodar a partir de um symlink em caminho sem acentos:
ln -s "$PWD" /tmp/smartlog && cd /tmp/smartlog && dart analyze
```

**Para testar o fluxo completo:**
1. Cadastre-se como **Administrador** (cria automaticamente uma empresa/tenant).
2. No painel, aba **Motoristas** → Cadastrar (defina e-mail e senha inicial).
3. Aba **Rotas** → Criar Nova Rota, atribuindo ao motorista criado.
4. Deslogue, entre com as credenciais do motorista → as paradas aparecem em "Minha Rota".
5. O botão "Bipar Caixa" exige um QR Code contendo o ID `ENT-XXXXX` — **que precisa ser gerado manualmente por enquanto** (veja o ID no Firestore Console).

---

## 11. Resumo em uma frase

O projeto está num **MVP sólido de backend real com Firebase**, cobrindo o ciclo Admin → cria rota → Motorista → bipa QR → entrega confirmada; o que falta é o **perfil Cliente inteiro**, a **aba Entregas do admin**, as **regras de segurança do Firestore**, a **geração dos QR Codes** e a substituição de cerca de **9 blocos de dados mockados** na interface — além de 14 arquivos de esqueleto que ainda estão vazios.
