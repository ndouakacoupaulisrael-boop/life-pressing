class Tarif {
  int? id;
  String nom;
  double prix;

  Tarif({
    this.id,
    required this.nom,
    required this.prix,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prix': prix,
    };
  }

  factory Tarif.fromMap(Map<String, dynamic> map) {
    return Tarif(
      id: map['id'],
      nom: map['nom'],
      prix: map['prix'],
    );
  }
}