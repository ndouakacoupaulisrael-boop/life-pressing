class Paiement {
  int? id;
  int commandeId;
  double montant;
  String date;
  String modePaiement;

  Paiement({
    this.id,
    required this.commandeId,
    required this.montant,
    required this.date,
    required this.modePaiement,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'commandeId': commandeId,
      'montant': montant,
      'date': date,
      'modePaiement': modePaiement,
    };
  }

  factory Paiement.fromMap(Map<String, dynamic> map) {
    return Paiement(
      id: map['id'],
      commandeId: map['commandeId'],
      montant: map['montant'],
      date: map['date'],
      modePaiement: map['modePaiement'],
    );
  }
}

