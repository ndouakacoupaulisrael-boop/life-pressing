import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/tarif.dart';
import 'session_service.dart';

class TarifService {
  TarifService._();

  static final TarifService instance = TarifService._();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // ============================================================
  // LECTURE
  // ============================================================

  Future<List<Tarif>> getTarifs() async {
    final db = await _databaseHelper.database;

    final resultats = await db.query('tarifs', orderBy: 'nom ASC');

    return resultats.map((map) => Tarif.fromMap(map)).toList();
  }

  Future<Tarif?> getTarifById(int id) async {
    final db = await _databaseHelper.database;

    final resultats = await db.query(
      'tarifs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultats.isEmpty) {
      return null;
    }

    return Tarif.fromMap(resultats.first);
  }

  // ============================================================
  // AUTORISATION
  // ============================================================

  void _verifierAutorisation() {
    if (!SessionService.estConnecte) {
      throw Exception('Aucun utilisateur connecté.');
    }

    if (!SessionService.estProprietaire) {
      debugPrint(
        'Tentative non autorisée de '
        'modification des tarifs par '
        '${SessionService.utilisateur ?? "utilisateur inconnu"}.',
      );

      throw Exception(
        'Seul le propriétaire peut '
        'modifier les tarifs.',
      );
    }
  }

  // ============================================================
  // AJOUT
  // ============================================================

  Future<int> ajouterTarif(Tarif tarif) async {
    _verifierAutorisation();

    final db = await _databaseHelper.database;

    final id = await db.insert('tarifs', tarif.toMap());

    debugPrint('Tarif ajouté avec id: $id');

    debugPrint('Tarif: ${tarif.toMap()}');

    return id;
  }

  // ============================================================
  // MODIFICATION
  // ============================================================

  Future<int> modifierTarif(Tarif tarif) async {
    _verifierAutorisation();

    if (tarif.id == null) {
      throw ArgumentError(
        'Impossible de modifier un tarif '
        'sans identifiant.',
      );
    }

    final db = await _databaseHelper.database;

    return db.update(
      'tarifs',
      tarif.toMap(),
      where: 'id = ?',
      whereArgs: [tarif.id],
    );
  }

  // ============================================================
  // SUPPRESSION
  // ============================================================

  Future<int> supprimerTarif(int id) async {
    _verifierAutorisation();

    final db = await _databaseHelper.database;

    return db.delete('tarifs', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================
  // ACTIVATION / DÉSACTIVATION
  // ============================================================

  Future<int> activerOuDesactiverTarif({
    required int id,
    required bool actif,
  }) async {
    _verifierAutorisation();

    final db = await _databaseHelper.database;

    return db.update(
      'tarifs',
      {'actif': actif ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
