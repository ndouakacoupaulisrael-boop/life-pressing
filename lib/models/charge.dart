class Charge {
  final int? id;
  final String libelle;
  final String categorie;
  final double montant;
  final String date;
  final String note;

  const Charge({
    this.id,
    required this.libelle,
    required this.categorie,
    required this.montant,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'libelle': libelle,
      'categorie': categorie,
      'montant': montant,
      'date': date,
      'note': note,
    };
  }

  factory Charge.fromMap(
    Map<String, dynamic> map,
  ) {
    return Charge(
      id: map['id'] == null
          ? null
          : (map['id'] as num).toInt(),
      libelle:
          map['libelle']?.toString() ?? '',
      categorie:
          map['categorie']?.toString() ?? '',
      montant:
          (map['montant'] as num?)?.toDouble() ??
              0,
      date: map['date']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
    );
  }

  Charge copyWith({
    int? id,
    String? libelle,
    String? categorie,
    double? montant,
    String? date,
    String? note,
  }) {
    return Charge(
      id: id ?? this.id,
      libelle: libelle ?? this.libelle,
      categorie:
          categorie ?? this.categorie,
      montant: montant ?? this.montant,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}