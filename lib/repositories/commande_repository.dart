import '../database/database_helper.dart';
import '../models/commande.dart';
import '../models/detail_commande.dart';
import '../models/paiement.dart';

class CommandeRepository {
  final DatabaseHelper _database =
      DatabaseHelper.instance;

  Future<List<Commande>> getCommandes() {
    return _database.getCommandes();
  }

  Future<Commande?> getCommandeById(
    int id,
  ) {
    return _database.getCommandeById(id);
  }

  Future<List<DetailCommande>>
      getDetailsCommande(
    int commandeId,
  ) {
    return _database.getDetailsCommande(
      commandeId,
    );
  }

  Future<List<Paiement>>
      getPaiementsCommande(
    int commandeId,
  ) {
    return _database.getPaiementsCommande(
      commandeId,
    );
  }

  Future<int> creerCommande(
    Commande commande,
    List<DetailCommande> details,
  ) async {
    final commandeId =
        await _database.insertCommande(
      commande,
    );

    for (final detail in details) {
      await _database.insertDetailCommande(
        detail.copyWith(
          commandeId: commandeId,
        ),
      );
    }

    await _database
        .mettreAJourTotalCommande(
      commandeId,
    );

    return commandeId;
  }

  Future<void> modifierCommande(
    Commande commande,
  ) async {
    await _database.updateCommande(
      commande,
    );
  }
  Future<void> modifierCommandeComplete(
  Commande commande,
  List<DetailCommande> details,
) async {
  final commandeId = commande.id;

  if (commandeId == null) {
    throw Exception(
      'Commande invalide.',
    );
  }

  // Récupérer les anciens détails.
  final anciensDetails =
      await _database.getDetailsCommande(
    commandeId,
  );

  // Supprimer les anciennes lignes.
  for (final detail in anciensDetails) {
    if (detail.id != null) {
      await _database.deleteDetailCommande(
        detail.id!,
      );
    }
  }

  // Enregistrer les nouvelles lignes.
  for (final detail in details) {
    await _database.insertDetailCommande(
      detail.copyWith(
        commandeId: commandeId,
      ),
    );
  }

  // Mettre à jour client, date,
  // statut et total.
  await _database.updateCommande(
    commande,
  );

  // Recalcul de sécurité depuis les détails.
  await _database.mettreAJourTotalCommande(
    commandeId,
  );
}

  Future<void> modifierStatut(
    int commandeId,
    String statut,
  ) async {
    await _database.updateStatutCommande(
      commandeId,
      statut,
    );
  }

  Future<void> supprimerCommandeComplete(
    int commandeId,
  ) async {
    // Supprimer les détails associés.
    final details =
        await _database
            .getDetailsCommande(
      commandeId,
    );

    for (final detail in details) {
      if (detail.id != null) {
        await _database
            .deleteDetailCommande(
          detail.id!,
        );
      }
    }

    // Supprimer les paiements associés.
    final paiements =
        await _database
            .getPaiementsCommande(
      commandeId,
    );

    for (final paiement in paiements) {
      if (paiement.id != null) {
        await _database.deletePaiement(
          paiement.id!,
        );
      }
    }

    // Supprimer ensuite la commande.
    await _database.deleteCommande(
      commandeId,
    );
  }
}