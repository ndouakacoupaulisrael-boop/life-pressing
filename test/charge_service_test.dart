import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pressing_app/models/charge.dart';
import 'package:pressing_app/services/charge_service.dart';
import 'package:pressing_app/services/session_service.dart';

Matcher exceptionContenant(String texte) {
  return throwsA(
    isA<Exception>().having(
      (erreur) => erreur.toString(),
      'message',
      contains(texte),
    ),
  );
}

void main() {
  final service = ChargeService.instance;

  setUp(() async {
    // Base SharedPreferences simulée pour les tests.
    SharedPreferences.setMockInitialValues({});

    // Les charges sont réservées au propriétaire.
    // On ouvre donc une session propriétaire avant chaque test.
    await SessionService.ouvrirSession(
      utilisateur: 'proprietaire_test',
      role: RoleUtilisateur.proprietaire,
    );
  });

  tearDown(() async {
    await SessionService.fermerSession();
  });

  group('ChargeService.ajouterCharge', () {
    test('refuse un libellé vide', () async {
      await expectLater(
        service.ajouterCharge(
          libelle: '   ',
          categorie: 'Électricité',
          montant: 5000,
          date: '2026-08-15',
        ),
        exceptionContenant('libellé est obligatoire'),
      );
    });

    test('refuse une catégorie vide', () async {
      await expectLater(
        service.ajouterCharge(
          libelle: 'Facture CIE',
          categorie: '   ',
          montant: 5000,
          date: '2026-08-15',
        ),
        exceptionContenant('catégorie est obligatoire'),
      );
    });

    test('refuse une date vide', () async {
      await expectLater(
        service.ajouterCharge(
          libelle: 'Facture CIE',
          categorie: 'Électricité',
          montant: 5000,
          date: '   ',
        ),
        exceptionContenant('date est obligatoire'),
      );
    });

    test('refuse un montant égal à zéro', () async {
      await expectLater(
        service.ajouterCharge(
          libelle: 'Facture CIE',
          categorie: 'Électricité',
          montant: 0,
          date: '2026-08-15',
        ),
        exceptionContenant('supérieur à 0'),
      );
    });
  });

  group('ChargeService.modifierCharge', () {
    test('refuse une charge sans identifiant', () async {
      const charge = Charge(
        libelle: 'Facture CIE',
        categorie: 'Électricité',
        montant: 5000,
        date: '2026-08-15',
      );

      await expectLater(
        service.modifierCharge(charge),
        exceptionContenant('Charge invalide'),
      );
    });

    test('refuse un libellé vide', () async {
      const charge = Charge(
        id: 1,
        libelle: '   ',
        categorie: 'Électricité',
        montant: 5000,
        date: '2026-08-15',
      );

      await expectLater(
        service.modifierCharge(charge),
        exceptionContenant('libellé est obligatoire'),
      );
    });

    test('refuse une catégorie vide', () async {
      const charge = Charge(
        id: 1,
        libelle: 'Facture CIE',
        categorie: '   ',
        montant: 5000,
        date: '2026-08-15',
      );

      await expectLater(
        service.modifierCharge(charge),
        exceptionContenant('catégorie est obligatoire'),
      );
    });

    test('refuse une date vide', () async {
      const charge = Charge(
        id: 1,
        libelle: 'Facture CIE',
        categorie: 'Électricité',
        montant: 5000,
        date: '   ',
      );

      await expectLater(
        service.modifierCharge(charge),
        exceptionContenant('date est obligatoire'),
      );
    });

    test('refuse un montant égal à zéro', () async {
      const charge = Charge(
        id: 1,
        libelle: 'Facture CIE',
        categorie: 'Électricité',
        montant: 0,
        date: '2026-08-15',
      );

      await expectLater(
        service.modifierCharge(charge),
        exceptionContenant('supérieur à 0'),
      );
    });
  });

  group('ChargeService.supprimerCharge', () {
    test('refuse une charge sans identifiant', () async {
      const charge = Charge(
        libelle: 'Facture CIE',
        categorie: 'Électricité',
        montant: 5000,
        date: '2026-08-15',
      );

      await expectLater(
        service.supprimerCharge(charge),
        exceptionContenant('Charge invalide'),
      );
    });
  });

  group('ChargeService sécurité', () {
    test('refuse la gestion des charges à un employé', () async {
      await SessionService.fermerSession();

      await SessionService.ouvrirSession(
        utilisateur: 'employe_test',
        role: RoleUtilisateur.employe,
      );

      await expectLater(
        service.ajouterCharge(
          libelle: 'Facture CIE',
          categorie: 'Électricité',
          montant: 5000,
          date: '2026-08-15',
        ),
        exceptionContenant('réservée au propriétaire'),
      );
    });
  });
}
