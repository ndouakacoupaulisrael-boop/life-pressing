import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../models/parametre.dart';

class ParametreScreen extends StatefulWidget {
  const ParametreScreen({super.key});

  @override
  State<ParametreScreen> createState() => _ParametreScreenState();
}

class _ParametreScreenState extends State<ParametreScreen> {
  final nomPressingController = TextEditingController();
  final proprietaireController = TextEditingController();
  final telephoneController = TextEditingController();
  final adresseController = TextEditingController();
  final emailController = TextEditingController();

  File? logoPressing;

  final ImagePicker picker = ImagePicker();
  final db = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    chargerParametres();
    chargerLogo();
  }

  Future<void> chargerParametres() async {
    final parametre = await db.getParametre();

    if (parametre != null) {
      setState(() {
        nomPressingController.text = parametre.nomPressing;
        proprietaireController.text = parametre.proprietaire;
        telephoneController.text = parametre.telephone;
        adresseController.text = parametre.adresse;
        emailController.text = parametre.email;
      });
    }
  }

  Future<void> choisirLogo() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("logo", image.path);

    setState(() {
      logoPressing = File(image.path);
    });
  }

  Future<void> chargerLogo() async {
    final prefs = await SharedPreferences.getInstance();

    final path = prefs.getString("logo");

    if (path != null) {
      setState(() {
        logoPressing = File(path);
      });
    }
  }

  Future<void> enregistrer() async {
    final parametre = Parametre(
      nomPressing: nomPressingController.text,
      proprietaire: proprietaireController.text,
      telephone: telephoneController.text,
      adresse: adresseController.text,
      email: emailController.text,
    );

    final ancien = await db.getParametre();

    if (ancien == null) {
      await db.saveParametre(parametre);
    } else {
      await db.updateParametre(
        Parametre(
          id: ancien.id,
          nomPressing: nomPressingController.text,
          proprietaire: proprietaireController.text,
          telephone: telephoneController.text,
          adresse: adresseController.text,
          email: emailController.text,
        ),
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Paramètres enregistrés avec succès."),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Paramètres",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: logoPressing != null
                          ? FileImage(logoPressing!)
                          : null,
                      child: logoPressing == null
                          ? const Icon(Icons.store, size: 45)
                          : null,
                    ),

                    const SizedBox(height: 10),

                    TextButton.icon(
                      onPressed: choisirLogo,
                      icon: const Icon(Icons.photo),
                      label: const Text("Choisir un logo"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              TextField(
                controller: nomPressingController,
                decoration: const InputDecoration(
                  labelText: "Nom du pressing",
                  prefixIcon: Icon(Icons.local_laundry_service),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: proprietaireController,
                decoration: const InputDecoration(
                  labelText: "Nom du propriétaire",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: telephoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Téléphone",
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: adresseController,
                decoration: const InputDecoration(
                  labelText: "Adresse",
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: enregistrer,
                icon: const Icon(Icons.save),
                label: const Text("Enregistrer"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),

              const SizedBox(height: 15),

              OutlinedButton.icon(
                onPressed: () {
                  nomPressingController.clear();
                  proprietaireController.clear();
                  telephoneController.clear();
                  adresseController.clear();
                  emailController.clear();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Réinitialiser"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nomPressingController.dispose();
    proprietaireController.dispose();
    telephoneController.dispose();
    adresseController.dispose();
    emailController.dispose();
    super.dispose();
  }
}