import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';
import '../models/invoice_detail_model.dart';
import 'package:flutter/services.dart' show rootBundle;

class PdfInvoiceApi {
  static Future<void> generateAndPrint(InvoiceModel invoice, List<InvoiceDetailModel> details) async {
    final pdf = pw.Document();

    // Load font for Vietnamese
    pw.Font? ttf;
    try {
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      ttf = pw.Font.ttf(fontData);
    } catch (e) {
      try {
        // Fallback to downloading Google Font if local font is missing
        ttf = await PdfGoogleFonts.robotoRegular();
      } catch (_) {
        ttf = pw.Font.helvetica();
      }
    }

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Typical receipt printer size
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('STITCH MINI MART', style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Center(
                child: pw.Text(invoice.isImport ? 'Hóa đơn nhập hàng' : 'Hóa đơn bán hàng', style: pw.TextStyle(font: ttf, fontSize: 14)),
              ),
              pw.SizedBox(height: 10),
              pw.Text(invoice.isImport ? 'Số Phiếu: ${invoice.mahd}' : 'Số HĐ: ${invoice.mahd}', style: pw.TextStyle(font: ttf, fontSize: 10)),
              pw.Text('Ngày: ${invoice.ngaylap}', style: pw.TextStyle(font: ttf, fontSize: 10)),
              pw.Divider(),
              // Header
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Sản phẩm', style: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('SL', style: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Đơn giá', style: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 2, child: pw.Text('T.Tiền', style: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.Divider(),
              // Items
              ...details.map((item) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(flex: 3, child: pw.Text(item.productName, style: pw.TextStyle(font: ttf, fontSize: 9))),
                    pw.Expanded(flex: 1, child: pw.Text('${item.soluong}', style: pw.TextStyle(font: ttf, fontSize: 9))),
                    pw.Expanded(flex: 2, child: pw.Text(currencyFormat.format(item.dongia), style: pw.TextStyle(font: ttf, fontSize: 9), textAlign: pw.TextAlign.right)),
                    pw.Expanded(flex: 2, child: pw.Text(currencyFormat.format(item.thanhtien), style: pw.TextStyle(font: ttf, fontSize: 9), textAlign: pw.TextAlign.right)),
                  ],
                ),
              )),
              pw.Divider(),
              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TỔNG CỘNG:', style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(currencyFormat.format(invoice.tongtien), style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text('Cảm ơn quý khách. Hẹn gặp lại!', style: pw.TextStyle(font: ttf, fontSize: 10, fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );

    // Save and share the PDF instead of layoutPdf (which might fail if no printer service is installed)
    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'HoaDon_${invoice.mahd}.pdf');
  }
}
