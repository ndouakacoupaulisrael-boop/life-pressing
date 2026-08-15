import '../database/database_helper.dart';
import '../models/charge.dart';

class ChargeRepository {
  final DatabaseHelper _database =
      DatabaseHelper.instance;

  Future<List<Charge>> getCharges() {
    return _database.getCharges();
  }

  Future<int> ajouterCharge(
    Charge charge,
  ) {
    return _database.insertCharge(
      charge,
    );
  }

  Future<int> modifierCharge(
    Charge charge,
  ) {
    return _database.updateCharge(
      charge,
    );
  }

  Future<int> supprimerCharge(
    int id,
  ) {
    return _database.deleteCharge(id);
  }

  Future<double> getTotalCharges() {
    return _database.getTotalCharges();
  }

  Future<double>
      getTotalChargesMois() {
    return _database
        .getTotalChargesMois();
  }
}