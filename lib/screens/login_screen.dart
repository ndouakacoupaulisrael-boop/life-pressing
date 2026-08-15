import 'package:flutter/material.dart';

import 'navigation_screen.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final utilisateurController = TextEditingController();

  final motDePasseController = TextEditingController();

  bool motDePasseVisible = false;

  final AuthService authService = AuthService.instance;

  @override
  void dispose() {
    utilisateurController.dispose();
    motDePasseController.dispose();
    super.dispose();
  }

  void seConnecter() {
    final utilisateur = utilisateurController.text.trim().toLowerCase();

    final motDePasse = motDePasseController.text.trim();

    if (utilisateur.isEmpty || motDePasse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs.")),
      );

      return;
    }

    if (!authService.estConfigure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authService.erreurConfiguration ??
                'Les accès ne sont pas configurés.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final resultat = authService.authentifier(
      utilisateur: utilisateur,
      motDePasse: motDePasse,
    );

    if (resultat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nom d'utilisateur ou mot de passe incorrect."),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    SessionService.ouvrirSession(
      utilisateur: resultat.utilisateur,
      role: resultat.role,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const NavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final erreurConfiguration = authService.erreurConfiguration;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.local_laundry_service,
                        size: 45,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Life Pressing",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Connexion",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),

                    if (erreurConfiguration != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          erreurConfiguration,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),

                    TextField(
                      controller: utilisateurController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: "Nom d'utilisateur",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: motDePasseController,
                      obscureText: !motDePasseVisible,
                      onSubmitted: (_) {
                        seConnecter();
                      },
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            motDePasseVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              motDePasseVisible = !motDePasseVisible;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    ElevatedButton.icon(
                      onPressed: authService.estConfigure ? seConnecter : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      icon: const Icon(Icons.login),
                      label: const Text(
                        "Se connecter",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "Version 1.0",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
