import '../database/database_helper.dart';
import '../models/tarif.dart';

class TarifRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> insertTarif(Tarif tarif) async {
    final db = await _db.database;

    return db.insert('tarifs', tarif.toMap());
  }

  Future<List<Tarif>> getTarifs() async {
    final db = await _db.database;

    final maps = await db.query('tarifs', orderBy: 'nom ASC');

    return maps.map((map) => Tarif.fromMap(map)).toList();
  }

  Future<List<Tarif>> getTarifsParVetement(int vetementId) async {
    final db = await _db.database;

    final maps = await db.query(
      'tarifs',
      where: 'vetementId = ?',
      whereArgs: [vetementId],
      orderBy: 'nom ASC',
    );

    return maps.map((map) => Tarif.fromMap(map)).toList();
  }

  Future<int> updateTarif(Tarif tarif) async {
    final db = await _db.database;

    return db.update(
      'tarifs',
      tarif.toMap(),
      where: 'id = ?',
      whereArgs: [tarif.id],
    );
  }

  Future<int> deleteTarif(int id) async {
    final db = await _db.database;

    return db.delete('tarifs', where: 'id = ?', whereArgs: [id]);
  }
}
