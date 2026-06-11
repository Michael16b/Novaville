import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_auth.dart';
import 'package:frontend/constants/texts/texts_bulk_user_creation.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfFontPack {
  const PdfFontPack({required this.base, required this.bold});

  final pw.Font base;
  final pw.Font bold;
}

class PdfGenerationUtil {
  static Future<pw.MemoryImage?> loadPdfLogo() async {
    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static Future<PdfFontPack?> loadPdfFonts() async {
    try {
      final regular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Montserrat-Regular.ttf'),
      );
      final bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Montserrat-Bold.ttf'),
      );
      return PdfFontPack(base: regular, bold: bold);
    } catch (_) {
      return null;
    }
  }

  static String buildPdfDateSuffix() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return '$day$month$year';
  }

  static pw.Widget buildCredentialPdfCard({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String shareUrl,
    required PdfColor primary,
    required PdfColor accent,
    required PdfColor background,
    pw.MemoryImage? logo,
    bool compact = false,
  }) {
    final titleSize = compact ? 11.0 : 15.0;
    final valueSize = compact ? 9.5 : 11.5;
    final nameSize = compact ? 12.0 : 17.0;

    final currentUri = Uri.base;
    final usesHashRouting = currentUri.fragment.startsWith('/');
    final setPasswordUrl = usesHashRouting
        ? '${currentUri.scheme}://${currentUri.authority}${currentUri.path}#/set-password'
        : currentUri.resolve('/set-password').toString();

    pw.Widget lineItem(String label, String value) {
      return pw.Container(
        margin: pw.EdgeInsets.only(bottom: compact ? 5 : 8),
        padding: pw.EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 6 : 8,
        ),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: compact ? 54 : 76,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: compact ? 8.5 : 9.5,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: valueSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      padding: pw.EdgeInsets.all(compact ? 10 : 14),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(compact ? 10 : 14),
        border: pw.Border.all(color: accent, width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              if (logo != null)
                pw.Container(
                  width: compact ? 20 : 30,
                  height: compact ? 20 : 30,
                  margin: pw.EdgeInsets.only(right: compact ? 6 : 10),
                  child: pw.Image(logo),
                ),
              pw.Text(
                BulkUserCreationTexts.pdfBrand,
                style: pw.TextStyle(
                  color: primary,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: titleSize,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: compact ? 6 : 10),
          pw.Text(
            '$firstName $lastName',
            style: pw.TextStyle(
              fontSize: nameSize,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: compact ? 6 : 10),
          lineItem(BulkUserCreationTexts.pdfEmailLabel, email),
          lineItem(BulkUserCreationTexts.pdfUsernameLabel, username),
          pw.SizedBox(height: compact ? 8 : 12),
          pw.Container(
            padding: pw.EdgeInsets.all(compact ? 6 : 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  AppTextsAuth.pdfFirstConnectionNote,
                  style: pw.TextStyle(
                    fontSize: compact ? 7.5 : 8.5,
                    color: PdfColors.grey700,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${AppTextsAuth.pdfActivationCode}$password',
                  style: pw.TextStyle(
                    fontSize: compact ? 9.5 : 11.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: compact ? 8 : 12),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: shareUrl,
              color: primary,
              width: compact ? 60 : 90,
              height: compact ? 60 : 90,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Scannez le QR Code pour l\'activation',
                  style: pw.TextStyle(
                    fontSize: compact ? 7.5 : 9.5,
                    color: primary,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: compact ? 6 : 8),
                pw.Text(
                  '--- OU ---',
                  style: pw.TextStyle(
                    fontSize: compact ? 6.5 : 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: compact ? 6 : 8),
                pw.Text(
                  AppTextsAuth.pdfAlternativeInstructions(setPasswordUrl),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: compact ? 6.5 : 8.5,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> generateAndDownloadSingleUserPdf({
    required BuildContext context,
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String shareUrl,
  }) async {
    final document = pw.Document();
    final primary = PdfColor.fromInt(AppColors.primary.toARGB32());
    final accent = PdfColor.fromInt(AppColors.secondary.toARGB32());
    final background = PdfColors.white;

    final logo = await loadPdfLogo();
    final fontPack = await loadPdfFonts();
    final theme = fontPack == null
        ? null
        : pw.ThemeData.withFont(base: fontPack.base, bold: fontPack.bold);

    document.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(28),
        theme: theme,
        build: (pwContext) {
          return pw.Center(
            child: pw.SizedBox(
              width: 460,
              child: buildCredentialPdfCard(
                firstName: firstName,
                lastName: lastName,
                username: username,
                email: email,
                password: password,
                shareUrl: shareUrl,
                primary: primary,
                accent: accent,
                background: background,
                logo: logo,
              ),
            ),
          );
        },
      ),
    );

    final bytes = await document.save();
    final dateSuffix = buildPdfDateSuffix();
    final fileName =
        '${BulkUserCreationTexts.pdfFileBaseName}$dateSuffix${BulkUserCreationTexts.oneUserPdfSuffix}_$username.pdf';

    try {
      await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (!context.mounted) return;
      CustomSnackBar.showSuccess(context, BulkUserCreationTexts.pdfDownloaded);
    } catch (_) {
      if (!context.mounted) return;
      CustomSnackBar.showError(context, BulkUserCreationTexts.pdfDownloadError);
    }
  }
}
