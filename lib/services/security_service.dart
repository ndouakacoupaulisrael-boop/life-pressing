import '../database/database_helper.dart';
import '../models/action_journal.dart';
import 'session_service.dart';

class SecurityService {
  SecurityService._();

  static Future<bool> verifierActionSensible({
    required String action,
    required String cibleType,
    int? cibleId,
    required String description,
  }) async {
    final autorisee =
        SessionService.estProprietaire;

    final journal = ActionJournal(
      date: DateTime.now().toIso8601String(),
      utilisateur:
          SessionService.utilisateur ??
              'Utilisateur inconnu',
      role: SessionService.roleTexte,
      action: action,
      cibleType: cibleType,
      cibleId: cibleId,
      description: description,
      autorisee: autorisee,

      // Une action autorisée du propriétaire
      // reste dans l'historique mais ne doit
      // pas devenir une notification non lue.
      lue: autorisee,
    );

    await DatabaseHelper.instance
        .insertActionJournal(
      journal,
    );

    return autorisee;
  }
}