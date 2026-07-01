import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Isolated Typography system exclusively for PDF generation.
/// 
/// PDFs have strict physical layout constraints (A4, Letter) and 
/// must use embedded .ttf fonts to guarantee rendering.
/// 
/// Changing sizes here affects PRINTED documents only, and will NEVER 
/// break the mobile/web UI.
class PdfTypography {
  
  /// Base factory for PDF text styles. 
  /// In a full implementation, you would load a .ttf font via rootBundle 
  /// and pass it to pw.Font.ttf().
  static pw.TextStyle _baseStyle(double size, pw.FontWeight weight, [PdfColor? color]) {
    return pw.TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color ?? PdfColors.black,
      // font: pw.Font.ttf(myLoadedTtfData), // To be configured during PDF generation
    );
  }

  // ---------------------------------------------------------------------------
  // PDF SPECIFIC STYLES
  // ---------------------------------------------------------------------------
  
  /// Use for: The main document title (e.g., "TAX INVOICE")
  static pw.TextStyle get documentTitle => _baseStyle(24, pw.FontWeight.bold);

  /// Use for: Section headers inside the PDF
  static pw.TextStyle get sectionHeader => _baseStyle(14, pw.FontWeight.bold);

  /// Use for: Standard text blocks (Addresses, Terms & Conditions)
  static pw.TextStyle get body => _baseStyle(10, pw.FontWeight.normal);

  /// Use for: Small print / footer text
  static pw.TextStyle get smallPrint => _baseStyle(8, pw.FontWeight.normal);

  /// Use for: Table column headers
  static pw.TextStyle get tableHeader => _baseStyle(10, pw.FontWeight.bold, PdfColors.grey800);

  /// Use for: Standard data cells inside tables
  static pw.TextStyle get tableCell => _baseStyle(10, pw.FontWeight.normal);

  /// Use for: Important financial totals (Grand Total, Amount Due)
  static pw.TextStyle get grandTotal => _baseStyle(14, pw.FontWeight.bold);

}
