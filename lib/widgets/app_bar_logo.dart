import 'package:flutter/material.dart';

class AppBarLogo extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenu;
  final List<Widget>? actions;
  final Color backgroundColor;
  final bool centerTitle;

  const AppBarLogo({
    Key? key,
    this.onMenu,
    this.actions,
    this.backgroundColor = Colors.white,
    this.centerTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Color(0xFF374151)),
        onPressed: () {
          print('🔍 Botão do menu pressionado!');
          if (onMenu != null) {
            print('🔍 Chamando onMenu callback');
            onMenu!();
          } else {
            print('🔍 Tentando abrir drawer com Scaffold.of(context)');
            try {
              Scaffold.of(context).openDrawer();
              print('🔍 Drawer aberto com sucesso');
            } catch (e) {
              print('❌ Erro ao abrir drawer: $e');
            }
          }
        },
      ),
      title: Center(
        child: Image.asset(
          'assets/backgrounds/logo.png',
          height: 32,
          fit: BoxFit.contain,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Color(0xFF374151), size: 24),
          onPressed: () {
            // Aqui você pode abrir notificações, etc.
          },
        ),
        if (actions != null) ...actions!,
      ],
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 