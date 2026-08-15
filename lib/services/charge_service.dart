import '../models/charge.dart';
import '../repositories/charge_repository.dart';
import 'security_service.dart';
import 'session_service.dart';

class ChargeService {
  ChargeService._();

  static final ChargeService instance = ChargeService._();

  final ChargeRepository _repository = ChargeRepository();

  void _verifierProprietaire() {
    if (!SessionService.estProprietaire) {
      throw Exception('La gestion des charges est réservée au propriétaire.');
    }
  }

  Future<List<Charge>> getCharges() async {
    _verifierProprietaire();

    return _repository.getCharges();
  }

  Future<double> getTotalCharges() async {
    _verifierProprietaire();

    return _repository.getTotalCharges();
  }

  Future<double> getTotalChargesMois() async {
    _verifierProprietaire();

    return _repository.getTotalChargesMois();
  }

  Future<void> ajouterCharge({
    required String libelle,
    required String categorie,
    required double montant,
    required String date,
    String note = '',
  }) async {
    if (libelle.trim().isEmpty) {
      throw Exception('Le libellé est obligatoire.');
    }

    if (categorie.trim().isEmpty) {
      throw Exception('La catégorie est obligatoire.');
    }

    if (date.trim().isEmpty) {
      throw Exception('La date est obligatoire.');
    }

    if (montant <= 0) {
      throw Exception('Le montant doit être supérieur à 0.');
    }

    final autorisee = await SecurityService.verifierActionSensible(
      action: 'AJOUTER_CHARGE',
      cibleType: 'charge',
      description:
          'Ajout de la charge "$libelle" '
          'pour ${montant.toStringAsFixed(0)} FCFA.',
    );

    if (!autorisee) {
      throw Exception('Cette action est réservée au propriétaire.');
    }

    final charge = Charge(
      libelle: libelle.trim(),
      categorie: categorie.trim(),
      montant: montant,
      date: date.trim(),
      note: note.trim(),
    );

    await _repository.ajouterCharge(charge);
  }

  Future<void> modifierCharge(Charge charge) async {
    if (charge.id == null) {
      throw Exception('Charge invalide.');
    }

    if (charge.libelle.trim().isEmpty) {
      throw Exception('Le libellé est obligatoire.');
    }

    if (charge.categorie.trim().isEmpty) {
      throw Exception('La catégorie est obligatoire.');
    }

    if (charge.date.trim().isEmpty) {
      throw Exception('La date est obligatoire.');
    }

    if (charge.montant <= 0) {
      throw Exception('Le montant doit être supérieur à 0.');
    }

    final chargeNormalisee = charge.copyWith(
      libelle: charge.libelle.trim(),
      categorie: charge.categorie.trim(),
      date: charge.date.trim(),
      note: charge.note.trim(),
    );

    final autorisee = await SecurityService.verifierActionSensible(
      action: 'MODIFIER_CHARGE',
      cibleType: 'charge',
      cibleId: chargeNormalisee.id,
      description:
          'Modification de la charge '
          '"${chargeNormalisee.libelle}".',
    );

    if (!autorisee) {
      throw Exception('Cette action est réservée au propriétaire.');
    }

    await _repository.modifierCharge(chargeNormalisee);
  }

  Future<void> supprimerCharge(Charge charge) async {
    if (charge.id == null) {
      throw Exception('Charge invalide.');
    }

    final autorisee = await SecurityService.verifierActionSensible(
      action: 'SUPPRIMER_CHARGE',
      cibleType: 'charge',
      cibleId: charge.id,
      description:
          'Suppression de la charge '
          '"${charge.libelle}" '
          '(${charge.montant.toStringAsFixed(0)} FCFA).',
    );

    if (!autorisee) {
      throw Exception('Cette action est réservée au propriétaire.');
    }

    await _repository.supprimerCharge(charge.id!);
  }
}
