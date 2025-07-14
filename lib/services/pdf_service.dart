// services/pdf_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:vayujal_technician/models/service_acknowledgement_model.dart';

class PdfService {
  static Future<File> generateServiceAcknowledgmentPdf(
    ServiceAcknowledgmentModel serviceData,
  ) async {
    final pdf = pw.Document();

    // Download images for PDF
    pw.ImageProvider? issueImage;
    pw.ImageProvider? resolutionImage;

    try {
      if (serviceData.images.issueImageUrl != null) {
        final issueResponse = await http.get(Uri.parse(serviceData.images.issueImageUrl!));
        if (issueResponse.statusCode == 200) {
          issueImage = pw.MemoryImage(issueResponse.bodyBytes);
        }
      }
      
      if (serviceData.images.resolutionImageUrl != null) {
        final resolutionResponse = await http.get(Uri.parse(serviceData.images.resolutionImageUrl!));
        if (resolutionResponse.statusCode == 200) {
          resolutionImage = pw.MemoryImage(resolutionResponse.bodyBytes);
        }
      }
    } catch (e) {
      print('Error downloading images: $e');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Service Acknowledgment',
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text('VAYUJAL', style: pw.TextStyle(fontSize: 18, color: PdfColors.blue)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Service Summary
            _buildSection('Service Summary', [
              _buildRow('SR Number', serviceData.srNumber),
              _buildRow('Service Date', _formatDate(serviceData.serviceDate)),
              _buildRow('Next Service Date', _formatDate(serviceData.nextServiceDate)),
            ]),

            // AWG Details
            _buildSection('AWG Details', [
              _buildRow('Model', serviceData.awgDetails.model),
              _buildRow('Serial Number', serviceData.awgDetails.serialNumber),
            ]),

            // Customer Details
            _buildSection('Customer Details', [
              _buildRow('Name', serviceData.customerDetails.name),
              _buildRow('Phone Number', serviceData.customerDetails.phone),
              _buildRow('Company', serviceData.customerDetails.company),
              _buildRow('Address', serviceData.customerDetails.fullAddress),
              _buildRow('City', serviceData.customerDetails.city),
              _buildRow('State', serviceData.customerDetails.state),
            ]),

            // Service Details
            _buildSection('Service Details', [
              _buildRow('Parts Replaced', serviceData.partsReplaced),
              _buildRow('Issue Type', serviceData.issueType),
              _buildRow('Complaint Related To', serviceData.complaintRelatedTo),
              _buildRow('Solution Provided', serviceData.solutionProvided),
            ]),

            // Suggestions
            _buildSection('Suggestions', [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (serviceData.suggestions.keepAirFilterClean)
                    _buildCheckItem('Keep Air Filter Clean'),
                  if (serviceData.suggestions.keepAwayFromSmells)
                    _buildCheckItem('Keep Away From Smells'),
                  if (serviceData.suggestions.protectFromSunAndRain)
                    _buildCheckItem('Protect From Sun And Rain'),
                  if (serviceData.suggestions.supplyStableElectricity)
                    _buildCheckItem('Supply Stable Electricity'),
                  if (serviceData.customSuggestions.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 10),
                      child: pw.Text(
                        'Additional Suggestions: ${serviceData.customSuggestions}',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ]),

            // Images Section
            if (issueImage != null || resolutionImage != null)
              pw.SizedBox(height: 20),
            
            if (issueImage != null)
              _buildSection('Issue Photo', [
                pw.Container(
                  height: 200,
                  child: pw.Image(issueImage, fit: pw.BoxFit.contain),
                ),
              ]),

            if (resolutionImage != null)
              _buildSection('Resolution Photo', [
                pw.Container(
                  height: 200,
                  child: pw.Image(resolutionImage, fit: pw.BoxFit.contain),
                ),
              ]),

            // Footer
            pw.SizedBox(height: 30),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Customer Verification Completed',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'This document serves as acknowledgment of the service provided.',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Generated on: ${_formatDate(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/service_acknowledgment_${serviceData.srNumber}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildSection(String title, List<pw.Widget> children) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCheckItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.Container(
            width: 12,
            height: 12,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.green),
              borderRadius: pw.BorderRadius.circular(2),
            ),
            child: pw.Center(
              child: pw.Text('✓', style: pw.TextStyle(fontSize: 8, color: PdfColors.green)),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(text, style: pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static Future<void> shareAcknowledgmentPdf(File pdfFile) async {
    await Share.shareXFiles([XFile(pdfFile.path)]);
  }
}