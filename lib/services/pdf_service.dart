import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/detail_commande.dart';

class PdfService {
  // ============================================================
  // LOGO
  // ============================================================

  static Future<pw.MemoryImage?> chargerLogo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final valeur = prefs.getString("logo");

      if (valeur == null || valeur.trim().isEmpty) {
        return null;
      }

      // Format : data:image/png;base64,...
      if (valeur.startsWith("data:image")) {
        final indexVirgule = valeur.indexOf(',');

        if (indexVirgule == -1) {
          return null;
        }

        final base64Image = valeur.substring(indexVirgule + 1);

        final Uint8List bytes = base64Decode(base64Image);

        return pw.MemoryImage(bytes);
      }

      // Base64 direct
      try {
        final Uint8List bytes = base64Decode(valeur);

        return pw.MemoryImage(bytes);
      } catch (_) {
        // Ancien chemin local.
        // Non exploitable directement sur Flutter Web.
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  static Future<pw.ThemeData> _chargerThemePdf() async {
    final policeNormale = await PdfGoogleFonts.notoSansRegular();

    final policeGrasse = await PdfGoogleFonts.notoSansBold();

    final policeItalique = await PdfGoogleFonts.notoSansItalic();

    return pw.ThemeData.withFont(
      base: policeNormale,
      bold: policeGrasse,
      italic: policeItalique,
    );
  }
  // ============================================================
  // EN-TÊTE
  // ============================================================

  static pw.Widget _entete({
    required pw.MemoryImage? logo,
    required String nomPressing,
    required String adresse,
    required String email,
  }) {
    return pw.Center(
      child: pw.Column(
        children: [
          if (logo != null) ...[
            pw.Image(logo, width: 80, height: 80, fit: pw.BoxFit.contain),
            pw.SizedBox(height: 10),
          ],

          pw.Text(
            nomPressing,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),

          if (adresse.trim().isNotEmpty)
            pw.Text(adresse, textAlign: pw.TextAlign.center),

          if (email.trim().isNotEmpty)
            pw.Text(email, textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }

  // ============================================================
  // CELLULES
  // ============================================================

  static pw.Widget _celluleEntete(String texte) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        texte,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _cellule(
    String texte, {
    pw.TextAlign alignement = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        texte,
        textAlign: alignement,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  // ============================================================
  // TABLE DES ARTICLES
  // ============================================================

  static pw.Widget _tableArticles(List<DetailCommande> articles) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.7),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.7),
        1: const pw.FlexColumnWidth(1.8),
        2: const pw.FlexColumnWidth(0.8),
        3: const pw.FlexColumnWidth(1.6),
        4: const pw.FlexColumnWidth(1.8),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _celluleEntete("Vêtement"),
            _celluleEntete("Couleur"),
            _celluleEntete("Qté"),
            _celluleEntete("Prix"),
            _celluleEntete("Total"),
          ],
        ),

        ...articles.map((detail) {
          return pw.TableRow(
            children: [
              _cellule(detail.vetement),

              _cellule(detail.couleur),

              _cellule(
                detail.quantite.toString(),
                alignement: pw.TextAlign.center,
              ),

              _cellule(
                "${detail.prix.toStringAsFixed(0)} FCFA",
                alignement: pw.TextAlign.right,
              ),

              _cellule(
                "${detail.total.toStringAsFixed(0)} FCFA",
                alignement: pw.TextAlign.right,
              ),
            ],
          );
        }),
      ],
    );
  }

  // ============================================================
  // LIGNE FINANCIÈRE
  // ============================================================

  static pw.Widget _ligneMontant(
    String label,
    double montant, {
    bool gras = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: gras ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),

        pw.Text(
          "${montant.toStringAsFixed(0)} FCFA",
          style: pw.TextStyle(
            fontWeight: gras ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REÇU
  // ============================================================

  static Future<void> genererRecu({
    required String client,
    required String telephone,
    required int numeroCommande,
    required String date,
    required String modePaiement,
    required List<DetailCommande> articles,

    // Conservé pour rester compatible
    // avec les anciens appels de CommandeScreen.
    required double montant,

    required String nomPressing,
    required String adresse,
    required String email,

    // Informations détaillées facultatives.
    double? montantCommande,
    double? paiementEffectue,
    double? totalPaye,
    double? resteAPayer,
  }) async {
    final pdf = pw.Document();

    final logo = await chargerLogo();
    final theme = await _chargerThemePdf();

    final afficherResumePaiement =
        montantCommande != null ||
        paiementEffectue != null ||
        totalPaye != null ||
        resteAPayer != null;

    final montantCommandeFinal = montantCommande ?? montant;

    final paiementEffectueFinal = paiementEffectue ?? montant;

    final totalPayeFinal = totalPaye ?? paiementEffectueFinal;

    final resteCalcule = montantCommandeFinal - totalPayeFinal;

    final resteFinal = resteAPayer ?? (resteCalcule > 0 ? resteCalcule : 0);

    // Une commande est considérée comme soldée uniquement
    // lorsque les informations détaillées de paiement sont disponibles
    // et que le total payé couvre le montant de la commande.
    final estSolde =
        afficherResumePaiement &&
        montantCommandeFinal > 0 &&
        resteFinal <= 0.01 &&
        totalPayeFinal >= montantCommandeFinal - 0.01;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return [
            _entete(
              logo: logo,
              nomPressing: nomPressing,
              adresse: adresse,
              email: email,
            ),

            pw.SizedBox(height: 25),

            pw.Center(
              child: pw.Text(
                "REÇU DE PAIEMENT",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Divider(),

            pw.Text("Commande : #$numeroCommande"),

            pw.Text("Client : $client"),

            pw.Text("Téléphone : $telephone"),

            pw.Text("Date : $date"),

            pw.Text("Mode de paiement : $modePaiement"),

            pw.SizedBox(height: 20),

            if (articles.isEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Center(child: pw.Text("Aucun vêtement enregistré")),
              )
            else
              _tableArticles(articles),

            pw.SizedBox(height: 20),

            if (afficherResumePaiement)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Column(
                  children: [
                    _ligneMontant(
                      "Montant de la commande",
                      montantCommandeFinal,
                    ),

                    pw.Divider(),

                    _ligneMontant("Dernier paiement", paiementEffectueFinal),

                    pw.Divider(),

                    _ligneMontant("Total payé", totalPayeFinal),

                    pw.Divider(),

                    _ligneMontant("Reste à payer", resteFinal, gras: true),
                  ],
                ),
              )
            else ...[
              pw.Divider(),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "TOTAL : "
                  "${montant.toStringAsFixed(0)} FCFA",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],

            if (estSolde) ...[
              pw.SizedBox(height: 14),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green700, width: 1.5),
                ),
                child: pw.Center(
                  child: pw.Text(
                    "SOLDÉ",
                    style: pw.TextStyle(
                      color: PdfColors.green800,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],

            pw.SizedBox(height: 24),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "CONDITIONS IMPORTANTES",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  pw.SizedBox(height: 9),
                  pw.Text(
                    "1. Les articles doivent être retirés dans un délai maximum d'un (1) mois à compter de la date prévue de livraison. Au-delà, des frais de magasinage de 200 FCFA par jour seront appliqués.",
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "2. Passé ce délai d'un mois, la conservation des articles ne peut plus être garantie.",
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "3. En cas de perte ou de dommage imputable au pressing, l'indemnisation est limitée à 20 fois le prix du lavage de l'article concerné.",
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "4. Les retraits partiels ne sont pas acceptés. Les articles d'une même commande doivent être retirés ensemble.",
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "5. Les taches persistantes et les risques de décoloration de certains vêtements ne peuvent être garantis.",
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "6. Toute réclamation doit être faite dans les 24 heures suivant le retrait des articles.",
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "7. Les boutons, fermetures éclair et autres accessoires fragiles ne sont pas garantis.",
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            pw.Center(
              child: pw.Text(
                "Merci pour votre confiance !",
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      name: "recu_commande_$numeroCommande.pdf",
      onLayout: (_) async {
        return pdf.save();
      },
    );
  }

  // ============================================================
  // TICKET DE DÉPÔT
  // ============================================================

  static Future<void> genererTicketDepot({
    required String nomPressing,
    required String adresse,
    required String email,
    required String client,
    required String telephone,
    required int numeroCommande,
    required String date,
    required List<DetailCommande> articles,
    required double total,
    required String statut,
  }) async {
    final pdf = pw.Document();

    final logo = await chargerLogo();
    final theme = await _chargerThemePdf();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        theme: theme,
        build: (context) {
          return [
            _entete(
              logo: logo,
              nomPressing: nomPressing,
              adresse: adresse,
              email: email,
            ),

            pw.SizedBox(height: 25),

            pw.Center(
              child: pw.Text(
                "TICKET DE DÉPÔT",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Divider(),

            pw.Text("Commande : #$numeroCommande"),

            pw.Text("Client : $client"),

            pw.Text("Téléphone : $telephone"),

            pw.Text("Date : $date"),

            pw.Text("Statut : $statut"),

            pw.SizedBox(height: 20),

            if (articles.isEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Center(child: pw.Text("Aucun vêtement enregistré")),
              )
            else
              _tableArticles(articles),

            pw.SizedBox(height: 15),

            pw.Divider(),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "TOTAL : "
                "${total.toStringAsFixed(0)} FCFA",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 40),

            pw.Center(
              child: pw.Text(
                "Merci pour votre confiance !",
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      name: "ticket_depot_commande_$numeroCommande.pdf",
      onLayout: (_) async {
        return pdf.save();
      },
    );
  }
}
