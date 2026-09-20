import 'dart:typed_data';

class Charge {
  final int? id;
  final String libelle;
  final String categorie;
  final double montant;
  final String date;
  final String note;

  final String? pieceJustificativeNom;
  final Uint8List? pieceJustificative;

  const Charge({
    this.id,
    required this.libelle,
    required this.categorie,
    required this.montant,
    required this.date,
    this.note = '',
    this.pieceJustificativeNom,
    this.pieceJustificative,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'libelle': libelle,
      'categorie': categorie,
      'montant': montant,
      'date': date,
      'note': note,
      'pieceJustificativeNom': pieceJustificativeNom,
      'pieceJustificative': pieceJustificative,
    };
  }

  factory Charge.fromMap(Map<String, dynamic> map) {
    return Charge(
      id: map['id'] == null ? null : (map['id'] as num).toInt(),
      libelle: map['libelle']?.toString() ?? '',
      categorie: map['categorie']?.toString() ?? '',
      montant: (map['montant'] as num?)?.toDouble() ?? 0,
      date: map['date']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      pieceJustificativeNom: map['pieceJustificativeNom']?.toString(),
      pieceJustificative: map['pieceJustificative'] is Uint8List
          ? map['pieceJustificative'] as Uint8List
          : null,
    );
  }

  Charge copyWith({
    int? id,
    String? libelle,
    String? categorie,
    double? montant,
    String? date,
    String? note,
    String? pieceJustificativeNom,
    Uint8List? pieceJustificative,
  }) {
    return Charge(
      id: id ?? this.id,
      libelle: libelle ?? this.libelle,
      categorie: categorie ?? this.categorie,
      montant: montant ?? this.montant,
      date: date ?? this.date,
      note: note ?? this.note,
      pieceJustificativeNom:
          pieceJustificativeNom ?? this.pieceJustificativeNom,
      pieceJustificative: pieceJustificative ?? this.pieceJustificative,
    );
  }
}
