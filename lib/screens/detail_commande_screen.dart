import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/commande.dart';
import '../models/detail_commande.dart';
import '../models/paiement.dart';
import '../services/pdf_service.dart';

class DetailCommandeScreen extends StatefulWidget {
  final Commande commande;

  const DetailCommandeScreen({super.key, required this.commande});

  @override
  State<DetailCommandeScreen> createState() => _DetailCommandeScreenState();
}

class _DetailCommandeScreenState extends State<DetailCommandeScreen> {
  Client? client;

  List<DetailCommande> details = [];
  List<Paiement> paiements = [];

  bool chargement = true;

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> chargerDonnees() async {
    final nouveauClient = await DatabaseHelper.instance.getClientById(
      widget.commande.clientId,
    );

    final nouveauxDetails = await DatabaseHelper.instance.getDetailsCommande(
      widget.commande.id!,
    );

    final nouveauxPaiements = await DatabaseHelper.instance
        .getPaiementsCommande(widget.commande.id!);

    if (!mounted) return;

    setState(() {
      client = nouveauClient;
      details = nouveauxDetails;
      paiements = nouveauxPaiements;
      chargement = false;
    });
  }

  // ============================================================
  // CALCULS
  // ============================================================

  double get totalPaye {
    return paiements.fold<double>(
      0,
      (somme, paiement) => somme + paiement.montant,
    );
  }

  double get resteAPayer {
    final reste = widget.commande.total - totalPaye;

    return reste < 0 ? 0 : reste;
  }

  // ============================================================
  // COULEUR STATUT
  // ============================================================

  Color couleurStatut() {
    switch (widget.commande.statut) {
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

  // ============================================================
  // PDF
  // ============================================================
  Future<void> genererRecuPdf() async {
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

    if (client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de récupérer les informations du client.'),
        ),
      );

      return;
    }

    try {
      final paiementsTries = List<Paiement>.from(paiements)
        ..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

      final dernierPaiement = paiementsTries.last;

      final parametre = await DatabaseHelper.instance.getParametre();

      await PdfService.genererRecu(
        nomPressing: parametre?.nomPressing ?? 'Life Pressing',
        adresse: parametre?.adresse ?? '',
        email: parametre?.email ?? '',
        client: '${client!.nom} ${client!.prenom}',
        telephone: client!.telephone,
        numeroCommande: widget.commande.id!,
        date: dernierPaiement.date,
        modePaiement: dernierPaiement.modePaiement,
        articles: details,
        montant: dernierPaiement.montant,
        montantCommande: widget.commande.total,
        paiementEffectue: dernierPaiement.montant,
        totalPaye: totalPaye,
        resteAPayer: resteAPayer,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la génération du PDF : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (chargement) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Commande #${widget.commande.id}"),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: chargerDonnees,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================
              // COMMANDE
              // =========================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${client?.nom ?? ""} "
                        "${client?.prenom ?? ""}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text("📅 ${widget.commande.date}"),

                      const SizedBox(height: 4),

                      Text(
                        "💰 "
                        "${widget.commande.total.toStringAsFixed(0)} FCFA",
                      ),

                      const SizedBox(height: 8),

                      Chip(
                        avatar: const Icon(
                          Icons.local_laundry_service,
                          color: Colors.white,
                        ),

                        backgroundColor: couleurStatut(),

                        label: Text(
                          widget.commande.statut,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =========================
              // VÊTEMENTS
              // =========================
              const Text(
                "Vêtements",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              details.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text("Aucun vêtement enregistré")),
                      ),
                    )
                  : Card(
                      child: Column(
                        children: List.generate(details.length, (index) {
                          final detail = details[index];

                          return Column(
                            children: [
                              ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.checkroom),
                                ),

                                title: Text(
                                  detail.vetement,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),

                                    Text(
                                      "Couleur : "
                                      "${detail.couleur}",
                                    ),
                                    Text("Matière : ${detail.matiere}"),

                                    Text(
                                      "Quantité : "
                                      "${detail.quantite}",
                                    ),
                                  ],
                                ),

                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${detail.prix.toStringAsFixed(0)} FCFA",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 3),

                                    Text(
                                      "Total : "
                                      "${detail.total.toStringAsFixed(0)} FCFA",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (index < details.length - 1)
                                const Divider(height: 1),
                            ],
                          );
                        }),
                      ),
                    ),

              const SizedBox(height: 25),

              // =========================
              // PAIEMENTS
              // =========================
              const Text(
                "Paiements",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              paiements.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text("Aucun paiement enregistré")),
                      ),
                    )
                  : Card(
                      child: Column(
                        children: List.generate(paiements.length, (index) {
                          final paiement = paiements[index];

                          return Column(
                            children: [
                              ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.payments),
                                ),

                                title: Text(paiement.modePaiement),

                                subtitle: Text(
                                  "Date : "
                                  "${paiement.date}",
                                ),

                                trailing: Text(
                                  "${paiement.montant.toStringAsFixed(0)} FCFA",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),

                              if (index < paiements.length - 1)
                                const Divider(height: 1),
                            ],
                          );
                        }),
                      ),
                    ),

              const SizedBox(height: 25),

              // =========================
              // TOTAL
              // =========================
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Montant de la commande",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          Text(
                            "${widget.commande.total.toStringAsFixed(0)} FCFA",
                          ),
                        ],
                      ),

                      const Divider(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total payé",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          Text(
                            "${totalPaye.toStringAsFixed(0)} FCFA",
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),

                      const Divider(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Reste à payer",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          Text(
                            "${resteAPayer.toStringAsFixed(0)} FCFA",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,

                              color: resteAPayer > 0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =========================
              // PDF
              // =========================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: paiements.isEmpty ? null : genererRecuPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(
                    paiements.isEmpty
                        ? 'Reçu indisponible : aucun paiement'
                        : 'Générer le reçu PDF',
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
