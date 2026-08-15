import '../database/database_helper.dart';
import '../models/commande.dart';
import '../models/paiement.dart';

class PaiementRepository {
  final DatabaseHelper _database =
      DatabaseHelper.instance;

  Future<List<Paiement>> getPaiements() {
    return _database.getPaiements();
  }

  Future<List<Paiement>> getPaiementsCommande(
    int commandeId,
  ) {
    return _database.getPaiementsCommande(
      commandeId,
    );
  }

  Future<double> getTotalPayeCommande(
    int commandeId,
  ) {
    return _database.getTotalPayeCommande(
      commandeId,
    );
  }

  Future<Commande?> getCommandeById(
    int commandeId,
  ) {
    return _database.getCommandeById(
      commandeId,
    );
  }

  Future<int> insertPaiement(
    Paiement paiement,
  ) {
    return _database.insertPaiement(
      paiement,
    );
  }
}