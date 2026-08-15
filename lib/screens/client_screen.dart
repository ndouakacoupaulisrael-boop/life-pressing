import 'package:flutter/material.dart';

import '../models/client.dart';
import '../services/client_service.dart';
import 'historique_client_screen.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() =>
      _ClientScreenState();
}

class _ClientScreenState
    extends State<ClientScreen> {
  final nomController =
      TextEditingController();

  final prenomController =
      TextEditingController();

  final telephoneController =
      TextEditingController();

  final adresseController =
      TextEditingController();

  final rechercheController =
      TextEditingController();

  List<Client> clients = [];
  List<Client> clientsFiltres = [];

  Client? clientEnModification;

  bool modeModification = false;
  bool chargement = true;
  bool enregistrement = false;

  @override
  void initState() {
    super.initState();
    chargerClients();
  }

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    telephoneController.dispose();
    adresseController.dispose();
    rechercheController.dispose();

    super.dispose();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> chargerClients() async {
    try {
      final liste =
          await ClientService.instance
              .getClients();

      if (!mounted) return;

      setState(() {
        clients = liste;
        chargement = false;
      });

      rechercherClient(
        rechercheController.text,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        chargement = false;
      });

      _afficherMessage(
        'Impossible de charger les clients.',
        erreur: true,
      );
    }
  }

  // ============================================================
  // RECHERCHE
  // ============================================================

  void rechercherClient(
    String valeur,
  ) {
    final recherche =
        valeur.trim().toLowerCase();

    setState(() {
      if (recherche.isEmpty) {
        clientsFiltres =
            List<Client>.from(
          clients,
        );

        return;
      }

      clientsFiltres =
          clients.where(
        (client) {
          final nomComplet =
              '${client.nom} '
              '${client.prenom}'
                  .toLowerCase();

          return nomComplet
                  .contains(recherche) ||
              client.telephone
                  .toLowerCase()
                  .contains(recherche) ||
              client.adresse
                  .toLowerCase()
                  .contains(recherche);
        },
      ).toList();
    });
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  void _afficherMessage(
    String message, {
    bool erreur = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: erreur
            ? Colors.red
            : Colors.green,
      ),
    );
  }

  Future<void>
      _afficherActionInterdite(
    String message,
  ) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.lock_rounded,
                color: Colors.orange,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Autorisation requise',
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
                  const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CHAMPS
  // ============================================================

  bool _champsValides() {
    if (nomController.text
            .trim()
            .isEmpty ||
        prenomController.text
            .trim()
            .isEmpty ||
        telephoneController.text
            .trim()
            .isEmpty ||
        adresseController.text
            .trim()
            .isEmpty) {
      _afficherMessage(
        'Veuillez remplir tous les champs.',
        erreur: true,
      );

      return false;
    }

    return true;
  }

  void viderChamps() {
    nomController.clear();
    prenomController.clear();
    telephoneController.clear();
    adresseController.clear();
  }

  void annulerModification() {
    viderChamps();

    setState(() {
      clientEnModification = null;
      modeModification = false;
    });
  }

  // ============================================================
  // AJOUT
  // ============================================================

  Future<void> ajouterClient() async {
    if (!_champsValides()) {
      return;
    }

    setState(() {
      enregistrement = true;
    });

    try {
      await ClientService.instance
          .ajouterClient(
        nom: nomController.text,
        prenom:
            prenomController.text,
        telephone:
            telephoneController.text,
        adresse:
            adresseController.text,
      );

      viderChamps();

      await chargerClients();

      if (!mounted) return;

      _afficherMessage(
        'Client ajouté avec succès.',
      );
    } catch (e) {
      _afficherMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        erreur: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          enregistrement = false;
        });
      }
    }
  }

  // ============================================================
  // MODIFICATION
  // ============================================================

  Future<void> modifierClient() async {
    final client =
        clientEnModification;

    if (client == null) return;

    if (!_champsValides()) {
      return;
    }

    setState(() {
      enregistrement = true;
    });

    try {
      final autorise =
          await ClientService.instance
              .modifierClient(
        client: client,
        nom: nomController.text,
        prenom:
            prenomController.text,
        telephone:
            telephoneController.text,
        adresse:
            adresseController.text,
      );

      if (!mounted) return;

      if (!autorise) {
        await _afficherActionInterdite(
          'Seul le propriétaire peut '
          'modifier un client.\n\n'
          'Cette tentative a été enregistrée '
          'dans le journal de sécurité.',
        );

        return;
      }

      viderChamps();

      setState(() {
        clientEnModification = null;
        modeModification = false;
      });

      await chargerClients();

      if (!mounted) return;

      _afficherMessage(
        'Client modifié avec succès.',
      );
    } catch (e) {
      _afficherMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        erreur: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          enregistrement = false;
        });
      }
    }
  }

  // ============================================================
  // SUPPRESSION
  // ============================================================

  Future<void> supprimerClient(
    Client client,
  ) async {
    final confirmation =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Confirmation',
          ),
          content: Text(
            'Voulez-vous vraiment supprimer '
            '${client.nom} ${client.prenom} ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text('Non'),
            ),
            FilledButton.icon(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              icon: const Icon(
                Icons.delete,
              ),
              label:
                  const Text('Oui'),
            ),
          ],
        );
      },
    );

    if (confirmation != true) {
      return;
    }

    try {
      final autorise =
          await ClientService.instance
              .supprimerClient(
        client,
      );

      if (!mounted) return;

      if (!autorise) {
        await _afficherActionInterdite(
          'Seul le propriétaire peut '
          'supprimer un client.\n\n'
          'Cette tentative a été enregistrée '
          'dans le journal de sécurité.',
        );

        return;
      }

      await chargerClients();

      if (!mounted) return;

      _afficherMessage(
        'Client supprimé avec succès.',
      );
    } catch (e) {
      _afficherMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        erreur: true,
      );
    }
  }

  // ============================================================
  // MODE MODIFICATION
  // ============================================================

  void preparerModification(
    Client client,
  ) {
    nomController.text =
        client.nom;

    prenomController.text =
        client.prenom;

    telephoneController.text =
        client.telephone;

    adresseController.text =
        client.adresse;

    setState(() {
      clientEnModification =
          client;

      modeModification = true;
    });
  }

  // ============================================================
  // INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Gestion des clients',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed:
                chargerClients,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: chargement
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
                  children: [
                    // ===========================================
                    // FORMULAIRE
                    // ===========================================

                    if (modeModification)
                      Card(
                        color:
                            Colors.orange
                                .shade50,
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit,
                                color:
                                    Colors.orange,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  'Modification de '
                                  '${clientEnModification?.nom ?? ''} '
                                  '${clientEnModification?.prenom ?? ''}',
                                ),
                              ),
                              IconButton(
                                tooltip:
                                    'Annuler',
                                onPressed:
                                    annulerModification,
                                icon:
                                    const Icon(
                                  Icons.close,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (modeModification)
                      const SizedBox(
                        height: 15,
                      ),

                    TextField(
                      controller:
                          nomController,
                      decoration:
                          const InputDecoration(
                        labelText: 'Nom',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons.person,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    TextField(
                      controller:
                          prenomController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Prénom',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons
                              .person_outline,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    TextField(
                      controller:
                          telephoneController,
                      keyboardType:
                          TextInputType.phone,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Téléphone',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons.phone,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    TextField(
                      controller:
                          adresseController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Adresse',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons
                              .location_on,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    ElevatedButton.icon(
                      onPressed:
                          enregistrement
                              ? null
                              : modeModification
                                  ? modifierClient
                                  : ajouterClient,
                      icon:
                          enregistrement
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : Icon(
                                  modeModification
                                      ? Icons.edit
                                      : Icons.add,
                                ),
                      label: Text(
                        enregistrement
                            ? 'Enregistrement...'
                            : modeModification
                                ? 'Modifier le client'
                                : 'Ajouter le client',
                      ),
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    const Divider(),

                    const SizedBox(
                      height: 10,
                    ),

                    const Text(
                      'Liste des clients',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    // ===========================================
                    // RECHERCHE
                    // ===========================================

                    TextField(
                      controller:
                          rechercheController,
                      onChanged:
                          rechercherClient,
                      decoration:
                          InputDecoration(
                        hintText:
                            'Rechercher un client...',
                        prefixIcon:
                            const Icon(
                          Icons.search,
                        ),
                        suffixIcon:
                            rechercheController
                                    .text
                                    .isNotEmpty
                                ? IconButton(
                                    icon:
                                        const Icon(
                                      Icons.clear,
                                    ),
                                    onPressed:
                                        () {
                                      rechercheController
                                          .clear();

                                      rechercherClient(
                                        '',
                                      );
                                    },
                                  )
                                : null,
                        filled: true,
                        fillColor:
                            Colors.grey
                                .shade100,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                          borderSide:
                              BorderSide
                                  .none,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      '${clientsFiltres.length} '
                      'client(s) trouvé(s)',
                      style:
                          const TextStyle(
                        color: Colors.grey,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ===========================================
                    // LISTE
                    // ===========================================

                    if (clientsFiltres.isEmpty)
                      const Center(
                        child: Padding(
                          padding:
                              EdgeInsets.all(
                            20,
                          ),
                          child: Text(
                            'Aucun client enregistré',
                            style:
                                TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount:
                            clientsFiltres
                                .length,
                        itemBuilder:
                            (context,
                                index) {
                          final client =
                              clientsFiltres[
                                  index];

                          return Card(
                            margin:
                                const EdgeInsets
                                    .only(
                              bottom: 10,
                            ),
                            elevation: 3,
                            child:
                                ListTile(
                              leading:
                                  const CircleAvatar(
                                child: Icon(
                                  Icons.person,
                                ),
                              ),

                              title: Text(
                                '${client.nom} '
                                '${client.prenom}',
                              ),

                              subtitle: Text(
                                '${client.telephone}\n'
                                '${client.adresse}',
                              ),

                              isThreeLine:
                                  true,

                              trailing: Row(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,
                                children: [
                                  IconButton(
                                    tooltip:
                                        'Modifier',
                                    icon:
                                        const Icon(
                                      Icons.edit,
                                      color:
                                          Colors.blue,
                                    ),
                                    onPressed:
                                        () {
                                      preparerModification(
                                        client,
                                      );
                                    },
                                  ),

                                  IconButton(
                                    tooltip:
                                        'Historique',
                                    icon:
                                        const Icon(
                                      Icons.history,
                                      color:
                                          Colors.orange,
                                    ),
                                    onPressed:
                                        () async {
                                      await Navigator
                                          .push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) =>
                                                  HistoriqueClientScreen(
                                            client:
                                                client,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  IconButton(
                                    tooltip:
                                        'Supprimer',
                                    icon:
                                        const Icon(
                                      Icons.delete,
                                      color:
                                          Colors.red,
                                    ),
                                    onPressed:
                                        () {
                                      supprimerClient(
                                        client,
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
      ),
    );
  }
}