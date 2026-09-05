import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/commande.dart';
import 'detail_commande_screen.dart';
import 'modifier_commande_screen.dart';
import '../services/pdf_service.dart';
import '../models/vetement.dart';
import '../models/detail_commande.dart';
import '../models/tarif.dart';
import '../repositories/tarif_repository.dart';
import '../services/commande_service.dart';

class CommandeScreen extends StatefulWidget {
  final int refreshSignal;

  const CommandeScreen({super.key, this.refreshSignal = 0});
  @override
  State<CommandeScreen> createState() => _CommandeScreenState();
}

class _CommandeScreenState extends State<CommandeScreen> {
  List<Client> clients = [];
  List<Commande> commandes = [];
  List<Commande> commandesFiltrees = [];
  List<Vetement> vetements = [];
  List<DetailCommande> detailsTemporaires = [];
  List<Tarif> tarifs = [];

  final TarifRepository tarifRepository = TarifRepository();

  Vetement? vetementSelectionne;

  String couleurSelectionnee = "Blanc";
  String matiereSelectionnee = "Standard";
  bool expressSelectionne = false;

  final TextEditingController quantiteController = TextEditingController(
    text: "1",
  );
  final TextEditingController complexiteController = TextEditingController(
    text: "0",
  );

  final List<String> couleurs = [
    "Blanc",
    "Noir",
    "Bleu",
    "Rouge",
    "Vert",
    "Jaune",
    "Gris",
    "Marron",
    "Beige",
    "Rose",
    "Violet",
    "Orange",
    "Multicolore",
    "Autre",
  ];
  final List<String> matieres = ["Standard", "Lin", "Soie", "Laine"];

  final rechercheController = TextEditingController();
  String filtreStatut = "Toutes";

  Client? clientSelectionne;

  String statut = "En attente";

  final TextEditingController dateController = TextEditingController();
  String dateHeureActuelle() {
    final maintenant = DateTime.now();

    return '${maintenant.year.toString().padLeft(4, '0')}-'
        '${maintenant.month.toString().padLeft(2, '0')}-'
        '${maintenant.day.toString().padLeft(2, '0')} '
        '${maintenant.hour.toString().padLeft(2, '0')}:'
        '${maintenant.minute.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();

    dateController.text = dateHeureActuelle();

    chargerDonnees();
  }

  @override
  void didUpdateWidget(covariant CommandeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshSignal != widget.refreshSignal) {
      chargerDonnees();
    }
  }

  Future<void> chargerDonnees() async {
    clients = await DatabaseHelper.instance.getClients();
    commandes = await CommandeService.instance.getCommandes();
    vetements = await DatabaseHelper.instance.getVetements();
    tarifs = await tarifRepository.getTarifs();

    debugPrint("CLIENTS CHARGÉS : ${clients.length}");
    debugPrint("VÊTEMENTS CHARGÉS : ${vetements.length}");
    debugPrint("TARIFS CHARGÉS : ${tarifs.length}");

    for (final client in clients) {
      debugPrint("Client : ${client.nom} ${client.prenom}");
    }

    for (final vetement in vetements) {
      debugPrint("Vêtement : ${vetement.nom} - ${vetement.prix}");
    }

    commandesFiltrees = commandes;

    if (clientSelectionne != null) {
      try {
        clientSelectionne = clients.firstWhere(
          (c) => c.id == clientSelectionne!.id,
        );
      } catch (_) {
        clientSelectionne = null;
      }
    }

    if (vetementSelectionne != null) {
      try {
        vetementSelectionne = vetements.firstWhere(
          (v) => v.id == vetementSelectionne!.id,
        );
      } catch (_) {
        vetementSelectionne = null;
      }
    }

    if (!mounted) return;

    setState(() {});
  }

  void rechercherCommande(String valeur) {
    setState(() {
      if (valeur.trim().isEmpty) {
        commandesFiltrees = commandes;
      } else {
        commandesFiltrees = commandes.where((commande) {
          try {
            final client = clients.firstWhere((c) => c.id == commande.clientId);

            final nomComplet = "${client.nom} ${client.prenom}".toLowerCase();

            return nomComplet.contains(valeur.toLowerCase());
          } catch (_) {
            return false;
          }
        }).toList();
      }
    });
  }

  void filtrerCommandes(String filtre) {
    setState(() {
      filtreStatut = filtre;

      if (filtre == "Toutes") {
        commandesFiltrees = commandes;
      } else {
        commandesFiltrees = commandes
            .where((commande) => commande.statut == filtre)
            .toList();
      }
    });
  }

  Color couleurStatut(String statut) {
    switch (statut) {
      case "En attente":
        return Colors.orange;

      case "En cours":
        return Colors.blue;

      case "Terminée":
        return Colors.green;

      case "Livrée":
        return Colors.teal;

      default:
        return Colors.grey;
    }
  }

  double? prixTarifVetement(int? vetementId) {
    if (vetementId == null) {
      return null;
    }

    try {
      final tarif = tarifs.firstWhere(
        (tarif) =>
            tarif.vetementId == vetementId &&
            tarif.actif &&
            tarif.type == 'service' &&
            tarif.modeCalcul == 'fixe',
      );

      return tarif.valeur;
    } catch (_) {
      return null;
    }
  }

  Tarif? tarifMatiereSelectionnee() {
    if (matiereSelectionnee == "Standard") {
      return null;
    }

    final nomMatiere = matiereSelectionnee.trim().toLowerCase();
    final vetementId = vetementSelectionne?.id;

    // Priorité au tarif spécifique du vêtement.
    for (final tarif in tarifs) {
      if (tarif.actif &&
          tarif.type == 'supplement' &&
          tarif.nom.trim().toLowerCase() == nomMatiere &&
          tarif.vetementId == vetementId) {
        return tarif;
      }
    }

    // Sinon, on utilise le tarif général de la matière.
    for (final tarif in tarifs) {
      if (tarif.actif &&
          tarif.type == 'supplement' &&
          tarif.nom.trim().toLowerCase() == nomMatiere &&
          tarif.vetementId == null) {
        return tarif;
      }
    }

    return null;
  }

  double supplementMatiereActuel() {
    final vetement = vetementSelectionne;
    if (vetement == null || matiereSelectionnee == "Standard") {
      return 0;
    }

    final tarif = tarifMatiereSelectionnee();
    if (tarif == null) {
      return 0;
    }

    switch (tarif.modeCalcul) {
      case 'pourcentage':
        return vetement.prix * tarif.valeur / 100;
      case 'multiplicateur':
        return vetement.prix * (tarif.valeur - 1);
      case 'fixe':
      default:
        return tarif.valeur;
    }
  }

  double supplementComplexiteActuel() {
    return double.tryParse(complexiteController.text.trim()) ?? 0;
  }

  int quantiteActuelle() {
    final quantite = int.tryParse(quantiteController.text.trim()) ?? 1;
    return quantite > 0 ? quantite : 1;
  }

  double prixUnitaireCalcule() {
    final vetement = vetementSelectionne;
    if (vetement == null) {
      return 0;
    }

    final avantExpress =
        vetement.prix +
        supplementMatiereActuel() +
        supplementComplexiteActuel();

    return expressSelectionne ? avantExpress * 2 : avantExpress;
  }

  double totalArticleCalcule() {
    return prixUnitaireCalcule() * quantiteActuelle();
  }

  void ajouterVetementTemporaire() {
    if (vetementSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner un vêtement")),
      );
      return;
    }
    final prixBase = vetementSelectionne!.prix;

    if (prixBase <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Le tarif de « ${vetementSelectionne!.nom} » "
            "n'a pas encore été défini. "
            "Veuillez renseigner son tarif avant de l'ajouter.",
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    final quantite = int.tryParse(quantiteController.text.trim());

    if (quantite == null || quantite <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez saisir une quantité valide")),
      );
      return;
    }
    final supplementComplexite =
        double.tryParse(complexiteController.text.trim()) ?? 0;

    if (supplementComplexite < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Le supplément complexité ne peut pas être négatif."),
        ),
      );

      return;
    }
    final supplementMatiere = supplementMatiereActuel();
    final prixAvantExpress =
        prixBase + supplementMatiere + supplementComplexite;

    final prixFinal = expressSelectionne
        ? prixAvantExpress * 2
        : prixAvantExpress;
    final detail = DetailCommande(
      commandeId: 0,
      vetementId: vetementSelectionne!.id,
      vetement: vetementSelectionne!.nom,
      couleur: couleurSelectionnee,
      matiere: matiereSelectionnee,
      quantite: quantite,
      prix: prixFinal,
    );

    setState(() {
      detailsTemporaires.add(detail);

      vetementSelectionne = null;
      couleurSelectionnee = "Blanc";
      matiereSelectionnee = "Standard";
      quantiteController.text = "1";
      complexiteController.text = "0";
      expressSelectionne = false;
    });
  }

  double get totalTemporaire {
    return detailsTemporaires.fold(
      0.0,
      (total, detail) => total + detail.total,
    );
  }

  Future<void> ajouterCommande() async {
    if (clientSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner un client")),
      );

      return;
    }

    if (detailsTemporaires.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez ajouter au moins un vêtement")),
      );

      return;
    }

    try {
      final commandeId = await CommandeService.instance.creerCommande(
        clientId: clientSelectionne!.id!,
        date: dateController.text,
        statut: statut,

        // On envoie une copie de la liste.
        details: List<DetailCommande>.from(detailsTemporaires),
      );

      if (!mounted) return;

      setState(() {
        detailsTemporaires.clear();

        clientSelectionne = null;
        vetementSelectionne = null;

        couleurSelectionnee = "Blanc";
        matiereSelectionnee = "Standard";

        quantiteController.text = "1";
        complexiteController.text = "0";

        statut = "En attente";

        dateController.text = dateHeureActuelle();
      });

      await chargerDonnees();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Commande #$commandeId "
            "enregistrée avec succès",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erreur lors de "
            "l'enregistrement : $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> imprimerRecu(Commande commande, String nomClient) async {
    try {
      if (commande.id == null) {
        throw Exception('Commande invalide.');
      }

      final paiements = await DatabaseHelper.instance.getPaiementsCommande(
        commande.id!,
      );

      if (!mounted) return;

      if (paiements.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible de générer un reçu : '
              'aucun paiement n’a été enregistré.',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        return;
      }

      final paiementsTries = List.of(paiements)
        ..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

      final dernierPaiement = paiementsTries.last;

      final totalPaye = paiements.fold<double>(
        0,
        (somme, paiement) => somme + paiement.montant,
      );

      final resteCalcule = commande.total - totalPaye;

      final resteAPayer = resteCalcule > 0 ? resteCalcule : 0.0;

      final articles = await DatabaseHelper.instance.getDetailsCommande(
        commande.id!,
      );

      final client = clients.firstWhere((c) => c.id == commande.clientId);

      final parametre = await DatabaseHelper.instance.getParametre();

      await PdfService.genererRecu(
        nomPressing: parametre?.nomPressing ?? 'Life Pressing',
        adresse: parametre?.adresse ?? '',
        email: parametre?.email ?? '',
        client: nomClient,
        telephone: client.telephone,
        numeroCommande: commande.id!,
        date: dernierPaiement.date,
        modePaiement: dernierPaiement.modePaiement,
        articles: articles,
        montant: dernierPaiement.montant,
        montantCommande: commande.total,
        paiementEffectue: dernierPaiement.montant,
        totalPaye: totalPaye,
        resteAPayer: resteAPayer,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _afficherActionInterdite(String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Expanded(child: Text('Autorisation requise')),
            ],
          ),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changerStatutCommande(Commande commande) async {
    String nouveauStatut = commande.statut;

    final statutChoisi = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Statut de la commande #${commande.id}'),
              content: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Statut",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: nouveauStatut,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: "En attente",
                        child: Text("🟡 En attente"),
                      ),
                      DropdownMenuItem(
                        value: "En cours",
                        child: Text("🔵 En cours"),
                      ),
                      DropdownMenuItem(
                        value: "Terminée",
                        child: Text("🟢 Terminée"),
                      ),
                      DropdownMenuItem(
                        value: "Livrée",
                        child: Text("✅ Livrée"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        nouveauStatut = value;
                      });
                    },
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
                    Navigator.pop(dialogContext, nouveauStatut);
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (statutChoisi == null || statutChoisi == commande.statut) {
      return;
    }

    try {
      await CommandeService.instance.modifierStatut(
        commandeId: commande.id!,
        statut: statutChoisi,
      );

      await chargerDonnees();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut modifié : $statutChoisi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _actualiserAvecMessage() async {
    await chargerDonnees();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Données actualisées')));
  }

  Future<void> _ouvrirModificationCommande(Commande commande) async {
    try {
      final autorise = await CommandeService.instance.autoriserModification(
        commande,
      );

      if (!mounted) return;

      if (!autorise) {
        await _afficherActionInterdite(
          'Seul le propriétaire peut modifier '
          'la commande #${commande.id}.\n\n'
          'Cette tentative a été enregistrée '
          'dans le journal de sécurité.',
        );

        return;
      }

      if (!mounted) return;

      final resultat = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ModifierCommandeScreen(commande: commande),
        ),
      );

      if (!mounted) return;

      if (resultat == true) {
        await chargerDonnees();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _supprimerCommande(Commande commande) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Expanded(child: Text('Supprimer la commande')),
            ],
          ),
          content: Text(
            'Voulez-vous vraiment supprimer '
            'la commande #${commande.id} ?\n\n'
            'Une commande ayant déjà reçu '
            'un paiement ne pourra pas être supprimée.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.delete_rounded),
              label: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmation != true || !mounted) {
      return;
    }

    try {
      final autorise = await CommandeService.instance.supprimerCommande(
        commande,
      );

      if (!mounted) return;

      if (!autorise) {
        await _afficherActionInterdite(
          'Seul le propriétaire peut supprimer '
          'la commande #${commande.id}.\n\n'
          'Cette tentative a été enregistrée '
          'dans le journal de sécurité.',
        );

        return;
      }

      await chargerDonnees();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande supprimée avec succès.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des commandes"),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Actualiser",
            icon: const Icon(Icons.refresh),
            onPressed: _actualiserAvecMessage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: "Date",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),

            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              key: ValueKey(statut),
              initialValue: statut,
              decoration: const InputDecoration(
                labelText: "Statut",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
              items: const [
                DropdownMenuItem(
                  value: "En attente",
                  child: Text("🟡 En attente"),
                ),
                DropdownMenuItem(value: "En cours", child: Text("🔵 En cours")),
                DropdownMenuItem(value: "Terminée", child: Text("🟢 Terminée")),
                DropdownMenuItem(value: "Livrée", child: Text("✅ Livrée")),
              ],
              onChanged: (value) {
                setState(() {
                  statut = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            InputDecorator(
              decoration: const InputDecoration(
                labelText: "Client",
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Client>(
                  value: clients.contains(clientSelectionne)
                      ? clientSelectionne
                      : null,
                  isExpanded: true,
                  hint: const Text("Sélectionner un client"),
                  items: clients.map((client) {
                    return DropdownMenuItem<Client>(
                      value: client,
                      child: Text("${client.nom} ${client.prenom}"),
                    );
                  }).toList(),
                  onChanged: (client) {
                    setState(() {
                      clientSelectionne = client;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Divider(),

            const SizedBox(height: 10),

            const Text(
              "Vêtements de la commande",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: "Vêtement",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.checkroom),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Vetement>(
                  value: vetements.contains(vetementSelectionne)
                      ? vetementSelectionne
                      : null,
                  isExpanded: true,
                  hint: const Text("Sélectionner un vêtement"),
                  items: vetements.map((vetement) {
                    return DropdownMenuItem<Vetement>(
                      value: vetement,
                      child: Text(
                        "${vetement.nom} - "
                        "${vetement.prix.toStringAsFixed(0)} FCFA",
                      ),
                    );
                  }).toList(),
                  onChanged: (vetement) {
                    setState(() {
                      vetementSelectionne = vetement;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 15),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: "Couleur",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.palette),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: couleurs.contains(couleurSelectionnee)
                      ? couleurSelectionnee
                      : "Blanc",
                  isExpanded: true,
                  items: couleurs.map((couleur) {
                    return DropdownMenuItem<String>(
                      value: couleur,
                      child: Text(couleur),
                    );
                  }).toList(),
                  onChanged: (couleur) {
                    if (couleur == null) return;

                    setState(() {
                      couleurSelectionnee = couleur;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 15),

            InputDecorator(
              decoration: const InputDecoration(
                labelText: "Matière",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.texture),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: matieres.contains(matiereSelectionnee)
                      ? matiereSelectionnee
                      : "Standard",
                  isExpanded: true,
                  items: matieres.map((matiere) {
                    return DropdownMenuItem<String>(
                      value: matiere,
                      child: Text(matiere),
                    );
                  }).toList(),
                  onChanged: (matiere) {
                    if (matiere == null) return;

                    setState(() {
                      matiereSelectionnee = matiere;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: quantiteController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: "Quantité",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: complexiteController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: "Supplément complexité",
                hintText: "0 si aucun supplément",
                suffixText: "FCFA",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.add_circle_outline),
              ),
            ),

            const SizedBox(height: 15),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Lavage express"),
              subtitle: const Text("Double le prix de cet article"),
              value: expressSelectionne,
              onChanged: (value) {
                setState(() {
                  expressSelectionne = value;
                });
              },
            ),

            const SizedBox(height: 15),

            if (vetementSelectionne != null)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Prix de base"),
                          Text(
                            "${vetementSelectionne!.prix.toStringAsFixed(0)} FCFA",
                          ),
                        ],
                      ),
                      if (supplementMatiereActuel() != 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Matière : $matiereSelectionnee"),
                            Text(
                              "+${supplementMatiereActuel().toStringAsFixed(0)} FCFA",
                            ),
                          ],
                        ),
                      ],
                      if (supplementComplexiteActuel() != 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Complexité"),
                            Text(
                              "+${supplementComplexiteActuel().toStringAsFixed(0)} FCFA",
                            ),
                          ],
                        ),
                      ],
                      if (expressSelectionne) ...[
                        const SizedBox(height: 6),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text("Lavage express"), Text("×2")],
                        ),
                      ],
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Prix unitaire calculé",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${prixUnitaireCalcule().toStringAsFixed(0)} FCFA",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total × ${quantiteActuelle()}"),
                          Text(
                            "${totalArticleCalcule().toStringAsFixed(0)} FCFA",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: ajouterVetementTemporaire,
              icon: const Icon(Icons.add),
              label: const Text("Ajouter le vêtement"),
            ),

            const SizedBox(height: 20),
            if (detailsTemporaires.isNotEmpty) ...[
              const Text(
                "Articles ajoutés",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: detailsTemporaires.length,
                itemBuilder: (context, index) {
                  final detail = detailsTemporaires[index];

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.checkroom),
                      title: Text(detail.vetement),
                      subtitle: Text(
                        "${detail.couleur} • "
                        "${detail.matiere} • "
                        "${detail.quantite} × "
                        "${detail.prix.toStringAsFixed(0)} FCFA",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${detail.total.toStringAsFixed(0)} F",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            tooltip: "Retirer",
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                detailsTemporaires.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TOTAL",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${totalTemporaire.toStringAsFixed(0)} FCFA",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: ajouterCommande,
              icon: const Icon(Icons.save),
              label: const Text("Enregistrer la commande"),
            ),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 10),

            const Text(
              "Liste des commandes",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text("Toutes"),
                  selected: filtreStatut == "Toutes",
                  onSelected: (_) => filtrerCommandes("Toutes"),
                ),
                ChoiceChip(
                  label: const Text("En attente"),
                  selected: filtreStatut == "En attente",
                  onSelected: (_) => filtrerCommandes("En attente"),
                ),
                ChoiceChip(
                  label: const Text("En cours"),
                  selected: filtreStatut == "En cours",
                  onSelected: (_) => filtrerCommandes("En cours"),
                ),
                ChoiceChip(
                  label: const Text("Terminée"),
                  selected: filtreStatut == "Terminée",
                  onSelected: (_) => filtrerCommandes("Terminée"),
                ),
                ChoiceChip(
                  label: const Text("Livrée"),
                  selected: filtreStatut == "Livrée",
                  onSelected: (_) => filtrerCommandes("Livrée"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: rechercheController,
              onChanged: rechercherCommande,
              decoration: const InputDecoration(
                hintText: "Rechercher une commande...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 15),
            commandesFiltrees.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "Aucune commande enregistrée",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: commandesFiltrees.length,
                    itemBuilder: (context, index) {
                      final commande = commandesFiltrees[index];

                      String nomClient = "Client inconnu";

                      try {
                        final client = clients.firstWhere(
                          (c) => c.id == commande.clientId,
                        );
                        nomClient = "${client.nom} ${client.prenom}";
                      } catch (_) {}

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: Text(nomClient),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Date : ${commande.date}"),
                              const SizedBox(height: 5),
                              Chip(
                                label: Text(commande.statut),
                                backgroundColor: couleurStatut(commande.statut),
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Total : ${commande.total.toStringAsFixed(0)} FCFA",
                              ),
                            ],
                          ),
                          isThreeLine: true,

                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailCommandeScreen(commande: commande),
                              ),
                            );
                            await chargerDonnees();
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              switch (value) {
                                case 'recu':
                                  await imprimerRecu(commande, nomClient);
                                  break;

                                case 'depot':
                                  final details = await DatabaseHelper.instance
                                      .getDetailsCommande(commande.id!);

                                  final client = clients.firstWhere(
                                    (c) => c.id == commande.clientId,
                                  );

                                  final parametre = await DatabaseHelper
                                      .instance
                                      .getParametre();

                                  await PdfService.genererTicketDepot(
                                    nomPressing:
                                        parametre?.nomPressing ??
                                        'Life Pressing',
                                    adresse: parametre?.adresse ?? '',
                                    email: parametre?.email ?? '',
                                    client: nomClient,
                                    telephone: client.telephone,
                                    numeroCommande: commande.id!,
                                    date: commande.date,
                                    articles: details,
                                    total: commande.total,
                                    statut: commande.statut,
                                  );
                                  break;

                                case 'statut':
                                  await _changerStatutCommande(commande);
                                  break;

                                case 'modifier':
                                  await _ouvrirModificationCommande(commande);
                                  break;

                                case 'supprimer':
                                  await _supprimerCommande(commande);
                                  break;
                              }
                            },

                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: "recu",
                                child: Text("🧾 Imprimer le reçu"),
                              ),
                              PopupMenuItem(
                                value: "depot",
                                child: Text("📄 Ticket de dépôt"),
                              ),
                              PopupMenuItem(
                                value: "statut",
                                child: Text("🔄 Changer le statut"),
                              ),

                              PopupMenuDivider(),
                              PopupMenuItem(
                                value: "modifier",
                                child: Text("✏️ Modifier"),
                              ),
                              PopupMenuItem(
                                value: "supprimer",
                                child: Text("🗑️ Supprimer"),
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
