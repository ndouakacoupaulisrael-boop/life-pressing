import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/action_journal.dart';
import '../models/client.dart';
import '../models/commande.dart';
import '../models/detail_commande.dart';
import '../models/paiement.dart';
import '../models/parametre.dart';
import '../models/vetement.dart';
import '../models/charge.dart';

class DatabaseHelper {
  static final DatabaseHelper instance =
      DatabaseHelper();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  // =======================
  // PAIEMENTS
  // =======================

  Future<int> insertPaiement(
    Paiement paiement,
  ) async {
    final db = await database;

    return db.insert(
      'paiements',
      paiement.toMap(),
    );
  }

  Future<List<Paiement>>
      getPaiements() async {
    final db = await database;

    final maps =
        await db.query('paiements');

    return List.generate(
      maps.length,
      (index) =>
          Paiement.fromMap(
        maps[index],
      ),
    );
  }

  Future<int> updatePaiement(
    Paiement paiement,
  ) async {
    final db = await database;

    return db.update(
      'paiements',
      paiement.toMap(),
      where: 'id = ?',
      whereArgs: [
        paiement.id,
      ],
    );
  }

  Future<int> deletePaiement(
    int id,
  ) async {
    final db = await database;

    return db.delete(
      'paiements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Paiement>>
      getPaiementsCommande(
    int commandeId,
  ) async {
    final db = await database;

    final maps = await db.query(
      'paiements',
      where: 'commandeId = ?',
      whereArgs: [
        commandeId,
      ],
    );

    return List.generate(
      maps.length,
      (index) =>
          Paiement.fromMap(
        maps[index],
      ),
    );
  }

  Future<double> getTotalPayeCommande(
    int commandeId,
  ) async {
    final paiements =
        await getPaiementsCommande(
      commandeId,
    );

    double total = 0;

    for (final paiement in paiements) {
      total += paiement.montant;
    }

    return total;
  }

  // =======================
  // DETAILS COMMANDE
  // =======================

  Future<int> insertDetailCommande(
    DetailCommande detail,
  ) async {
    final db = await database;

    return db.insert(
      'details_commande',
      detail.toMap(),
    );
  }

  Future<List<DetailCommande>>
      getDetailsCommande(
    int commandeId,
  ) async {
    final db = await database;

    final maps = await db.query(
      'details_commande',
      where: 'commandeId = ?',
      whereArgs: [
        commandeId,
      ],
    );

    return List.generate(
      maps.length,
      (index) =>
          DetailCommande.fromMap(
        maps[index],
      ),
    );
  }

  Future<int> deleteDetailCommande(
    int id,
  ) async {
    final db = await database;

    return db.delete(
      'details_commande',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> calculerTotalCommande(
    int commandeId,
  ) async {
    final db = await database;

    final resultat =
        await db.rawQuery(
      '''
      SELECT SUM(prix * quantite) AS total
      FROM details_commande
      WHERE commandeId = ?
      ''',
      [
        commandeId,
      ],
    );

    if (resultat.isEmpty ||
        resultat.first['total'] == null) {
      return 0;
    }

    return (resultat.first['total']
            as num)
        .toDouble();
  }

  // =======================
  // VETEMENTS
  // =======================

  Future<int> insertVetement(
    Vetement vetement,
  ) async {
    final db = await database;

    return db.insert(
      'vetements',
      vetement.toMap(),
    );
  }

  Future<List<Vetement>>
      getVetements() async {
    final db = await database;

    final maps =
        await db.query('vetements');

    return List.generate(
      maps.length,
      (index) =>
          Vetement.fromMap(
        maps[index],
      ),
    );
  }

  Future<int> updateVetement(
    Vetement vetement,
  ) async {
    final db = await database;

    return db.update(
      'vetements',
      vetement.toMap(),
      where: 'id = ?',
      whereArgs: [
        vetement.id,
      ],
    );
  }

  Future<int> deleteVetement(
    int id,
  ) async {
    final db = await database;

    return db.delete(
      'vetements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =======================
  // INITIALISATION BDD
  // =======================

  Future<Database>
      _initDatabase() async {
    if (kIsWeb) {
      databaseFactory =
          databaseFactoryFfiWeb;
    }

    final String path = kIsWeb
        ? 'pressing.db'
        : join(
            await getDatabasesPath(),
            'pressing.db',
          );

    return openDatabase(
      path,
      version: 10,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
Future<void> _ajouterVetementsParDefaut(
  Database db,
) async {
 const vetementsParDefaut = [
  // =========================
  // HAUTS
  // =========================
  'Chemise',
  'Chemisier',
  'T-shirt',
  'Polo',
  'Débardeur',
  'Top',
  'Blouse',
  'Tunique',
  'Maillot',
  'Maillot de sport',

  // =========================
  // BAS
  // =========================
  'Pantalon',
  'Jean',
  'Short',
  'Bermuda',
  'Jupe',
  'Legging',
  'Jogging',

  // =========================
  // ROBES / ENSEMBLES
  // =========================
  'Robe',
  'Robe de soirée',
  'Robe de mariée',
  'Robe de cérémonie',
  'Combinaison',
  'Ensemble 2 pièces',
  'Ensemble 3 pièces',

  // =========================
  // COSTUMES
  // =========================
  'Costume complet',
  'Veste de costume',
  'Pantalon de costume',
  'Gilet de costume',
  'Smoking',
  'Blazer',
  'Cravate',
  'Nœud papillon',

  // =========================
  // VESTES / MANTEAUX
  // =========================
  'Veste',
  'Manteau',
  'Imperméable',
  'Trench',
  'Blouson',
  'Parka',
  'Doudoune',
  'Coupe-vent',

  // =========================
  // PULLS
  // =========================
  'Pull',
  'Sweat',
  'Sweat à capuche',
  'Cardigan',
  'Gilet',

  // =========================
  // SOUS-VÊTEMENTS
  // =========================
  'Caleçon',
  'Boxer',
  'Slip',
  'Culotte',
  'Soutien-gorge',
  'Body',
  'Chaussettes',
  'Bas',
  'Collants',

  // =========================
  // NUIT
  // =========================
  'Pyjama',
  'Chemise de nuit',
  'Peignoir',
  'Robe de chambre',

  // =========================
  // TENUES TRADITIONNELLES
  // =========================
  'Boubou',
  'Grand boubou',
  'Petit boubou',
  'Pagne',
  'Ensemble pagne',
  'Tenue africaine',
  'Tenue traditionnelle',
  'Kaftan',
  'Caftan',
  'Djellaba',
  'Abaya',
  'Kita',
  'Bazín',
  'Tenue en bazin',

  // =========================
  // TRAVAIL / ÉCOLE
  // =========================
  'Uniforme scolaire',
  'Chemise scolaire',
  'Pantalon scolaire',
  'Jupe scolaire',
  'Tenue de travail',
  'Combinaison de travail',
  'Blouse de travail',
  'Blouse médicale',
  'Tablier',
  'Uniforme',

  // =========================
  // ENFANTS / BÉBÉS
  // =========================
  'Vêtement bébé',
  'Body bébé',
  'Grenouillère',
  'Barboteuse',
  'Ensemble bébé',
  'Robe enfant',
  'Chemise enfant',
  'Pantalon enfant',
  'Short enfant',

  // =========================
  // SPORT
  // =========================
  'Survêtement',
  'Tenue de sport',
  'Short de sport',
  'Pantalon de sport',
  'Maillot de football',
  'Kimono de sport',

  // =========================
  // LINGE DE LIT
  // =========================
  'Drap simple',
  'Drap double',
  'Drap-housse',
  'Taie d’oreiller',
  'Housse de couette',
  'Couette',
  'Couverture',
  'Plaid',
  'Oreiller',
  'Protège-matelas',
  'Alèse',

  // =========================
  // SALLE DE BAIN
  // =========================
  'Serviette',
  'Serviette de bain',
  'Drap de bain',
  'Tapis de bain',

  // =========================
  // CUISINE / TABLE
  // =========================
  'Nappe',
  'Serviette de table',
  'Torchon',
  'Tablier de cuisine',

  // =========================
  // RIDEAUX / MAISON
  // =========================
  'Rideau',
  'Voilage',
  'Double rideau',
  'Housse de canapé',
  'Housse de fauteuil',
  'Housse de chaise',
  'Coussin',
  'Housse de coussin',
  'Tapis',
  'Moquette',

  // =========================
  // ACCESSOIRES
  // =========================
  'Casquette',
  'Chapeau',
  'Bonnet',
  'Écharpe',
  'Foulard',
  'Gants',

  // =========================
  // ARTICLES SPÉCIAUX
  // =========================
  'Sac en tissu',
  'Sac à dos',
  'Peluche',
  'Moustiquaire',
  'Sac de couchage',
  'Autre article',
];

  for (final nom in vetementsParDefaut) {
    final existants = await db.query(
      'vetements',
      where: 'LOWER(nom) = LOWER(?)',
      whereArgs: [nom],
      limit: 1,
    );

    if (existants.isEmpty) {
      await db.insert(
        'vetements',
        {
          'nom': nom,
          'prix': 0.0,
        },
      );
    }
  }
}
  Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    // =======================
    // CLIENTS
    // =======================

    await db.execute(
      '''
      CREATE TABLE clients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        telephone TEXT NOT NULL,
        adresse TEXT NOT NULL
      )
      ''',
    );

    // =======================
    // COMMANDES
    // =======================

    await db.execute(
      '''
      CREATE TABLE commandes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER NOT NULL,
        date TEXT NOT NULL,
        total REAL NOT NULL,
        statut TEXT NOT NULL
      )
      ''',
    );

    // =======================
    // VETEMENTS
    // =======================

    await db.execute(
      '''
      CREATE TABLE vetements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prix REAL NOT NULL
      )
      ''',
    );

    // =======================
    // DETAILS COMMANDE
    // =======================

    await db.execute(
      '''
      CREATE TABLE details_commande(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        commandeId INTEGER NOT NULL,
        vetementId INTEGER,
        vetement TEXT NOT NULL,
        couleur TEXT NOT NULL
          DEFAULT 'Non précisée',
        quantite INTEGER NOT NULL,
        prix REAL NOT NULL
      )
      ''',
    );

    // =======================
    // PAIEMENTS
    // =======================

    await db.execute(
      '''
      CREATE TABLE paiements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        commandeId INTEGER,
        montant REAL,
        date TEXT,
        modePaiement TEXT
      )
      ''',
    );

    // =======================
    // PARAMETRES
    // =======================

    await db.execute(
      '''
      CREATE TABLE parametres(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nomPressing TEXT,
        proprietaire TEXT,
        telephone TEXT,
        adresse TEXT,
        email TEXT
      )
      ''',
    );

    // =======================
    // JOURNAL ACTIONS
    // =======================

    await db.execute(
      '''
      CREATE TABLE journal_actions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        utilisateur TEXT NOT NULL,
        role TEXT NOT NULL,
        action TEXT NOT NULL,
        cibleType TEXT NOT NULL,
        cibleId INTEGER,
        description TEXT NOT NULL,
        autorisee INTEGER NOT NULL
          DEFAULT 0,
        lue INTEGER NOT NULL
          DEFAULT 0
      )
      ''',
    );
    // =======================
// CHARGES
// =======================

await db.execute(
  '''
  CREATE TABLE charges(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    libelle TEXT NOT NULL,
    categorie TEXT NOT NULL,
    montant REAL NOT NULL,
    date TEXT NOT NULL,
    note TEXT NOT NULL DEFAULT ''
  )
  ''',
);
await _ajouterVetementsParDefaut(db);
  }

  // =======================
  // MIGRATIONS
  // =======================

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 3) {
      await db.execute(
        '''
        CREATE TABLE paiements(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          commandeId INTEGER,
          montant REAL,
          date TEXT,
          modePaiement TEXT
        )
        ''',
      );
    }

    if (oldVersion < 4) {
      await db.execute(
        '''
        CREATE TABLE parametres(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nomPressing TEXT,
          proprietaire TEXT,
          telephone TEXT,
          adresse TEXT,
          email TEXT
        )
        ''',
      );
    }

    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE details_commande '
        'ADD COLUMN vetementId INTEGER',
      );

      await db.execute(
        "ALTER TABLE details_commande "
        "ADD COLUMN couleur TEXT "
        "NOT NULL DEFAULT 'Non précisée'",
      );
    }

    if (oldVersion < 6) {
      await db.execute(
        '''
        CREATE TABLE IF NOT EXISTS journal_actions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          utilisateur TEXT NOT NULL,
          role TEXT NOT NULL,
          action TEXT NOT NULL,
          cibleType TEXT NOT NULL,
          cibleId INTEGER,
          description TEXT NOT NULL,
          autorisee INTEGER NOT NULL
            DEFAULT 0
        )
        ''',
      );
    }

    if (oldVersion < 7) {
      // Certaines anciennes bases peuvent
      // ne pas avoir encore journal_actions.
      await db.execute(
        '''
        CREATE TABLE IF NOT EXISTS journal_actions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          utilisateur TEXT NOT NULL,
          role TEXT NOT NULL,
          action TEXT NOT NULL,
          cibleType TEXT NOT NULL,
          cibleId INTEGER,
          description TEXT NOT NULL,
          autorisee INTEGER NOT NULL
            DEFAULT 0,
          lue INTEGER NOT NULL
            DEFAULT 0
        )
        ''',
      );

      final colonnes =
          await db.rawQuery(
        'PRAGMA table_info(journal_actions)',
      );

      final contientLue =
          colonnes.any(
        (colonne) =>
            colonne['name'] == 'lue',
      );

      if (!contientLue) {
        await db.execute(
          'ALTER TABLE journal_actions '
          'ADD COLUMN lue INTEGER '
          'NOT NULL DEFAULT 0',
        );
      }

      // Les anciennes actions autorisées
      // restent dans l'historique mais ne
      // deviennent pas des notifications.
      await db.update(
        'journal_actions',
        {
          'lue': 1,
        },
        where: 'autorisee = ?',
        whereArgs: [1],
      );
    }
    if (oldVersion < 8) {
  await db.execute(
    '''
    CREATE TABLE IF NOT EXISTS charges(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      libelle TEXT NOT NULL,
      categorie TEXT NOT NULL,
      montant REAL NOT NULL,
      date TEXT NOT NULL,
      note TEXT NOT NULL DEFAULT ''
    )
    ''',
  );
}

if (oldVersion < 9) {
  await _ajouterVetementsParDefaut(db);
}
if (oldVersion < 10) {
  await _ajouterVetementsParDefaut(db);
}
  }

      


  // =======================
  // CLIENTS
  // =======================

  Future<int> insertClient(
    Client client,
  ) async {
    final db = await database;

    return db.insert(
      'clients',
      client.toMap(),
    );
  }

  Future<List<Client>>
      getClients() async {
    final db = await database;

    final maps =
        await db.query('clients');

    return List.generate(
      maps.length,
      (index) =>
          Client.fromMap(
        maps[index],
      ),
    );
  }

  Future<Client?> getClientById(
    int id,
  ) async {
    final db = await database;

    final maps = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Client.fromMap(
        maps.first,
      );
    }

    return null;
  }

  Future<int> updateClient(
    Client client,
  ) async {
    final db = await database;

    return db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [
        client.id,
      ],
    );
  }

  Future<int> deleteClient(
    int id,
  ) async {
    final db = await database;

    return db.delete(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Commande>>
      getCommandesParClient(
    int clientId,
  ) async {
    final db = await database;

    final maps = await db.query(
      'commandes',
      where: 'clientId = ?',
      whereArgs: [
        clientId,
      ],
      orderBy: 'date DESC',
    );

    return List.generate(
      maps.length,
      (index) =>
          Commande.fromMap(
        maps[index],
      ),
    );
  }

  // =======================
  // COMMANDES
  // =======================

  Future<int> insertCommande(
    Commande commande,
  ) async {
    final db = await database;

    return db.insert(
      'commandes',
      commande.toMap(),
    );
  }

  Future<List<Commande>>
      getCommandes() async {
    final db = await database;

    final maps =
        await db.query('commandes');

    return List.generate(
      maps.length,
      (index) =>
          Commande.fromMap(
        maps[index],
      ),
    );
  }

  Future<Commande?> getCommandeById(
    int id,
  ) async {
    final db = await database;

    final maps = await db.query(
      'commandes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Commande.fromMap(
        maps.first,
      );
    }

    return null;
  }

  Future<int> updateCommande(
    Commande commande,
  ) async {
    final db = await database;

    return db.update(
      'commandes',
      commande.toMap(),
      where: 'id = ?',
      whereArgs: [
        commande.id,
      ],
    );
  }

  Future<void> updateStatutCommande(
    int commandeId,
    String statut,
  ) async {
    final db = await database;

    await db.update(
      'commandes',
      {
        'statut': statut,
      },
      where: 'id = ?',
      whereArgs: [
        commandeId,
      ],
    );
  }

  Future<void> mettreAJourTotalCommande(
    int commandeId,
  ) async {
    final db = await database;

    final total =
        await calculerTotalCommande(
      commandeId,
    );

    await db.update(
      'commandes',
      {
        'total': total,
      },
      where: 'id = ?',
      whereArgs: [
        commandeId,
      ],
    );
  }

  Future<int> deleteCommande(
    int id,
  ) async {
    final db = await database;

    return db.delete(
      'commandes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =======================
  // STATISTIQUES
  // =======================

  Future<int> getNombreClients() async {
    final db = await database;

    final resultat =
        await db.rawQuery(
      'SELECT COUNT(*) AS total '
      'FROM clients',
    );

    return Sqflite.firstIntValue(
          resultat,
        ) ??
        0;
  }

  Future<int>
      getNombreCommandes() async {
    final db = await database;

    final resultat =
        await db.rawQuery(
      'SELECT COUNT(*) AS total '
      'FROM commandes',
    );

    return Sqflite.firstIntValue(
          resultat,
        ) ??
        0;
  }

  Future<int>
      getNombreVetements() async {
    final db = await database;

    final resultat =
        await db.rawQuery(
      'SELECT COUNT(*) AS total '
      'FROM vetements',
    );

    return Sqflite.firstIntValue(
          resultat,
        ) ??
        0;
  }

  Future<double>
      getTotalPaiements() async {
    final db = await database;

    final resultat =
        await db.rawQuery(
      '''
      SELECT SUM(montant) AS total
      FROM paiements
      ''',
    );

    if (resultat.isEmpty ||
        resultat.first['total'] == null) {
      return 0;
    }

    return (resultat.first['total']
            as num)
        .toDouble();
  }

  Future<int>
      getNombreCommandesEnAttente()
      async {
    final db = await database;

    final resultat =
        await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM commandes
      WHERE statut = 'En attente'
      ''',
    );

    return Sqflite.firstIntValue(
          resultat,
        ) ??
        0;
  }

  Future<int>
      getNombreCommandesTerminees()
      async {
    final db = await database;

    final resultat =
        await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM commandes
      WHERE statut = 'Terminée'
      ''',
    );

    return Sqflite.firstIntValue(
          resultat,
        ) ??
        0;
  }

  Future<double>
      getChiffreAffairesJour() async {
    final db = await database;

    final aujourdHui =
        DateTime.now()
            .toIso8601String()
            .substring(
              0,
              10,
            );

    final resultat =
        await db.rawQuery(
      '''
      SELECT SUM(montant) AS total
      FROM paiements
      WHERE date LIKE ?
      ''',
      [
        '$aujourdHui%',
      ],
    );

    if (resultat.isEmpty ||
        resultat.first['total'] == null) {
      return 0;
    }

    return (resultat.first['total']
            as num)
        .toDouble();
  }

  Future<double>
      getChiffreAffairesMois() async {
    final db = await database;

    final maintenant =
        DateTime.now();

    final mois =
        '${maintenant.year}-'
        '${maintenant.month.toString().padLeft(2, '0')}';

    final resultat =
        await db.rawQuery(
      '''
      SELECT SUM(montant) AS total
      FROM paiements
      WHERE date LIKE ?
      ''',
      [
        '$mois%',
      ],
    );

    if (resultat.isEmpty ||
        resultat.first['total'] == null) {
      return 0;
    }

    return (resultat.first['total']
            as num)
        .toDouble();
  }

  // =======================
  // DEBUG
  // =======================

  Future<void>
      afficherPaiements() async {
    final db = await database;

    final resultat =
        await db.query(
      'paiements',
    );

    debugPrint(
      '========== PAIEMENTS ==========',
    );

    for (final ligne in resultat) {
      debugPrint(
        ligne.toString(),
      );
    }

    debugPrint(
      '========== FIN ==========',
    );
  }

  Future<void>
      afficherCommandes() async {
    final db = await database;

    final resultat =
        await db.query(
      'commandes',
    );

    debugPrint(
      '========== COMMANDES ==========',
    );

    for (final ligne in resultat) {
      debugPrint(
        ligne.toString(),
      );
    }

    debugPrint(
      '========== FIN COMMANDES ==========',
    );
  }

  Future<void> afficherDetailsCommande(
    int commandeId,
  ) async {
    final db = await database;

    final resultat =
        await db.query(
      'details_commande',
      where: 'commandeId = ?',
      whereArgs: [
        commandeId,
      ],
    );

    debugPrint(
      '===== DETAILS COMMANDE '
      '$commandeId =====',
    );

    for (final ligne in resultat) {
      debugPrint(
        ligne.toString(),
      );
    }

    debugPrint(
      '===== FIN =====',
    );
  }

  // =======================
  // PARAMETRES
  // =======================

  Future<int> saveParametre(
    Parametre parametre,
  ) async {
    final db = await database;

    return db.insert(
      'parametres',
      parametre.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  Future<Parametre?>
      getParametre() async {
    final db = await database;

    final resultat =
        await db.query(
      'parametres',
      limit: 1,
    );

    if (resultat.isEmpty) {
      return null;
    }

    return Parametre.fromMap(
      resultat.first,
    );
  }

  Future<int> updateParametre(
    Parametre parametre,
  ) async {
    final db = await database;

    return db.update(
      'parametres',
      parametre.toMap(),
      where: 'id = ?',
      whereArgs: [
        parametre.id,
      ],
    );
  }

  // =======================
  // JOURNAL DES ACTIONS
  // =======================

  Future<int> insertActionJournal(
    ActionJournal action,
  ) async {
    final db = await database;

    return db.insert(
      'journal_actions',
      action.toMap(),
    );
  }

  Future<List<ActionJournal>>
      getActionsJournal({
    int limit = 100,
  }) async {
    final db = await database;

    final maps = await db.query(
      'journal_actions',
      orderBy: 'id DESC',
      limit: limit,
    );

    return maps
        .map(
          (map) =>
              ActionJournal.fromMap(
            map,
          ),
        )
        .toList();
  }

  // =======================
  // NOTIFICATIONS
  // =======================

  Future<List<ActionJournal>>
      getNotificationsNonLues({
    int limit = 50,
  }) async {
    final db = await database;

    final maps = await db.query(
      'journal_actions',
      where:
          'autorisee = ? AND lue = ?',
      whereArgs: [
        0,
        0,
      ],
      orderBy: 'id DESC',
      limit: limit,
    );

    return maps
        .map(
          (map) =>
              ActionJournal.fromMap(
            map,
          ),
        )
        .toList();
  }

  Future<int>
      getNombreNotificationsNonLues()
      async {
    final db = await database;

    final resultat =
        await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM journal_actions
      WHERE autorisee = 0
        AND lue = 0
      ''',
    );

    return Sqflite.firstIntValue(
          resultat,
        ) ??
        0;
  }

  Future<int> marquerActionCommeLue(
    int id,
  ) async {
    final db = await database;

    return db.update(
      'journal_actions',
      {
        'lue': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int>
      marquerToutesNotificationsCommeLues()
      async {
    final db = await database;

    return db.update(
      'journal_actions',
      {
        'lue': 1,
      },
      where:
          'autorisee = ? AND lue = ?',
      whereArgs: [
        0,
        0,
      ],
    );
  }
  // =======================
// CHARGES
// =======================

Future<int> insertCharge(
  Charge charge,
) async {
  final db = await database;

  return db.insert(
    'charges',
    charge.toMap(),
  );
}

Future<List<Charge>> getCharges() async {
  final db = await database;

  final maps = await db.query(
    'charges',
    orderBy: 'date DESC, id DESC',
  );

  return maps
      .map(
        (map) => Charge.fromMap(map),
      )
      .toList();
}

Future<Charge?> getChargeById(
  int id,
) async {
  final db = await database;

  final maps = await db.query(
    'charges',
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );

  if (maps.isEmpty) {
    return null;
  }

  return Charge.fromMap(
    maps.first,
  );
}

Future<int> updateCharge(
  Charge charge,
) async {
  final db = await database;

  return db.update(
    'charges',
    charge.toMap(),
    where: 'id = ?',
    whereArgs: [
      charge.id,
    ],
  );
}

Future<int> deleteCharge(
  int id,
) async {
  final db = await database;

  return db.delete(
    'charges',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<double> getTotalCharges() async {
  final db = await database;

  final resultat =
      await db.rawQuery(
    '''
    SELECT SUM(montant) AS total
    FROM charges
    ''',
  );

  if (resultat.isEmpty ||
      resultat.first['total'] == null) {
    return 0;
  }

  return (resultat.first['total']
          as num)
      .toDouble();
}

Future<double>
    getTotalChargesMois() async {
  final db = await database;

  final maintenant =
      DateTime.now();

  final mois =
      '${maintenant.year}-'
      '${maintenant.month.toString().padLeft(2, '0')}';

  final resultat =
      await db.rawQuery(
    '''
    SELECT SUM(montant) AS total
    FROM charges
    WHERE date LIKE ?
    ''',
    [
      '$mois%',
    ],
  );

  if (resultat.isEmpty ||
      resultat.first['total'] == null) {
    return 0;
  }

  return (resultat.first['total']
          as num)
      .toDouble();
}
}