import 'package:flutter/material.dart';

import '../database/database_helper.dart';

import 'client_screen.dart';
import 'commande_screen.dart';
import 'paiement_screen.dart';
import 'statistique_screen.dart';
import 'vetement_screen.dart';
import '../services/session_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int nombreClients = 0;
  int nombreCommandes = 0;
  int nombreVetements = 0;

  int commandesEnAttente = 0;
  int commandesTerminees = 0;

  double totalPaiements = 0;
  double chiffreJour = 0;
  double chiffreMois = 0;

  bool chargementEnCours = true;
  String? messageErreur;

  @override
  void initState() {
    super.initState();
    chargerStatistiques();
  }

  Future<void> chargerStatistiques() async {
    if (mounted) {
      setState(() {
        chargementEnCours = true;
        messageErreur = null;
      });
    }

    try {
      final clients = await DatabaseHelper.instance.getNombreClients();

      final commandes = await DatabaseHelper.instance.getNombreCommandes();

      final vetements = await DatabaseHelper.instance.getNombreVetements();

      final enAttente = await DatabaseHelper.instance
          .getNombreCommandesEnAttente();

      final terminees = await DatabaseHelper.instance
          .getNombreCommandesTerminees();
      double paiements = 0;
      double chiffreAffairesJour = 0;
      double chiffreAffairesMois = 0;

      if (SessionService.estProprietaire) {
        paiements = await DatabaseHelper.instance.getTotalPaiements();

        chiffreAffairesJour = await DatabaseHelper.instance
            .getChiffreAffairesJour();

        chiffreAffairesMois = await DatabaseHelper.instance
            .getChiffreAffairesMois();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        nombreClients = clients;
        nombreCommandes = commandes;
        nombreVetements = vetements;

        totalPaiements = paiements;
        commandesEnAttente = enAttente;
        commandesTerminees = terminees;

        chiffreJour = chiffreAffairesJour;
        chiffreMois = chiffreAffairesMois;

        chargementEnCours = false;
        messageErreur = null;
      });
    } catch (erreur) {
      if (!mounted) {
        return;
      }

      setState(() {
        chargementEnCours = false;
        messageErreur = "Impossible de charger les statistiques.";
      });
    }
  }

  String formatMontant(double montant) {
    final texte = montant.toStringAsFixed(0);

    return texte.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ' ',
    );
  }

  String obtenirDateDuJour() {
    final date = DateTime.now();

    const jours = [
      "Lundi",
      "Mardi",
      "Mercredi",
      "Jeudi",
      "Vendredi",
      "Samedi",
      "Dimanche",
    ];

    const mois = [
      "janvier",
      "février",
      "mars",
      "avril",
      "mai",
      "juin",
      "juillet",
      "août",
      "septembre",
      "octobre",
      "novembre",
      "décembre",
    ];

    return "${jours[date.weekday - 1]} "
        "${date.day} "
        "${mois[date.month - 1]} "
        "${date.year}";
  }

  Future<void> ouvrirEcran(Widget ecran) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ecran));

    await chargerStatistiques();
  }

  Future<void> ouvrirOnglet(int index) async {
    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
      return;
    }

    switch (index) {
      case 1:
        await ouvrirEcran(const CommandeScreen());
        break;

      case 2:
        await ouvrirEcran(const PaiementScreen());
        break;

      case 3:
        await ouvrirEcran(const StatistiqueScreen());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF2563EB),
      onRefresh: chargerStatistiques,

      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chargementEnCours)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),

            _buildWelcomeCard(),

            if (messageErreur != null) ...[
              const SizedBox(height: 14),
              _buildErrorCard(),
            ],

            const SizedBox(height: 26),

            _buildSectionTitle(
              titre: "Vue d'ensemble",
              sousTitre: "Les informations principales du pressing",
            ),

            const SizedBox(height: 14),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _buildStatCard(
                  titre: "Clients",
                  valeur: nombreClients.toString(),
                  icon: Icons.people_alt_rounded,
                  couleur: const Color(0xFF2563EB),
                  couleurFond: const Color(0xFFEAF1FF),
                ),
                _buildStatCard(
                  titre: "Commandes",
                  valeur: nombreCommandes.toString(),
                  icon: Icons.receipt_long_rounded,
                  couleur: const Color(0xFFF59E0B),
                  couleurFond: const Color(0xFFFFF4DA),
                ),
                _buildStatCard(
                  titre: "En attente",
                  valeur: commandesEnAttente.toString(),
                  icon: Icons.schedule_rounded,
                  couleur: const Color(0xFFEF4444),
                  couleurFond: const Color(0xFFFFE7E7),
                ),
                if (SessionService.estProprietaire)
                  _buildStatCard(
                    titre: "Chiffre du mois",
                    valeur: "${formatMontant(chiffreMois)} F",
                    icon: Icons.trending_up_rounded,
                    couleur: const Color(0xFF8B5CF6),
                    couleurFond: const Color(0xFFF0EAFE),
                  )
                else
                  _buildStatCard(
                    titre: "Vêtements",
                    valeur: nombreVetements.toString(),
                    icon: Icons.checkroom_rounded,
                    couleur: const Color(0xFF10B981),
                    couleurFond: const Color(0xFFE5F8F2),
                  ),
              ],
            ),

            const SizedBox(height: 26),

            _buildSectionTitle(
              titre: "Activité",
              sousTitre: "Résumé des opérations enregistrées",
            ),

            const SizedBox(height: 14),

            _buildActivityCard(),

            const SizedBox(height: 26),

            _buildSectionTitle(
              titre: "Gestion",
              sousTitre: "Accédez rapidement aux fonctionnalités",
            ),

            const SizedBox(height: 14),

            _buildMenuCard(
              icon: Icons.people_alt_rounded,
              titre: "Clients",
              sousTitre: "Ajouter, rechercher et gérer les clients",
              couleur: const Color(0xFF2563EB),
              onTap: () {
                ouvrirEcran(const ClientScreen());
              },
            ),

            const SizedBox(height: 12),

            _buildMenuCard(
              icon: Icons.local_laundry_service_rounded,
              titre: "Commandes",
              sousTitre: "Créer et suivre les commandes du pressing",
              couleur: const Color(0xFFF59E0B),
              onTap: () {
                ouvrirOnglet(1);
              },
            ),

            const SizedBox(height: 12),
            _buildMenuCard(
              icon: Icons.checkroom_rounded,
              titre: "Vêtements",
              sousTitre: "Configurer les vêtements et leurs tarifs",
              couleur: const Color(0xFF10B981),
              onTap: () {
                ouvrirEcran(const VetementScreen());
              },
            ),

            const SizedBox(height: 12),

            _buildMenuCard(
              icon: Icons.payments_rounded,
              titre: "Paiements",
              sousTitre: "Enregistrer et consulter les paiements",
              couleur: const Color(0xFF8B5CF6),
              onTap: () {
                ouvrirOnglet(2);
              },
            ),

            if (SessionService.estProprietaire) ...[
              const SizedBox(height: 12),
              _buildMenuCard(
                icon: Icons.analytics_rounded,
                titre: "Statistiques",
                sousTitre: "Analyser les performances du pressing",
                couleur: const Color(0xFF0EA5E9),
                onTap: () {
                  ouvrirOnglet(3);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF0F5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE7FA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE8FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: Color(0xFF2563EB),
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bonjour 👋",
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  obtenirDateDuJour(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Actualiser",
            onPressed: chargementEnCours
                ? null
                : () async {
                    await chargerStatistiques();

                    if (!mounted || messageErreur != null) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Tableau de bord actualisé"),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: const Color(0xFFFFE7E7),
        borderRadius: BorderRadius.circular(14),
      ),

      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              messageErreur!,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: chargerStatistiques,
            child: const Text("Réessayer"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String titre,
    required String sousTitre,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titre,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          sousTitre,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String titre,
    required String valeur,
    required IconData icon,
    required Color couleur,
    required Color couleurFond,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: couleurFond,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: couleur, size: 23),
          ),

          const Spacer(),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valeur,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            titre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActivityMetric(
                  icon: Icons.checkroom_rounded,
                  titre: "Vêtements",
                  valeur: nombreVetements.toString(),
                  couleur: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 55, child: VerticalDivider()),
              Expanded(
                child: _buildActivityMetric(
                  icon: Icons.check_circle_rounded,
                  titre: "Terminées",
                  valeur: commandesTerminees.toString(),
                  couleur: const Color(0xFF0EA5E9),
                ),
              ),
            ],
          ),

          if (SessionService.estProprietaire) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildActivityMetric(
                    icon: Icons.account_balance_wallet_rounded,
                    titre: "Paiements",
                    valeur: "${formatMontant(totalPaiements)} F",
                    couleur: const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(height: 55, child: VerticalDivider()),
                Expanded(
                  child: _buildActivityMetric(
                    icon: Icons.today_rounded,
                    titre: "Aujourd'hui",
                    valeur: "${formatMontant(chiffreJour)} F",
                    couleur: const Color(0xFFF97316),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityMetric({
    required IconData icon,
    required String titre,
    required String valeur,
    required Color couleur,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Icon(icon, color: couleur, size: 25),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valeur,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String titre,
    required String sousTitre,
    required Color couleur,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),

      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,

        child: Container(
          padding: const EdgeInsets.all(15),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECF3)),
          ),

          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: couleur.withAlpha(25),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: couleur, size: 25),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sousTitre,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
