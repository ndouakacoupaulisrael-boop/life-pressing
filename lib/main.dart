import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/navigation_screen.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SessionService.restaurerSession();

  runApp(const PressingApp());
}

class PressingApp extends StatelessWidget {
  const PressingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Life Pressing',
      theme: AppTheme.lightTheme,

      home: SessionService.estConnecte
          ? const NavigationScreen()
          : const LoginScreen(),
    );
  }
}