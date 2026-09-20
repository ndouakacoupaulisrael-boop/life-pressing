import '../database/database_helper.dart';
import 'session_service.dart';

// ============================================================
// STATISTIQUES GÉNÉRALES
// ============================================================

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

// ============================================================
// ANALYSE FINANCIÈRE
// ============================================================

enum TypeRevenuFinancier { encaissements, commandes }

enum TypePeriodeFinanciere { mois, annee }

class AnalyseFinanciereResultat {
  final TypeRevenuFinancier typeRevenu;
  final TypePeriodeFinanciere typePeriode;

  final int annee;
  final int? mois;

  final double revenus;
  final double charges;
  final double benefice;

  const AnalyseFinanciereResultat({
    required this.typeRevenu,
    required this.typePeriode,
    required this.annee,
    required this.mois,
    required this.revenus,
    required this.charges,
    required this.benefice,
  });

  bool get estBeneficiaire => benefice >= 0;
}

// ============================================================
// SERVICE
// ============================================================

class StatistiqueService {
  StatistiqueService._();

  static final StatistiqueService instance = StatistiqueService._();

  final DatabaseHelper _database = DatabaseHelper.instance;

  // ==========================================================
  // SÉCURITÉ
  // ==========================================================

  void _verifierProprietaire() {
    if (!SessionService.estProprietaire) {
      throw Exception('Les statistiques sont réservées au propriétaire.');
    }
  }

  // ==========================================================
  // STATISTIQUES GÉNÉRALES
  // ==========================================================

  Future<StatistiquesResultat> chargerStatistiques() async {
    _verifierProprietaire();

    final clients = await _database.getClients();

    final commandes = await _database.getCommandes();

    final vetements = await _database.getVetements();

    final paiements = await _database.getPaiements();

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

    // Chiffre d'affaires réellement encaissé.
    final chiffreAffaires = await _database.getTotalPaiements();

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

  // ==========================================================
  // ANALYSE FINANCIÈRE
  // ==========================================================

  Future<AnalyseFinanciereResultat> chargerAnalyseFinanciere({
    required TypeRevenuFinancier typeRevenu,
    required TypePeriodeFinanciere typePeriode,
    required int annee,
    int? mois,
  }) async {
    _verifierProprietaire();

    if (annee < 2000 || annee > 2100) {
      throw Exception('Année invalide.');
    }

    if (typePeriode == TypePeriodeFinanciere.mois) {
      if (mois == null || mois < 1 || mois > 12) {
        throw Exception('Mois invalide.');
      }
    }

    final revenus = await _calculerRevenus(
      typeRevenu: typeRevenu,
      typePeriode: typePeriode,
      annee: annee,
      mois: mois,
    );

    final charges = await _calculerCharges(
      typePeriode: typePeriode,
      annee: annee,
      mois: mois,
    );

    final benefice = revenus - charges;

    return AnalyseFinanciereResultat(
      typeRevenu: typeRevenu,
      typePeriode: typePeriode,
      annee: annee,
      mois: typePeriode == TypePeriodeFinanciere.mois ? mois : null,
      revenus: revenus,
      charges: charges,
      benefice: benefice,
    );
  }

  // ==========================================================
  // REVENUS
  // ==========================================================

  Future<double> _calculerRevenus({
    required TypeRevenuFinancier typeRevenu,
    required TypePeriodeFinanciere typePeriode,
    required int annee,
    int? mois,
  }) async {
    switch (typeRevenu) {
      case TypeRevenuFinancier.encaissements:
        return _calculerRevenusEncaissements(
          typePeriode: typePeriode,
          annee: annee,
          mois: mois,
        );

      case TypeRevenuFinancier.commandes:
        return _calculerRevenusCommandes(
          typePeriode: typePeriode,
          annee: annee,
          mois: mois,
        );
    }
  }

  // ==========================================================
  // ENCAISSEMENTS
  // ==========================================================

  Future<double> _calculerRevenusEncaissements({
    required TypePeriodeFinanciere typePeriode,
    required int annee,
    int? mois,
  }) async {
    final paiements = await _database.getPaiements();

    double total = 0;

    for (final paiement in paiements) {
      final date = _convertirDate(paiement.date);

      if (date == null) {
        continue;
      }

      if (_dateCorrespondPeriode(
        date: date,
        typePeriode: typePeriode,
        annee: annee,
        mois: mois,
      )) {
        total += paiement.montant;
      }
    }

    return total;
  }

  // ==========================================================
  // COMMANDES
  // ==========================================================

  Future<double> _calculerRevenusCommandes({
    required TypePeriodeFinanciere typePeriode,
    required int annee,
    int? mois,
  }) async {
    final commandes = await _database.getCommandes();

    double total = 0;

    for (final commande in commandes) {
      final date = _convertirDate(commande.date);

      if (date == null) {
        continue;
      }

      if (_dateCorrespondPeriode(
        date: date,
        typePeriode: typePeriode,
        annee: annee,
        mois: mois,
      )) {
        total += commande.total;
      }
    }

    return total;
  }

  // ==========================================================
  // CHARGES
  // ==========================================================

  Future<double> _calculerCharges({
    required TypePeriodeFinanciere typePeriode,
    required int annee,
    int? mois,
  }) async {
    final charges = await _database.getCharges();

    double total = 0;

    for (final charge in charges) {
      final date = _convertirDate(charge.date);

      if (date == null) {
        continue;
      }

      if (_dateCorrespondPeriode(
        date: date,
        typePeriode: typePeriode,
        annee: annee,
        mois: mois,
      )) {
        total += charge.montant;
      }
    }

    return total;
  }

  // ==========================================================
  // DATES
  // ==========================================================

  DateTime? _convertirDate(String valeur) {
    final texte = valeur.trim();

    if (texte.isEmpty) {
      return null;
    }

    // Gère :
    // 2026-09-20
    // 2026-09-20 14:30
    // 2026-09-20T14:30
    final normalise = texte.replaceFirst(' ', 'T');

    final dateIso = DateTime.tryParse(normalise);

    if (dateIso != null) {
      return dateIso;
    }

    // Compatibilité éventuelle :
    // 20/09/2026
    final morceaux = texte.split('/');

    if (morceaux.length == 3) {
      final jour = int.tryParse(morceaux[0]);

      final mois = int.tryParse(morceaux[1]);

      final annee = int.tryParse(morceaux[2]);

      if (jour != null && mois != null && annee != null) {
        try {
          return DateTime(annee, mois, jour);
        } catch (_) {
          return null;
        }
      }
    }

    return null;
  }

  bool _dateCorrespondPeriode({
    required DateTime date,
    required TypePeriodeFinanciere typePeriode,
    required int annee,
    int? mois,
  }) {
    if (date.year != annee) {
      return false;
    }

    if (typePeriode == TypePeriodeFinanciere.annee) {
      return true;
    }

    return date.month == mois;
  }
}
