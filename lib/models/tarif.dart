class Tarif {
  int? id;
  int? vetementId;
  String nom;
  String type;
  String modeCalcul;
  double valeur;
  bool actif;

  Tarif({
    this.id,
    this.vetementId,
    required this.nom,
    required this.type,
    required this.modeCalcul,
    required this.valeur,
    this.actif = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vetementId': vetementId,
      'nom': nom,
      'type': type,
      'modeCalcul': modeCalcul,
      'valeur': valeur,
      'actif': actif ? 1 : 0,
    };
  }

  factory Tarif.fromMap(Map<String, dynamic> map) {
    return Tarif(
      id: map['id'],
      vetementId: map['vetementId'],
      nom: map['nom'],
      type: map['type'],
      modeCalcul: map['modeCalcul'],
      valeur: (map['valeur'] as num).toDouble(),
      actif: (map['actif'] ?? 1) == 1,
    );
  }

  Tarif copyWith({
    int? id,
    int? vetementId,
    String? nom,
    String? type,
    String? modeCalcul,
    double? valeur,
    bool? actif,
  }) {
    return Tarif(
      id: id ?? this.id,
      vetementId: vetementId ?? this.vetementId,
      nom: nom ?? this.nom,
      type: type ?? this.type,
      modeCalcul: modeCalcul ?? this.modeCalcul,
      valeur: valeur ?? this.valeur,
      actif: actif ?? this.actif,
    );
  }
}
