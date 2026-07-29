class Commande {
  int? id;
  int clientId;
  String date;
  double total;
  String statut;

  Commande({
    this.id,
    required this.clientId,
    required this.date,
    required this.total,
    required this.statut,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'date': date,
      'total': total,
      'statut': statut,
    };
  }

  factory Commande.fromMap(Map<String, dynamic> map) {
    return Commande(
      id: map['id'],
      clientId: map['clientId'],
      date: map['date'],
      total: map['total'],
      statut: map['statut'],
    );
  }
}