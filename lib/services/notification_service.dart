import '../database/database_helper.dart';
import '../models/action_journal.dart';
import 'session_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final DatabaseHelper _database =
      DatabaseHelper.instance;

  void _verifierProprietaire() {
    if (!SessionService.estProprietaire) {
      throw Exception(
        'Cette fonctionnalité est réservée au propriétaire.',
      );
    }
  }

  Future<List<ActionJournal>> getJournal({
    int limit = 100,
  }) async {
    _verifierProprietaire();

    return _database.getActionsJournal(
      limit: limit,
    );
  }

  Future<List<ActionJournal>>
      getNotificationsNonLues({
    int limit = 50,
  }) async {
    _verifierProprietaire();

    return _database.getNotificationsNonLues(
      limit: limit,
    );
  }

  Future<int>
      getNombreNotificationsNonLues() async {
    _verifierProprietaire();

    return _database
        .getNombreNotificationsNonLues();
  }

  Future<void> marquerCommeLue(
    ActionJournal action,
  ) async {
    _verifierProprietaire();

    if (action.id == null || action.lue) {
      return;
    }

    await _database.marquerActionCommeLue(
      action.id!,
    );
  }

  Future<void>
      marquerToutesCommeLues() async {
    _verifierProprietaire();

    await _database
        .marquerToutesNotificationsCommeLues();
  }
}