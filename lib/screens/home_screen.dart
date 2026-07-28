import 'package:flutter/material.dart';

import '../database/database_helper.dart';

import '../widgets/dashboard_header.dart';
import '../widgets/menu_card.dart';
import '../widgets/stat_card.dart';

import 'client_screen.dart';
import 'commande_screen.dart';
import 'paiement_screen.dart';
import 'statistique_screen.dart';
import 'vetement_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int nombreClients = 0;
  int nombreCommandes = 0;
  int nombreVetements = 0;
  double totalPaiements = 0;

  @override
  void initState() {
    super.initState();
    chargerStatistiques();
  }

  Future<void> chargerStatistiques() async {
    nombreClients =
        await DatabaseHelper.instance.getNombreClients();

    nombreCommandes =
        await DatabaseHelper.instance.getNombreCommandes();

    nombreVetements =
        await DatabaseHelper.instance.getNombreVetements();

    totalPaiements =
        await DatabaseHelper.instance.getTotalPaiements();

    if (mounted) {
      setState(() {});
    }
  }

  String formatMontant(double montant) {
    final texte = montant.toStringAsFixed(0);

    return texte.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ' ',
    );
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Life Pressing"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const DashboardHeader(),

              const SizedBox(height: 30),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
                children: [
                  StatCard(
                    titre: "Clients",
                    valeur: nombreClients.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),

                  StatCard(
                    titre: "Commandes",
                    valeur: nombreCommandes.toString(),
                    icon: Icons.local_laundry_service,
                    color: Colors.orange,
                  ),

                  StatCard(
                    titre: "Vêtements",
                    valeur: nombreVetements.toString(),
                    icon: Icons.checkroom,
                    color: Colors.green,
                  ),

                  StatCard(
                    titre: "Paiements",
                    valeur:
                        "${formatMontant(totalPaiements)} FCFA",
                    icon: Icons.payments,
                    color: Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              MenuCard(
                icon: Icons.people,
                title: "Clients",
                subtitle: "Gérer les clients",
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClientScreen(),
                    ),
                  );

                  await chargerStatistiques();
                },
              ),

              const SizedBox(height: 12),

              MenuCard(
                icon: Icons.local_laundry_service,
                title: "Commandes",
                subtitle: "Gérer les commandes",
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CommandeScreen(),
                    ),
                  );

                  await chargerStatistiques();
                },
              ),

              const SizedBox(height: 12),

              MenuCard(
                icon: Icons.checkroom,
                title: "Vêtements",
                subtitle: "Gérer les vêtements",
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VetementScreen(),
                    ),
                  );

                  await chargerStatistiques();
                },
              ),

              const SizedBox(height: 12),

              MenuCard(
                icon: Icons.payment,
                title: "Paiements",
                subtitle: "Gérer les paiements",
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaiementScreen(),
                    ),
                  );

                  await chargerStatistiques();
                },
              ),

              const SizedBox(height: 12),

              MenuCard(
                icon: Icons.analytics,
                title: "Statistiques",
                subtitle: "Voir les statistiques",
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StatistiqueScreen(),
                    ),
                  );

                  await chargerStatistiques();
                },
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CommandeScreen(),
            ),
          );

          await chargerStatistiques();
        },
        icon: const Icon(Icons.add),
        label: const Text("Commande"),
      ),
    );
  }
}