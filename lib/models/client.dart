class Client {
  int? id;
  String nom;
  String prenom;
  String telephone;
  String adresse;

  Client({
    this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.adresse,
  });
  Map<String, dynamic> toMap() {
  return {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'telephone': telephone,
    'adresse': adresse,
  };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      nom: map['nom'],
      prenom: map['prenom'],
      telephone: map['telephone'],
      adresse: map['adresse'],
    );
  }
}