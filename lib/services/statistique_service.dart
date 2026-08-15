import '../database/database_helper.dart';
import 'session_service.dart';

class StatistiquesResultat {
  final int nombreClients;
  final int nombreCommandes;
  final int nombreVetements;
  final int nombrePaiements;

  final int enAttente;
  final int enCours;
  final int terminees;
  final int livrees;

  final double chiffreAffaires;

  const StatistiquesResultat({
    required this.nombreClients,
    required this.nombreCommandes,
    required this.nombreVetements,
    required this.nombrePaiements,
    required this.enAttente,
    required this.enCours,
    required this.terminees,
    required this.livrees,
    required this.chiffreAffaires,
  });
}

class StatistiqueService {
  StatistiqueService._();

  static final StatistiqueService instance =
      StatistiqueService._();

  final DatabaseHelper _database =
      DatabaseHelper.instance;

  void _verifierProprietaire() {
    if (!SessionService.estProprietaire) {
      throw Exception(
        'Les statistiques sont réservées au propriétaire.',
      );
    }
  }

  Future<StatistiquesResultat>
      chargerStatistiques() async {
    _verifierProprietaire();

    final clients =
        await _database.getClients();

    final commandes =
        await _database.getCommandes();

    final vetements =
        await _database.getVetements();

    final paiements =
        await _database.getPaiements();

    int enAttente = 0;
    int enCours = 0;
    int terminees = 0;
    int livrees = 0;

    for (final commande in commandes) {
      switch (commande.statut) {
        case 'En attente':
          enAttente++;
          break;

        case 'En cours':
          enCours++;
          break;

        case 'Terminée':
          terminees++;
          break;

        case 'Livrée':
          livrees++;
          break;
      }
    }

    // Le CA correspond ici aux paiements
    // réellement encaissés.
    final chiffreAffaires =
        await _database.getTotalPaiements();

    return StatistiquesResultat(
      nombreClients: clients.length,
      nombreCommandes: commandes.length,
      nombreVetements: vetements.length,
      nombrePaiements: paiements.length,
      enAttente: enAttente,
      enCours: enCours,
      terminees: terminees,
      livrees: livrees,
      chiffreAffaires: chiffreAffaires,
    );
  }
}