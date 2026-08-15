import 'package:flutter/material.dart';

import '../models/action_journal.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
  });

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState
    extends State<NotificationScreen> {
  List<ActionJournal> actions = [];

  bool chargement = true;
  bool traitement = false;

  int nombreNonLues = 0;

  @override
  void initState() {
    super.initState();

    _charger();
  }

  Future<void> _charger() async {
    if (!SessionService.estProprietaire) {
      if (!mounted) return;

      setState(() {
        chargement = false;
      });

      return;
    }

    try {
      final journal =
          await NotificationService.instance
              .getJournal();

      final compteur =
          await NotificationService.instance
              .getNombreNotificationsNonLues();

      if (!mounted) return;

      setState(() {
        actions = journal;
        nombreNonLues = compteur;
        chargement = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        chargement = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _marquerCommeLue(
    ActionJournal action,
  ) async {
    if (action.lue ||
        action.autorisee ||
        action.id == null) {
      return;
    }

    try {
      await NotificationService.instance
          .marquerCommeLue(
        action,
      );

      await _charger();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void>
      _marquerToutesCommeLues() async {
    if (nombreNonLues == 0 ||
        traitement) {
      return;
    }

    setState(() {
      traitement = true;
    });

    try {
      await NotificationService.instance
          .marquerToutesCommeLues();

      await _charger();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Toutes les notifications ont été marquées comme lues.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          traitement = false;
        });
      }
    }
  }

  String _formaterDate(
    String valeur,
  ) {
    final date =
        DateTime.tryParse(valeur);

    if (date == null) {
      return valeur;
    }

    final jour =
        date.day.toString().padLeft(2, '0');

    final mois =
        date.month.toString().padLeft(2, '0');

    final heure =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$jour/$mois/${date.year} '
        'à $heure:$minute';
  }

  Color _couleurAction(
    ActionJournal action,
  ) {
    if (!action.autorisee &&
        !action.lue) {
      return Colors.red;
    }

    if (!action.autorisee) {
      return Colors.orange;
    }

    return Colors.green;
  }

  IconData _iconeAction(
    ActionJournal action,
  ) {
    if (!action.autorisee) {
      return Icons.warning_amber_rounded;
    }

    return Icons.check_circle_outline;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (!SessionService.estProprietaire) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Journal de sécurité',
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 60,
                  color: Colors.orange,
                ),
                SizedBox(height: 16),
                Text(
                  'Accès réservé au propriétaire.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Journal de sécurité',
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _charger,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: chargement
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                children: [
                  Card(
                    color:
                        nombreNonLues > 0
                            ? Colors.red
                                .shade50
                            : Colors.green
                                .shade50,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                nombreNonLues >
                                        0
                                    ? Colors.red
                                    : Colors.green,
                            foregroundColor:
                                Colors.white,
                            child: Text(
                              '$nombreNonLues',
                            ),
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Text(
                                  'Notifications de sécurité',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        17,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  nombreNonLues ==
                                          0
                                      ? 'Aucune nouvelle alerte.'
                                      : '$nombreNonLues alerte(s) non lue(s).',
                                ),
                              ],
                            ),
                          ),

                          if (nombreNonLues >
                              0)
                            TextButton(
                              onPressed:
                                  traitement
                                      ? null
                                      : _marquerToutesCommeLues,
                              child:
                                  const Text(
                                'Tout lire',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  const Text(
                    'Historique des actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  if (actions.isEmpty)
                    const Card(
                      child: Padding(
                        padding:
                            EdgeInsets.all(
                          30,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons
                                  .history_rounded,
                              size: 50,
                              color:
                                  Colors.grey,
                            ),
                            SizedBox(
                              height: 12,
                            ),
                            Text(
                              'Aucune action enregistrée.',
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...actions.map(
                      (action) {
                        final couleur =
                            _couleurAction(
                          action,
                        );

                        final estNouvelleAlerte =
                            !action
                                    .autorisee &&
                                !action.lue;

                        return Card(
                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 10,
                          ),
                          color:
                              estNouvelleAlerte
                                  ? Colors.red
                                      .shade50
                                  : null,
                          child: ListTile(
                            onTap:
                                estNouvelleAlerte
                                    ? () =>
                                        _marquerCommeLue(
                                          action,
                                        )
                                    : null,

                            leading:
                                CircleAvatar(
                              backgroundColor:
                                  couleur
                                      .withValues(
                                alpha:
                                    0.15,
                              ),
                              foregroundColor:
                                  couleur,
                              child: Icon(
                                _iconeAction(
                                  action,
                                ),
                              ),
                            ),

                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${action.action} • ${action.cibleType}',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          estNouvelleAlerte
                                              ? FontWeight
                                                  .bold
                                              : FontWeight
                                                  .w600,
                                    ),
                                  ),
                                ),

                                if (estNouvelleAlerte)
                                  Container(
                                    width: 9,
                                    height: 9,
                                    decoration:
                                        const BoxDecoration(
                                      color:
                                          Colors.red,
                                      shape:
                                          BoxShape
                                              .circle,
                                    ),
                                  ),
                              ],
                            ),

                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const SizedBox(
                                  height: 6,
                                ),

                                Text(
                                  action.description,
                                ),

                                const SizedBox(
                                  height: 6,
                                ),

                                Text(
                                  '${action.utilisateur} • '
                                  '${action.role}',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w500,
                                  ),
                                ),

                                const SizedBox(
                                  height: 3,
                                ),

                                Text(
                                  _formaterDate(
                                    action.date,
                                  ),
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.grey
                                            .shade600,
                                    fontSize:
                                        12,
                                  ),
                                ),

                                if (!action
                                    .autorisee) ...[
                                  const SizedBox(
                                    height: 6,
                                  ),
                                  Text(
                                    'Action refusée',
                                    style:
                                        TextStyle(
                                      color:
                                          couleur,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}