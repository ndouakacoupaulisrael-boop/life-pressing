import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/commande.dart';
import '../models/vetement.dart';
import '../models/paiement.dart';

class StatistiqueScreen extends StatefulWidget {
  const StatistiqueScreen({super.key});

  @override
  State<StatistiqueScreen> createState() => _StatistiqueScreenState();
}

class _StatistiqueScreenState extends State<StatistiqueScreen> {
  List<Client> clients = [];
  List<Commande> commandes = [];
  List<Vetement> vetements = [];
  List<Paiement> paiements = [];

  double chiffreAffaires = 0;

  @override
  void initState() {
    super.initState();
    chargerStatistiques();
  }

  Future<void> chargerStatistiques() async {
    clients = await DatabaseHelper.instance.getClients();
    commandes = await DatabaseHelper.instance.getCommandes();
    vetements = await DatabaseHelper.instance.getVetements();
    paiements = await DatabaseHelper.instance.getPaiements();

    chiffreAffaires = 0;

    for (var commande in commandes) {
      chiffreAffaires += commande.total;
    }

    setState(() {});
  }
  Widget buildStatCard({
  required IconData icon,
  required String titre,
  required String valeur,
}) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: Colors.blue,
          ),
          const SizedBox(height: 6),

          Text(
            titre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valeur,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
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
      title: const Text("Statistiques"),
      centerTitle: true,
    ),
    body: Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    children: [
      Expanded(
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            buildStatCard(
              icon: Icons.people,
              titre: "Clients",
              valeur: clients.length.toString(),
            ),
            buildStatCard(
              icon: Icons.shopping_bag,
              titre: "Commandes",
              valeur: commandes.length.toString(),
            ),
            buildStatCard(
              icon: Icons.checkroom,
              titre: "Vêtements",
              valeur: vetements.length.toString(),
            ),
            buildStatCard(
              icon: Icons.payment,
              titre: "Paiements",
              valeur: paiements.length.toString(),
            ),
          ],
        ),
      ),

      const SizedBox(height: 15),

      SizedBox(
        width: double.infinity,
        child: buildStatCard(
          icon: Icons.attach_money,
          titre: "Chiffre d'affaires",
          valeur: "${chiffreAffaires.toStringAsFixed(0)} FCFA",
        ),
      ),
    ],
  ),
),

  
  );
}
}
  