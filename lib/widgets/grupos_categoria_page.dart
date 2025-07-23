import 'package:flutter/material.dart';
import 'lista_exercicios_categoria_page.dart';

class GruposCategoriaPage extends StatelessWidget {
  final String categoria;
  final List<String> grupos;

  const GruposCategoriaPage({Key? key, required this.categoria, required this.grupos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selecione um grupo'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF374151)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF374151),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: grupos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final grupo = grupos[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: Text(grupo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              leading: const Icon(Icons.group_work, color: Color(0xFF374151)),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF374151)),
              onTap: () async {
                final exercicioSelecionado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListaExerciciosCategoriaPage(categoria: categoria, grupo: grupo),
                  ),
                );
                if (exercicioSelecionado != null) {
                  Navigator.pop(context, exercicioSelecionado);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
// Esta tela foi gerada e aplicada por GPT-4o. 