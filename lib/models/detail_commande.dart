class DetailCommande {
  final int? id;
  final int commandeId;

  // Identifiant du vêtement choisi dans le catalogue.
  final int? vetementId;

  // Nom conservé pour l’historique de la commande.
  final String vetement;

  // Couleur sélectionnée par l’employé.
  final String couleur;

  final int quantite;

  // Prix unitaire au moment de la commande.
  final double prix;

  const DetailCommande({
    this.id,
    required this.commandeId,
    this.vetementId,
    required this.vetement,
    this.couleur = 'Non précisée',
    required this.quantite,
    required this.prix,
  });

  // Total automatique de la ligne.
  double get total => prix * quantite;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'commandeId': commandeId,
      'vetementId': vetementId,
      'vetement': vetement,
      'couleur': couleur,
      'quantite': quantite,
      'prix': prix,
    };
  }

  factory DetailCommande.fromMap(
    Map<String, dynamic> map,
  ) {
    return DetailCommande(
      id: map['id'] == null
          ? null
          : (map['id'] as num).toInt(),
      commandeId:
          (map['commandeId'] as num).toInt(),
      vetementId: map['vetementId'] == null
          ? null
          : (map['vetementId'] as num).toInt(),
      vetement:
          map['vetement']?.toString() ?? '',
      couleur:
          map['couleur']?.toString() ?? 'Non précisée',
      quantite:
          (map['quantite'] as num).toInt(),
      prix:
          (map['prix'] as num).toDouble(),
    );
  }

  DetailCommande copyWith({
    int? id,
    int? commandeId,
    int? vetementId,
    String? vetement,
    String? couleur,
    int? quantite,
    double? prix,
  }) {
    return DetailCommande(
      id: id ?? this.id,
      commandeId: commandeId ?? this.commandeId,
      vetementId: vetementId ?? this.vetementId,
      vetement: vetement ?? this.vetement,
      couleur: couleur ?? this.couleur,
      quantite: quantite ?? this.quantite,
      prix: prix ?? this.prix,
    );
  }
}