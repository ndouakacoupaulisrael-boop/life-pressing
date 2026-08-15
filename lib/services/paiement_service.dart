import '../models/commande.dart';
import '../models/paiement.dart';
import '../repositories/paiement_repository.dart';

class SituationPaiement {
  final double totalCommande;
  final double totalPaye;
  final double resteAPayer;

  const SituationPaiement({
    required this.totalCommande,
    required this.totalPaye,
    required this.resteAPayer,
  });

  bool get estPayee {
    return resteAPayer <= 0;
  }

  String get statut {
    if (totalPaye <= 0) {
      return 'Non payé';
    }

    if (resteAPayer <= 0) {
      return 'Payé';
    }

    return 'Partiellement payé';
  }
}

class PaiementEnregistreResultat {
  final Paiement paiement;
  final SituationPaiement situation;

  const PaiementEnregistreResultat({
    required this.paiement,
    required this.situation,
  });
}

class PaiementService {
  PaiementService._();

  static final PaiementService instance =
      PaiementService._();

  final PaiementRepository _repository =
      PaiementRepository();

  Future<List<Paiement>> getPaiements() {
    return _repository.getPaiements();
  }

  Future<List<Paiement>> getPaiementsCommande(
    int commandeId,
  ) {
    return _repository.getPaiementsCommande(
      commandeId,
    );
  }

  Future<SituationPaiement> calculerSituation(
    Commande commande,
  ) async {
    if (commande.id == null) {
      throw Exception(
        'Commande sans identifiant.',
      );
    }

    final totalPaye =
        await _repository.getTotalPayeCommande(
      commande.id!,
    );

    double reste =
        commande.total - totalPaye;

    if (reste < 0) {
      reste = 0;
    }

    return SituationPaiement(
      totalCommande: commande.total,
      totalPaye: totalPaye,
      resteAPayer: reste,
    );
  }

  Future<PaiementEnregistreResultat>
      enregistrerPaiement({
    required Commande commande,
    required double montant,
    required String modePaiement,
  }) async {
    if (commande.id == null) {
      throw Exception(
        'Commande invalide.',
      );
    }

    if (montant <= 0) {
      throw Exception(
        'Le montant doit être supérieur à zéro.',
      );
    }

    if (modePaiement.trim().isEmpty) {
      throw Exception(
        'Le mode de paiement est obligatoire.',
      );
    }

    final situationAvant =
        await calculerSituation(
      commande,
    );

    if (situationAvant.estPayee) {
      throw Exception(
        'Cette commande est déjà entièrement payée.',
      );
    }

    if (montant >
        situationAvant.resteAPayer + 0.001) {
      throw Exception(
        'Le montant dépasse le reste à payer '
        '(${situationAvant.resteAPayer.toStringAsFixed(0)} FCFA).',
      );
    }

    final paiement = Paiement(
      commandeId: commande.id!,
      montant: montant,
      date: DateTime.now()
          .toIso8601String()
          .substring(0, 10),
      modePaiement:
          modePaiement.trim(),
    );

    await _repository.insertPaiement(
      paiement,
    );

    final situationApres =
        await calculerSituation(
      commande,
    );

    return PaiementEnregistreResultat(
      paiement: paiement,
      situation: situationApres,
    );
  }
}