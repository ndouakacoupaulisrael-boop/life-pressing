import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/client.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final telephoneController = TextEditingController();
  final adresseController = TextEditingController();

  List<Client> clients = [];
  List<Client> clientsFiltres = [];
final rechercheController = TextEditingController();

  Client? clientEnModification;
  bool modeModification = false;

  @override
  void initState() {
    super.initState();
    chargerClients();
  }

  Future<void> chargerClients() async {
    final liste = await DatabaseHelper.instance.getClients();
setState(() {
  clients = liste;
  clientsFiltres = liste;
});
  }
  void rechercherClient(String valeur) {
  setState(() {
    if (valeur.trim().isEmpty) {
      clientsFiltres = clients;
    } else {
      clientsFiltres = clients.where((client) {
        return client.nom
                .toLowerCase()
                .contains(valeur.toLowerCase()) ||
            client.prenom
                .toLowerCase()
                .contains(valeur.toLowerCase()) ||
            client.telephone.contains(valeur);
      }).toList();
    }
  });
}

  Future<void> ajouterClient() async {
    if (nomController.text.isEmpty ||
        prenomController.text.isEmpty ||
        telephoneController.text.isEmpty ||
        adresseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs."),
        ),
      );
      return;
    }

    Client client = Client(
      nom: nomController.text,
      prenom: prenomController.text,
      telephone: telephoneController.text,
      adresse: adresseController.text,
    );

    await DatabaseHelper.instance.insertClient(client);

    viderChamps();

    await chargerClients();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Client ajouté avec succès"),
      ),
    );
  }

  Future<void> modifierClient() async {
    if (clientEnModification == null) return;

    Client client = Client(
      id: clientEnModification!.id,
      nom: nomController.text,
      prenom: prenomController.text,
      telephone: telephoneController.text,
      adresse: adresseController.text,
    );

    await DatabaseHelper.instance.updateClient(client);

    viderChamps();

    setState(() {
      clientEnModification = null;
      modeModification = false;
    });

    await chargerClients();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Client modifié avec succès"),
      ),
    );
  }

  void viderChamps() {
    nomController.clear();
    prenomController.clear();
    telephoneController.clear();
    adresseController.clear();
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des clients"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: "Nom",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: prenomController,
                decoration: const InputDecoration(
                  labelText: "Prénom",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: telephoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Téléphone",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: adresseController,
                decoration: const InputDecoration(
                  labelText: "Adresse",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed:
                    modeModification ? modifierClient : ajouterClient,
                icon: Icon(
                  modeModification ? Icons.edit : Icons.add,
                ),
                label: Text(
                  modeModification
                      ? "Modifier le client"
                      : "Ajouter le client",
                ),
              ),

              const SizedBox(height: 25),

              const Divider(),

              const SizedBox(height: 10),

              const Text(
                "Liste des clients",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

TextField(
  controller: rechercheController,
  onChanged: rechercherClient,
  decoration: const InputDecoration(
    hintText: "Rechercher un client...",
    prefixIcon: Icon(Icons.search),
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 20),

              const SizedBox(height: 15),
                            clientsFiltres.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "Aucun client enregistré",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: clientsFiltres.length,
                      itemBuilder: (context, index) {
                        final client = clientsFiltres[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 3,
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text("${client.nom} ${client.prenom}"),
                            subtitle: Text(
                              "${client.telephone}\n${client.adresse}",
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    nomController.text = client.nom;
                                    prenomController.text = client.prenom;
                                    telephoneController.text =
                                        client.telephone;
                                    adresseController.text =
                                        client.adresse;

                                    setState(() {
                                      clientEnModification = client;
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
                                    bool? confirmer =
                                        await showDialog<bool>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text(
                                            "Confirmation",
                                          ),
                                          content: const Text(
                                            "Voulez-vous vraiment supprimer ce client ?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                  context,
                                                  false,
                                                );
                                              },
                                              child: const Text("Non"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                  context,
                                                  true,
                                                );
                                              },
                                              child: const Text("Oui"),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirmer == true) {
                                      await DatabaseHelper.instance
                                          .deleteClient(client.id!);

                                      await chargerClients();

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Client supprimé avec succès",
                                          ),
                                        ),
                                      );
                                    }
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
      ),
    );
  }
}