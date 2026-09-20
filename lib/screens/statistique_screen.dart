import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../services/statistique_service.dart';

class StatistiqueScreen extends StatefulWidget {
  const StatistiqueScreen({super.key});

  @override
  State<StatistiqueScreen> createState() => _StatistiqueScreenState();
}

class _StatistiqueScreenState extends State<StatistiqueScreen> {
  StatistiquesResultat? statistiques;
  AnalyseFinanciereResultat? analyseFinanciere;

  bool chargement = true;
  bool chargementAnalyse = false;

  String? erreur;
  String? erreurAnalyse;

  TypeRevenuFinancier typeRevenu = TypeRevenuFinancier.encaissements;

  TypePeriodeFinanciere typePeriode = TypePeriodeFinanciere.mois;

  int anneeSelectionnee = DateTime.now().year;
  int moisSelectionne = DateTime.now().month;

  static const List<String> nomsMois = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  @override
  void initState() {
    super.initState();

    if (SessionService.estProprietaire) {
      chargerStatistiques();
    } else {
      chargement = false;
    }
  }

  // ============================================================
  // CHARGEMENT GÉNÉRAL
  // ============================================================

  Future<void> chargerStatistiques() async {
    if (!SessionService.estProprietaire) {
      return;
    }

    if (mounted) {
      setState(() {
        chargement = true;
        erreur = null;
      });
    }

    try {
      final resultat = await StatistiqueService.instance.chargerStatistiques();

      final analyse = await StatistiqueService.instance
          .chargerAnalyseFinanciere(
            typeRevenu: typeRevenu,
            typePeriode: typePeriode,
            annee: anneeSelectionnee,
            mois: typePeriode == TypePeriodeFinanciere.mois
                ? moisSelectionne
                : null,
          );

      if (!mounted) return;

      setState(() {
        statistiques = resultat;
        analyseFinanciere = analyse;
        chargement = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        erreur = e.toString().replaceFirst('Exception: ', '');

        chargement = false;
      });
    }
  }

  // ============================================================
  // ANALYSE FINANCIÈRE
  // ============================================================

  Future<void> chargerAnalyseFinanciere() async {
    if (!SessionService.estProprietaire) {
      return;
    }

    if (mounted) {
      setState(() {
        chargementAnalyse = true;
        erreurAnalyse = null;
      });
    }

    try {
      final resultat = await StatistiqueService.instance
          .chargerAnalyseFinanciere(
            typeRevenu: typeRevenu,
            typePeriode: typePeriode,
            annee: anneeSelectionnee,
            mois: typePeriode == TypePeriodeFinanciere.mois
                ? moisSelectionne
                : null,
          );

      if (!mounted) return;

      setState(() {
        analyseFinanciere = resultat;
        chargementAnalyse = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        erreurAnalyse = e.toString().replaceFirst('Exception: ', '');

        chargementAnalyse = false;
      });
    }
  }

  // ============================================================
  // FORMATAGE
  // ============================================================

  String formatMontant(double montant) {
    return '${montant.toStringAsFixed(0)} FCFA';
  }

  String libellePeriode() {
    if (typePeriode == TypePeriodeFinanciere.annee) {
      return 'Année $anneeSelectionnee';
    }

    return '${nomsMois[moisSelectionne - 1]} '
        '$anneeSelectionnee';
  }

  // ============================================================
  // CARTE STATISTIQUE
  // ============================================================

  Widget buildStatCard({
    required IconData icon,
    required String titre,
    required String valeur,
    Color couleur = Colors.blue,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: couleur),

            const SizedBox(height: 6),

            Text(
              titre,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                valeur,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: couleur,
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
  // GRAPHIQUE GÉNÉRAL
  // ============================================================

  Widget buildGraphique(StatistiquesResultat stats) {
    final valeurs = [
      stats.nombreClients,
      stats.nombreCommandes,
      stats.nombreVetements,
      stats.nombrePaiements,
    ];

    final maximum = valeurs.fold<int>(
      0,
      (max, valeur) => valeur > max ? valeur : max,
    );

    double intervalle;

    if (maximum <= 10) {
      intervalle = 1;
    } else if (maximum <= 50) {
      intervalle = 5;
    } else if (maximum <= 100) {
      intervalle = 10;
    } else if (maximum <= 200) {
      intervalle = 20;
    } else if (maximum <= 500) {
      intervalle = 50;
    } else if (maximum <= 1000) {
      intervalle = 100;
    } else {
      intervalle = ((maximum / 5) / 100).ceil() * 100.0;
    }

    final hauteurMax = maximum == 0
        ? 5.0
        : ((maximum / intervalle).ceil() + 1) * intervalle;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: SizedBox(
          height: 280,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: hauteurMax,

              alignment: BarChartAlignment.spaceAround,

              borderData: FlBorderData(show: false),

              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: intervalle,
              ),

              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: intervalle,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value > hauteurMax) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          value.toInt().toString(),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    getTitlesWidget: (value, meta) {
                      String texte;

                      switch (value.toInt()) {
                        case 0:
                          texte = 'Clients';
                          break;

                        case 1:
                          texte = 'Commandes';
                          break;

                        case 2:
                          texte = 'Vêtements';
                          break;

                        case 3:
                          texte = 'Paiements';
                          break;

                        default:
                          return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          texte,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String titre;

                    switch (group.x) {
                      case 0:
                        titre = 'Clients';
                        break;

                      case 1:
                        titre = 'Commandes';
                        break;

                      case 2:
                        titre = 'Vêtements';
                        break;

                      case 3:
                        titre = 'Paiements';
                        break;

                      default:
                        titre = '';
                    }

                    return BarTooltipItem(
                      '$titre\n'
                      '${rod.toY.toInt()}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),

              barGroups: [
                _creerBarre(
                  x: 0,
                  valeur: stats.nombreClients.toDouble(),
                  couleur: Colors.blue,
                  maxY: hauteurMax,
                ),

                _creerBarre(
                  x: 1,
                  valeur: stats.nombreCommandes.toDouble(),
                  couleur: Colors.orange,
                  maxY: hauteurMax,
                ),

                _creerBarre(
                  x: 2,
                  valeur: stats.nombreVetements.toDouble(),
                  couleur: Colors.green,
                  maxY: hauteurMax,
                ),

                _creerBarre(
                  x: 3,
                  valeur: stats.nombrePaiements.toDouble(),
                  couleur: Colors.purple,
                  maxY: hauteurMax,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BarChartGroupData _creerBarre({
    required int x,
    required double valeur,
    required Color couleur,
    required double maxY,
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: valeur,
          color: couleur,
          width: 25,
          borderRadius: BorderRadius.circular(6),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: Colors.grey.shade200,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ANALYSE FINANCIÈRE
  // ============================================================

  Widget buildAnalyseFinanciere() {
    final analyse = analyseFinanciere;

    final annees = [
      for (int annee = 2020; annee <= DateTime.now().year + 5; annee++) annee,
    ];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Analyse financière',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              'Bénéfice = revenus − charges',
              style: TextStyle(color: Colors.grey.shade700),
            ),

            const SizedBox(height: 20),

            const Text(
              'Période',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Mois'),
                  selected: typePeriode == TypePeriodeFinanciere.mois,
                  onSelected: (_) {
                    setState(() {
                      typePeriode = TypePeriodeFinanciere.mois;
                    });

                    chargerAnalyseFinanciere();
                  },
                ),

                ChoiceChip(
                  label: const Text('Année'),
                  selected: typePeriode == TypePeriodeFinanciere.annee,
                  onSelected: (_) {
                    setState(() {
                      typePeriode = TypePeriodeFinanciere.annee;
                    });

                    chargerAnalyseFinanciere();
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                if (typePeriode == TypePeriodeFinanciere.mois) ...[
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('mois-$moisSelectionne'),
                      initialValue: moisSelectionne,
                      decoration: const InputDecoration(
                        labelText: 'Mois',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (int i = 1; i <= 12; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(nomsMois[i - 1]),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          moisSelectionne = value;
                        });

                        chargerAnalyseFinanciere();
                      },
                    ),
                  ),

                  const SizedBox(width: 12),
                ],

                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('annee-$anneeSelectionnee'),
                    initialValue: anneeSelectionnee,
                    decoration: const InputDecoration(
                      labelText: 'Année',
                      border: OutlineInputBorder(),
                    ),
                    items: annees
                        .map(
                          (annee) => DropdownMenuItem<int>(
                            value: annee,
                            child: Text(annee.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        anneeSelectionnee = value;
                      });

                      chargerAnalyseFinanciere();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              'Revenus basés sur',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.payments, size: 18),
                  label: const Text('Encaissements'),
                  selected: typeRevenu == TypeRevenuFinancier.encaissements,
                  onSelected: (_) {
                    setState(() {
                      typeRevenu = TypeRevenuFinancier.encaissements;
                    });

                    chargerAnalyseFinanciere();
                  },
                ),

                ChoiceChip(
                  avatar: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('Commandes'),
                  selected: typeRevenu == TypeRevenuFinancier.commandes,
                  onSelected: (_) {
                    setState(() {
                      typeRevenu = TypeRevenuFinancier.commandes;
                    });

                    chargerAnalyseFinanciere();
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      libellePeriode(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (chargementAnalyse)
              const Center(child: CircularProgressIndicator())
            else if (erreurAnalyse != null)
              Text(erreurAnalyse!, style: const TextStyle(color: Colors.red))
            else if (analyse != null) ...[
              buildStatCard(
                icon: typeRevenu == TypeRevenuFinancier.encaissements
                    ? Icons.payments
                    : Icons.receipt_long,
                titre: typeRevenu == TypeRevenuFinancier.encaissements
                    ? 'Revenus encaissés'
                    : 'Valeur des commandes',
                valeur: formatMontant(analyse.revenus),
                couleur: Colors.green,
              ),

              const SizedBox(height: 10),

              buildStatCard(
                icon: Icons.money_off,
                titre: 'Charges',
                valeur: formatMontant(analyse.charges),
                couleur: Colors.red,
              ),

              const SizedBox(height: 10),

              buildStatCard(
                icon: analyse.benefice >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                titre: analyse.benefice >= 0 ? 'Bénéfice' : 'Perte',
                valeur: formatMontant(analyse.benefice),
                couleur: analyse.benefice >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ],
        ),
      ),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                size: 44,
                color: Colors.orange,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Accès réservé au propriétaire',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              'Les statistiques et les '
              'informations financières '
              'du pressing ne sont pas '
              'accessibles avec un compte '
              'employé.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
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
        appBar: AppBar(title: const Text('Statistiques'), centerTitle: true),
        body: _buildAccesRefuse(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: chargerStatistiques,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: chargement
          ? const Center(child: CircularProgressIndicator())
          : erreur != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 55,
                    ),

                    const SizedBox(height: 12),

                    Text(erreur!, textAlign: TextAlign.center),

                    const SizedBox(height: 16),

                    FilledButton.icon(
                      onPressed: chargerStatistiques,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          : _buildContenu(),
    );
  }

  // ============================================================
  // CONTENU
  // ============================================================

  Widget _buildContenu() {
    final stats = statistiques;

    if (stats == null) {
      return const Center(child: Text('Aucune statistique disponible.'));
    }

    return RefreshIndicator(
      onRefresh: chargerStatistiques,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              buildStatCard(
                icon: Icons.people,
                titre: 'Clients',
                valeur: stats.nombreClients.toString(),
                couleur: Colors.blue,
              ),

              buildStatCard(
                icon: Icons.shopping_bag,
                titre: 'Commandes',
                valeur: stats.nombreCommandes.toString(),
                couleur: Colors.orange,
              ),

              buildStatCard(
                icon: Icons.checkroom,
                titre: 'Vêtements',
                valeur: stats.nombreVetements.toString(),
                couleur: Colors.green,
              ),

              buildStatCard(
                icon: Icons.payment,
                titre: 'Paiements',
                valeur: stats.nombrePaiements.toString(),
                couleur: Colors.purple,
              ),

              buildStatCard(
                icon: Icons.hourglass_empty,
                titre: 'En attente',
                valeur: stats.enAttente.toString(),
                couleur: Colors.orange,
              ),

              buildStatCard(
                icon: Icons.local_laundry_service,
                titre: 'En cours',
                valeur: stats.enCours.toString(),
                couleur: Colors.blue,
              ),

              buildStatCard(
                icon: Icons.task_alt,
                titre: 'Terminées',
                valeur: stats.terminees.toString(),
                couleur: Colors.green,
              ),

              buildStatCard(
                icon: Icons.inventory,
                titre: 'Livrées',
                valeur: stats.livrees.toString(),
                couleur: Colors.teal,
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Vue générale',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          buildGraphique(stats),

          const SizedBox(height: 24),

          const Text(
            'Finances',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          buildStatCard(
            icon: Icons.payments_rounded,
            titre: "Chiffre d'affaires encaissé",
            valeur: '${stats.chiffreAffaires.toStringAsFixed(0)} FCFA',
            couleur: Colors.green,
          ),

          const SizedBox(height: 20),

          buildAnalyseFinanciere(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
