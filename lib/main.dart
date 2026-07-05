import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'controllers/dashboard_controller.dart';

// Controllers
import 'controllers/auth_controller.dart';

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
    // MultiProvider facilita caso você adicione novos controllers depois (ex: DeliveryController)
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => DashboardController()),
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
          seedColor: const Color(0xFF002F6C), // Azul escuro corporativo (exemplo)
        ),
      ),
      home: const LoginScreen(), // Tela inicial do aplicativo
    );
  }
}