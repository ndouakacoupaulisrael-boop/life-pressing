import '../models/commande.dart';
import '../models/detail_commande.dart';
import '../models/paiement.dart';
import '../repositories/commande_repository.dart';
import 'security_service.dart';
import 'session_service.dart';



class CommandeService {
  CommandeService._();

  static final CommandeService instance =
      CommandeService._();

  final CommandeRepository _repository =
      CommandeRepository();

  static const Set<String> _statutsAutorises = {
    'En attente',
    'En cours',
    'Terminée',
    'Livrée',
  };

  // ============================================================
  // LECTURE
  // ============================================================

  Future<List<Commande>> getCommandes() {
    return _repository.getCommandes();
  }

  Future<Commande?> getCommandeById(
    int id,
  ) {
    return _repository.getCommandeById(id);
  }

  Future<List<DetailCommande>>
      getDetailsCommande(
    int commandeId,
  ) {
    return _repository.getDetailsCommande(
      commandeId,
    );
  }

  Future<List<Paiement>>
      getPaiementsCommande(
    int commandeId,
  ) {
    return _repository.getPaiementsCommande(
      commandeId,
    );
  }

  // ============================================================
  // CRÉATION
  // ============================================================

  Future<int> creerCommande({
    required int clientId,
    required String date,
    required String statut,
    required List<DetailCommande> details,
  }) async {
    if (clientId <= 0) {
      throw Exception(
        'Client invalide.',
      );
    }

    if (date.trim().isEmpty) {
      throw Exception(
        'La date de la commande est obligatoire.',
      );
    }

    if (!_statutsAutorises.contains(statut)) {
      throw Exception(
        'Statut de commande invalide.',
      );
    }

    if (details.isEmpty) {
      throw Exception(
        'La commande doit contenir '
        'au moins un vêtement.',
      );
    }

    for (final detail in details) {
      if (detail.quantite <= 0) {
        throw Exception(
          'La quantité doit être '
          'supérieure à zéro.',
        );
      }
if (detail.prix <= 0) {
  throw Exception(
    'Le tarif de chaque vêtement '
    'doit être supérieur à zéro.',
  );
}
    }

    final total = details.fold<double>(
      0,
      (somme, detail) =>
          somme + detail.total,
    );

    final commande = Commande(
      clientId: clientId,
      date: date.trim(),
      total: total,
      statut: statut,
    );

    return _repository.creerCommande(
      commande,
      details,
    );
  }

  // ============================================================
  // AUTORISATION DE MODIFICATION
  // ============================================================

  Future<bool> autoriserModification(
    Commande commande,
  ) async {
    if (commande.id == null) {
      throw Exception(
        'Commande invalide.',
      );
    }

    return SecurityService
        .verifierActionSensible(
      action: 'MODIFICATION',
      cibleType: 'COMMANDE',
      cibleId: commande.id,
      description:
          'Tentative de modification '
          'de la commande #${commande.id}',
    );
  }

  // ============================================================
  // STATUT DE TRAITEMENT
  // ============================================================
  Future<void> modifierCommande({
  required Commande commandeOriginale,
  required int clientId,
  required String date,
  required String statut,
}) async {
  if (!SessionService.estProprietaire) {
    throw Exception(
      'Seul le propriétaire peut modifier une commande.',
    );
  }

  if (commandeOriginale.id == null) {
    throw Exception('Commande invalide.');
  }

  if (clientId <= 0) {
    throw Exception('Client invalide.');
  }

  if (date.trim().isEmpty) {
    throw Exception(
      'La date de la commande est obligatoire.',
    );
  }

  if (!_statutsAutorises.contains(statut)) {
    throw Exception('Statut invalide.');
  }

  final commandeModifiee = Commande(
    id: commandeOriginale.id,
    clientId: clientId,
    date: date.trim(),
    total: commandeOriginale.total,
    statut: statut,
  );

  await _repository.modifierCommande(
    commandeModifiee,
  );
}
Future<void> modifierCommandeComplete({
  required Commande commandeOriginale,
  required int clientId,
  required String date,
  required String statut,
  required List<DetailCommande> details,
}) async {
  if (!SessionService.estProprietaire) {
    throw Exception(
      'Seul le propriétaire peut modifier une commande.',
    );
  }

  if (commandeOriginale.id == null) {
    throw Exception(
      'Commande invalide.',
    );
  }

  if (clientId <= 0) {
    throw Exception(
      'Client invalide.',
    );
  }

  if (date.trim().isEmpty) {
    throw Exception(
      'La date de la commande est obligatoire.',
    );
  }

  if (!_statutsAutorises.contains(statut)) {
    throw Exception(
      'Statut invalide.',
    );
  }

  if (details.isEmpty) {
    throw Exception(
      'La commande doit contenir '
      'au moins un vêtement.',
    );
  }

  // Sécurité financière :
  // une commande ayant déjà reçu un paiement
  // ne doit pas voir son total modifié.
  final paiements =
      await _repository.getPaiementsCommande(
    commandeOriginale.id!,
  );

  if (paiements.isNotEmpty) {
    throw Exception(
      'Impossible de modifier les vêtements '
      'ou les quantités car cette commande '
      'a déjà reçu un paiement.',
    );
  }

  for (final detail in details) {
    if (detail.quantite <= 0) {
      throw Exception(
        'La quantité doit être supérieure à zéro.',
      );
    }

    if (detail.prix <= 0) {
      throw Exception(
        'Le tarif de chaque vêtement '
        'doit être supérieur à zéro.',
      );
    }
  }

  final total = details.fold<double>(
    0,
    (somme, detail) =>
        somme + detail.total,
  );

  final commandeModifiee = Commande(
    id: commandeOriginale.id,
    clientId: clientId,
    date: date.trim(),
    total: total,
    statut: statut,
  );

  await _repository.modifierCommandeComplete(
    commandeModifiee,
    details,
  );
}
  Future<void> modifierStatut({
    required int commandeId,
    required String statut,
  }) async {
    if (!_statutsAutorises.contains(statut)) {
      throw Exception(
        'Statut invalide.',
      );
    }

    await _repository.modifierStatut(
      commandeId,
      statut,
    );
  }

  // ============================================================
  // SUPPRESSION
  // ============================================================

  Future<bool> supprimerCommande(
    Commande commande,
  ) async {
    if (commande.id == null) {
      throw Exception(
        'Commande invalide.',
      );
    }

    final autorise =
        await SecurityService
            .verifierActionSensible(
      action: 'SUPPRESSION',
      cibleType: 'COMMANDE',
      cibleId: commande.id,
      description:
          'Tentative de suppression '
          'de la commande #${commande.id}',
    );

    if (!autorise) {
      return false;
    }

    // Une commande ayant déjà reçu de l'argent
    // doit rester dans l'historique financier.
    final paiements =
        await _repository
            .getPaiementsCommande(
      commande.id!,
    );

    if (paiements.isNotEmpty) {
      throw Exception(
        'Impossible de supprimer cette commande '
        'car elle possède déjà un ou plusieurs '
        'paiements.',
      );
    }

    await _repository
        .supprimerCommandeComplete(
      commande.id!,
    );

    return true;
  }
}