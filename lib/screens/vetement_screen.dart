import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/vetement.dart';
import '../services/vetement_service.dart';
class VetementScreen extends StatefulWidget {
  const VetementScreen({super.key});

  @override
  State<VetementScreen> createState() =>
      _VetementScreenState();
}

class _VetementScreenState
    extends State<VetementScreen> {
  final TextEditingController _rechercheController =
      TextEditingController();

  List<Vetement> _vetements = [];
  List<Vetement> _vetementsFiltres = [];

  bool _chargementEnCours = true;
  String? _messageErreur;

  @override
  void initState() {
    super.initState();

    _chargerVetements();

    _rechercheController.addListener(
      _filtrerVetements,
    );
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _chargerVetements() async {
    if (mounted) {
      setState(() {
        _chargementEnCours = true;
        _messageErreur = null;
      });
    }

    try {
     final vetements =
    await VetementService.instance
        .getVetements();

      vetements.sort(
        (a, b) =>
            a.nom.toLowerCase().compareTo(
                  b.nom.toLowerCase(),
                ),
      );

      if (!mounted) return;

      setState(() {
        _vetements = vetements;
        _chargementEnCours = false;
      });

      _filtrerVetements();
    } catch (erreur) {
      debugPrint(
        'Erreur lors du chargement des vêtements : '
        '$erreur',
      );

      if (!mounted) return;

      setState(() {
        _chargementEnCours = false;
        _messageErreur =
            'Impossible de charger les vêtements.';
      });
    }
  }

  // ============================================================
  // RECHERCHE
  // ============================================================

  void _filtrerVetements() {
    final recherche =
        _rechercheController.text
            .trim()
            .toLowerCase();

    if (!mounted) return;

    setState(() {
      if (recherche.isEmpty) {
        _vetementsFiltres =
            List<Vetement>.from(
          _vetements,
        );
      } else {
        _vetementsFiltres =
            _vetements.where((vetement) {
          return vetement.nom
              .toLowerCase()
              .contains(recherche);
        }).toList();
      }
    });
  }

  // ============================================================
  // FORMATAGE
  // ============================================================

  String _formaterMontant(
    double montant,
  ) {
    final texte =
        montant.toStringAsFixed(0);

    return texte.replaceAllMapped(
      RegExp(
        r'\B(?=(\d{3})+(?!\d))',
      ),
      (match) => ' ',
    );
  }

  // ============================================================
  // MESSAGE
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
            ? Colors.red.shade700
            : Colors.green.shade700,
      ),
    );
  }

  // ============================================================
  // DIALOGUE ACTION INTERDITE
  // ============================================================

  Future<void> _afficherActionInterdite({
    required String message,
    required Color couleur,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.lock_rounded,
                color: couleur,
              ),
              const SizedBox(width: 10),
              const Expanded(
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
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // AJOUT / MODIFICATION
  // ============================================================

Future<void> _ouvrirFormulaire({
  Vetement? vetement,
}) async {
  final modification = vetement != null;

  final formulaireKey =
      GlobalKey<FormState>();

  final nomController =
      TextEditingController(
    text: vetement?.nom ?? '',
  );

  final prixController =
      TextEditingController(
    text: vetement == null
        ? ''
        : vetement.prix
            .toStringAsFixed(0),
  );

  if (!mounted) {
    nomController.dispose();
    prixController.dispose();
    return;
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      bool enregistrementEnCours =
          false;

      return StatefulBuilder(
        builder:
            (context, modifierDialogue) {
          Future<void> enregistrer() async {
            if (!(formulaireKey
                    .currentState
                    ?.validate() ??
                false)) {
              return;
            }

            final prixTexte =
                prixController.text
                    .trim()
                    .replaceAll(' ', '')
                    .replaceAll(',', '.');

            final prix =
                double.tryParse(
              prixTexte,
            );

            if (prix == null ||
                prix <= 0) {
              _afficherMessage(
                'Le tarif saisi est invalide.',
                erreur: true,
              );

              return;
            }

            modifierDialogue(() {
              enregistrementEnCours =
                  true;
            });

            try {
              if (modification) {
                final autorise =
                    await VetementService
                        .instance
                        .modifierVetement(
                  vetement: vetement,
                  nouveauNom:
                      nomController.text,
                  nouveauPrix: prix,
                );

                if (!autorise) {
                  if (dialogContext
                      .mounted) {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  }

                  if (!mounted) return;

                  await _afficherActionInterdite(
                    couleur:
                        Colors.orange,
                    message:
                        'Seul le propriétaire peut '
                        'modifier le vêtement '
                        '« ${vetement.nom} ».\n\n'
                        'Cette tentative a été '
                        'enregistrée dans le journal '
                        'de sécurité.',
                  );

                  return;
                }
              } else {
                await VetementService
                    .instance
                    .ajouterVetement(
                  nom:
                      nomController.text,
                  prix: prix,
                );
              }

              if (!dialogContext
                  .mounted) {
                return;
              }

              Navigator.of(
                dialogContext,
              ).pop();

              await _chargerVetements();

              if (!mounted) return;

              _afficherMessage(
                modification
                    ? 'Vêtement modifié avec succès.'
                    : 'Vêtement ajouté avec succès.',
              );
            } catch (erreur) {
              debugPrint(
                'Erreur lors de '
                'l’enregistrement : '
                '$erreur',
              );

              if (dialogContext
                  .mounted) {
                modifierDialogue(() {
                  enregistrementEnCours =
                      false;
                });
              }

              final message =
                  erreur
                      .toString()
                      .replaceFirst(
                        'Exception: ',
                        '',
                      );

              _afficherMessage(
                message,
                erreur: true,
              );
            }
          }

          return AlertDialog(
            title: Text(
              modification
                  ? 'Modifier le vêtement'
                  : 'Ajouter un vêtement',
            ),
            content: SizedBox(
              width: 450,
              child: Form(
                key: formulaireKey,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller:
                          nomController,
                      autofocus: true,
                      textCapitalization:
                          TextCapitalization
                              .sentences,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Nom du vêtement',
                        hintText:
                            'Exemple : Chemise',
                        prefixIcon: Icon(
                          Icons
                              .checkroom_rounded,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                      validator: (valeur) {
                        if (valeur ==
                                null ||
                            valeur
                                .trim()
                                .isEmpty) {
                          return 'Saisissez le nom du vêtement.';
                        }

                        if (valeur
                                .trim()
                                .length <
                            2) {
                          return 'Le nom est trop court.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextFormField(
                      controller:
                          prixController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .allow(
                          RegExp(
                            r'[0-9., ]',
                          ),
                        ),
                      ],
                      decoration:
                          const InputDecoration(
                        labelText: 'Tarif',
                        hintText:
                            'Exemple : 1000',
                        suffixText:
                            'F CFA',
                        prefixIcon: Icon(
                          Icons
                              .payments_rounded,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                      validator: (valeur) {
                        if (valeur ==
                                null ||
                            valeur
                                .trim()
                                .isEmpty) {
                          return 'Saisissez le tarif.';
                        }

                        final texte =
                            valeur
                                .trim()
                                .replaceAll(
                                  ' ',
                                  '',
                                )
                                .replaceAll(
                                  ',',
                                  '.',
                                );

                        final prix =
                            double.tryParse(
                          texte,
                        );

                        if (prix == null ||
                            prix <= 0) {
                          return 'Saisissez un tarif valide.';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    enregistrementEnCours
                        ? null
                        : () {
                            Navigator.of(
                              dialogContext,
                            ).pop();
                          },
                child: const Text(
                  'Annuler',
                ),
              ),

              FilledButton.icon(
                onPressed:
                    enregistrementEnCours
                        ? null
                        : enregistrer,
                icon:
                    enregistrementEnCours
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons
                                .save_rounded,
                          ),
                label: Text(
                  modification
                      ? 'Modifier'
                      : 'Enregistrer',
                ),
              ),
            ],
          );
        },
      );
    },
  );

  nomController.dispose();
  prixController.dispose();
}
  // ============================================================
  // SUPPRESSION
  // ============================================================

 Future<void> _supprimerVetement(
  Vetement vetement,
) async {
  if (vetement.id == null) {
    _afficherMessage(
      'Identifiant du vêtement introuvable.',
      erreur: true,
    );

    return;
  }

  final confirmation =
      await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Supprimer le vêtement',
              ),
            ),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment supprimer '
          '« ${vetement.nom} » ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(false);
            },
            child: const Text(
              'Annuler',
            ),
          ),

          FilledButton.icon(
            style:
                FilledButton.styleFrom(
              backgroundColor:
                  Colors.red.shade700,
              foregroundColor:
                  Colors.white,
            ),
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(true);
            },
            icon: const Icon(
              Icons.delete_rounded,
            ),
            label: const Text(
              'Supprimer',
            ),
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
        await VetementService.instance
            .supprimerVetement(
      vetement,
    );

    if (!mounted) return;

    if (!autorise) {
      await _afficherActionInterdite(
        couleur: Colors.red,
        message:
            'Seul le propriétaire peut '
            'supprimer le vêtement '
            '« ${vetement.nom} ».\n\n'
            'Cette tentative a été enregistrée '
            'dans le journal de sécurité.',
      );

      return;
    }

    await _chargerVetements();

    if (!mounted) return;

    _afficherMessage(
      'Vêtement supprimé avec succès.',
    );
  } catch (erreur) {
    debugPrint(
      'Erreur lors de la suppression : '
      '$erreur',
    );

    final message =
        erreur.toString().replaceFirst(
              'Exception: ',
              '',
            );

    _afficherMessage(
      message,
      erreur: true,
    );
  }
}

  // ============================================================
  // CONTENU
  // ============================================================

  Widget _construireContenu() {
    if (_chargementEnCours) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_messageErreur != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .error_outline_rounded,
                size: 55,
                color: Colors.red,
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                _messageErreur!,
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 16,
              ),

              FilledButton.icon(
                onPressed:
                    _chargerVetements,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'Réessayer',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_vetementsFiltres.isEmpty) {
      final rechercheActive =
          _rechercheController.text
              .trim()
              .isNotEmpty;

      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                rechercheActive
                    ? Icons
                        .search_off_rounded
                    : Icons
                        .checkroom_rounded,
                size: 65,
                color:
                    Colors.grey.shade400,
              ),

              const SizedBox(
                height: 14,
              ),

              Text(
                rechercheActive
                    ? 'Aucun vêtement ne correspond à la recherche.'
                    : 'Aucun vêtement enregistré.',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              if (!rechercheActive) ...[
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'Ajoutez les vêtements '
                  'et leurs tarifs.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _chargerVetements,
      child: ListView.separated(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          110,
        ),
        itemCount:
            _vetementsFiltres.length,
        separatorBuilder:
            (context, index) {
          return const SizedBox(
            height: 10,
          );
        },
        itemBuilder:
            (context, index) {
          final vetement =
              _vetementsFiltres[index];

          return Card(
            elevation: 0,
            color: Colors.white,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              side: BorderSide(
                color:
                    Colors.grey.shade300,
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),

              leading: Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFE8F0FF,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons
                      .checkroom_rounded,
                  color:
                      Color(
                    0xFF2563EB,
                  ),
                ),
              ),

              title: Text(
                vetement.nom,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w700,
                  fontSize: 16,
                ),
              ),

              subtitle: Padding(
                padding:
                    const EdgeInsets.only(
                  top: 5,
                ),
                child: Text(
                  '${_formaterMontant(vetement.prix)} '
                  'F CFA',
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF2563EB,
                    ),
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              trailing:
                  PopupMenuButton<String>(
                tooltip: 'Options',
                onSelected:
                    (valeur) async {
                  if (valeur ==
                      'modifier') {
                    await _ouvrirFormulaire(
                      vetement: vetement,
                    );
                  } else if (valeur ==
                      'supprimer') {
                    await _supprimerVetement(
                      vetement,
                    );
                  }
                },
                itemBuilder:
                    (context) {
                  return const [
                    PopupMenuItem(
                      value: 'modifier',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .edit_rounded,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Modifier',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value:
                          'supprimer',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .delete_rounded,
                            color:
                                Colors.red,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Supprimer',
                            style:
                                TextStyle(
                              color:
                                  Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FB),

      appBar: AppBar(
        title:
            const Text('Vêtements'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed:
                _chargerVetements,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              14,
            ),
            child: Column(
              children: [
                SizedBox(
                  width:
                      double.infinity,
                  child:
                      FilledButton.icon(
                    onPressed: () {
                      _ouvrirFormulaire();
                    },
                    icon: const Icon(
                      Icons.add_rounded,
                    ),
                    label: const Text(
                      'Ajouter un vêtement',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                TextField(
                  controller:
                      _rechercheController,
                  decoration:
                      InputDecoration(
                    hintText:
                        'Rechercher un vêtement...',
                    prefixIcon:
                        const Icon(
                      Icons.search_rounded,
                    ),
                    suffixIcon:
                        _rechercheController
                                .text
                                .isEmpty
                            ? null
                            : IconButton(
                                tooltip:
                                    'Effacer',
                                onPressed:
                                    () {
                                  _rechercheController
                                      .clear();
                                },
                                icon:
                                    const Icon(
                                  Icons
                                      .close_rounded,
                                ),
                              ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child:
                _construireContenu(),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: () {
          _ouvrirFormulaire();
        },
        child: const Icon(
          Icons.add_rounded,
        ),
      ),
    );
  }
}