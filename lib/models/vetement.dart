class Vetement {
  int? id;
  String nom;
  double prix;

  Vetement({
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

  factory Vetement.fromMap(Map<String, dynamic> map) {
    return Vetement(
      id: map['id'],
      nom: map['nom'],
      prix: map['prix'],
    );
  }
}