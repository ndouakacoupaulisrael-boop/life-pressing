import '../models/client.dart';
import '../repositories/client_repository.dart';
import 'security_service.dart';

class ClientService {
  ClientService._();

  static final ClientService instance =
      ClientService._();

  final ClientRepository _repository =
      ClientRepository();

  Future<List<Client>> getClients() {
    return _repository.getClients();
  }

  Future<Client?> getClientById(int id) {
    return _repository.getClientById(id);
  }

  String _nettoyerChamp(String valeur) {
    return valeur.trim();
  }

  void _valider({
    required String nom,
    required String prenom,
    required String telephone,
    required String adresse,
  }) {
    if (nom.trim().length < 2) {
      throw Exception(
        'Le nom du client est invalide.',
      );
    }

    if (prenom.trim().length < 2) {
      throw Exception(
        'Le prénom du client est invalide.',
      );
    }

    final telephoneNettoye =
        telephone
            .replaceAll(' ', '')
            .replaceAll('-', '');

    if (telephoneNettoye.length < 8) {
      throw Exception(
        'Le numéro de téléphone est invalide.',
      );
    }

    if (adresse.trim().isEmpty) {
      throw Exception(
        'L’adresse du client est obligatoire.',
      );
    }
  }

  Future<void> _verifierTelephoneUnique({
    required String telephone,
    int? clientIgnoreId,
  }) async {
    final clients =
        await _repository.getClients();

    final telephoneRecherche =
        telephone
            .replaceAll(' ', '')
            .replaceAll('-', '')
            .trim();

    final existe =
        clients.any(
      (client) {
        if (clientIgnoreId != null &&
            client.id == clientIgnoreId) {
          return false;
        }

        final numeroExistant =
            client.telephone
                .replaceAll(' ', '')
                .replaceAll('-', '')
                .trim();

        return numeroExistant ==
            telephoneRecherche;
      },
    );

    if (existe) {
      throw Exception(
        'Un client avec ce numéro '
        'de téléphone existe déjà.',
      );
    }
  }

  Future<int> ajouterClient({
    required String nom,
    required String prenom,
    required String telephone,
    required String adresse,
  }) async {
    _valider(
      nom: nom,
      prenom: prenom,
      telephone: telephone,
      adresse: adresse,
    );

    await _verifierTelephoneUnique(
      telephone: telephone,
    );

    final client = Client(
      nom: _nettoyerChamp(nom),
      prenom: _nettoyerChamp(prenom),
      telephone:
          _nettoyerChamp(telephone),
      adresse:
          _nettoyerChamp(adresse),
    );

    return _repository.ajouterClient(
      client,
    );
  }

  Future<bool> modifierClient({
    required Client client,
    required String nom,
    required String prenom,
    required String telephone,
    required String adresse,
  }) async {
    if (client.id == null) {
      throw Exception(
        'Client invalide.',
      );
    }

    final autorise =
        await SecurityService
            .verifierActionSensible(
      action: 'MODIFICATION',
      cibleType: 'CLIENT',
      cibleId: client.id,
      description:
          'Tentative de modification '
          'du client ${client.nom} '
          '${client.prenom}',
    );

    if (!autorise) {
      return false;
    }

    _valider(
      nom: nom,
      prenom: prenom,
      telephone: telephone,
      adresse: adresse,
    );

    await _verifierTelephoneUnique(
      telephone: telephone,
      clientIgnoreId: client.id,
    );

    final clientModifie = Client(
      id: client.id,
      nom: _nettoyerChamp(nom),
      prenom: _nettoyerChamp(prenom),
      telephone:
          _nettoyerChamp(telephone),
      adresse:
          _nettoyerChamp(adresse),
    );

    await _repository.modifierClient(
      clientModifie,
    );

    return true;
  }

  Future<bool> supprimerClient(
    Client client,
  ) async {
    if (client.id == null) {
      throw Exception(
        'Client invalide.',
      );
    }

    final autorise =
        await SecurityService
            .verifierActionSensible(
      action: 'SUPPRESSION',
      cibleType: 'CLIENT',
      cibleId: client.id,
      description:
          'Tentative de suppression '
          'du client ${client.nom} '
          '${client.prenom}',
    );

    if (!autorise) {
      return false;
    }

    final possedeDesCommandes =
        await _repository
            .possedeDesCommandes(
      client.id!,
    );

    if (possedeDesCommandes) {
      throw Exception(
        'Impossible de supprimer ce client '
        'car il possède déjà un historique '
        'de commandes.',
      );
    }

    await _repository.supprimerClient(
      client.id!,
    );

    return true;
  }
}