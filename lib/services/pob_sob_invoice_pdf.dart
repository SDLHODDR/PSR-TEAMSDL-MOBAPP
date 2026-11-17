import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/pob_sob_data.dart';

class PobSobInvoicePdf {
  const PobSobInvoicePdf();

  Future<void> download(PobSobOrderDetails order) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'Shree Dhootapapeshwar Ltd.',
              style: const pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 22),
          _summary('Employee Name', order.employee),
          _summary('Order Date', order.dateLabel),
          _summary('Order ID', '${order.orderId}'),
          _summary(
            'Customer Name',
            '${order.customer}${order.customerCode.isEmpty ? '' : ' (${order.customerCode})'}',
          ),
          _summary('Order To', order.orderTo),
          _summary(
              'Total ${order.type}', 'INR ${order.amount.toStringAsFixed(2)}'),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.6),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.5),
              1: pw.FlexColumnWidth(3.2),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1),
              4: pw.FlexColumnWidth(1),
              5: pw.FlexColumnWidth(1.3),
            },
            children: [
              _row(
                const ['No', 'Items', 'Rate', 'Quantity', 'Free Qty', 'Amount'],
                header: true,
              ),
              for (var index = 0; index < order.items.length; index++)
                _row([
                  '${index + 1}',
                  order.items[index].product,
                  order.items[index].rate.toStringAsFixed(2),
                  _quantity(order.items[index].quantity),
                  _quantity(order.items[index].freeQuantity),
                  order.items[index].amount.toStringAsFixed(2),
                ]),
              _row([
                '',
                '',
                '',
                '',
                'Total',
                order.items
                    .fold<double>(
                      0,
                      (total, item) => total + item.amount,
                    )
                    .toStringAsFixed(2),
              ]),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => document.save(),
      name: 'pob_sob_order_${order.orderId}.pdf',
    );
  }

  pw.Widget _summary(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '$label: ',
                style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(text: value),
            ],
          ),
        ),
      );

  pw.TableRow _row(List<String> cells, {bool header = false}) => pw.TableRow(
        decoration:
            header ? const pw.BoxDecoration(color: PdfColors.grey300) : null,
        children: [
          for (var index = 0; index < cells.length; index++)
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                cells[index],
                textAlign: index == 1 ? pw.TextAlign.left : pw.TextAlign.center,
                style: header
                    ? const pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      )
                    : const pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.normal,
                      ),
              ),
            ),
        ],
      );

  String _quantity(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';
}
