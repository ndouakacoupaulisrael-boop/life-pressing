import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../models/charge.dart';
import '../services/charge_service.dart';
import '../services/session_service.dart';

class ChargeScreen extends StatefulWidget {
  const ChargeScreen({super.key});

  @override
  State<ChargeScreen> createState() => _ChargeScreenState();
}

class _ChargeScreenState extends State<ChargeScreen> {
  final ChargeService _service = ChargeService.instance;

  List<Charge> _charges = [];

  bool _chargement = true;
  String? _erreur;

  double _totalCharges = 0;
  double _totalMois = 0;

  static const List<String> _categories = [
    'Électricité',
    'Eau',
    'Loyer',
    'Salaires',
    'Transport',
    'Produits',
    'Entretien',
    'Matériel',
    'Internet',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();

    if (SessionService.estProprietaire) {
      _charger();
    } else {
      _chargement = false;
    }
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _charger() async {
    if (!SessionService.estProprietaire) {
      return;
    }

    if (mounted) {
      setState(() {
        _chargement = true;
        _erreur = null;
      });
    }

    try {
      final charges = await _service.getCharges();
      final total = await _service.getTotalCharges();
      final totalMois = await _service.getTotalChargesMois();

      if (!mounted) return;

      setState(() {
        _charges = charges;
        _totalCharges = total;
        _totalMois = totalMois;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erreur = e.toString().replaceFirst('Exception: ', '');

        _chargement = false;
      });
    }
  }

  // ============================================================
  // FORMATAGE
  // ============================================================

  String _formatMontant(double montant) {
    return '${montant.toStringAsFixed(0)} FCFA';
  }

  String _formatDate(String date) {
    final parsed = DateTime.tryParse(date);

    if (parsed == null) {
      return date;
    }

    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/'
        '${parsed.year}';
  }

  // ============================================================
  // AJOUT
  // ============================================================

  Future<void> _ajouterCharge() async {
    final resultat = await _ouvrirFormulaire();

    if (resultat == null) {
      return;
    }

    try {
      await _service.ajouterCharge(
        libelle: resultat.libelle,
        categorie: resultat.categorie,
        montant: resultat.montant,
        date: resultat.date,
        note: resultat.note,
        pieceJustificativeNom: resultat.pieceJustificativeNom,
        pieceJustificative: resultat.pieceJustificative,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Charge ajoutée avec succès.'),
          backgroundColor: Colors.green,
        ),
      );

      await _charger();
    } catch (e) {
      if (!mounted) return;

      _afficherErreur(e);
    }
  }

  // ============================================================
  // MODIFICATION
  // ============================================================

  Future<void> _modifierCharge(Charge charge) async {
    final resultat = await _ouvrirFormulaire(charge: charge);

    if (resultat == null) {
      return;
    }

    try {
      await _service.modifierCharge(
        charge.copyWith(
          libelle: resultat.libelle,
          categorie: resultat.categorie,
          montant: resultat.montant,
          date: resultat.date,
          note: resultat.note,
          pieceJustificativeNom: resultat.pieceJustificativeNom,
          pieceJustificative: resultat.pieceJustificative,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Charge modifiée avec succès.'),
          backgroundColor: Colors.green,
        ),
      );

      await _charger();
    } catch (e) {
      if (!mounted) return;

      _afficherErreur(e);
    }
  }

  // ============================================================
  // SUPPRESSION
  // ============================================================

  Future<void> _supprimerCharge(Charge charge) async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer la charge'),
          content: Text(
            'Voulez-vous supprimer '
            '"${charge.libelle}" '
            '(${_formatMontant(charge.montant)}) ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmer != true) {
      return;
    }

    try {
      await _service.supprimerCharge(charge);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Charge supprimée.')));

      await _charger();
    } catch (e) {
      if (!mounted) return;

      _afficherErreur(e);
    }
  }

  // ============================================================
  // ERREUR
  // ============================================================

  void _afficherErreur(Object erreur) {
    final message = erreur.toString().replaceFirst('Exception: ', '');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ============================================================
  // FORMULAIRE
  // ============================================================

  Future<_ChargeFormResult?> _ouvrirFormulaire({Charge? charge}) async {
    final libelleController = TextEditingController(
      text: charge?.libelle ?? '',
    );

    final montantController = TextEditingController(
      text: charge == null ? '' : charge.montant.toStringAsFixed(0),
    );

    final noteController = TextEditingController(text: charge?.note ?? '');

    String categorie = charge?.categorie ?? _categories.first;

    DateTime date = DateTime.tryParse(charge?.date ?? '') ?? DateTime.now();

    String? pieceNom = charge?.pieceJustificativeNom;

    Uint8List? pieceOctets = charge?.pieceJustificative;

    final resultat = await showDialog<_ChargeFormResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final dateTexte =
                '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}/'
                '${date.year}';

            Future<void> choisirPieceJustificative() async {
              try {
                const typeGroup = XTypeGroup(
                  label: 'Pièces justificatives',
                  extensions: ['pdf', 'jpg', 'jpeg', 'png'],
                );

                final XFile? fichier = await openFile(
                  acceptedTypeGroups: const [typeGroup],
                );

                if (fichier == null) {
                  debugPrint('Aucun fichier sélectionné');
                  return;
                }

                debugPrint('Fichier sélectionné : ${fichier.name}');

                final bytes = await fichier.readAsBytes();

                debugPrint('Taille : ${bytes.length} octets');

                const tailleMax = 5 * 1024 * 1024;

                if (bytes.length > tailleMax) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'La pièce justificative '
                        'ne doit pas dépasser 5 Mo.',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );

                  return;
                }

                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  pieceNom = fichier.name;
                  pieceOctets = bytes;
                });

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Pièce sélectionnée : ${fichier.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e, stackTrace) {
                debugPrint('ERREUR SÉLECTION FICHIER : $e');

                debugPrint(stackTrace.toString());

                if (!dialogContext.mounted) {
                  return;
                }

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Impossible de sélectionner '
                      'le fichier : $e',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return AlertDialog(
              title: Text(
                charge == null ? 'Ajouter une charge' : 'Modifier la charge',
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: libelleController,
                        decoration: const InputDecoration(
                          labelText: 'Libellé',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                      ),

                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        initialValue: categorie,
                        decoration: const InputDecoration(
                          labelText: 'Catégorie',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categories
                            .map(
                              (categorie) => DropdownMenuItem<String>(
                                value: categorie,
                                child: Text(categorie),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          categorie = value;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: montantController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Montant',
                          suffixText: 'FCFA',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_month),
                          title: const Text('Date'),
                          subtitle: Text(dateTexte),
                          trailing: const Icon(Icons.edit),
                          onTap: () async {
                            final nouvelleDate = await showDatePicker(
                              context: dialogContext,
                              initialDate: date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );

                            if (nouvelleDate == null) {
                              return;
                            }

                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              date = nouvelleDate;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ===========================
                      // PIÈCE JUSTIFICATIVE
                      // ===========================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Pièce justificative',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 5),

                            const Text(
                              'PDF, JPG ou PNG '
                              '(5 Mo maximum)',
                              style: TextStyle(color: Colors.grey),
                            ),

                            const SizedBox(height: 10),

                            OutlinedButton.icon(
                              onPressed: choisirPieceJustificative,
                              icon: const Icon(Icons.attach_file),
                              label: Text(
                                pieceNom == null
                                    ? 'Ajouter une pièce justificative'
                                    : 'Changer la pièce justificative',
                              ),
                            ),

                            if (pieceNom != null) ...[
                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.description_outlined,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      pieceNom!,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Note facultative',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                    ],
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
                  onPressed: () {
                    final libelle = libelleController.text.trim();

                    final montantTexte = montantController.text
                        .trim()
                        .replaceAll(',', '.');

                    final montant = double.tryParse(montantTexte);

                    if (libelle.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Le libellé '
                            'est obligatoire.',
                          ),
                        ),
                      );

                      return;
                    }

                    if (montant == null || montant <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Saisissez un '
                            'montant valide.',
                          ),
                        ),
                      );

                      return;
                    }

                    final dateIso =
                        '${date.year}-'
                        '${date.month.toString().padLeft(2, '0')}-'
                        '${date.day.toString().padLeft(2, '0')}';

                    Navigator.pop(
                      dialogContext,
                      _ChargeFormResult(
                        libelle: libelle,
                        categorie: categorie,
                        montant: montant,
                        date: dateIso,
                        note: noteController.text.trim(),
                        pieceJustificativeNom: pieceNom,
                        pieceJustificative: pieceOctets,
                      ),
                    );
                  },
                  child: Text(charge == null ? 'Ajouter' : 'Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    libelleController.dispose();
    montantController.dispose();
    noteController.dispose();

    return resultat;
  }

  // ============================================================
  // RÉSUMÉ
  // ============================================================

  Widget _buildResume() {
    return Row(
      children: [
        Expanded(
          child: _buildResumeCard(
            titre: 'Charges du mois',
            montant: _totalMois,
            icon: Icons.calendar_month,
            couleur: Colors.orange,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildResumeCard(
            titre: 'Total charges',
            montant: _totalCharges,
            icon: Icons.payments,
            couleur: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildResumeCard({
    required String titre,
    required double montant,
    required IconData icon,
    required Color couleur,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: couleur, size: 30),
            const SizedBox(height: 8),
            Text(titre, textAlign: TextAlign.center),
            const SizedBox(height: 5),
            FittedBox(
              child: Text(
                _formatMontant(montant),
                style: TextStyle(
                  color: couleur,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LISTE
  // ============================================================

  Widget _buildListe() {
    if (_charges.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey),
              SizedBox(height: 12),
              Text('Aucune charge enregistrée.', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 12, bottom: 90),
      itemCount: _charges.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final charge = _charges[index];

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade50,
              child: const Icon(Icons.payments_outlined, color: Colors.orange),
            ),
            title: Text(
              charge.libelle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),

                Text(
                  '${charge.categorie} • '
                  '${_formatDate(charge.date)}',
                ),

                if (charge.pieceJustificativeNom != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.attach_file, size: 16),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          charge.pieceJustificativeNom!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                if (charge.note.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    charge.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMontant(charge.montant),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),

                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'modifier') {
                      _modifierCharge(charge);
                    }

                    if (action == 'supprimer') {
                      _supprimerCharge(charge);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'modifier',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Modifier'),
                      ),
                    ),

                    const PopupMenuItem(
                      value: 'supprimer',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Supprimer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ACCÈS REFUSÉ
  // ============================================================

  Widget _buildAccesRefuse() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 70, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Accès réservé au propriétaire',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Les charges du pressing '
              'contiennent des informations '
              'financières sensibles.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (!SessionService.estProprietaire) {
      return Scaffold(
        appBar: AppBar(title: const Text('Charges'), centerTitle: true),
        body: _buildAccesRefuse(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charges'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _charger,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 55, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(_erreur!),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _charger,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _charger,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildResume(),
                  ),
                  Expanded(child: _buildListe()),
                ],
              ),
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouterCharge,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}

// ============================================================
// RÉSULTAT DU FORMULAIRE
// ============================================================

class _ChargeFormResult {
  final String libelle;
  final String categorie;
  final double montant;
  final String date;
  final String note;

  final String? pieceJustificativeNom;

  final Uint8List? pieceJustificative;

  const _ChargeFormResult({
    required this.libelle,
    required this.categorie,
    required this.montant,
    required this.date,
    required this.note,
    this.pieceJustificativeNom,
    this.pieceJustificative,
  });
}
