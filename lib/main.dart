import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'providers/auth_service.dart';
import 'providers/theme_provider.dart';

import 'screens/root.dart';
import 'screens/home.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Game Manager',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,   // 🌞 Tema claro morado elegante
            darkTheme: themeProvider.darkTheme, // 🌙 Tema oscuro morado elegante
            themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
            home: const Root(),
            routes: {
              "/home": (context) => HomeScreen(),
            },
          );
        },
      ),
    );
  }
}
