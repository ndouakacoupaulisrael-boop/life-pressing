import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/commande.dart';
import 'detail_commande_screen.dart';

class HistoriqueClientScreen extends StatefulWidget {
  final Client client;

  const HistoriqueClientScreen({super.key, required this.client});

  @override
  State<HistoriqueClientScreen> createState() => _HistoriqueClientScreenState();
}

class _HistoriqueClientScreenState extends State<HistoriqueClientScreen> {
  List<Commande> commandes = [];
  double totalDepense = 0;

  @override
  void initState() {
    super.initState();
    chargerCommandes();
  }

  Future<void> chargerCommandes() async {
    commandes = await DatabaseHelper.instance.getCommandesParClient(
      widget.client.id!,
    );

    totalDepense = 0;

    for (final commande in commandes) {
      totalDepense += commande.total;
    }

    if (!mounted) return;

    setState(() {});
  }

  Color couleurStatut(String statut) {
    if (statut == "Terminée") {
      return Colors.green;
    }

    if (statut == "Livrée") {
      return Colors.blue;
    }

    if (statut == "En cours") {
      return Colors.orange;
    }

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.client.nom} ${widget.client.prenom}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      child: Icon(Icons.person, size: 35),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${widget.client.nom} "
                      "${widget.client.prenom}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(widget.client.telephone),
                    Text(widget.client.adresse),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text("Résumé"),
                subtitle: Text(
                  "${commandes.length} commande(s)\n"
                  "${totalDepense.toStringAsFixed(0)} "
                  "FCFA dépensés",
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Historique",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: commandes.isEmpty
                  ? const Center(child: Text("Aucune commande"))
                  : ListView.builder(
                      itemCount: commandes.length,
                      itemBuilder: (context, index) {
                        final commande = commandes[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: couleurStatut(commande.statut),
                              child: const Icon(
                                Icons.local_laundry_service,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              "Commande "
                              "#${commande.id}",
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "📅 "
                                  "${commande.date}",
                                ),
                                Text(
                                  "💰 "
                                  "${commande.total.toStringAsFixed(0)} "
                                  "FCFA",
                                ),
                                Text(
                                  "📌 "
                                  "${commande.statut}",
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Touchez pour voir "
                                  "les vêtements",
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailCommandeScreen(commande: commande),
                                ),
                              );

                              await chargerCommandes();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
