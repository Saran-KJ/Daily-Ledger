import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';


class PdfService {
  static Future<Uint8List> generatePdf() async {
    final pdf = pw.Document();

    // Fetch data
    final workerEntries = await ApiService.getWorkerEntries();
    final personalEntries = await ApiService.getPersonalEntries();

    // Calculate totals
    double totalPaid = 0;
    double totalEarned = 0;
    double pendingPayments = 0;

    for (var w in workerEntries) {
      final cost = (w['cost'] as num).toDouble();
      final notReceived = (w['notReceived'] == 1) || (w['notReceived'] == true);
      if (!notReceived) {
        totalPaid += cost;
      } else {
        pendingPayments += cost;
      }
    }

    for (var p in personalEntries) {
      final cost = (p['cost'] as num).toDouble();
      final notReceived = (p['notReceived'] == 1) || (p['notReceived'] == true);
      if (!notReceived) {
        totalEarned += cost;
      } else {
        pendingPayments += cost;
      }
    }

    // Load font
    final fontData = await rootBundle.load('assets/fonts/arial.ttf');
    final font = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(font),
            pw.SizedBox(height: 20),
            _buildSummary(totalPaid, totalEarned, pendingPayments, font),
            pw.SizedBox(height: 20),
            _buildSectionTitle('Worker Entries', font),
            _buildWorkerTable(workerEntries, font),
            pw.SizedBox(height: 20),
            _buildSectionTitle('Personal Entries', font),
            _buildPersonalTable(personalEntries, font),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printPdf(Uint8List bytes, {bool allowDownload = true}) async {
    final fileName = 'Daily_Ledger_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    
    if (Platform.isAndroid || Platform.isIOS) {
      // On mobile, use share dialog which is more reliable across Android versions
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } else {
      // On desktop, use the print preview dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: fileName,
      );
    }
  }

  static Future<String> downloadPdf(Uint8List bytes) async {
    final fileName = 'Daily_Ledger_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    
    try {
      if (Platform.isAndroid) {
        // Request storage permission for Android
        PermissionStatus status;
        
        // For Android 13+ (API 33+), we don't need WRITE_EXTERNAL_STORAGE
        // For Android 10-12, request storage permission
        if (await Permission.storage.isDenied) {
          status = await Permission.storage.request();
          if (status.isDenied) {
            return 'Storage permission denied. Please grant permission in settings.';
          }
        }
        
        // Try to save to Downloads directory
        final dir = Directory('/storage/emulated/0/Download');
        if (await dir.exists()) {
          final file = File('${dir.path}/$fileName');
          await file.writeAsBytes(bytes);
          return 'PDF saved to Downloads: $fileName';
        } else {
          // Fallback to app's external storage
          final appDir = await getExternalStorageDirectory();
          if (appDir != null) {
            final file = File('${appDir.path}/$fileName');
            await file.writeAsBytes(bytes);
            return 'PDF saved to: ${appDir.path}/$fileName';
          }
        }
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final dir = await getDownloadsDirectory();
        if (dir != null) {
          final file = File('${dir.path}/$fileName');
          await file.writeAsBytes(bytes);
          return 'PDF saved to Downloads: $fileName';
        }
      } else if (Platform.isIOS) {
        // For iOS, save to app documents directory
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        // Then share it so user can save to Files app
        await Printing.sharePdf(bytes: bytes, filename: fileName);
        return 'PDF saved and shared';
      }
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      // Fallback to share dialog
      await Printing.sharePdf(bytes: bytes, filename: fileName);
      return 'PDF shared (fallback)';
    }
    
    // Final fallback
    await Printing.sharePdf(bytes: bytes, filename: fileName);
    return 'PDF shared';
  }

  static pw.Widget _buildHeader(pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Daily Ledger Report',
          style: pw.TextStyle(font: font, fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700),
        ),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildSummary(
      double paid, double earned, double pending, pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildSummaryCard('Total Paid', paid, PdfColors.red100, font),
        _buildSummaryCard('Total Earned', earned, PdfColors.green100, font),
        _buildSummaryCard('Pending', pending, PdfColors.orange100, font),
      ],
    );
  }

  static pw.Widget _buildSummaryCard(
      String title, double amount, PdfColor color, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Text(
            'INR ${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildWorkerTable(List<Map<String, dynamic>> entries, pw.Font font) {
    if (entries.isEmpty) {
      return pw.Text('No worker entries found.', style: pw.TextStyle(font: font));
    }

    return pw.TableHelper.fromTextArray(
      border: null,
      headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(font: font, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
      },
      headers: ['Name', 'Description', 'Cost', 'Status', 'Date'],
      data: entries.map((e) {
        final notReceived = (e['notReceived'] == 1) || (e['notReceived'] == true);
        return [
          e['workerName'] ?? '',
          e['description'] ?? '',
          'INR ${e['cost']}',
          notReceived ? 'Pending' : 'Paid',
          (e['startDate'] ?? '').toString().split('T')[0],
        ];
      }).toList(),
    );
  }

  static pw.Widget _buildPersonalTable(List<Map<String, dynamic>> entries, pw.Font font) {
    if (entries.isEmpty) {
      return pw.Text('No personal entries found.', style: pw.TextStyle(font: font));
    }

    return pw.TableHelper.fromTextArray(
      border: null,
      headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(font: font, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
      },
      headers: ['Name', 'Description', 'Cost', 'Status', 'Date'],
      data: entries.map((e) {
        final notReceived = (e['notReceived'] == 1) || (e['notReceived'] == true);
        return [
          e['name'] ?? '',
          e['description'] ?? '',
          'INR ${e['cost']}',
          notReceived ? 'Pending' : 'Paid',
          (e['startDate'] ?? '').toString().split('T')[0],
        ];
      }).toList(),
    );
  }
}
