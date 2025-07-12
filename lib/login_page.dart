import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cadastro_page.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _erro;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    final url = Uri.parse('https://airfit.online/api/api.php');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'tabela': 'usuarios',
        'acao': 'login',
        'email': _emailController.text.trim(),
        'senha': _senhaController.text.trim(),
      },
    );
    setState(() {
      _loading = false;
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Resposta do backend: $data');
      if (data is Map && data['sucesso'] == true) {
        // Login bem-sucedido
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('logado', true);
        // Salvar o ID do usuário
        if (data['usuario_id'] != null) {
          await prefs.setInt('usuario_id', data['usuario_id']);
          print('Usuario ID salvo: ${data['usuario_id']}');
        } else {
          print('ERRO: usuario_id não encontrado na resposta do backend');
          print('Campos disponíveis na resposta: ${data.keys.toList()}');
        }
        
        // Verificar se foi salvo corretamente
        final idSalvo = prefs.getInt('usuario_id');
        print('ID verificado após salvar: $idSalvo');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      } else {
        setState(() {
          _erro = data['erro'] ?? 'E-mail ou senha inválidos.';
        });
      }
    } else {
      setState(() {
        _erro = 'Erro de conexão. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF111827), // Preto
              Color(0xFF1E3A8A), // Azul escuro
              Color(0xFF3B82F6), // Azul médio
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo e título
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bem-vindo ao UPMAX',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sua jornada fitness começa aqui',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Card de login
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Entrar',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          
                          // Campo de e-mail
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                            validator: (v) => v != null && v.contains('@') ? null : 'Digite um e-mail válido',
                          ),
                          const SizedBox(height: 20),
                          
                          // Campo de senha
                          TextFormField(
                            controller: _senhaController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                            validator: (v) => v != null && v.length >= 4 ? null : 'Senha muito curta',
                          ),
                          
                          // Mensagem de erro
                          if (_erro != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFCA5A5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: const Color(0xFFDC2626),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _erro!,
                                      style: const TextStyle(
                                        color: Color(0xFFDC2626),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Botão de login
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _loading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        _login();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Entrar',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Link para cadastro
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Não tem conta? ',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => CadastroPage()),
                                  );
                                },
                                child: Text(
                                  'Cadastre-se',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
} 