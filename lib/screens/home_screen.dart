import 'package:flutter/material.dart';
import 'client_screen.dart';
import 'commande_screen.dart';
import 'paiement_screen.dart';
import 'statistique_screen.dart';
import 'vetement_screen.dart';
import '../database/database_helper.dart';

class TarifScreen extends StatelessWidget {
  const TarifScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tarifs"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "Gestion des tarifs",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

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

    setState(() {});
  }

  String formatMontant(double montant) {
    final texte = montant.toStringAsFixed(0);

    return texte.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ' ',
    );
  }
   Widget buildMenuCard({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required Widget page,
}) {
  return Card(
    elevation: 8,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );

        await chargerStatistiques();
      },
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                icon,
                color: Colors.blue,
                size: 30,
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}
Widget buildStatCard(
  String titre,
  String valeur,
  IconData icon,
  Color color,
) {
  return Card(
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 12,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 15),
          FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    valeur,
    textAlign: TextAlign.center,
    style: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),
),
          const SizedBox(height: 6),
          Text(
            titre,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    ),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade700,
                      Colors.blue.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: const [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.local_laundry_service,
                        size: 42,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(
                      "Life Pressing",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Gestion intelligente de votre pressing",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
                children: [
                  buildStatCard(
                    "Clients",
                    nombreClients.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                  buildStatCard(
                    "Commandes",
                    nombreCommandes.toString(),
                    Icons.local_laundry_service,
                    Colors.green,
                  ),
                  buildStatCard(
                    "Vêtements",
                    nombreVetements.toString(),
                    Icons.checkroom,
                    Colors.orange,
                  ),
                  buildStatCard(
                    "Paiements",
                    "${formatMontant(totalPaiements)} FCFA",
                    Icons.payments,
                    Colors.purple,
                  ),
                  
                ],
              ),

              const SizedBox(height: 30),

              buildMenuCard(
                context: context,
                icon: Icons.people,
                title: "Clients",
                subtitle: "Gérer les clients",
                page: const ClientScreen(),
              ),

              const SizedBox(height: 12),

              buildMenuCard(
                context: context,
                icon: Icons.local_laundry_service,
                title: "Commandes",
                subtitle: "Gérer les commandes",
                page: const CommandeScreen(),
              ),

              const SizedBox(height: 12),

              buildMenuCard(
                context: context,
                icon: Icons.checkroom,
                title: "Vêtements",
                subtitle: "Gérer les vêtements",
                page: const VetementScreen(),
              ),

              const SizedBox(height: 12),

              buildMenuCard(
                context: context,
                icon: Icons.payment,
                title: "Paiements",
                subtitle: "Gérer les paiements",
                page: const PaiementScreen(),
              ),

              const SizedBox(height: 12),

              buildMenuCard(
                context: context,
                icon: Icons.analytics,
                title: "Statistiques",
                subtitle: "Voir les statistiques",
                page: const StatistiqueScreen(),
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