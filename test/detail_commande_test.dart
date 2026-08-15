import 'package:flutter_test/flutter_test.dart';
import 'package:pressing_app/models/detail_commande.dart';

void main() {
  group('DetailCommande', () {
    test('calcule correctement le total', () {
      const detail = DetailCommande(
        commandeId: 4,
        vetementId: 2,
        vetement: 'Chemise',
        couleur: 'Bleu',
        quantite: 3,
        prix: 1000,
      );

      expect(detail.total, 3000.0);
    });

    test('conserve les données après conversion en Map', () {
      const detail = DetailCommande(
        id: 7,
        commandeId: 4,
        vetementId: 2,
        vetement: 'Chemise',
        couleur: 'Rouge',
        quantite: 2,
        prix: 1500,
      );

      final resultat = DetailCommande.fromMap(detail.toMap());

      expect(resultat.id, 7);
      expect(resultat.commandeId, 4);
      expect(resultat.vetementId, 2);
      expect(resultat.vetement, 'Chemise');
      expect(resultat.couleur, 'Rouge');
      expect(resultat.quantite, 2);
      expect(resultat.prix, 1500.0);
      expect(resultat.total, 3000.0);
    });

    test('copyWith remplace uniquement les valeurs demandées', () {
      const detail = DetailCommande(
        commandeId: 0,
        vetement: 'Pantalon',
        couleur: 'Gris',
        quantite: 1,
        prix: 1500,
      );

      final copie = detail.copyWith(commandeId: 8, quantite: 2);

      expect(copie.commandeId, 8);
      expect(copie.quantite, 2);
      expect(copie.vetement, 'Pantalon');
      expect(copie.couleur, 'Gris');
      expect(copie.prix, 1500.0);
      expect(copie.total, 3000.0);
    });
  });
}
