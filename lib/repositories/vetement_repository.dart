import '../database/database_helper.dart';
import '../models/vetement.dart';

class VetementRepository {
  final DatabaseHelper _database =
      DatabaseHelper.instance;

  Future<List<Vetement>> getVetements() {
    return _database.getVetements();
  }

  Future<int> ajouterVetement(
    Vetement vetement,
  ) {
    return _database.insertVetement(
      vetement,
    );
  }

  Future<int> modifierVetement(
    Vetement vetement,
  ) {
    return _database.updateVetement(
      vetement,
    );
  }

  Future<int> supprimerVetement(
    int id,
  ) {
    return _database.deleteVetement(id);
  }
}