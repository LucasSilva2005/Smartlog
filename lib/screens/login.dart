import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../services/auth_service.dart';
import 'cadastro.dart';
import 'dashboard_admin.dart';
import 'motorista.dart'; // IMPORTAÇÃO CORRIGIDA para o nome do seu arquivo real

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  // Controle de visibilidade da senha (O "olhinho")
  bool _ocultarSenha = true;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // Função para disparar o e-mail de recuperação de senha
  void _recuperarSenha() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite seu e-mail no campo acima para redefinir a senha.')),
      );
      return;
    }

    try {
      // Instancia temporariamente o serviço para enviar o e-mail
      final authService = AuthService();
      await authService.resetarSenha(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('E-mail de redefinição enviado para: $email')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'SmartLog',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Campo E-mail
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty ? 'Insira seu e-mail' : null,
                ),
                const SizedBox(height: 16),

                // Campo Senha com o "Olhinho"
                TextFormField(
                  controller: _senhaController,
                  obscureText: _ocultarSenha, // Controla se a senha aparece ou não
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_ocultarSenha ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _ocultarSenha = !_ocultarSenha; // Inverte o estado do olho
                        });
                      },
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Insira sua senha' : null,
                ),

                // Botão Esqueci Minha Senha
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _recuperarSenha,
                    child: const Text('Esqueci minha senha'),
                  ),
                ),
                const SizedBox(height: 16),

                // Botão de Login Tratado e Otimizado
                ElevatedButton(
                  onPressed: authController.carregando
                      ? null
                      : () async {
                    if (_formKey.currentState!.validate()) {
                      String? tipoUsuario = await authController.realizarLogin(
                        _emailController.text.trim(),
                        _senhaController.text.trim(),
                      );

                      if (tipoUsuario != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Logado como $tipoUsuario!')),
                        );

                        final tipoFormatado = tipoUsuario.trim().toUpperCase();

                        // 1. Redirecionamento para o perfil Administrador
                        if (tipoFormatado == 'ADMINISTRADOR') {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const DashboardAdmin(),
                            ),
                          );
                        }
                        // 2. Redirecionamento para o perfil Motorista (Chamando a classe PascalCase correta)
                        else if (tipoFormatado == 'MOTORISTA') {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const DashboardMotorista(
                                nomeMotorista: "Carlos Silva",
                                regiaoDesignada: "Zona Sul",
                              ),
                            ),
                          );
                        }

                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(authController.erroMensagem ?? 'Erro ao logar')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: authController.carregando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Entrar', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),

                // Link para a tela de Cadastro
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CadastroScreen()),
                    );
                  },
                  child: const Text('Não tem uma conta? Cadastre-se aqui'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}