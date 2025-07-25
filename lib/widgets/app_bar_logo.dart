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
          if (onMenu != null) {
            onMenu!();
          } else {
            // Tenta abrir o drawer de forma mais robusta
            try {
              Scaffold.of(context).openDrawer();
            } catch (e) {
              // Se falhar, tenta uma abordagem alternativa
              final scaffoldState = Scaffold.of(context);
              if (scaffoldState.hasDrawer) {
                scaffoldState.openDrawer();
              } else {
                // Se não houver drawer, mostra um snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menu não disponível')),
                );
              }
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