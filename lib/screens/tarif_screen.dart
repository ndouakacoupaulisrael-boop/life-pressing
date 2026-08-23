import 'package:flutter/material.dart';

import '../models/tarif.dart';
import '../services/tarif_service.dart';

class TarifScreen extends StatefulWidget {
  const TarifScreen({super.key});

  @override
  State<TarifScreen> createState() => _TarifScreenState();
}

class _TarifScreenState extends State<TarifScreen> {
  List<Tarif> tarifs = [];
  bool chargement = true;

  @override
  void initState() {
    super.initState();
    chargerTarifs();
  }

  Future<void> chargerTarifs() async {
    final resultats =
        await TarifService.instance.getTarifs();

    if (!mounted) return;

    setState(() {
      tarifs = resultats;
      chargement = false;
    });
  }

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
Future<void> ouvrirFormulaireTarif() async {
  final formKey = GlobalKey<FormState>();

  final nomController = TextEditingController();
  final valeurController = TextEditingController();

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
                      TextFormField(
                        controller: nomController,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          hintText: 'Exemple : Stoppage',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Saisissez un nom.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

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

                      TextFormField(
                        controller: valeurController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Valeur',
                          hintText: modeCalcul == 'fixe'
                              ? 'Exemple : 1000'
                              : modeCalcul == 'pourcentage'
                                  ? 'Exemple : 25'
                                  : 'Exemple : 2',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final valeur = double.tryParse(
                            value
                                    ?.trim()
                                    .replaceAll(',', '.') ??
                                '',
                          );

                          if (valeur == null || valeur <= 0) {
                            return 'Saisissez une valeur valide.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 10),

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
                  if (!(formKey.currentState?.validate() ??
                      false)) {
                    return;
                  }

                  final valeur = double.parse(
                    valeurController.text
                        .trim()
                        .replaceAll(',', '.'),
                  );

                  await TarifService.instance.ajouterTarif(
                    Tarif(
                      nom: nomController.text.trim(),
                      type: type,
                      modeCalcul: modeCalcul,
                      valeur: valeur,
                      actif: actif,
                    ),
                  );

                  if (!dialogContext.mounted) return;

                  Navigator.pop(dialogContext);

                  await chargerTarifs();
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
Future<void> ouvrirFormulaireModification(
  Tarif tarif,
) async {
  final formKey = GlobalKey<FormState>();

  final nomController = TextEditingController(
    text: tarif.nom,
  );

  final valeurController = TextEditingController(
    text: tarif.valeur.toStringAsFixed(0),
  );

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
                      TextFormField(
                        controller: nomController,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Saisissez un nom.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

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

                      TextFormField(
                        controller: valeurController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valeur',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final nombre = double.tryParse(
                            value
                                    ?.trim()
                                    .replaceAll(',', '.') ??
                                '',
                          );

                          if (nombre == null || nombre <= 0) {
                            return 'Saisissez une valeur valide.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 10),

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
                  if (!(formKey.currentState?.validate() ??
                      false)) {
                    return;
                  }

                  final valeur = double.parse(
                    valeurController.text
                        .trim()
                        .replaceAll(',', '.'),
                  );

                  await TarifService.instance.modifierTarif(
                    Tarif(
                      id: tarif.id,
                      nom: nomController.text.trim(),
                      type: type,
                      modeCalcul: modeCalcul,
                      valeur: valeur,
                      actif: actif,
                    ),
                  );

                  if (!dialogContext.mounted) return;

                  Navigator.pop(dialogContext);

                  await chargerTarifs();
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarifs et services'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: chargerTarifs,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: chargement
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : tarifs.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun tarif enregistré.',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tarifs.length,
                  itemBuilder: (context, index) {
                    final tarif = tarifs[index];

                    return Card(
                      child: ListTile(
                          onTap: () {
      ouvrirFormulaireModification(tarif);
    },
                        leading: const CircleAvatar(
                          child: Icon(
                            Icons.payments_outlined,
                          ),
                        ),
                        title: Text(
                          tarif.nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${tarif.type} • ${tarif.modeCalcul}',
                        ),
                        trailing: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Text(
                              afficherValeur(tarif),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              tarif.actif
                                  ? 'Actif'
                                  : 'Inactif',
                              style: TextStyle(
                                color: tarif.actif
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
  onPressed: ouvrirFormulaireTarif,
  child: const Icon(Icons.add),
),
    );
  }
}