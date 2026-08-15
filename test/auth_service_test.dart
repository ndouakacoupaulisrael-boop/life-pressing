import 'package:flutter_test/flutter_test.dart';
import 'package:pressing_app/services/auth_service.dart';
import 'package:pressing_app/services/session_service.dart';

void main() {
  const configurationValide = ConfigurationAuthentification(
    proprietaireUtilisateur: 'proprietaire',
    proprietaireMotDePasse: 'Proprietaire2026',
    employeUtilisateur: 'employe',
    employeMotDePasse: 'Employe2026',
  );

  const service = AuthService(configuration: configurationValide);

  group('ConfigurationAuthentification', () {
    test('accepte une configuration complète et robuste', () {
      expect(configurationValide.estValide, isTrue);
      expect(configurationValide.erreur, isNull);
    });

    test('refuse une configuration incomplète', () {
      const configuration = ConfigurationAuthentification(
        proprietaireUtilisateur: '',
        proprietaireMotDePasse: '',
        employeUtilisateur: '',
        employeMotDePasse: '',
      );

      expect(configuration.estValide, isFalse);
      expect(configuration.erreur, contains('ne sont pas configurés'));
    });

    test('refuse un mot de passe trop faible', () {
      const configuration = ConfigurationAuthentification(
        proprietaireUtilisateur: 'proprietaire',
        proprietaireMotDePasse: '1234',
        employeUtilisateur: 'employe',
        employeMotDePasse: 'Employe2026',
      );

      expect(configuration.estValide, isFalse);
      expect(configuration.erreur, contains('au moins 8 caractères'));
    });

    test('refuse des identifiants identiques', () {
      const configuration = ConfigurationAuthentification(
        proprietaireUtilisateur: 'compte',
        proprietaireMotDePasse: 'Proprietaire2026',
        employeUtilisateur: 'COMPTE',
        employeMotDePasse: 'Employe2026',
      );

      expect(configuration.estValide, isFalse);
      expect(configuration.erreur, contains('doivent être différents'));
    });

    test('refuse des mots de passe identiques', () {
      const configuration = ConfigurationAuthentification(
        proprietaireUtilisateur: 'proprietaire',
        proprietaireMotDePasse: 'AccesPrive2026',
        employeUtilisateur: 'employe',
        employeMotDePasse: 'AccesPrive2026',
      );

      expect(configuration.estValide, isFalse);
      expect(configuration.erreur, contains('mots de passe différents'));
    });
  });

  group('AuthService.authentifier', () {
    test('authentifie le propriétaire', () {
      final resultat = service.authentifier(
        utilisateur: '  PROPRIETAIRE ',
        motDePasse: 'Proprietaire2026',
      );

      expect(resultat, isNotNull);

      final authentification = resultat!;

      expect(authentification.utilisateur, 'proprietaire');
      expect(authentification.role, RoleUtilisateur.proprietaire);
    });

    test('authentifie l’employé', () {
      final resultat = service.authentifier(
        utilisateur: 'employe',
        motDePasse: 'Employe2026',
      );

      expect(resultat, isNotNull);
      expect(resultat!.role, RoleUtilisateur.employe);
    });

    test('refuse un mot de passe incorrect', () {
      final resultat = service.authentifier(
        utilisateur: 'proprietaire',
        motDePasse: 'MotDePasseIncorrect2026',
      );

      expect(resultat, isNull);
    });

    test('échoue explicitement si les accès ne sont pas configurés', () {
      const serviceNonConfigure = AuthService(
        configuration: ConfigurationAuthentification(
          proprietaireUtilisateur: '',
          proprietaireMotDePasse: '',
          employeUtilisateur: '',
          employeMotDePasse: '',
        ),
      );

      expect(
        () => serviceNonConfigure.authentifier(
          utilisateur: 'proprietaire',
          motDePasse: 'Proprietaire2026',
        ),
        throwsStateError,
      );
    });
  });
}
