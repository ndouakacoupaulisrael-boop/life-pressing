import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/commande.dart';
import '../models/detail_commande.dart';
import '../models/vetement.dart';

class DetailCommandeScreen extends StatefulWidget {
  final Commande commande;

  const DetailCommandeScreen({
    super.key,
    required this.commande,
  });

  @override
  State<DetailCommandeScreen> createState() =>
      _DetailCommandeScreenState();
}

class _DetailCommandeScreenState
    extends State<DetailCommandeScreen> {
  List<Vetement> vetements = [];
  List<DetailCommande> details = [];

  Vetement? vetementSelectionne;

  final TextEditingController quantiteController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    vetements = await DatabaseHelper.instance.getVetements();

    details = await DatabaseHelper.instance
        .getDetailsCommande(widget.commande.id!);

    setState(() {});
  }

  Future<void> ajouterDetail() async {
    if (vetementSelectionne == null ||
        quantiteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs"),
        ),
      );
      return;
    }

    DetailCommande detail = DetailCommande(
      commandeId: widget.commande.id!,
      vetement: vetementSelectionne!.nom,
      quantite: int.parse(quantiteController.text),
      prix: vetementSelectionne!.prix,
    );

    await DatabaseHelper.instance.insertDetailCommande(detail);

    await DatabaseHelper.instance
        .mettreAJourTotalCommande(widget.commande.id!);

    quantiteController.clear();
    vetementSelectionne = null;

    await chargerDonnees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Détail de la commande"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<Vetement>(
              initialValue: vetementSelectionne,
              decoration: const InputDecoration(
                labelText: "Vêtement",
                border: OutlineInputBorder(),
              ),
              items: vetements.map((v) {
                return DropdownMenuItem(
                  value: v,
                  child: Text(
                    "${v.nom} - ${v.prix} FCFA",
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  vetementSelectionne = value;
                });
              },
            ),
            if (vetementSelectionne != null)
  Card(
    color: Colors.blue.shade50,
    child: ListTile(
      leading: const Icon(
        Icons.attach_money,
        color: Colors.green,
      ),
      title: const Text("Prix unitaire"),
      subtitle: Text(
        "${vetementSelectionne!.prix.toStringAsFixed(0)} FCFA",
      ),
    ),
  ),

            const SizedBox(height: 20),

            TextField(
              controller: quantiteController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Quantité",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: ajouterDetail,
              icon: const Icon(Icons.add),
              label: const Text("Ajouter"),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: details.length,
                itemBuilder: (context, index) {
                  final detail = details[index];

                  return Card(
                    child: ListTile(
                      title: Text(detail.vetement),
                      subtitle: Text(
                        "Quantité : ${detail.quantite}",
                      ),
                      trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      "${detail.prix * detail.quantite} FCFA",
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
    IconButton(
      icon: const Icon(
        Icons.delete,
        color: Colors.red,
      ),
      onPressed: () async {
        await DatabaseHelper.instance
            .deleteDetailCommande(detail.id!);

        await DatabaseHelper.instance
            .mettreAJourTotalCommande(widget.commande.id!);

        await chargerDonnees();
      },
    ),
  ],
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