import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/vetement.dart';

class VetementScreen extends StatefulWidget {
  const VetementScreen({super.key});

  @override
  State<VetementScreen> createState() => _VetementScreenState();
}

class _VetementScreenState extends State<VetementScreen> {
  final nomController = TextEditingController();
  final prixController = TextEditingController();

  List<Vetement> vetements = [];
  List<Vetement> vetementsFiltres = [];

final rechercheController = TextEditingController();

  Vetement? vetementEnModification;
  bool modeModification = false;

  @override
  void initState() {
    super.initState();
    chargerVetements();
  }

  Future<void> chargerVetements() async {
    final liste = await DatabaseHelper.instance.getVetements();

    setState(() {
      vetements = liste;
      vetementsFiltres = liste;
    });
  }
  void rechercherVetement(String valeur) {
  setState(() {
    if (valeur.trim().isEmpty) {
      vetementsFiltres = vetements;
    } else {
      vetementsFiltres = vetements.where((vetement) {
        return vetement.nom
            .toLowerCase()
            .contains(valeur.toLowerCase());
      }).toList();
    }
  });
}

  Future<void> ajouterVetement() async {
    if (nomController.text.isEmpty ||
        prixController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs."),
        ),
      );
      return;
    }

    final prix = double.tryParse(prixController.text);

    if (prix == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Prix invalide."),
        ),
      );
      return;
    }

    await DatabaseHelper.instance.insertVetement(
      Vetement(
        nom: nomController.text,
        prix: prix,
      ),
    );

    nomController.clear();
    prixController.clear();

    await chargerVetements();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Vêtement ajouté avec succès"),
      ),
    );
  }
    Future<void> modifierVetement() async {
    if (vetementEnModification == null) return;

    final prix = double.tryParse(prixController.text);

    if (prix == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Prix invalide."),
        ),
      );
      return;
    }

    await DatabaseHelper.instance.updateVetement(
      Vetement(
        id: vetementEnModification!.id,
        nom: nomController.text,
        prix: prix,
      ),
    );

    nomController.clear();
    prixController.clear();

    setState(() {
      modeModification = false;
      vetementEnModification = null;
    });

    await chargerVetements();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Vêtement modifié avec succès"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des vêtements"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: "Nom du vêtement",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: prixController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: "Prix (FCFA)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: modeModification
                  ? modifierVetement
                  : ajouterVetement,
              icon: Icon(
                modeModification
                    ? Icons.edit
                    : Icons.add,
              ),
              label: Text(
                modeModification
                    ? "Modifier le vêtement"
                    : "Ajouter le vêtement",
              ),
            ),

            const SizedBox(height: 25),

            const Divider(),

            const SizedBox(height: 10),

            const Text(
              "Liste des vêtements",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

TextField(
  controller: rechercheController,
  onChanged: rechercherVetement,
  decoration: const InputDecoration(
    hintText: "Rechercher un vêtement...",
    prefixIcon: Icon(Icons.search),
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 20),

            const SizedBox(height: 15),
                        vetementsFiltres.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "Aucun vêtement enregistré",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: vetementsFiltres.length,
                    itemBuilder: (context, index) {
                      final vetement = vetementsFiltres[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.checkroom),
                          ),
                          title: Text(vetement.nom),
                          subtitle: Text(
                            "${vetement.prix.toStringAsFixed(0)} FCFA",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  nomController.text = vetement.nom;
                                  prixController.text =
                                      vetement.prix.toString();

                                  setState(() {
                                    vetementEnModification = vetement;
                                    modeModification = true;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await DatabaseHelper.instance
                                      .deleteVetement(vetement.id!);

                                  await chargerVetements();

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Vêtement supprimé avec succès",
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
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