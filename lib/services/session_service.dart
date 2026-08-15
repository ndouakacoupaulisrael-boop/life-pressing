enum RoleUtilisateur { proprietaire, employe }

class SessionService {
  static String? _utilisateur;
  static RoleUtilisateur? _role;

  static String? get utilisateur => _utilisateur;

  static RoleUtilisateur? get role => _role;

  static bool get estConnecte {
    return _utilisateur != null && _role != null;
  }

  static bool get estProprietaire {
    return _role == RoleUtilisateur.proprietaire;
  }

  static bool get estEmploye {
    return _role == RoleUtilisateur.employe;
  }

  static String get roleTexte {
    switch (_role) {
      case RoleUtilisateur.proprietaire:
        return "Propriétaire";

      case RoleUtilisateur.employe:
        return "Employé";

      default:
        return "Inconnu";
    }
  }

  static void ouvrirSession({
    required String utilisateur,
    required RoleUtilisateur role,
  }) {
    final utilisateurNormalise = utilisateur.trim().toLowerCase();

    if (utilisateurNormalise.isEmpty) {
      throw ArgumentError.value(
        utilisateur,
        'utilisateur',
        'Le nom d’utilisateur est obligatoire.',
      );
    }

    _utilisateur = utilisateurNormalise;
    _role = role;
  }

  static void fermerSession() {
    _utilisateur = null;
    _role = null;
  }
}
