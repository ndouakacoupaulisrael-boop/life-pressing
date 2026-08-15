import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  int nbClients = 0;
  int nbCommandes = 0;
  int nbVetements = 0;
  int nbAttente = 0;
  int nbTerminees = 0;

  double totalPaiements = 0;
  double caJour = 0;
  double caMois = 0;

  @override
  void initState() {
    super.initState();
    chargerStatistiques();
  }

  Future<void> chargerStatistiques() async {
    final nombreClients =
        await DatabaseHelper.instance
            .getNombreClients();

    final nombreCommandes =
        await DatabaseHelper.instance
            .getNombreCommandes();

    final nombreVetements =
        await DatabaseHelper.instance
            .getNombreVetements();

    final nombreAttente =
        await DatabaseHelper.instance
            .getNombreCommandesEnAttente();

    final nombreTerminees =
        await DatabaseHelper.instance
            .getNombreCommandesTerminees();

    final paiements =
        await DatabaseHelper.instance
            .getTotalPaiements();

    final chiffreAffairesJour =
        await DatabaseHelper.instance
            .getChiffreAffairesJour();

    final chiffreAffairesMois =
        await DatabaseHelper.instance
            .getChiffreAffairesMois();

    if (!mounted) return;

    setState(() {
      nbClients = nombreClients;
      nbCommandes = nombreCommandes;
      nbVetements = nombreVetements;
      nbAttente = nombreAttente;
      nbTerminees = nombreTerminees;

      totalPaiements = paiements;
      caJour = chiffreAffairesJour;
      caMois = chiffreAffairesMois;
    });
  }

  Widget carte(
    String titre,
    String valeur,
    IconData icone,
    Color couleur,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: couleur,
              child: Icon(
                icone,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    valeur,
                    style:
                        const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
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
        leading: const Icon(
          Icons.local_laundry_service,
        ),
        title: const Text(
          'Life Pressing',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: chargerStatistiques,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            const SizedBox(
              height: 10,
            ),
            const Text(
              'Bienvenue sur Life Pressing 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            const Text(
              'Voici un aperçu de votre activité.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            carte(
              'Clients',
              nbClients.toString(),
              Icons.people,
              Colors.blue,
            ),
            const SizedBox(
              height: 10,
            ),
            carte(
              'Commandes',
              nbCommandes.toString(),
              Icons.shopping_bag,
              Colors.orange,
            ),
            const SizedBox(
              height: 10,
            ),
            carte(
              'Vêtements',
              nbVetements.toString(),
              Icons.checkroom,
              Colors.purple,
            ),
            const SizedBox(
              height: 10,
            ),
            carte(
              'Commandes en attente',
              nbAttente.toString(),
              Icons.pending_actions,
              Colors.red,
            ),
            const SizedBox(
              height: 10,
            ),
            carte(
              'Commandes terminées',
              nbTerminees.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            const SizedBox(
              height: 10,
            ),
            carte(
              'Total des paiements',
              '${totalPaiements.toStringAsFixed(0)} FCFA',
              Icons.payments,
              Colors.teal,
            ),
            const SizedBox(
              height: 10,
            ),
            carte(
              "Chiffre d'affaires du jour",
              '${caJour.toStringAsFixed(0)} FCFA',
              Icons.today,
              Colors.indigo,
            ),
            const SizedBox(
              height: 10,
            ),
            carte(
              "Chiffre d'affaires du mois",
              '${caMois.toStringAsFixed(0)} FCFA',
              Icons.calendar_month,
              Colors.deepOrange,
            ),
          ],
        ),
      ),
    );
  }
}