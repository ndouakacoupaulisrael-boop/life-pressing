import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/commande.dart';
import 'detail_commande_screen.dart';

class CommandeScreen extends StatefulWidget {
  const CommandeScreen({super.key});

  @override
  State<CommandeScreen> createState() => _CommandeScreenState();
}

class _CommandeScreenState extends State<CommandeScreen> {
  List<Client> clients = [];
  List<Commande> commandes = [];
  List<Commande> commandesFiltrees = [];

final rechercheController = TextEditingController();

  Client? clientSelectionne;

  String statut = "En cours";

  final TextEditingController dateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    dateController.text = DateTime.now().toString().split(' ')[0];

    chargerDonnees();
  }
Future<void> chargerDonnees() async {
  clients = await DatabaseHelper.instance.getClients();
  commandes = await DatabaseHelper.instance.getCommandes();
  commandesFiltrees = commandes;

  if (clientSelectionne != null) {
    try {
      clientSelectionne = clients.firstWhere(
        (c) => c.id == clientSelectionne!.id,
      );
    } catch (_) {
      clientSelectionne = null;
    }
  }

  setState(() {});
}
void rechercherCommande(String valeur) {
  setState(() {
    if (valeur.trim().isEmpty) {
      commandesFiltrees = commandes;
    } else {
      commandesFiltrees = commandes.where((commande) {
        try {
          final client = clients.firstWhere(
            (c) => c.id == commande.clientId,
          );

          final nomComplet =
              "${client.nom} ${client.prenom}".toLowerCase();

          return nomComplet.contains(valeur.toLowerCase());
        } catch (_) {
          return false;
        }
      }).toList();
    }
  });
}

  Future<void> ajouterCommande() async {
    if (clientSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner un client"),
        ),
      );
      return;
    }

    Commande commande = Commande(
      clientId: clientSelectionne!.id!,
      date: dateController.text,
      total: 0.0,
      statut: statut,
    );

    await DatabaseHelper.instance.insertCommande(commande);

    await chargerDonnees();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Commande enregistrée avec succès"),
      ),
    );
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des commandes"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

         

            const SizedBox(height: 20),

            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: "Date",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),

            const SizedBox(height: 20),

DropdownButtonFormField<Client>(
  initialValue: clients.contains(clientSelectionne)
    ? clientSelectionne
    : null,
  decoration: const InputDecoration(
    labelText: "Client",
    border: OutlineInputBorder(),
  ),
  items: clients.map((client) {
    return DropdownMenuItem<Client>(
      value: client,
      child: Text("${client.nom} ${client.prenom}"),
    );
  }).toList(),
  onChanged: (client) {
    setState(() {
      clientSelectionne = client;
    });
  },
),
            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: ajouterCommande,
              icon: const Icon(Icons.save),
              label: const Text("Enregistrer la commande"),
            ),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 10),

            const Text(
              "Liste des commandes",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

TextField(
  controller: rechercheController,
  onChanged: rechercherCommande,
  decoration: const InputDecoration(
    hintText: "Rechercher une commande...",
    prefixIcon: Icon(Icons.search),
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 20),

            const SizedBox(height: 15),
                        commandesFiltrees.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "Aucune commande enregistrée",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: commandesFiltrees.length,
                    itemBuilder: (context, index) {
                      final commande = commandesFiltrees[index];

                      String nomClient = "Client inconnu";

                      try {
                        final client = clients.firstWhere(
                          (c) => c.id == commande.clientId,
                        );
                        nomClient = "${client.nom} ${client.prenom}";
                      } catch (_) {}

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
  leading: const Icon(Icons.receipt_long),
  title: Text(nomClient),
  subtitle: Text(
    "Date : ${commande.date}\n"
    "Statut : ${commande.statut}\n"
    "Total : ${commande.total.toStringAsFixed(0)} FCFA",
  ),
  isThreeLine: true,

  onTap: () async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailCommandeScreen(
          commande: commande,
        ),
      ),
    );
    await chargerDonnees();
  },

  trailing: IconButton(
    icon: const Icon(
      Icons.delete,
      color: Colors.red,
    ),
    onPressed: () async {
      await DatabaseHelper.instance.deleteCommande(commande.id!);

      await chargerDonnees();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Commande supprimée avec succès",
          ),
        ),
      );
    },
  ),
),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}