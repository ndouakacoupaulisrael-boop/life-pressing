import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> genererRecu({
    required String client,
required String telephone,
required int numeroCommande,
required String date,
required String modePaiement,
required List<String> articles,
required double montant,
    
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "LIFE PRESSING",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                pw.Text("Reçu de paiement"),
                pw.Divider(),
                pw.Text("Commande : #$numeroCommande"),
pw.Text("Client : $client"),
pw.Text("Téléphone : $telephone"),
pw.Text("Date : $date"),
pw.Text("Mode de paiement : $modePaiement"),

pw.SizedBox(height: 20),

pw.Text(
  "Articles",
  style: pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 16,
  ),
),

pw.Divider(),

...articles.map(
  (article) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Text(article),
  ),
),

pw.Divider(),

pw.SizedBox(height: 15),

pw.Text(
  "Montant : ${montant.toStringAsFixed(0)} FCFA",
  style: pw.TextStyle(
    fontSize: 18,
    fontWeight: pw.FontWeight.bold,
  ),
),
pw.Spacer(),

pw.Center(
  child: pw.Text(
    "Merci pour votre confiance !",
  ),
),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}