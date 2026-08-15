import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/commande.dart';
import '../models/paiement.dart';
import '../services/commande_service.dart';
import '../services/paiement_service.dart';
import '../services/pdf_service.dart';

class PaiementScreen extends StatefulWidget {
  const PaiementScreen({super.key});

  @override
  State<PaiementScreen> createState() =>
      _PaiementScreenState();
}

class _PaiementScreenState
    extends State<PaiementScreen> {
  List<Commande> commandes = [];
  List<Paiement> paiements = [];
  List<Paiement> paiementsFiltres = [];

  final TextEditingController rechercheController =
      TextEditingController();

  final TextEditingController montantController =
      TextEditingController();

  Commande? commandeSelectionnee;

  double totalPaye = 0;
  double resteAPayer = 0;

  String statutPaiement = 'Non payé';

  String modePaiement = 'Espèces';

  bool chargement = true;
  bool enregistrement = false;

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  @override
  void dispose() {
    rechercheController.dispose();
    montantController.dispose();
    super.dispose();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> chargerDonnees() async {
    final idSelectionne =
        commandeSelectionnee?.id;

    try {
      final nouvellesCommandes =
          await CommandeService.instance
              .getCommandes();

      final nouveauxPaiements =
          await PaiementService.instance
              .getPaiements();

      Commande? commandeRechargee;

      if (idSelectionne != null) {
        try {
          commandeRechargee =
              nouvellesCommandes.firstWhere(
            (commande) =>
                commande.id == idSelectionne,
          );
        } catch (_) {
          commandeRechargee = null;
        }
      }

      if (!mounted) return;

      setState(() {
        commandes = nouvellesCommandes;

        paiements = nouveauxPaiements;

        paiementsFiltres =
            List<Paiement>.from(
          nouveauxPaiements,
        );

        commandeSelectionnee =
            commandeRechargee;

        chargement = false;
      });

      if (commandeSelectionnee != null) {
        await calculerPaiement();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        chargement = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du chargement : $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // RECHERCHE
  // ============================================================

  void rechercherPaiement(
    String valeur,
  ) {
    final recherche =
        valeur.trim().toLowerCase();

    setState(() {
      if (recherche.isEmpty) {
        paiementsFiltres =
            List<Paiement>.from(
          paiements,
        );

        return;
      }

      paiementsFiltres =
          paiements.where(
        (paiement) {
          return paiement.commandeId
                  .toString()
                  .contains(recherche) ||
              paiement.modePaiement
                  .toLowerCase()
                  .contains(recherche) ||
              paiement.date
                  .toLowerCase()
                  .contains(recherche);
        },
      ).toList();
    });
  }

  // ============================================================
  // SITUATION DU PAIEMENT
  // ============================================================

  Future<void> calculerPaiement() async {
    final commande =
        commandeSelectionnee;

    if (commande == null) {
      if (!mounted) return;

      setState(() {
        totalPaye = 0;
        resteAPayer = 0;
        statutPaiement =
            'Non payé';
      });

      return;
    }

    try {
      final situation =
          await PaiementService.instance
              .calculerSituation(
        commande,
      );

      if (!mounted) return;

      setState(() {
        totalPaye =
            situation.totalPaye;

        resteAPayer =
            situation.resteAPayer;

        statutPaiement =
            situation.statut;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de calculer le paiement : $e',
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // ENREGISTRER UN PAIEMENT
  // ============================================================

  Future<void> enregistrerPaiement() async {
    final commande =
        commandeSelectionnee;

    if (commande == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez sélectionner une commande.',
          ),
        ),
      );

      return;
    }

    final texteMontant =
        montantController.text
            .trim()
            .replaceAll(',', '.');

    final montant =
        double.tryParse(
      texteMontant,
    );

    if (montant == null ||
        montant <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez saisir un montant valide.',
          ),
        ),
      );

      return;
    }

    setState(() {
      enregistrement = true;
    });

    PaiementEnregistreResultat resultat;

    // ----------------------------------------------------------
    // ENREGISTREMENT MÉTIER
    // ----------------------------------------------------------

    try {
      resultat =
          await PaiementService.instance
              .enregistrerPaiement(
        commande: commande,
        montant: montant,
        modePaiement: modePaiement,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        enregistrement = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
          backgroundColor:
              Colors.red,
        ),
      );

      return;
    }

    if (!mounted) return;

    setState(() {
      totalPaye =
          resultat.situation.totalPaye;

      resteAPayer =
          resultat.situation.resteAPayer;

      statutPaiement =
          resultat.situation.statut;
    });

    // ----------------------------------------------------------
    // GÉNÉRATION DU REÇU
    //
    // Le paiement est déjà sauvegardé à ce stade.
    // Une erreur PDF ne doit donc pas faire croire
    // que le paiement a échoué.
    // ----------------------------------------------------------

    String? erreurPdf;

    try {
      final client =
          await DatabaseHelper.instance
              .getClientById(
        commande.clientId,
      );

      final details =
          await CommandeService.instance
              .getDetailsCommande(
        commande.id!,
      );

      final parametre =
          await DatabaseHelper.instance
              .getParametre();

      await PdfService.genererRecu(
        nomPressing:
            parametre?.nomPressing ??
                'Life Pressing',

        adresse:
            parametre?.adresse ?? '',

        email:
            parametre?.email ?? '',

        client: client == null
            ? 'Client inconnu'
            : '${client.nom} ${client.prenom}',

        telephone: client == null
            ? '-'
            : client.telephone,

        numeroCommande:
            commande.id!,

        date:
            resultat.paiement.date,

        modePaiement:
            resultat
                .paiement.modePaiement,

        articles: details,

        montant: montant,

        montantCommande:
            commande.total,

        paiementEffectue:
            montant,

        totalPaye:
            resultat
                .situation.totalPaye,

        resteAPayer:
            resultat
                .situation.resteAPayer,
      );
    } catch (e) {
      erreurPdf = e.toString();
    }

    montantController.clear();

    await chargerDonnees();

    if (!mounted) return;

    setState(() {
      enregistrement = false;
    });

    if (erreurPdf == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Paiement enregistré avec succès.',
          ),
          backgroundColor:
              Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Paiement enregistré, mais le reçu PDF '
            'n’a pas pu être généré.',
          ),
          backgroundColor:
              Colors.orange,
        ),
      );
    }
  }

  // ============================================================
  // COULEUR DU STATUT DE PAIEMENT
  // ============================================================

  Color couleurStatutPaiement() {
    switch (statutPaiement) {
      case 'Payé':
        return Colors.green;

      case 'Partiellement payé':
        return Colors.orange;

      default:
        return Colors.red;
    }
  }

  // ============================================================
  // INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Paiements'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed:
                chargerDonnees,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: chargement
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                children: [
                  // =============================================
                  // COMMANDE
                  // =============================================

                  DropdownButtonFormField<
                      Commande>(
                    key: ValueKey(
                      commandeSelectionnee
                              ?.id ??
                          'aucune',
                    ),
                    initialValue:
                        commandeSelectionnee,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Commande',
                      border:
                          OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.receipt_long,
                      ),
                    ),
                    items:
                        commandes.map(
                      (commande) {
                        return DropdownMenuItem<
                            Commande>(
                          value:
                              commande,
                          child: Text(
                            'Commande '
                            '#${commande.id} - '
                            '${commande.total.toStringAsFixed(0)} FCFA',
                          ),
                        );
                      },
                    ).toList(),
                    onChanged:
                        (commande) async {
                      setState(() {
                        commandeSelectionnee =
                            commande;

                        totalPaye = 0;
                        resteAPayer = 0;
                        statutPaiement =
                            'Non payé';
                      });

                      await calculerPaiement();
                    },
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  // =============================================
                  // RÉSUMÉ
                  // =============================================

                  if (commandeSelectionnee !=
                      null)
                    Card(
                      color:
                          Colors.blue.shade50,
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                const Text(
                                  'Montant de la commande',
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                Text(
                                  '${commandeSelectionnee!.total.toStringAsFixed(0)} FCFA',
                                ),
                              ],
                            ),

                            const Divider(),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                const Text(
                                  'Total payé',
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                Text(
                                  '${totalPaye.toStringAsFixed(0)} FCFA',
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.green,
                                  ),
                                ),
                              ],
                            ),

                            const Divider(),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                const Text(
                                  'Reste à payer',
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                Text(
                                  '${resteAPayer.toStringAsFixed(0)} FCFA',
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color:
                                        resteAPayer >
                                                0
                                            ? Colors.red
                                            : Colors.green,
                                  ),
                                ),
                              ],
                            ),

                            const Divider(),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                const Text(
                                  'Statut du paiement',
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                Chip(
                                  label: Text(
                                    statutPaiement,
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,
                                    ),
                                  ),
                                  backgroundColor:
                                      couleurStatutPaiement(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(
                    height: 15,
                  ),

                  // =============================================
                  // MONTANT
                  // =============================================

                  TextField(
                    controller:
                        montantController,
                    enabled:
                        commandeSelectionnee !=
                                null &&
                            resteAPayer > 0,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    decoration:
                        InputDecoration(
                      labelText:
                          'Montant payé',
                      border:
                          const OutlineInputBorder(),
                      prefixIcon:
                          const Icon(
                        Icons.payments,
                      ),
                      suffixText:
                          'FCFA',
                      helperText:
                          commandeSelectionnee ==
                                  null
                              ? 'Sélectionnez d’abord une commande'
                              : resteAPayer <=
                                      0
                                  ? 'Commande entièrement payée'
                                  : 'Maximum : ${resteAPayer.toStringAsFixed(0)} FCFA',
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  // =============================================
                  // MODE DE PAIEMENT
                  // =============================================

                  DropdownButtonFormField<
                      String>(
                    initialValue:
                        modePaiement,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Mode de paiement',
                      border:
                          OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons
                            .account_balance_wallet,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value:
                            'Espèces',
                        child:
                            Text('Espèces'),
                      ),
                      DropdownMenuItem(
                        value:
                            'Orange Money',
                        child: Text(
                          'Orange Money',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Wave',
                        child:
                            Text('Wave'),
                      ),
                      DropdownMenuItem(
                        value:
                            'Carte bancaire',
                        child: Text(
                          'Carte bancaire',
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        modePaiement =
                            value;
                      });
                    },
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          enregistrement
                              ? null
                              : enregistrerPaiement,
                      icon: enregistrement
                          ? const SizedBox(
                              width: 18,
                              height: 18,
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
                            : 'Enregistrer le paiement',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Divider(),

                  const Text(
                    'Historique des paiements',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  TextField(
                    controller:
                        rechercheController,
                    onChanged:
                        rechercherPaiement,
                    decoration:
                        const InputDecoration(
                      hintText:
                          'Rechercher un paiement...',
                      prefixIcon:
                          Icon(Icons.search),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  // =============================================
                  // HISTORIQUE
                  // =============================================

                  Expanded(
                    child:
                        paiementsFiltres.isEmpty
                            ? const Center(
                                child: Text(
                                  'Aucun paiement enregistré',
                                ),
                              )
                            : ListView.builder(
                                itemCount:
                                    paiementsFiltres
                                        .length,
                                itemBuilder:
                                    (context,
                                        index) {
                                  final paiement =
                                      paiementsFiltres[
                                          index];

                                  return FutureBuilder<
                                      Commande?>(
                                    future: CommandeService
                                        .instance
                                        .getCommandeById(
                                      paiement
                                          .commandeId,
                                    ),
                                    builder:
                                        (context,
                                            commandeSnapshot) {
                                      if (commandeSnapshot
                                              .connectionState ==
                                          ConnectionState
                                              .waiting) {
                                        return const Card(
                                          child:
                                              ListTile(
                                            title:
                                                Text(
                                              'Chargement...',
                                            ),
                                          ),
                                        );
                                      }

                                      final commande =
                                          commandeSnapshot
                                              .data;

                                      if (commande ==
                                          null) {
                                        return const SizedBox
                                            .shrink();
                                      }

                                      return FutureBuilder(
                                        future: DatabaseHelper
                                            .instance
                                            .getClientById(
                                          commande
                                              .clientId,
                                        ),
                                        builder:
                                            (context,
                                                clientSnapshot) {
                                          if (clientSnapshot
                                                  .connectionState ==
                                              ConnectionState
                                                  .waiting) {
                                            return const Card(
                                              child:
                                                  ListTile(
                                                title:
                                                    Text(
                                                  'Chargement...',
                                                ),
                                              ),
                                            );
                                          }

                                          final client =
                                              clientSnapshot
                                                  .data;

                                          return Card(
                                            margin:
                                                const EdgeInsets
                                                    .only(
                                              bottom:
                                                  10,
                                            ),
                                            child:
                                                ListTile(
                                              leading:
                                                  const CircleAvatar(
                                                child:
                                                    Icon(
                                                  Icons
                                                      .payments,
                                                ),
                                              ),
                                              title:
                                                  Text(
                                                client ==
                                                        null
                                                    ? 'Client inconnu'
                                                    : '${client.nom} ${client.prenom}',
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                              subtitle:
                                                  Text(
                                                'Commande #${paiement.commandeId}\n'
                                                '${paiement.modePaiement}\n'
                                                '${paiement.date}',
                                              ),
                                              trailing:
                                                  Text(
                                                '${paiement.montant.toStringAsFixed(0)} FCFA',
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color:
                                                      Colors.green,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
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