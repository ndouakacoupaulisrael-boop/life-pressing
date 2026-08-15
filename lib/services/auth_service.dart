import 'session_service.dart';

class ConfigurationAuthentification {
  final String proprietaireUtilisateur;
  final String proprietaireMotDePasse;
  final String employeUtilisateur;
  final String employeMotDePasse;

  const ConfigurationAuthentification({
    required this.proprietaireUtilisateur,
    required this.proprietaireMotDePasse,
    required this.employeUtilisateur,
    required this.employeMotDePasse,
  });

  String? get erreur {
    if (proprietaireUtilisateur.trim().isEmpty ||
        proprietaireMotDePasse.isEmpty ||
        employeUtilisateur.trim().isEmpty ||
        employeMotDePasse.isEmpty) {
      return 'Les accès propriétaire et employé ne sont pas configurés.';
    }

    final proprietaire = proprietaireUtilisateur.trim().toLowerCase();
    final employe = employeUtilisateur.trim().toLowerCase();

    if (proprietaire == employe) {
      return 'Les noms d’utilisateur doivent être différents.';
    }

    if (!_motDePasseRobuste(proprietaireMotDePasse) ||
        !_motDePasseRobuste(employeMotDePasse)) {
      return 'Chaque mot de passe doit contenir au moins 8 caractères, '
          'une lettre et un chiffre.';
    }

    if (proprietaireMotDePasse == employeMotDePasse) {
      return 'Le propriétaire et l’employé doivent avoir des mots de passe '
          'différents.';
    }

    return null;
  }

  bool get estValide => erreur == null;

  static bool _motDePasseRobuste(String valeur) {
    return valeur.length >= 8 &&
        RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(valeur) &&
        RegExp(r'[0-9]').hasMatch(valeur);
  }
}

class ResultatAuthentification {
  final String utilisateur;
  final RoleUtilisateur role;

  const ResultatAuthentification({
    required this.utilisateur,
    required this.role,
  });
}

class AuthService {
  final ConfigurationAuthentification configuration;

  const AuthService({required this.configuration});

  static const AuthService instance = AuthService(
    configuration: ConfigurationAuthentification(
      proprietaireUtilisateur: String.fromEnvironment('OWNER_USERNAME'),
      proprietaireMotDePasse: String.fromEnvironment('OWNER_PASSWORD'),
      employeUtilisateur: String.fromEnvironment('EMPLOYEE_USERNAME'),
      employeMotDePasse: String.fromEnvironment('EMPLOYEE_PASSWORD'),
    ),
  );

  bool get estConfigure => configuration.estValide;

  String? get erreurConfiguration => configuration.erreur;

  ResultatAuthentification? authentifier({
    required String utilisateur,
    required String motDePasse,
  }) {
    final erreur = erreurConfiguration;

    if (erreur != null) {
      throw StateError(erreur);
    }

    final utilisateurNormalise = utilisateur.trim().toLowerCase();
    final proprietaireNormalise = configuration.proprietaireUtilisateur
        .trim()
        .toLowerCase();
    final employeNormalise = configuration.employeUtilisateur
        .trim()
        .toLowerCase();

    if (utilisateurNormalise == proprietaireNormalise &&
        _egaliteConstante(motDePasse, configuration.proprietaireMotDePasse)) {
      return ResultatAuthentification(
        utilisateur: proprietaireNormalise,
        role: RoleUtilisateur.proprietaire,
      );
    }

    if (utilisateurNormalise == employeNormalise &&
        _egaliteConstante(motDePasse, configuration.employeMotDePasse)) {
      return ResultatAuthentification(
        utilisateur: employeNormalise,
        role: RoleUtilisateur.employe,
      );
    }

    return null;
  }

  static bool _egaliteConstante(String valeur, String attendue) {
    final valeurCodes = valeur.codeUnits;
    final attenduCodes = attendue.codeUnits;
    final longueur = valeurCodes.length > attenduCodes.length
        ? valeurCodes.length
        : attenduCodes.length;

    var difference = valeurCodes.length ^ attenduCodes.length;

    for (var index = 0; index < longueur; index++) {
      final codeValeur = index < valeurCodes.length ? valeurCodes[index] : 0;
      final codeAttendu = index < attenduCodes.length ? attenduCodes[index] : 0;

      difference |= codeValeur ^ codeAttendu;
    }

    return difference == 0;
  }
}
