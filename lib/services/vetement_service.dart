import '../models/vetement.dart';
import '../repositories/vetement_repository.dart';
import 'security_service.dart';

class VetementService {
  VetementService._();

  static final VetementService instance =
      VetementService._();

  final VetementRepository _repository =
      VetementRepository();

  Future<List<Vetement>> getVetements() {
    return _repository.getVetements();
  }

  Future<int> ajouterVetement({
    required String nom,
    required double prix,
  }) async {
    final nomPropre = nom.trim();

    if (nomPropre.length < 2) {
      throw Exception(
        'Le nom du vêtement est invalide.',
      );
    }

    if (prix <= 0) {
      throw Exception(
        'Le tarif doit être supérieur à zéro.',
      );
    }

    final vetements =
        await _repository.getVetements();

    final existeDeja =
        vetements.any(
      (vetement) =>
          vetement.nom
              .trim()
              .toLowerCase() ==
          nomPropre.toLowerCase(),
    );

    if (existeDeja) {
      throw Exception(
        'Ce vêtement existe déjà.',
      );
    }

    final vetement = Vetement(
      nom: nomPropre,
      prix: prix,
    );

    return _repository.ajouterVetement(
      vetement,
    );
  }

  Future<bool> modifierVetement({
    required Vetement vetement,
    required String nouveauNom,
    required double nouveauPrix,
  }) async {
    if (vetement.id == null) {
      throw Exception(
        'Vêtement invalide.',
      );
    }

    final autorise =
        await SecurityService
            .verifierActionSensible(
      action: 'MODIFICATION',
      cibleType: 'VETEMENT',
      cibleId: vetement.id,
      description:
          'Tentative de modification '
          'du vêtement ${vetement.nom}',
    );

    if (!autorise) {
      return false;
    }

    final nomPropre =
        nouveauNom.trim();

    if (nomPropre.length < 2) {
      throw Exception(
        'Le nom du vêtement est invalide.',
      );
    }

    if (nouveauPrix <= 0) {
      throw Exception(
        'Le tarif doit être supérieur à zéro.',
      );
    }

    final vetementModifie =
        Vetement(
      id: vetement.id,
      nom: nomPropre,
      prix: nouveauPrix,
    );

    await _repository.modifierVetement(
      vetementModifie,
    );

    return true;
  }

  Future<bool> supprimerVetement(
    Vetement vetement,
  ) async {
    if (vetement.id == null) {
      throw Exception(
        'Vêtement invalide.',
      );
    }

    final autorise =
        await SecurityService
            .verifierActionSensible(
      action: 'SUPPRESSION',
      cibleType: 'VETEMENT',
      cibleId: vetement.id,
      description:
          'Tentative de suppression '
          'du vêtement ${vetement.nom}',
    );

    if (!autorise) {
      return false;
    }

    await _repository.supprimerVetement(
      vetement.id!,
    );

    return true;
  }
}