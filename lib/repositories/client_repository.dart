import '../database/database_helper.dart';
import '../models/client.dart';

class ClientRepository {
  final DatabaseHelper _database =
      DatabaseHelper.instance;

  Future<List<Client>> getClients() {
    return _database.getClients();
  }

  Future<Client?> getClientById(int id) {
    return _database.getClientById(id);
  }

  Future<int> ajouterClient(Client client) {
    return _database.insertClient(client);
  }

  Future<int> modifierClient(Client client) {
    return _database.updateClient(client);
  }

  Future<int> supprimerClient(int id) {
    return _database.deleteClient(id);
  }

  Future<bool> possedeDesCommandes(
    int clientId,
  ) async {
    final commandes =
        await _database.getCommandesParClient(
      clientId,
    );

    return commandes.isNotEmpty;
  }
}