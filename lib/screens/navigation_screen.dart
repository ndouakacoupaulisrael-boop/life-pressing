import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'commande_screen.dart';
import 'paiement_screen.dart';
import 'statistique_screen.dart';
import 'login_screen.dart';
import 'parametre_screen.dart';
import 'notification_screen.dart';
import 'charge_screen.dart';

import '../services/session_service.dart';
import '../services/notification_service.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int currentIndex = 0;

  int _commandeRefreshSignal = 0;

  int _nombreNotifications = 0;

  bool _chargementNotifications = false;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      HomeScreen(onNavigate: _changerPage),
      CommandeScreen(refreshSignal: _commandeRefreshSignal),
      const PaiementScreen(),
      if (SessionService.estProprietaire) ...[
        const StatistiqueScreen(),
        const ParametreScreen(),
        const ChargeScreen(),
      ],
    ];
    if (SessionService.estProprietaire) {
      _chargerNotifications();
    }
  }

  // =========================
  // NAVIGATION
  // =========================

  void _changerPage(int index) {
    if (index < 0 || index >= pages.length) {
      return;
    }

    setState(() {
      if (index == 1) {
        _commandeRefreshSignal++;

        pages[1] = CommandeScreen(refreshSignal: _commandeRefreshSignal);
      }

      currentIndex = index;
    });

    // Quand le propriétaire revient
    // sur l'accueil, on actualise aussi
    // le compteur des notifications.
    if (index == 0 && SessionService.estProprietaire) {
      _chargerNotifications();
    }
  }

  // =========================
  // NOTIFICATIONS
  // =========================

  Future<void> _chargerNotifications() async {
    if (!SessionService.estProprietaire || _chargementNotifications) {
      return;
    }

    _chargementNotifications = true;

    try {
      final nombre = await NotificationService.instance
          .getNombreNotificationsNonLues();

      if (!mounted) return;

      setState(() {
        _nombreNotifications = nombre;
      });
    } catch (e) {
      debugPrint('Erreur chargement notifications : $e');
    } finally {
      _chargementNotifications = false;
    }
  }

  Future<void> _ouvrirNotifications() async {
    if (!SessionService.estProprietaire) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );

    if (!mounted) return;

    await _chargerNotifications();
  }

  Widget _buildNotificationIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_none_rounded),

        if (_nombreNotifications > 0)
          Positioned(
            right: -7,
            top: -7,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _nombreNotifications > 99 ? '99+' : '$_nombreNotifications',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // =========================
  // DECONNEXION
  // =========================

  Future<void> _deconnexion() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('Déconnexion'),
            ],
          ),
          content: const Text('Voulez-vous vraiment vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );

    if (confirmation != true || !mounted) {
      return;
    }

    SessionService.fermerSession();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // =========================
  // APP BAR ACCUEIL
  // =========================

  AppBar _buildHomeAppBar() {
    return AppBar(
      toolbarHeight: 76,
      elevation: 0,
      centerTitle: false,
      foregroundColor: Colors.white,
      backgroundColor: const Color(0xFF2563EB),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF4F7CF7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.local_laundry_service_rounded,
              color: Color(0xFF2563EB),
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Life Pressing',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  SessionService.estConnecte
                      ? '${SessionService.roleTexte} • '
                            '${SessionService.utilisateur}'
                      : 'Gestion intelligente du pressing',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Les notifications de sécurité
        // sont réservées au propriétaire.
        if (SessionService.estProprietaire)
          IconButton(
            tooltip: _nombreNotifications > 0
                ? '$_nombreNotifications notification(s)'
                : 'Notifications',
            onPressed: _ouvrirNotifications,
            icon: _buildNotificationIcon(),
          ),

        IconButton(
          tooltip: 'Déconnexion',
          onPressed: _deconnexion,
          icon: const Icon(Icons.logout_rounded),
        ),

        const SizedBox(width: 4),
      ],
    );
  }

  // =========================
  // INTERFACE
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: currentIndex == 0 ? _buildHomeAppBar() : null,

      body: IndexedStack(index: currentIndex, children: pages),

      floatingActionButton: currentIndex == 0
          ? FloatingActionButton(
              heroTag: 'nouvelle_commande',
              tooltip: 'Nouvelle commande',
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              onPressed: () {
                _changerPage(1);
              },
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDCE8FF),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: _changerPage,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF2563EB)),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_laundry_service_outlined),
            selectedIcon: Icon(
              Icons.local_laundry_service_rounded,
              color: Color(0xFF2563EB),
            ),
            label: 'Commandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment_rounded, color: Color(0xFF2563EB)),
            label: 'Paiements',
          ),
          if (SessionService.estProprietaire) ...[
            const NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(
                Icons.bar_chart_rounded,
                color: Color(0xFF2563EB),
              ),
              label: 'Stats',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(
                Icons.settings_rounded,
                color: Color(0xFF2563EB),
              ),
              label: 'Paramètres',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF2563EB),
              ),
              label: 'Charges',
            ),
          ],
        ],
      ),
    );
  }
}
