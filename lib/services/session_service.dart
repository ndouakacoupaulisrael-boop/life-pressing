import 'package:shared_preferences/shared_preferences.dart';

enum RoleUtilisateur { proprietaire, employe }

class SessionService {
  static String? _utilisateur;
  static RoleUtilisateur? _role;

  static const String _cleUtilisateur = 'session_utilisateur';
  static const String _cleRole = 'session_role';

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

  static Future<void> ouvrirSession({
    required String utilisateur,
    required RoleUtilisateur role,
  }) async {
    final utilisateurNormalise =
        utilisateur.trim().toLowerCase();

    if (utilisateurNormalise.isEmpty) {
      throw ArgumentError.value(
        utilisateur,
        'utilisateur',
        'Le nom d’utilisateur est obligatoire.',
      );
    }

    _utilisateur = utilisateurNormalise;
    _role = role;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _cleUtilisateur,
      utilisateurNormalise,
    );

    await prefs.setString(
      _cleRole,
      role.name,
    );
  }

  static Future<bool> restaurerSession() async {
    final prefs = await SharedPreferences.getInstance();

    final utilisateur =
        prefs.getString(_cleUtilisateur);

    final roleTexte =
        prefs.getString(_cleRole);

    if (utilisateur == null ||
        utilisateur.trim().isEmpty ||
        roleTexte == null) {
      return false;
    }

    RoleUtilisateur? role;

    switch (roleTexte) {
      case 'proprietaire':
        role = RoleUtilisateur.proprietaire;
        break;

      case 'employe':
        role = RoleUtilisateur.employe;
        break;

      default:
        return false;
    }

    _utilisateur = utilisateur;
    _role = role;

    return true;
  }

  static Future<void> fermerSession() async {
    _utilisateur = null;
    _role = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_cleUtilisateur);
    await prefs.remove(_cleRole);
  }
}