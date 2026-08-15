import 'package:flutter_test/flutter_test.dart';
import 'package:pressing_app/models/detail_commande.dart';
import 'package:pressing_app/services/commande_service.dart';

void main() {
  const detailValide = DetailCommande(
    commandeId: 0,
    vetement: 'Chemise',
    couleur: 'Blanc',
    quantite: 1,
    prix: 1000,
  );

  final service = CommandeService.instance;

  group('CommandeService.creerCommande', () {
    test('refuse un client invalide', () async {
      await expectLater(
        service.creerCommande(
          clientId: 0,
          date: '2026-08-15',
          statut: 'En attente',
          details: const [detailValide],
        ),
        throwsA(
          isA<Exception>().having(
            (erreur) => erreur.toString(),
            'message',
            contains('Client invalide'),
          ),
        ),
      );
    });

    test('refuse un statut invalide', () async {
      await expectLater(
        service.creerCommande(
          clientId: 1,
          date: '2026-08-15',
          statut: 'Inconnu',
          details: const [detailValide],
        ),
        throwsA(
          isA<Exception>().having(
            (erreur) => erreur.toString(),
            'message',
            contains('Statut de commande invalide'),
          ),
        ),
      );
    });

    test('refuse une commande sans vêtement', () async {
      await expectLater(
        service.creerCommande(
          clientId: 1,
          date: '2026-08-15',
          statut: 'En attente',
          details: const [],
        ),
        throwsA(
          isA<Exception>().having(
            (erreur) => erreur.toString(),
            'message',
            contains('au moins un vêtement'),
          ),
        ),
      );
    });

    test('refuse une quantité égale à zéro', () async {
      await expectLater(
        service.creerCommande(
          clientId: 1,
          date: '2026-08-15',
          statut: 'En attente',
          details: const [
            DetailCommande(
              commandeId: 0,
              vetement: 'Chemise',
              quantite: 0,
              prix: 1000,
            ),
          ],
        ),
        throwsA(
          isA<Exception>().having(
            (erreur) => erreur.toString(),
            'message',
            contains('quantité'),
          ),
        ),
      );
    });

    test('refuse un tarif égal à zéro', () async {
      await expectLater(
        service.creerCommande(
          clientId: 1,
          date: '2026-08-15',
          statut: 'En attente',
          details: const [
            DetailCommande(
              commandeId: 0,
              vetement: 'Chemise',
              quantite: 1,
              prix: 0,
            ),
          ],
        ),
        throwsA(
          isA<Exception>().having(
            (erreur) => erreur.toString(),
            'message',
            contains('supérieur à zéro'),
          ),
        ),
      );
    });
  });
}
