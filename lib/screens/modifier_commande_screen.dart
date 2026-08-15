import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/commande.dart';
import '../models/detail_commande.dart';
import '../models/vetement.dart';
import '../services/client_service.dart';
import '../services/commande_service.dart';

class ModifierCommandeScreen extends StatefulWidget {
  final Commande commande;

  const ModifierCommandeScreen({
    super.key,
    required this.commande,
  });

  @override
  State<ModifierCommandeScreen> createState() =>
      _ModifierCommandeScreenState();
}

class _ModifierCommandeScreenState
    extends State<ModifierCommandeScreen> {
  List<Client> clients = [];
  List<Vetement> vetements = [];
  List<DetailCommande> details = [];

  Client? clientSelectionne;
  Vetement? vetementSelectionne;

  late String statut;

  String couleurSelectionnee = 'Blanc';

  final TextEditingController dateController =
      TextEditingController();

  final TextEditingController quantiteController =
      TextEditingController(text: '1');

  bool chargement = true;
  bool enregistrement = false;

  bool articlesVerrouilles = false;

  final List<String> couleurs = [
    'Blanc',
    'Noir',
    'Bleu',
    'Rouge',
    'Vert',
    'Jaune',
    'Gris',
    'Marron',
    'Beige',
    'Rose',
    'Violet',
    'Orange',
    'Multicolore',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();

    statut = widget.commande.statut;
    dateController.text = widget.commande.date;

    chargerDonnees();
  }

  @override
  void dispose() {
    dateController.dispose();
    quantiteController.dispose();
    super.dispose();
  }

  double get totalModifie {
    return details.fold<double>(
      0,
      (total, detail) => total + detail.total,
    );
  }

  Future<void> chargerDonnees() async {
    try {
      if (widget.commande.id == null) {
        throw Exception(
          'Commande invalide.',
        );
      }

      final listeClients =
          await ClientService.instance.getClients();

      final listeVetements =
          await DatabaseHelper.instance.getVetements();

      final listeDetails =
          await CommandeService.instance.getDetailsCommande(
        widget.commande.id!,
      );

      final paiements =
          await CommandeService.instance.getPaiementsCommande(
        widget.commande.id!,
      );

      Client? clientCommande;

      try {
        clientCommande = listeClients.firstWhere(
          (client) =>
              client.id == widget.commande.clientId,
        );
      } catch (_) {
        clientCommande = null;
      }

      if (!mounted) return;

      setState(() {
        clients = listeClients;
        vetements = listeVetements;

        details =
            List<DetailCommande>.from(
          listeDetails,
        );

        clientSelectionne = clientCommande;

        // Si la commande a reçu de l'argent,
        // on protège les articles et le total.
        articlesVerrouilles =
            paiements.isNotEmpty;

        chargement = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        chargement = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void ajouterVetement() {
    if (articlesVerrouilles) {
      return;
    }

    final vetement = vetementSelectionne;

    if (vetement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez sélectionner un vêtement.',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    if (vetement.prix <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le tarif de ce vêtement doit être défini '
            'avant de l’ajouter à une commande.',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    final quantite =
        int.tryParse(
      quantiteController.text.trim(),
    );

    if (quantite == null ||
        quantite <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez saisir une quantité valide.',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    final detail = DetailCommande(
      commandeId: widget.commande.id!,
      vetementId: vetement.id,
      vetement: vetement.nom,
      couleur: couleurSelectionnee,
      quantite: quantite,
      prix: vetement.prix,
    );

    setState(() {
      details.add(detail);

      vetementSelectionne = null;
      couleurSelectionnee = 'Blanc';
      quantiteController.text = '1';
    });
  }

  Future<void> modifierDetail(
    int index,
  ) async {
    if (articlesVerrouilles) {
      return;
    }

    final detail = details[index];

    int nouvelleQuantite =
        detail.quantite;

    final couleursDisponibles =
        List<String>.from(couleurs);

    if (!couleursDisponibles.contains(
      detail.couleur,
    )) {
      couleursDisponibles.add(
        detail.couleur,
      );
    }

    String nouvelleCouleur =
        detail.couleur;

    final controller =
        TextEditingController(
      text: detail.quantite.toString(),
    );

    final resultat =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(
                'Modifier ${detail.vetement}',
              ),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  InputDecorator(
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Couleur',
                      border:
                          OutlineInputBorder(),
                    ),
                    child:
                        DropdownButtonHideUnderline(
                      child:
                          DropdownButton<String>(
                        value:
                            nouvelleCouleur,
                        isExpanded: true,
                        items:
                            couleursDisponibles
                                .map(
                          (couleur) {
                            return DropdownMenuItem<
                                String>(
                              value:
                                  couleur,
                              child:
                                  Text(
                                couleur,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setDialogState(() {
                            nouvelleCouleur =
                                value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextField(
                    controller:
                        controller,
                    keyboardType:
                        TextInputType
                            .number,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Quantité',
                      border:
                          OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.numbers,
                      ),
                    ),
                    onChanged: (value) {
                      final q =
                          int.tryParse(
                        value.trim(),
                      );

                      if (q != null) {
                        nouvelleQuantite =
                            q;
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child:
                      const Text(
                    'Annuler',
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    final q =
                        int.tryParse(
                      controller.text
                          .trim(),
                    );

                    if (q == null ||
                        q <= 0) {
                      return;
                    }

                    nouvelleQuantite =
                        q;

                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },
                  child:
                      const Text(
                    'Enregistrer',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (resultat != true ||
        !mounted) {
      return;
    }

    setState(() {
      details[index] =
          DetailCommande(
        id: detail.id,
        commandeId:
            widget.commande.id!,
        vetementId:
            detail.vetementId,
        vetement:
            detail.vetement,
        couleur:
            nouvelleCouleur,
        quantite:
            nouvelleQuantite,
        prix: detail.prix,
      );
    });
  }

  void supprimerDetail(
    int index,
  ) {
    if (articlesVerrouilles) {
      return;
    }

    setState(() {
      details.removeAt(index);
    });
  }

  Future<void> modifierCommande() async {
    final client =
        clientSelectionne;

    if (client == null ||
        client.id == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez sélectionner un client.',
          ),
          backgroundColor:
              Colors.red,
        ),
      );

      return;
    }

    if (dateController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'La date est obligatoire.',
          ),
          backgroundColor:
              Colors.red,
        ),
      );

      return;
    }

    if (!articlesVerrouilles &&
        details.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'La commande doit contenir '
            'au moins un vêtement.',
          ),
          backgroundColor:
              Colors.red,
        ),
      );

      return;
    }

    setState(() {
      enregistrement = true;
    });

    try {
      if (articlesVerrouilles) {
        // Une commande payée conserve
        // ses articles et son total.
        await CommandeService.instance
            .modifierCommande(
          commandeOriginale:
              widget.commande,
          clientId: client.id!,
          date:
              dateController.text,
          statut: statut,
        );
      } else {
        // Pas encore de paiement :
        // modification complète autorisée.
        await CommandeService.instance
            .modifierCommandeComplete(
          commandeOriginale:
              widget.commande,
          clientId: client.id!,
          date:
              dateController.text,
          statut: statut,
          details:
              List<DetailCommande>.from(
            details,
          ),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Commande modifiée avec succès.',
          ),
          backgroundColor:
              Colors.green,
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString()
                .replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          enregistrement = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Modifier la commande '
          '#${widget.commande.id}',
        ),
      ),
      body: chargement
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
                  Card(
                    color:
                        Colors.orange
                            .shade50,
                    child: const Padding(
                      padding:
                          EdgeInsets.all(
                        12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .admin_panel_settings,
                            color:
                                Colors.orange,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              'Modification réservée '
                              'au propriétaire.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (articlesVerrouilles) ...[
                    const SizedBox(
                      height: 12,
                    ),
                    Card(
                      color:
                          Colors.blueGrey
                              .shade50,
                      child: const Padding(
                        padding:
                            EdgeInsets.all(
                          12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock,
                              color:
                                  Colors.blueGrey,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Text(
                                'Cette commande a déjà reçu '
                                'un paiement. Les vêtements, '
                                'quantités et le total sont '
                                'donc verrouillés.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 20,
                  ),

                  TextField(
                    controller:
                        dateController,
                    decoration:
                        const InputDecoration(
                      labelText: 'Date',
                      border:
                          OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons
                            .calendar_today,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  InputDecorator(
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Client',
                      border:
                          OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.person,
                      ),
                    ),
                    child:
                        DropdownButtonHideUnderline(
                      child:
                          DropdownButton<Client>(
                        value:
                            clientSelectionne,
                        isExpanded: true,
                        items:
                            clients.map(
                          (client) {
                            return DropdownMenuItem<
                                Client>(
                              value:
                                  client,
                              child:
                                  Text(
                                '${client.nom} '
                                '${client.prenom}',
                              ),
                            );
                          },
                        ).toList(),
                        onChanged:
                            (client) {
                          setState(() {
                            clientSelectionne =
                                client;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  InputDecorator(
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Statut',
                      border:
                          OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.flag,
                      ),
                    ),
                    child:
                        DropdownButtonHideUnderline(
                      child:
                          DropdownButton<String>(
                        value: statut,
                        isExpanded: true,
                        items:
                            const [
                          DropdownMenuItem(
                            value:
                                'En attente',
                            child:
                                Text(
                              '🟡 En attente',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'En cours',
                            child:
                                Text(
                              '🔵 En cours',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'Terminée',
                            child:
                                Text(
                              '🟢 Terminée',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'Livrée',
                            child:
                                Text(
                              '✅ Livrée',
                            ),
                          ),
                        ],
                        onChanged:
                            (value) {
                          if (value ==
                              null) {
                            return;
                          }

                          setState(() {
                            statut =
                                value;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  const Divider(),

                  const SizedBox(
                    height: 10,
                  ),

                  const Text(
                    'Vêtements de la commande',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  if (details.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.all(
                        12,
                      ),
                      child: Text(
                        'Aucun vêtement.',
                      ),
                    )
                  else
                    ...List.generate(
                      details.length,
                      (index) {
                        final detail =
                            details[
                                index];

                        return Card(
                          child: ListTile(
                            leading:
                                const Icon(
                              Icons
                                  .checkroom,
                            ),
                            title: Text(
                              detail
                                  .vetement,
                            ),
                            subtitle:
                                Text(
                              '${detail.couleur} • '
                              'Quantité : ${detail.quantite}\n'
                              '${detail.prix.toStringAsFixed(0)} FCFA / unité',
                            ),
                            trailing:
                                articlesVerrouilles
                                    ? Text(
                                        '${detail.total.toStringAsFixed(0)} F',
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip:
                                                'Modifier quantité / couleur',
                                            onPressed:
                                                () => modifierDetail(
                                              index,
                                            ),
                                            icon:
                                                const Icon(
                                              Icons.edit,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip:
                                                'Retirer',
                                            onPressed:
                                                () => supprimerDetail(
                                              index,
                                            ),
                                            icon:
                                                const Icon(
                                              Icons.delete_outline,
                                              color:
                                                  Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(
                    height: 15,
                  ),

                  Card(
                    color:
                        Colors.green
                            .shade50,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          const Text(
                            'TOTAL',
                            style:
                                TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${totalModifie.toStringAsFixed(0)} FCFA',
                            style:
                                const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (!articlesVerrouilles) ...[
                    const SizedBox(
                      height: 25,
                    ),

                    const Text(
                      'Ajouter un vêtement',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    InputDecorator(
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Vêtement',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons.checkroom,
                        ),
                      ),
                      child:
                          DropdownButtonHideUnderline(
                        child:
                            DropdownButton<Vetement>(
                          value:
                              vetementSelectionne,
                          hint:
                              const Text(
                            'Sélectionner un vêtement',
                          ),
                          isExpanded:
                              true,
                          items:
                              vetements
                                  .map(
                            (vetement) {
                              return DropdownMenuItem<
                                  Vetement>(
                                value:
                                    vetement,
                                child:
                                    Text(
                                  '${vetement.nom} - '
                                  '${vetement.prix.toStringAsFixed(0)} FCFA',
                                ),
                              );
                            },
                          ).toList(),
                          onChanged:
                              (value) {
                            setState(() {
                              vetementSelectionne =
                                  value;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    InputDecorator(
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Couleur',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons.palette,
                        ),
                      ),
                      child:
                          DropdownButtonHideUnderline(
                        child:
                            DropdownButton<String>(
                          value:
                              couleurSelectionnee,
                          isExpanded:
                              true,
                          items:
                              couleurs
                                  .map(
                            (couleur) {
                              return DropdownMenuItem<
                                  String>(
                                value:
                                    couleur,
                                child:
                                    Text(
                                  couleur,
                                ),
                              );
                            },
                          ).toList(),
                          onChanged:
                              (value) {
                            if (value ==
                                null) {
                              return;
                            }

                            setState(() {
                              couleurSelectionnee =
                                  value;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    TextField(
                      controller:
                          quantiteController,
                      keyboardType:
                          TextInputType.number,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Quantité',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons.numbers,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    ElevatedButton.icon(
                      onPressed:
                          ajouterVetement,
                      icon:
                          const Icon(
                        Icons.add,
                      ),
                      label:
                          const Text(
                        'Ajouter le vêtement',
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 30,
                  ),

                  ElevatedButton.icon(
                    onPressed:
                        enregistrement
                            ? null
                            : modifierCommande,
                    icon:
                        enregistrement
                            ? const SizedBox(
                                width: 18,
                                height:
                                    18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons.save,
                              ),
                    label: Text(
                      enregistrement
                          ? 'Enregistrement...'
                          : 'Enregistrer les modifications',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}