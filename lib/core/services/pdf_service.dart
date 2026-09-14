import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../shared/models/app_enums.dart';
import '../../shared/models/inspection.dart';
import '../../shared/models/property.dart';
import '../constants/app_strings.dart';

class PdfService {
  Future<Uint8List> createHandoverAct({
    required Property property,
    required Inspection inspection,
  }) async {
    final regularData = await rootBundle.load(
      'assets/fonts/NotoSans-Regular.ttf',
    );
    final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final regular = pw.Font.ttf(regularData);
    final bold = pw.Font.ttf(boldData);
    final photos = <String, Uint8List>{};
    for (final room in inspection.rooms) {
      for (final item in room.items) {
        for (final photo in item.photos.take(2)) {
          final file = File(photo.localPath);
          if (await file.exists()) photos[photo.id] = await file.readAsBytes();
        }
      }
    }

    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              AppStrings.appName,
              style: pw.TextStyle(
                font: bold,
                fontSize: 16,
                color: PdfColors.teal700,
              ),
            ),
            pw.Text(
              AppStrings.appTagline,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 18),
          pw.Text(
            AppStrings.handoverAct,
            style: pw.TextStyle(font: bold, fontSize: 24),
          ),
          pw.SizedBox(height: 16),
          _pdfInfo(AppStrings.propertyName, property.name, bold),
          _pdfInfo(AppStrings.address, property.address, bold),
          _pdfInfo(AppStrings.furnishing, property.furnishingType.label, bold),
          _pdfInfo(
            AppStrings.area,
            '${property.areaSquareMeters.toStringAsFixed(0)} ${AppStrings.areaUnit}',
            bold,
          ),
          _pdfInfo(AppStrings.actNumber, inspection.id, bold),
          _pdfInfo(
            AppStrings.inspectionDate,
            DateFormat('yyyy.MM.dd HH:mm').format(inspection.updatedAt),
            bold,
          ),
          _pdfInfo(
            AppStrings.confirmationStatus,
            inspection.status.label,
            bold,
          ),
          if (inspection.tenantName != null)
            _pdfInfo(AppStrings.tenantName, inspection.tenantName!, bold),
          pw.SizedBox(height: 22),
          ...inspection.rooms.expand(
            (room) => [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                color: PdfColors.teal50,
                child: pw.Text(
                  room.name,
                  style: pw.TextStyle(font: bold, fontSize: 14),
                ),
              ),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(3),
                },
                children: room.items
                    .map(
                      (item) => pw.TableRow(
                        children: [
                          _pdfCell(item.name),
                          _pdfCell(item.condition.label),
                          _pdfCell(item.notes),
                        ],
                      ),
                    )
                    .toList(),
              ),
              ...room.items.expand(
                (item) => item.photos
                    .where((photo) => photos.containsKey(photo.id))
                    .map(
                      (photo) => pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.name,
                              style: pw.TextStyle(font: bold, fontSize: 9),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Image(
                              pw.MemoryImage(photos[photo.id]!),
                              width: 180,
                              height: 120,
                              fit: pw.BoxFit.cover,
                            ),
                          ],
                        ),
                      ),
                    ),
              ),
              pw.SizedBox(height: 18),
            ],
          ),
          if (inspection.meterReadings.isNotEmpty) ...[
            pw.Text(
              AppStrings.meters,
              style: pw.TextStyle(font: bold, fontSize: 14),
            ),
            pw.SizedBox(height: 6),
            ...inspection.meterReadings.map(
              (meter) => _pdfInfo(
                meter.type,
                '${meter.reading} ${meter.unit}',
                bold,
              ),
            ),
            pw.SizedBox(height: 12),
          ],
          if (inspection.keys.isNotEmpty) ...[
            pw.Text(
              AppStrings.keys,
              style: pw.TextStyle(font: bold, fontSize: 14),
            ),
            pw.SizedBox(height: 6),
            ...inspection.keys.map(
              (key) => _pdfInfo(key.type, key.quantity.toString(), bold),
            ),
            pw.SizedBox(height: 12),
          ],
          pw.Divider(),
          pw.Text(
            AppStrings.confirmationNotice,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _pdfInfo(
                  AppStrings.ownerConfirmation,
                  inspection.ownerConfirmed
                      ? AppStrings.confirmed
                      : AppStrings.notConfirmed,
                  bold,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _pdfInfo(
                  AppStrings.tenantConfirmation,
                  inspection.tenantConfirmed
                      ? AppStrings.confirmed
                      : AppStrings.notConfirmed,
                  bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return document.save();
  }

  Future<void> presentHandoverAct({
    required Property property,
    required Inspection inspection,
  }) async {
    final bytes = await createHandoverAct(
      property: property,
      inspection: inspection,
    );
    await Printing.layoutPdf(
      name: AppStrings.actFileName,
      onLayout: (format) async => bytes,
    );
  }

  pw.Widget _pdfInfo(String label, String value, pw.Font bold) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(font: bold),
          ),
          pw.TextSpan(text: value),
        ],
      ),
    ),
  );

  pw.Widget _pdfCell(String value) => pw.Padding(
    padding: const pw.EdgeInsets.all(7),
    child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
  );
}

final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());
