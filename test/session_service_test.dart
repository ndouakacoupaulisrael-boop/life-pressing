import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pressing_app/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionService.fermerSession();
  });

  tearDown(() async {
    await SessionService.fermerSession();
  });

  test('la session est fermée par défaut', () {
    expect(SessionService.estConnecte, isFalse);
    expect(SessionService.estProprietaire, isFalse);
    expect(SessionService.estEmploye, isFalse);
    expect(SessionService.utilisateur, isNull);
    expect(SessionService.roleTexte, 'Inconnu');
  });

  test('ouvre une session propriétaire', () {
    SessionService.ouvrirSession(
      utilisateur: '  ADMIN_LIFE ',
      role: RoleUtilisateur.proprietaire,
    );

    expect(SessionService.estConnecte, isTrue);
    expect(SessionService.estProprietaire, isTrue);
    expect(SessionService.estEmploye, isFalse);
    expect(SessionService.utilisateur, 'admin_life');
    expect(SessionService.roleTexte, 'Propriétaire');
  });

  test('ouvre une session employé', () {
    SessionService.ouvrirSession(
      utilisateur: 'employe',
      role: RoleUtilisateur.employe,
    );

    expect(SessionService.estConnecte, isTrue);
    expect(SessionService.estProprietaire, isFalse);
    expect(SessionService.estEmploye, isTrue);
    expect(SessionService.roleTexte, 'Employé');
  });

  test('ferme complètement la session', () async {
    SessionService.ouvrirSession(
      utilisateur: 'proprietaire',
      role: RoleUtilisateur.proprietaire,
    );

    await SessionService.fermerSession();

    expect(SessionService.estConnecte, isFalse);
    expect(SessionService.utilisateur, isNull);
    expect(SessionService.role, isNull);
  });

  test('refuse un nom d’utilisateur vide', () {
    expect(
      () => SessionService.ouvrirSession(
        utilisateur: '   ',
        role: RoleUtilisateur.employe,
      ),
      throwsArgumentError,
    );
  });
}
