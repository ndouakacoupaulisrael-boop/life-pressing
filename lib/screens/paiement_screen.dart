import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/commande.dart';
import '../models/paiement.dart';
import '../services/pdf_service.dart';

class PaiementScreen extends StatefulWidget {
  const PaiementScreen({super.key});

  @override
  State<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends State<PaiementScreen> {
  List<Commande> commandes = [];
  List<Paiement> paiements = [];
  List<Paiement> paiementsFiltres = [];

final rechercheController = TextEditingController();

  Commande? commandeSelectionnee;

  final TextEditingController montantController =
      TextEditingController();

  String modePaiement = "Espèces";

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    commandes = await DatabaseHelper.instance.getCommandes();
    paiements = await DatabaseHelper.instance.getPaiements();
    paiementsFiltres = paiements;

    setState(() {});
  }
  void rechercherPaiement(String valeur) {
  setState(() {
    if (valeur.trim().isEmpty) {
      paiementsFiltres = paiements;
    } else {
      paiementsFiltres = paiements.where((paiement) {
        return paiement.commandeId
                .toString()
                .contains(valeur) ||
            paiement.modePaiement
                .toLowerCase()
                .contains(valeur.toLowerCase()) ||
            paiement.date.contains(valeur);
      }).toList();
    }
  });
}

  Future<void> enregistrerPaiement() async {
    if (commandeSelectionnee == null ||
        montantController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs"),
        ),
      );
      return;
    }

    Paiement paiement = Paiement(
      commandeId: commandeSelectionnee!.id!,
      montant: double.parse(montantController.text),
      date: DateTime.now().toString().substring(0, 10),
      modePaiement: modePaiement,
    );

    await DatabaseHelper.instance.insertPaiement(paiement);
    final client = await DatabaseHelper.instance
    .getClientById(commandeSelectionnee!.clientId);
    final details = await DatabaseHelper.instance
    .getDetailsCommande(commandeSelectionnee!.id!);


final articles = details.map((detail) {
  return "${detail.vetement} x${detail.quantite} - ${detail.prix.toStringAsFixed(0)} FCFA";
}).toList();

    await PdfService.genererRecu(
  client: client == null
      ? "Client inconnu"
      : "${client.nom} ${client.prenom}",
  telephone: client == null ? "-" : client.telephone,
  numeroCommande: commandeSelectionnee!.id!,
  date: DateTime.now().toString().split(' ')[0],
  modePaiement: modePaiement,
  articles: articles,
  montant: double.parse(montantController.text),
  
);
await chargerDonnees();
    montantController.clear();

    setState(() {
      commandeSelectionnee = null;
      modePaiement = "Espèces";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Paiement enregistré avec succès"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paiements"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<Commande>(
              initialValue: commandeSelectionnee,
              decoration: const InputDecoration(
                labelText: "Commande",
                border: OutlineInputBorder(),
              ),
              items: commandes.map((commande) {
                return DropdownMenuItem(
                  value: commande,
                  child: Text(
                    "Commande #${commande.id} - ${commande.total.toStringAsFixed(0)} FCFA",
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  commandeSelectionnee = value;
                });
              },
            ),

            const SizedBox(height: 20),

            TextField(
              controller: montantController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Montant payé",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: modePaiement,
              decoration: const InputDecoration(
                labelText: "Mode de paiement",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: "Espèces",
                  child: Text("Espèces"),
                ),
                DropdownMenuItem(
                  value: "Orange Money",
                  child: Text("Orange Money"),
                ),
                DropdownMenuItem(
                  value: "Wave",
                  child: Text("Wave"),
                ),
                DropdownMenuItem(
                  value: "Carte bancaire",
                  child: Text("Carte bancaire"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  modePaiement = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: enregistrerPaiement,
                icon: const Icon(Icons.save),
                label: const Text("Enregistrer le paiement"),
              ),
            ),

            const SizedBox(height: 20),

            const Divider(),

            const Text(
              "Historique des paiements",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 15),

TextField(
  controller: rechercheController,
  onChanged: rechercherPaiement,
  decoration: const InputDecoration(
    hintText: "Rechercher un paiement...",
    prefixIcon: Icon(Icons.search),
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 15),


            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: paiementsFiltres.length,
                itemBuilder: (context, index) {
                  final paiement = paiementsFiltres[index];

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.payments),
                      title: Text(
                          "${paiement.montant.toStringAsFixed(0)} FCFA"),
                      subtitle: Text(
                        "Commande #${paiement.commandeId}\n"
                        "${paiement.modePaiement}\n"
                        "${paiement.date}",
                      ),
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