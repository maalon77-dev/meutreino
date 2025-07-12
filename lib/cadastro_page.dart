import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CadastroPage extends StatefulWidget {
  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _erro;

  Future<void> _cadastrar() async {
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
        'acao': 'inserir',
        'nome': _nomeController.text.trim(),
        'email': _emailController.text.trim(),
        'senha': _senhaController.text.trim(),
      },
    );
    setState(() {
      _loading = false;
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data['sucesso'] == true) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Cadastro realizado!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            content: Text(
              'Agora você pode fazer login.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _erro = data['erro'] ?? 'Erro ao cadastrar.';
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
                      Icons.person_add_alt_1,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Criar Conta',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Junte-se à comunidade fitness',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Card de cadastro
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
                            'Cadastro',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          
                          // Campo de nome
                          TextFormField(
                            controller: _nomeController,
                            decoration: InputDecoration(
                              labelText: 'Nome completo',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                            validator: (v) => v != null && v.length >= 2 ? null : 'Digite seu nome completo',
                          ),
                          const SizedBox(height: 20),
                          
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
                            validator: (v) => v != null && v.length >= 4 ? null : 'Senha deve ter pelo menos 4 caracteres',
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
                          
                          // Botão de cadastro
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _loading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        _cadastrar();
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
                                      'Cadastrar',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Link para login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Já tem conta? ',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Fazer login',
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