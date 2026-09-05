import 'package:flutter/material.dart';

import '../models/tarif.dart';
import '../models/vetement.dart';
import '../repositories/vetement_repository.dart';
import '../services/tarif_service.dart';

class TarifScreen extends StatefulWidget {
  const TarifScreen({super.key});

  @override
  State<TarifScreen> createState() => _TarifScreenState();
}

class _TarifScreenState extends State<TarifScreen> {
  List<Tarif> tarifs = [];
  List<Vetement> vetements = [];

  bool chargement = true;

  final VetementRepository vetementRepository = VetementRepository();

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> chargerDonnees() async {
    final resultatsTarifs = await TarifService.instance.getTarifs();

    final resultatsVetements = await vetementRepository.getVetements();

    if (!mounted) return;

    setState(() {
      tarifs = resultatsTarifs;
      vetements = resultatsVetements;
      chargement = false;
    });
  }

  Future<void> chargerTarifs() async {
    final resultats = await TarifService.instance.getTarifs();

    if (!mounted) return;

    setState(() {
      tarifs = resultats;
      chargement = false;
    });
  }

  // ============================================================
  // AFFICHAGE
  // ============================================================

  String afficherValeur(Tarif tarif) {
    switch (tarif.modeCalcul) {
      case 'multiplicateur':
        return '×${tarif.valeur.toStringAsFixed(0)}';

      case 'pourcentage':
        return '+${tarif.valeur.toStringAsFixed(0)} %';

      default:
        return '${tarif.valeur.toStringAsFixed(0)} F CFA';
    }
  }

  String nomVetement(int? vetementId) {
    if (vetementId == null) {
      return 'Tarif général';
    }

    for (final vetement in vetements) {
      if (vetement.id == vetementId) {
        return vetement.nom;
      }
    }

    return 'Vêtement inconnu';
  }

  String afficherType(String type) {
    switch (type) {
      case 'supplement':
        return 'Supplément';

      case 'option':
        return 'Option';

      default:
        return 'Service';
    }
  }

  String afficherModeCalcul(String modeCalcul) {
    switch (modeCalcul) {
      case 'pourcentage':
        return 'Pourcentage';

      case 'multiplicateur':
        return 'Multiplicateur';

      default:
        return 'Montant fixe';
    }
  }

  // ============================================================
  // AJOUT
  // ============================================================

  Future<void> ouvrirFormulaireTarif() async {
    final formKey = GlobalKey<FormState>();

    final nomController = TextEditingController();
    final valeurController = TextEditingController();

    // -1 = aucun vêtement / tarif général
    int vetementSelectionne = -1;

    String type = 'service';
    String modeCalcul = 'fixe';
    bool actif = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ajouter un tarif'),
              content: SizedBox(
                width: 450,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // =========================================
                        // VÊTEMENT
                        // =========================================
                        DropdownButtonFormField<int>(
                          initialValue: vetementSelectionne,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Vêtement',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: -1,
                              child: Text('Tarif général / Aucun vêtement'),
                            ),
                            ...vetements
                                .where((vetement) => vetement.id != null)
                                .map(
                                  (vetement) => DropdownMenuItem<int>(
                                    value: vetement.id!,
                                    child: Text(
                                      vetement.nom,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              vetementSelectionne = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // =========================================
                        // NOM
                        // =========================================
                        TextFormField(
                          controller: nomController,
                          decoration: const InputDecoration(
                            labelText: 'Nom du tarif',
                            hintText: 'Exemple : Lin, Soie, Lavage à sec...',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Saisissez un nom.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // =========================================
                        // TYPE
                        // =========================================
                        DropdownButtonFormField<String>(
                          initialValue: type,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'service',
                              child: Text('Service'),
                            ),
                            DropdownMenuItem(
                              value: 'supplement',
                              child: Text('Supplément'),
                            ),
                            DropdownMenuItem(
                              value: 'option',
                              child: Text('Option'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              type = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // =========================================
                        // MODE DE CALCUL
                        // =========================================
                        DropdownButtonFormField<String>(
                          initialValue: modeCalcul,
                          decoration: const InputDecoration(
                            labelText: 'Mode de calcul',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'fixe',
                              child: Text('Montant fixe'),
                            ),
                            DropdownMenuItem(
                              value: 'pourcentage',
                              child: Text('Pourcentage'),
                            ),
                            DropdownMenuItem(
                              value: 'multiplicateur',
                              child: Text('Multiplicateur'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              modeCalcul = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // =========================================
                        // VALEUR
                        // =========================================
                        TextFormField(
                          controller: valeurController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Valeur',
                            hintText: modeCalcul == 'fixe'
                                ? 'Exemple : 200'
                                : modeCalcul == 'pourcentage'
                                ? 'Exemple : 25'
                                : 'Exemple : 2',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final valeur = double.tryParse(
                              value?.trim().replaceAll(',', '.') ?? '',
                            );

                            if (valeur == null || valeur <= 0) {
                              return 'Saisissez une valeur valide.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 10),

                        // =========================================
                        // ACTIF
                        // =========================================
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Tarif actif'),
                          subtitle: Text(
                            actif
                                ? 'Ce tarif pourra être utilisé.'
                                : 'Ce tarif sera désactivé.',
                          ),
                          value: actif,
                          onChanged: (value) {
                            setDialogState(() {
                              actif = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    final valeur = double.parse(
                      valeurController.text.trim().replaceAll(',', '.'),
                    );

                    // -1 devient null dans la base
                    final int? vetementId = vetementSelectionne == -1
                        ? null
                        : vetementSelectionne;

                    try {
                      await TarifService.instance.ajouterTarif(
                        Tarif(
                          vetementId: vetementId,
                          nom: nomController.text.trim(),
                          type: type,
                          modeCalcul: modeCalcul,
                          valeur: valeur,
                          actif: actif,
                        ),
                      );

                      if (!dialogContext.mounted) {
                        return;
                      }

                      Navigator.pop(dialogContext);

                      await chargerTarifs();

                      if (!mounted) return;

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Tarif ajouté avec succès.'),
                        ),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    nomController.dispose();
    valeurController.dispose();
  }

  // ============================================================
  // MODIFICATION
  // ============================================================

  Future<void> ouvrirFormulaireModification(Tarif tarif) async {
    final formKey = GlobalKey<FormState>();

    final nomController = TextEditingController(text: tarif.nom);

    final valeurController = TextEditingController(
      text: tarif.valeur.toStringAsFixed(0),
    );

    // null dans la DB = -1 dans le Dropdown
    int vetementSelectionne = tarif.vetementId ?? -1;

    String type = tarif.type;
    String modeCalcul = tarif.modeCalcul;
    bool actif = tarif.actif;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifier le tarif'),
              content: SizedBox(
                width: 450,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // =========================================
                        // VÊTEMENT
                        // =========================================
                        DropdownButtonFormField<int>(
                          initialValue: vetementSelectionne,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Vêtement',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: -1,
                              child: Text('Tarif général / Aucun vêtement'),
                            ),
                            ...vetements
                                .where((vetement) => vetement.id != null)
                                .map(
                                  (vetement) => DropdownMenuItem<int>(
                                    value: vetement.id!,
                                    child: Text(
                                      vetement.nom,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              vetementSelectionne = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // =========================================
                        // NOM
                        // =========================================
                        TextFormField(
                          controller: nomController,
                          decoration: const InputDecoration(
                            labelText: 'Nom du tarif',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Saisissez un nom.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // =========================================
                        // TYPE
                        // =========================================
                        DropdownButtonFormField<String>(
                          initialValue: type,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'service',
                              child: Text('Service'),
                            ),
                            DropdownMenuItem(
                              value: 'supplement',
                              child: Text('Supplément'),
                            ),
                            DropdownMenuItem(
                              value: 'option',
                              child: Text('Option'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              type = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // =========================================
                        // MODE DE CALCUL
                        // =========================================
                        DropdownButtonFormField<String>(
                          initialValue: modeCalcul,
                          decoration: const InputDecoration(
                            labelText: 'Mode de calcul',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'fixe',
                              child: Text('Montant fixe'),
                            ),
                            DropdownMenuItem(
                              value: 'pourcentage',
                              child: Text('Pourcentage'),
                            ),
                            DropdownMenuItem(
                              value: 'multiplicateur',
                              child: Text('Multiplicateur'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              modeCalcul = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // =========================================
                        // VALEUR
                        // =========================================
                        TextFormField(
                          controller: valeurController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Valeur',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final nombre = double.tryParse(
                              value?.trim().replaceAll(',', '.') ?? '',
                            );

                            if (nombre == null || nombre <= 0) {
                              return 'Saisissez une valeur valide.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 10),

                        // =========================================
                        // ACTIF
                        // =========================================
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Tarif actif'),
                          value: actif,
                          onChanged: (value) {
                            setDialogState(() {
                              actif = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    final valeur = double.parse(
                      valeurController.text.trim().replaceAll(',', '.'),
                    );

                    final int? vetementId = vetementSelectionne == -1
                        ? null
                        : vetementSelectionne;

                    try {
                      await TarifService.instance.modifierTarif(
                        Tarif(
                          id: tarif.id,
                          vetementId: vetementId,
                          nom: nomController.text.trim(),
                          type: type,
                          modeCalcul: modeCalcul,
                          valeur: valeur,
                          actif: actif,
                        ),
                      );

                      if (!dialogContext.mounted) {
                        return;
                      }

                      Navigator.pop(dialogContext);

                      await chargerTarifs();

                      if (!mounted) return;

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Tarif modifié avec succès.'),
                        ),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    nomController.dispose();
    valeurController.dispose();
  }

  // ============================================================
  // INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarifs et services'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: chargerDonnees,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: chargement
          ? const Center(child: CircularProgressIndicator())
          : tarifs.isEmpty
          ? const Center(child: Text('Aucun tarif enregistré.'))
          : RefreshIndicator(
              onRefresh: chargerDonnees,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tarifs.length,
                itemBuilder: (context, index) {
                  final tarif = tarifs[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      onTap: () {
                        ouvrirFormulaireModification(tarif);
                      },
                      leading: CircleAvatar(
                        child: Icon(
                          tarif.type == 'supplement'
                              ? Icons.add_circle_outline
                              : tarif.type == 'option'
                              ? Icons.tune
                              : Icons.payments_outlined,
                        ),
                      ),
                      title: Text(
                        tarif.nom,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${nomVetement(tarif.vetementId)}'
                        ' • ${afficherType(tarif.type)}'
                        ' • ${afficherModeCalcul(tarif.modeCalcul)}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            afficherValeur(tarif),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tarif.actif ? 'Actif' : 'Inactif',
                            style: TextStyle(
                              color: tarif.actif ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: ouvrirFormulaireTarif,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}
