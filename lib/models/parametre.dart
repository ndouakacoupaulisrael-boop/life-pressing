class Parametre {
  final int? id;
  final String nomPressing;
  final String proprietaire;
  final String telephone;
  final String adresse;
  final String email;

  Parametre({
    this.id,
    required this.nomPressing,
    required this.proprietaire,
    required this.telephone,
    required this.adresse,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomPressing': nomPressing,
      'proprietaire': proprietaire,
      'telephone': telephone,
      'adresse': adresse,
      'email': email,
    };
  }

  factory Parametre.fromMap(Map<String, dynamic> map) {
    return Parametre(
      id: map['id'],
      nomPressing: map['nomPressing'],
      proprietaire: map['proprietaire'],
      telephone: map['telephone'],
      adresse: map['adresse'],
      email: map['email'],
    );
  }
}