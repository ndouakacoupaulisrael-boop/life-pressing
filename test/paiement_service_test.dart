import 'package:flutter_test/flutter_test.dart';
import 'package:pressing_app/models/commande.dart';
import 'package:pressing_app/services/paiement_service.dart';

void main() {
  group('SituationPaiement', () {
    test('indique une commande non payée', () {
      const situation = SituationPaiement(
        totalCommande: 2000,
        totalPaye: 0,
        resteAPayer: 2000,
      );

      expect(situation.statut, 'Non payé');
      expect(situation.estPayee, isFalse);
    });

    test('indique une commande partiellement payée', () {
      const situation = SituationPaiement(
        totalCommande: 2000,
        totalPaye: 500,
        resteAPayer: 1500,
      );

      expect(situation.statut, 'Partiellement payé');
      expect(situation.estPayee, isFalse);
    });

    test('indique une commande entièrement payée', () {
      const situation = SituationPaiement(
        totalCommande: 2000,
        totalPaye: 2000,
        resteAPayer: 0,
      );

      expect(situation.statut, 'Payé');
      expect(situation.estPayee, isTrue);
    });
  });

  group('PaiementService', () {
    final service = PaiementService.instance;

    Commande creerCommande({int? id}) {
      return Commande(
        id: id,
        clientId: 1,
        date: '2026-08-15',
        total: 2000,
        statut: 'En attente',
      );
    }

    test('calculerSituation refuse une commande sans identifiant', () async {
      await expectLater(
        service.calculerSituation(creerCommande()),
        throwsA(
          isA<Exception>().having(
            (erreur) => erreur.toString(),
            'message',
            contains('Commande sans identifiant'),
          ),
        ),
      );
    });

    test('enregistrerPaiement refuse une commande sans identifiant', () async {
      await expectLater(
        service.enregistrerPaiement(
          commande: creerCommande(),
          montant: 500,
          modePaiement: 'Espèces',
        ),
        throwsA(
          isA<Exception>().having(
            (erreur) => erreur.toString(),
            'message',
            contains('Commande invalide'),
          ),
        ),
      );
    });

    test('refuse un montant égal à zéro', () async {
      await expectLater(
        service.enregistrerPaiement(
          commande: creerCommande(id: 1),
          montant: 0,
          modePaiement: 'Espèces',
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

    test('refuse un mode de paiement vide', () async {
      await expectLater(
        service.enregistrerPaiement(
          commande: creerCommande(id: 1),
          montant: 500,
          modePaiement: '   ',
        ),
        throwsA(
          isA<Exception>().having(
            (erreur) => erreur.toString(),
            'message',
            contains('mode de paiement est obligatoire'),
          ),
        ),
      );
    });
  });
}
