class DetailCommande {
  int? id;
  int commandeId;
  String vetement;
  int quantite;
  double prix;

  DetailCommande({
    this.id,
    required this.commandeId,
    required this.vetement,
    required this.quantite,
    required this.prix,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'commandeId': commandeId,
      'vetement': vetement,
      'quantite': quantite,
      'prix': prix,
    };
  }

  factory DetailCommande.fromMap(Map<String, dynamic> map) {
    return DetailCommande(
      id: map['id'],
      commandeId: map['commandeId'],
      vetement: map['vetement'],
      quantite: map['quantite'],
      prix: map['prix'],
    );
  }
}