import 'package:flutter/material.dart';
import 'package:game_manager_app/providers/auth_service.dart';
import 'package:provider/provider.dart';
import 'auth/login_page.dart';
import 'main/main_app_screen.dart';

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    // ⏳ Mientras Firebase inicializa
    if (auth.user == null) {
      return const LoginPage();
    }

    return const MainAppScreen();
  }
}
