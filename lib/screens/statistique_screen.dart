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

  bool chargement = true;

  String? erreur;

  @override
  void initState() {
    super.initState();

    if (SessionService.estProprietaire) {
      chargerStatistiques();
    } else {
      chargement = false;
    }
  }

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

      if (!mounted) return;

      setState(() {
        statistiques = resultat;
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
                      '$titre\n${rod.toY.toInt()}',
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
        ],
      ),
    );
  }
}
