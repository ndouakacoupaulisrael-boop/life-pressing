class ActionJournal {
  final int? id;
  final String date;
  final String utilisateur;
  final String role;
  final String action;
  final String cibleType;
  final int? cibleId;
  final String description;
  final bool autorisee;
  final bool lue;

  const ActionJournal({
    this.id,
    required this.date,
    required this.utilisateur,
    required this.role,
    required this.action,
    required this.cibleType,
    this.cibleId,
    required this.description,
    required this.autorisee,
    this.lue = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'utilisateur': utilisateur,
      'role': role,
      'action': action,
      'cibleType': cibleType,
      'cibleId': cibleId,
      'description': description,
      'autorisee': autorisee ? 1 : 0,
      'lue': lue ? 1 : 0,
    };
  }

  factory ActionJournal.fromMap(
    Map<String, dynamic> map,
  ) {
    return ActionJournal(
      id: map['id'] == null
          ? null
          : (map['id'] as num).toInt(),
      date: map['date']?.toString() ?? '',
      utilisateur:
          map['utilisateur']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      cibleType:
          map['cibleType']?.toString() ?? '',
      cibleId: map['cibleId'] == null
          ? null
          : (map['cibleId'] as num).toInt(),
      description:
          map['description']?.toString() ?? '',
      autorisee:
          (map['autorisee'] as num?)?.toInt() == 1,
      lue: (map['lue'] as num?)?.toInt() == 1,
    );
  }
}