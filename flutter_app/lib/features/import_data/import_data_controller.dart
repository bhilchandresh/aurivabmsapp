import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/api_service.dart';
import '../../core/constants/api_constants.dart';

class ImportDataController extends GetxController {
  var activeTab = 'clients'.obs; // 'clients', 'inventory', 'invoices'
  var selectedFileName = ''.obs;
  var parsedData = <Map<String, dynamic>>[].obs;
  var isParsing = false.obs;
  var isImporting = false.obs;

  final Map<String, Map<String, dynamic>> templates = {
    'clients': {
      'headers': ['name', 'email', 'phone', 'address', 'gstin', 'state'],
      'sample': [
        'Acme Corp',
        'contact@acme.com',
        '9876543210',
        '123 Business Rd',
        '22ABCDE1234F1Z5',
        'Maharashtra',
      ],
    },
    'inventory': {
      'headers': [
        'itemName',
        'sku',
        'description',
        'unitPrice',
        'currentStock',
        'status',
      ],
      'sample': [
        'Premium Widget',
        'WID-001',
        'High quality widget',
        '499.00',
        '50',
        'active',
      ],
    },
    'invoices': {
      'headers': [
        'invoiceNumber',
        'date',
        'clientName',
        'clientEmail',
        'clientPhone',
        'status',
        'advancePayment',
        'discountPercentage',
        'itemName',
        'quantity',
        'rate',
      ],
      'sample': [
        'INV-0001',
        '2023-10-15',
        'Acme Corp',
        'contact@acme.com',
        '9876543210',
        'Paid',
        '0',
        '10',
        'Premium Widget',
        '2',
        '499.00',
      ],
    },
  };

  void setActiveTab(String tab) {
    activeTab.value = tab;
    clearData();
  }

  void clearData() {
    selectedFileName.value = '';
    parsedData.clear();
  }

  Future<void> downloadTemplate() async {
    try {
      final template = templates[activeTab.value]!;
      final excel = Excel.createExcel();
      final Sheet sheetObject = excel['Sheet1'];
      excel.setDefaultSheet('Sheet1');

      final List<String> headers = (template['headers'] as List<String>)
          .cast<String>();
      final List<String> sample = (template['sample'] as List<String>).cast<String>();

      sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());
      sheetObject.appendRow(sample.map((s) => TextCellValue(s)).toList());

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/${activeTab.value}_template.xlsx';

      final fileBytes = excel.encode();
      if (fileBytes != null) {
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        // ignore: deprecated_member_use
        await Share.shareXFiles([
          XFile(path),
        ], text: 'Excel Template for ${activeTab.value}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not generate template: $e');
    }
  }

  Future<void> pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result != null && result.files.single.path != null) {
        selectedFileName.value = result.files.single.name;
        isParsing.value = true;

        final filePath = result.files.single.path!;
        final extension = filePath.split('.').last.toLowerCase();

        List<String> headers = [];
        final List<Map<String, dynamic>> data = [];

        if (extension == 'csv') {
          final input = File(filePath).openRead();
          final fields = await input
              .transform(utf8.decoder)
              .transform(const CsvToListConverter())
              .toList();

          if (fields.isEmpty) throw Exception("CSV file is empty");

          headers = fields[0].map((e) => e.toString().trim()).toList();
          for (int i = 1; i < fields.length; i++) {
            final row = fields[i];
            if (row.isEmpty ||
                row.every((element) => element.toString().trim().isEmpty)) {
              continue;
            }

            final Map<String, dynamic> rowData = {};
            for (int j = 0; j < headers.length; j++) {
              rowData[headers[j]] = j < row.length ? row[j].toString() : '';
            }
            data.add(rowData);
          }
        } else {
          final bytes = File(filePath).readAsBytesSync();
          final excel = Excel.decodeBytes(bytes);

          if (excel.tables.isEmpty) throw Exception("Excel file is empty");

          final table = excel.tables[excel.tables.keys.first];
          if (table == null || table.rows.isEmpty) {
            throw Exception("Excel sheet is empty");
          }

          headers = table.rows[0]
              .map((e) => e?.value.toString().trim() ?? '')
              .toList();

          for (int i = 1; i < table.rows.length; i++) {
            final row = table.rows[i];
            if (row.every(
              (element) => element?.value?.toString().trim().isEmpty ?? true,
            )) {
              continue;
            }

            final Map<String, dynamic> rowData = {};
            for (int j = 0; j < headers.length; j++) {
              rowData[headers[j]] = j < row.length
                  ? (row[j]?.value?.toString() ?? '')
                  : '';
            }
            data.add(rowData);
          }
        }

        parsedData.assignAll(data);
        isParsing.value = false;
      }
    } catch (e) {
      isParsing.value = false;
      Get.snackbar('Error', 'Could not parse file: $e');
    }
  }

  Future<void> importData() async {
    if (parsedData.isEmpty) {
      Get.snackbar('Error', 'No data found to import');
      return;
    }

    isImporting.value = true;
    dynamic payload = parsedData.toList();

    try {
      // Special transformation for invoices (grouping rows by invoiceNumber)
      if (activeTab.value == 'invoices') {
        final Map<String, Map<String, dynamic>> invoiceMap = {};
        for (var row in parsedData) {
          final invNum = (row['invoiceNumber']?.toString() ?? '').isNotEmpty
              ? row['invoiceNumber']
              : 'NEW';

          // Normalize invoice status
          final String statusStr = (row['status']?.toString() ?? 'Unpaid')
              .trim()
              .toLowerCase();
          String finalStatus = 'Unpaid';
          if (statusStr == 'paid') {
            finalStatus = 'Paid';
          } else if (statusStr == 'partially paid') {
            finalStatus = 'Partially Paid';
          } else if (statusStr == 'pending') {
            finalStatus = 'Pending';
          } else if (statusStr == 'overdue') {
            finalStatus = 'Overdue';
          } else if (statusStr == 'cancelled') {
            finalStatus = 'Cancelled';
          }

          if (!invoiceMap.containsKey(invNum)) {
            invoiceMap[invNum] = {
              'invoiceNumber': row['invoiceNumber'],
              'date': row['date'],
              'clientName': row['clientName'],
              'clientEmail': row['clientEmail'],
              'clientPhone': row['clientPhone'],
              'status': finalStatus,
              'advancePayment': row['advancePayment'],
              'discountPercentage': row['discountPercentage'],
              'items': <Map<String, dynamic>>[],
            };
          }
          if ((row['itemName']?.toString() ?? '').isNotEmpty) {
            invoiceMap[invNum]!['items'].add({
              'description': row['itemName'],
              'quantity': double.tryParse(row['quantity'].toString()) ?? 1,
              'rate': double.tryParse(row['rate'].toString()) ?? 0,
            });
          }
        }
        payload = invoiceMap.values.toList();
      } else if (activeTab.value == 'inventory') {
        payload = parsedData.map((row) {
          final newRow = Map<String, dynamic>.from(row);
          if (newRow.containsKey('status')) {
            final String s =
                newRow['status']?.toString().trim().toLowerCase() ?? 'active';
            if (s == 'in stock' || s == 'active' || s == 'yes' || s == '1') {
              newRow['status'] = 'active';
            } else if (s == 'out of stock' ||
                s == 'inactive' ||
                s == 'no' ||
                s == '0') {
              newRow['status'] = 'inactive';
            } else {
              newRow['status'] = 'active'; // Default
            }
          }
          return newRow;
        }).toList();
      }

      String endpoint = '';
      if (activeTab.value == 'clients') {
        endpoint = '${ApiConstants.clients}/bulk';
      }
      if (activeTab.value == 'inventory') {
        endpoint = '${ApiConstants.inventory}/bulk';
      }
      if (activeTab.value == 'invoices') {
        endpoint = '${ApiConstants.invoices}/bulk';
      }

      final response = await ApiService.post(endpoint, payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          Get.snackbar('Success', body['message'] ?? 'Import successful');
          clearData();
        } else {
          Get.snackbar(
            'Import Failed',
            body['message'] ?? 'Unknown error occurred',
          );
        }
      } else {
        final body = jsonDecode(response.body);
        Get.snackbar(
          'Import Failed',
          body['message'] ?? 'Server error ${response.statusCode}',
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Import failed: $e');
    } finally {
      isImporting.value = false;
    }
  }
}
