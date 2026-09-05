import '../database/database_helper.dart';
import '../models/action_journal.dart';
import 'session_service.dart';

class SecurityService {
  SecurityService._();

  /// Vérifie une action qui doit être réservée
  /// au propriétaire.
  ///
  /// La tentative est toujours enregistrée
  /// dans le journal, qu'elle soit autorisée
  /// ou refusée.
  static Future<bool> verifierActionSensible({
    required String action,
    required String cibleType,
    int? cibleId,
    required String description,
  }) async {
    final autorisee = SessionService.estProprietaire;

    await _enregistrerJournal(
      action: action,
      cibleType: cibleType,
      cibleId: cibleId,
      description: description,
      autorisee: autorisee,

      // Une tentative refusée doit rester
      // visible comme notification de sécurité.
      lue: autorisee,
    );

    return autorisee;
  }

  /// Journalise une action normale autorisée.
  ///
  /// Cette méthode est utile pour les opérations
  /// que le propriétaire ET l'employé ont le
  /// droit d'effectuer, comme l'enregistrement
  /// d'un paiement.
  static Future<void> journaliserAction({
    required String action,
    required String cibleType,
    int? cibleId,
    required String description,
  }) async {
    await _enregistrerJournal(
      action: action,
      cibleType: cibleType,
      cibleId: cibleId,
      description: description,
      autorisee: true,
      lue: true,
    );
  }

  static Future<void> _enregistrerJournal({
    required String action,
    required String cibleType,
    int? cibleId,
    required String description,
    required bool autorisee,
    required bool lue,
  }) async {
    final journal = ActionJournal(
      date: DateTime.now().toIso8601String(),
      utilisateur: SessionService.utilisateur ?? 'Utilisateur inconnu',
      role: SessionService.roleTexte,
      action: action,
      cibleType: cibleType,
      cibleId: cibleId,
      description: description,
      autorisee: autorisee,
      lue: lue,
    );

    await DatabaseHelper.instance.insertActionJournal(journal);
  }
}
