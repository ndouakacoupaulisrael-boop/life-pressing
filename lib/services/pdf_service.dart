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
      final prefs =
          await SharedPreferences.getInstance();

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

        final base64Image =
            valeur.substring(indexVirgule + 1);

        final Uint8List bytes =
            base64Decode(base64Image);

        return pw.MemoryImage(bytes);
      }

      // Base64 direct
      try {
        final Uint8List bytes =
            base64Decode(valeur);

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
static Future<pw.ThemeData>
    _chargerThemePdf() async {
  final policeNormale =
      await PdfGoogleFonts.notoSansRegular();

  final policeGrasse =
      await PdfGoogleFonts.notoSansBold();

  final policeItalique =
      await PdfGoogleFonts.notoSansItalic();

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
            pw.Image(
              logo,
              width: 80,
              height: 80,
              fit: pw.BoxFit.contain,
            ),
            pw.SizedBox(height: 10),
          ],

          pw.Text(
            nomPressing,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          if (adresse.trim().isNotEmpty)
            pw.Text(
              adresse,
              textAlign: pw.TextAlign.center,
            ),

          if (email.trim().isNotEmpty)
            pw.Text(
              email,
              textAlign: pw.TextAlign.center,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CELLULES
  // ============================================================

  static pw.Widget _celluleEntete(
    String texte,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        texte,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _cellule(
    String texte, {
    pw.TextAlign alignement =
        pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        texte,
        textAlign: alignement,
        style: const pw.TextStyle(
          fontSize: 9,
        ),
      ),
    );
  }

  // ============================================================
  // TABLE DES ARTICLES
  // ============================================================

  static pw.Widget _tableArticles(
    List<DetailCommande> articles,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey500,
        width: 0.7,
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.7),
        1: const pw.FlexColumnWidth(1.8),
        2: const pw.FlexColumnWidth(0.8),
        3: const pw.FlexColumnWidth(1.6),
        4: const pw.FlexColumnWidth(1.8),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _celluleEntete("Vêtement"),
            _celluleEntete("Couleur"),
            _celluleEntete("Qté"),
            _celluleEntete("Prix"),
            _celluleEntete("Total"),
          ],
        ),

        ...articles.map(
          (detail) {
            return pw.TableRow(
              children: [
                _cellule(
                  detail.vetement,
                ),

                _cellule(
                  detail.couleur,
                ),

                _cellule(
                  detail.quantite.toString(),
                  alignement:
                      pw.TextAlign.center,
                ),

                _cellule(
                  "${detail.prix.toStringAsFixed(0)} FCFA",
                  alignement:
                      pw.TextAlign.right,
                ),

                _cellule(
                  "${detail.total.toStringAsFixed(0)} FCFA",
                  alignement:
                      pw.TextAlign.right,
                ),
              ],
            );
          },
        ),
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
      mainAxisAlignment:
          pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: gras
                ? pw.FontWeight.bold
                : pw.FontWeight.normal,
          ),
        ),

        pw.Text(
          "${montant.toStringAsFixed(0)} FCFA",
          style: pw.TextStyle(
            fontWeight: gras
                ? pw.FontWeight.bold
                : pw.FontWeight.normal,
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

    final montantCommandeFinal =
        montantCommande ?? montant;

    final paiementEffectueFinal =
        paiementEffectue ?? montant;

    final totalPayeFinal =
        totalPaye ?? paiementEffectueFinal;

    final resteCalcule =
        montantCommandeFinal - totalPayeFinal;

    final resteFinal =
        resteAPayer ??
        (resteCalcule > 0 ? resteCalcule : 0);

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
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Divider(),

            pw.Text(
              "Commande : #$numeroCommande",
            ),

            pw.Text(
              "Client : $client",
            ),

            pw.Text(
              "Téléphone : $telephone",
            ),

            pw.Text(
              "Date : $date",
            ),

            pw.Text(
              "Mode de paiement : $modePaiement",
            ),

            pw.SizedBox(height: 20),

            if (articles.isEmpty)
              pw.Container(
                width: double.infinity,
                padding:
                    const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.grey400,
                  ),
                ),
                child: pw.Center(
                  child: pw.Text(
                    "Aucun vêtement enregistré",
                  ),
                ),
              )
            else
              _tableArticles(articles),

            pw.SizedBox(height: 20),

            if (afficherResumePaiement)
              pw.Container(
                padding:
                    const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(
                    color: PdfColors.grey400,
                  ),
                ),
                child: pw.Column(
                  children: [
                    _ligneMontant(
                      "Montant de la commande",
                      montantCommandeFinal,
                    ),

                    pw.Divider(),

                    _ligneMontant(
                      "Paiement effectué",
                      paiementEffectueFinal,
                    ),

                    pw.Divider(),

                    _ligneMontant(
                      "Total payé",
                      totalPayeFinal,
                    ),

                    pw.Divider(),

                    _ligneMontant(
                      "Reste à payer",
                      resteFinal,
                      gras: true,
                    ),
                  ],
                ),
              )
            else ...[
              pw.Divider(),

              pw.Align(
                alignment:
                    pw.Alignment.centerRight,
                child: pw.Text(
                  "TOTAL : "
                  "${montant.toStringAsFixed(0)} FCFA",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight:
                        pw.FontWeight.bold,
                  ),
                ),
              ),
            ],

            pw.SizedBox(height: 40),

            pw.Center(
              child: pw.Text(
                "Merci pour votre confiance !",
                style: pw.TextStyle(
                  fontStyle:
                      pw.FontStyle.italic,
                ),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      name:
          "recu_commande_$numeroCommande.pdf",
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
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Divider(),

            pw.Text(
              "Commande : #$numeroCommande",
            ),

            pw.Text(
              "Client : $client",
            ),

            pw.Text(
              "Téléphone : $telephone",
            ),

            pw.Text(
              "Date : $date",
            ),

            pw.Text(
              "Statut : $statut",
            ),

            pw.SizedBox(height: 20),

            if (articles.isEmpty)
              pw.Container(
                width: double.infinity,
                padding:
                    const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.grey400,
                  ),
                ),
                child: pw.Center(
                  child: pw.Text(
                    "Aucun vêtement enregistré",
                  ),
                ),
              )
            else
              _tableArticles(articles),

            pw.SizedBox(height: 15),

            pw.Divider(),

            pw.Align(
              alignment:
                  pw.Alignment.centerRight,
              child: pw.Text(
                "TOTAL : "
                "${total.toStringAsFixed(0)} FCFA",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 40),

            pw.Center(
              child: pw.Text(
                "Merci pour votre confiance !",
                style: pw.TextStyle(
                  fontStyle:
                      pw.FontStyle.italic,
                ),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      name:
          "ticket_depot_commande_$numeroCommande.pdf",
      onLayout: (_) async {
        return pdf.save();
      },
    );
  }
}