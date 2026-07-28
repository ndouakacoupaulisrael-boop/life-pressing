import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/client.dart';
import '../models/commande.dart';
import '../models/detail_commande.dart';
import '../models/vetement.dart';
import '../models/paiement.dart';
class DatabaseHelper {

  static final DatabaseHelper instance = DatabaseHelper();

  static Database? _database;

  Future<Database> get database async {
  if (_database != null) {
    return _database!;
  }

  _database = await _initDatabase();
  return _database!;
}
Future<int> insertPaiement(Paiement paiement) async {
  final db = await database;
  return await db.insert(
    'paiements',
    paiement.toMap(),
  );
}
Future<List<Paiement>> getPaiements() async {
  final db = await database;

  final List<Map<String, dynamic>> maps =
      await db.query('paiements');

  return List.generate(maps.length, (i) {
    return Paiement.fromMap(maps[i]);
  });
}
Future<int> updatePaiement(Paiement paiement) async {
  final db = await database;

  return await db.update(
    'paiements',
    paiement.toMap(),
    where: 'id = ?',
    whereArgs: [paiement.id],
  );
}
Future<int> deletePaiement(int id) async {
  final db = await database;

  return await db.delete(
    'paiements',
    where: 'id = ?',
    whereArgs: [id],
  );
}
// =======================
// CRUD DetailCommande
// =======================

Future<int> insertDetailCommande(DetailCommande detail) async {
  final db = await database;

  return await db.insert(
    'details_commande',
    detail.toMap(),
  );
}

Future<List<DetailCommande>> getDetailsCommande(int commandeId) async {
  final db = await database;

  final List<Map<String, dynamic>> maps = await db.query(
    'details_commande',
    where: 'commandeId = ?',
    whereArgs: [commandeId],
  );

  return List.generate(
    maps.length,
    (i) => DetailCommande.fromMap(maps[i]),
  );
}

Future<int> deleteDetailCommande(int id) async {
  final db = await database;

  return await db.delete(
    'details_commande',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<double> calculerTotalCommande(int commandeId) async {
  final db = await database;

  final resultat = await db.rawQuery(
    '''
    SELECT SUM(prix * quantite) AS total
    FROM details_commande
    WHERE commandeId = ?
    ''',
    [commandeId],
  );

  if (resultat.first["total"] == null) {
    return 0;
  }

  return (resultat.first["total"] as num).toDouble();
}
Future<int> insertVetement(Vetement vetement) async {
  final db = await database;
  return await db.insert('vetements', vetement.toMap());
}

Future<List<Vetement>> getVetements() async {
  final db = await database;

  final List<Map<String, dynamic>> maps =
      await db.query('vetements');

  return List.generate(
    maps.length,
    (i) => Vetement.fromMap(maps[i]),
  );
}

Future<int> updateVetement(Vetement vetement) async {
  final db = await database;

  return await db.update(
    'vetements',
    vetement.toMap(),
    where: 'id = ?',
    whereArgs: [vetement.id],
  );
}

Future<int> deleteVetement(int id) async {
  final db = await database;

  return await db.delete(
    'vetements',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<Database> _initDatabase() async {
  String path = join(await getDatabasesPath(), 'pressing.db');

  return await openDatabase(
    path,
    version: 3,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
}
Future<void> _onCreate(Database db, int version) async {
  // Table des clients
  await db.execute('''
    CREATE TABLE clients(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nom TEXT NOT NULL,
      prenom TEXT NOT NULL,
      telephone TEXT NOT NULL,
      adresse TEXT NOT NULL
    )
  ''');

  // Table des commandes
  await db.execute('''
    CREATE TABLE commandes(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      clientId INTEGER NOT NULL,
      date TEXT NOT NULL,
      total REAL NOT NULL,
      statut TEXT NOT NULL
    )
  ''');
  // Table des vêtements
await db.execute('''
  CREATE TABLE vetements(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom TEXT NOT NULL,
    prix REAL NOT NULL
  )
''');
  // Table des détails des commandes
  await db.execute('''
    CREATE TABLE details_commande(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      commandeId INTEGER NOT NULL,
      vetement TEXT NOT NULL,
      quantite INTEGER NOT NULL,
      prix REAL NOT NULL
    )
  ''');
  await db.execute('''
CREATE TABLE paiements(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  commandeId INTEGER,
  montant REAL,
  date TEXT,
  modePaiement TEXT
)
''');
}
Future<void> _onUpgrade(
  Database db,
  int oldVersion,
  int newVersion,
) async {
  if (oldVersion < 3) {
    await db.execute('''
      CREATE TABLE paiements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        commandeId INTEGER,
        montant REAL,
        date TEXT,
        modePaiement TEXT
      )
    ''');
  }
}
    
  // CRUD Client
  Future<int> insertClient(Client client) async {
    final db = await database;
    return await db.insert('clients', client.toMap());
  }
  Future<List<Client>> getClients() async {
  final db = await database;

  final List<Map<String, dynamic>> maps =
      await db.query('clients');

  return List.generate(
    maps.length,
    (i) => Client.fromMap(maps[i]),
  );
}
Future<Client?> getClientById(int id) async {
  final db = await database;

  final List<Map<String, dynamic>> maps = await db.query(
    'clients',
    where: 'id = ?',
    whereArgs: [id],
  );

  if (maps.isNotEmpty) {
    return Client.fromMap(maps.first);
  }

  return null;
}

Future<int> updateClient(Client client) async {
  final db = await database;

  return await db.update(
    'clients',
    client.toMap(),
    where: 'id = ?',
    whereArgs: [client.id],
  );
}

Future<int> deleteClient(int id) async {
  final db = await database;

  return await db.delete(
    'clients',
    where: 'id = ?',
    whereArgs: [id],
  );
}
// =======================
// CRUD Commande
// =======================

Future<int> insertCommande(Commande commande) async {
  final db = await database;
  return await db.insert('commandes', commande.toMap());
}

Future<List<Commande>> getCommandes() async {
  final db = await database;

  final List<Map<String, dynamic>> maps =
      await db.query('commandes');

  return List.generate(
    maps.length,
    (i) => Commande.fromMap(maps[i]),
  );
}

Future<int> updateCommande(Commande commande) async {
  final db = await database;

  return await db.update(
    'commandes',
    commande.toMap(),
    where: 'id = ?',
    whereArgs: [commande.id],
  );
}

Future<void> mettreAJourTotalCommande(int commandeId) async {
  final db = await database;

  double total = await calculerTotalCommande(commandeId);

  await db.update(
    'commandes',
    {
      'total': total,
    },
    where: 'id = ?',
    whereArgs: [commandeId],
  );
}

Future<int> deleteCommande(int id) async {
  final db = await database;

  return await db.delete(
    'commandes',
    where: 'id = ?',
    whereArgs: [id],
  );
}
Future<int> getNombreClients() async {
  final db = await database;

  final resultat =
      await db.rawQuery('SELECT COUNT(*) AS total FROM clients');

  return Sqflite.firstIntValue(resultat) ?? 0;
}

Future<int> getNombreCommandes() async {
  final db = await database;

  final resultat =
      await db.rawQuery('SELECT COUNT(*) AS total FROM commandes');

  return Sqflite.firstIntValue(resultat) ?? 0;
}

Future<int> getNombreVetements() async {
  final db = await database;

  final resultat =
      await db.rawQuery('SELECT COUNT(*) AS total FROM vetements');

  return Sqflite.firstIntValue(resultat) ?? 0;
}

Future<double> getTotalPaiements() async {
  final db = await database;

  final resultat = await db.rawQuery(
    'SELECT SUM(montant) AS total FROM paiements',
  );

  if (resultat.first["total"] == null) {
    return 0;
  }

  return (resultat.first["total"] as num).toDouble();
}
}