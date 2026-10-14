import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/invoice.dart';

class JazzcashReceiptCard extends StatelessWidget {
  final Invoice invoice;
  final double? customerTotalBaaqi;
  final VoidCallback? onClose;

  const JazzcashReceiptCard({
    Key? key,
    required this.invoice,
    this.customerTotalBaaqi,
    this.onClose,
  }) : super(key: key);

  String _formatCurrency(double amount) {
    return NumberFormat('#,##,###').format(amount);
  }

  // Format and launch WhatsApp message directly with customer phone number
  Future<void> _shareOnWhatsApp(BuildContext context) async {
    final itemsList = invoice.items
        .asMap()
        .entries
        .map((entry) =>
            '${entry.key + 1}. *${entry.value.marbleName}* (${entry.value.sizeOrSpecs ?? entry.value.qualityGrade}) - ${entry.value.quantity} ${entry.value.unit} @ PKR ${entry.value.rate} = *PKR ${_formatCurrency(entry.value.amount)}*')
        .join('\n');

    final mazdooriText = invoice.loadingCharges > 0
        ? '\n*Loading/Mazdoori:* PKR ${_formatCurrency(invoice.loadingCharges)}'
        : '';
    final freightText = invoice.freightCharges > 0
        ? '\n*Freight/Transport:* PKR ${_formatCurrency(invoice.freightCharges)}'
        : '';
    final discountText = invoice.discount > 0
        ? '\n*Discount:* -PKR ${_formatCurrency(invoice.discount)}'
        : '';

    final message = '''
🏢 *AL-MADINA MARBLE & GRANITE*
📍 Factory Gate, Stone Processing Zone
📞 +92 300 8452190
━━━━━━━━━━━━━━━━━━━━
🧾 *SALES INVOICE & GATE PASS*
*Invoice #:* ${invoice.invoiceNo}
*Gate Pass #:* ${invoice.gatePassNo}
*Date:* ${invoice.date} (${invoice.time})
━━━━━━━━━━━━━━━━━━━━
👤 *Customer:* ${invoice.customerName}
📱 *Phone:* ${invoice.customerPhone}
🏙️ *City/Site:* ${invoice.customerCity}
🚛 *Vehicle:* ${invoice.vehicleNo ?? 'Customer Own'}
━━━━━━━━━━━━━━━━━━━━
📦 *STONE ITEMS DISPATCHED:*
$itemsList
━━━━━━━━━━━━━━━━━━━━
*Stone Total:* PKR ${_formatCurrency(invoice.grossTotal)}$mazdooriText$freightText$discountText
*NET PAYABLE:* PKR ${_formatCurrency(invoice.netPayable)}
━━━━━━━━━━━━━━━━━━━━
💰 *Paid Amount:* PKR ${_formatCurrency(invoice.cashPaid + invoice.bankPaid)} (${invoice.paymentMethod})
⚠️ *Bill Khata (Udhaar):* PKR ${_formatCurrency(invoice.khataAmount)}
👤 *Total Outstanding Baaqi:* PKR ${_formatCurrency(customerTotalBaaqi ?? invoice.khataAmount)}
━━━━━━━━━━━━━━━━━━━━
_Goods dispatched in sound condition. Thank you for your business!_
''';

    // Format phone number for international WhatsApp
    String phone = invoice.customerPhone.replaceAll(RegExp(r'\D'), '');
    if (phone.startsWith('0')) {
      phone = '92${phone.substring(1)}';
    } else if (!phone.startsWith('92') && phone.length == 10) {
      phone = '92$phone';
    }

    final uri = Uri.parse('https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp. Opening web link...')),
        );
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('WhatsApp launch error: $e')),
      );
    }
  }

  // Print or Save PDF Receipt
  Future<void> _printReceiptPdf() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('AL-MADINA MARBLE & GRANITE',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
              pw.Text('Factory Gate, Industrial Stone Zone', style: const pw.TextStyle(fontSize: 8)),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Inv: ${invoice.invoiceNo}', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Date: ${invoice.date}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GP: ${invoice.gatePassNo}', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Time: ${invoice.time}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('Customer: ${invoice.customerName} (${invoice.customerPhone})',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              ),
              pw.Divider(thickness: 0.5),
              pw.Column(
                children: invoice.items.map((item) {
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text('${item.marbleName} (${item.quantity} ${item.unit})',
                            style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Text('PKR ${_formatCurrency(item.amount)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ],
                  );
                }).toList(),
              ),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('NET TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('PKR ${_formatCurrency(invoice.netPayable)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Paid (${invoice.paymentMethod}):', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('PKR ${_formatCurrency(invoice.cashPaid + invoice.bankPaid)}',
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill Khata / Udhaar:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('PKR ${_formatCurrency(invoice.khataAmount)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text('Thank you for your business!', style: const pw.TextStyle(fontSize: 7)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Invoice_${invoice.invoiceNo}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Digital Banking Header (Teal/Emerald Gradient)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'TRANSACTION SUCCESSFUL',
                      style: TextStyle(
                        color: Color(0xFF99F6E4),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      child: Text(
                        'PKR ${_formatCurrency(invoice.netPayable)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      invoice.customerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Itemized Details Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildRow('Invoice No', invoice.invoiceNo, isMono: true),
                    _buildRow('Gate Pass No', invoice.gatePassNo, isMono: true),
                    _buildRow('Date & Time', '${invoice.date} (${invoice.time})'),
                    _buildRow('Customer Phone', invoice.customerPhone),
                    if (invoice.vehicleNo != null && invoice.vehicleNo!.isNotEmpty)
                      _buildRow('Vehicle / Truck', invoice.vehicleNo!),
                    _buildRow(
                      'Payment Method',
                      invoice.paymentMethod,
                      color: invoice.paymentMethod.contains('Khata')
                          ? Colors.red.shade700
                          : Colors.teal.shade700,
                      isBold: true,
                    ),

                    const Divider(height: 24, thickness: 1),

                    // Dispatched Stones List
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'DISPATCHED STONE ITEMS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...invoice.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.marbleName} (${item.quantity} ${item.unit})',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              'PKR ${_formatCurrency(item.amount)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    const Divider(height: 24, thickness: 1),

                    // Totals & Baaqi
                    _buildRow('Cash/Bank Paid', 'PKR ${_formatCurrency(invoice.cashPaid + invoice.bankPaid)}',
                        color: Colors.teal.shade800),
                    if (invoice.khataAmount > 0)
                      _buildRow('Added to Khata', 'PKR ${_formatCurrency(invoice.khataAmount)}',
                          color: Colors.red.shade700, isBold: true),
                    if (customerTotalBaaqi != null)
                      _buildRow(
                        'Total Outstanding Baaqi',
                        'PKR ${_formatCurrency(customerTotalBaaqi!)}',
                        color: Colors.red.shade800,
                        isBold: true,
                      ),

                    const SizedBox(height: 20),

                    // Direct WhatsApp Share Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _shareOnWhatsApp(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 20),
                        label: const Text(
                          'Share to WhatsApp',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Secondary Action Buttons (Print Slip & Close)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _printReceiptPdf,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.print, size: 18, color: Color(0xFF0F172A)),
                            label: const Text(
                              'Print Slip',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (onClose != null) onClose!();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isMono = false, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontFamily: isMono ? 'monospace' : null,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
