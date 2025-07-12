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
  String? _erro;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    final url = Uri.parse('https://airfit.online/api/usuarios.php');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _emailController.text.trim(),
        'senha': _senhaController.text.trim(),
        'acao': 'login',
      }),
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
      backgroundColor: Color(0xFFE6F0FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 70),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text('Bem-vindo!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1565DF))),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v != null && v.contains('@') ? null : 'Digite um e-mail válido',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _senhaController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v != null && v.length >= 4 ? null : 'Senha muito curta',
                      ),
                      const SizedBox(height: 16),
                      if (_erro != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(_erro!, style: TextStyle(color: Colors.red)),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1565DF),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _loading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    _login();
                                  }
                                },
                          child: _loading
                              ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('Entrar', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CadastroPage()),
                          );
                        },
                        child: Text('Não tem conta? Cadastre-se', style: TextStyle(color: Color(0xFF1565DF))),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 