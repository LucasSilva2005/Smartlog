// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Controllers
import 'controllers/auth_controller.dart';
import 'controllers/dashboard_controller.dart';

// Screens
import 'screens/login.dart';

void main() async {
  // Garante que os bindings do Flutter estejam inicializados antes do Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as configurações geradas pelo CLI (firebase_options.dart)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        // 1. O AuthController inicia normalmente gerenciando a sessão pública
        ChangeNotifierProvider(create: (_) => AuthController()),

        // 2. CORREÇÃO DA LINHA 35: Inicializando o DashboardController de forma reativa e sem exigir parâmetros no construtor
        ChangeNotifierProxyProvider<AuthController, DashboardController?>(
          create: (_) => DashboardController(), // Inicializa a instância base
          update: (_, auth, previous) {
            // Retorna o próprio controller existente, permitindo que ele permaneça ativo na árvore
            return previous ?? DashboardController();
          },
        ),
      ],
      child: const SmartLogApp(),
    ),
  );
}

class SmartLogApp extends StatelessWidget {
  const SmartLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF002F6C), // Azul escuro corporativo
        ),
      ),
      home: const TelaLogin(),
    );
  }
}