import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:excel/excel.dart' as pkg_excel;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
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
        'Item Name',
        'SKU',
        'Description',
        'Purchase Price',
        'Selling Price',
        'Stock',
        'Status',
      ],
      'sample': [
        'Samsung Galaxy A16 5G',
        'SAM-A16-5G-128',
        '6.7-inch Super AMOLED display, 128GB storage',
        '14500',
        '16999',
        '24',
        'Active',
      ],
    },
    'invoices': {
      'headers': [
        'Invoice Number',
        'Date',
        'Client Name',
        'Client Email',
        'Client Phone',
        'Status',
        'Advance Payment',
        'Discount Percentage',
        'Item Name',
        'Quantity',
        'Rate',
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
        'Samsung Galaxy A16 5G',
        '2',
        '16999',
      ],
    },
  };

  void setActiveTab(String tab) {
    if (activeTab.value == tab) return;
    activeTab.value = tab;
    clearData();
  }

  void clearData() {
    selectedFileName.value = '';
    parsedData.clear();
  }

  Future<void> downloadTemplate() async {
    try {
      final template = templates[activeTab.value] ?? templates['clients'] ?? {
        'headers': <String>[],
        'sample': <String>[],
      };
      final excel = pkg_excel.Excel.createExcel();
      final pkg_excel.Sheet sheetObject = excel['Sheet1'];
      excel.setDefaultSheet('Sheet1');

      final List<String> headers = (template['headers'] as List?)?.cast<String>() ?? [];
      final List<String> sample = (template['sample'] as List?)?.cast<String>() ?? [];

      sheetObject.appendRow(headers.map((h) => pkg_excel.TextCellValue(h)).toList());
      sheetObject.appendRow(sample.map((s) => pkg_excel.TextCellValue(s)).toList());

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/${activeTab.value}_template.xlsx';

      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final f = File(path);
        f.createSync(recursive: true);
        f.writeAsBytesSync(fileBytes);
        // ignore: deprecated_member_use
        await Share.shareXFiles([
          XFile(path),
        ], text: 'Excel Template for ${activeTab.value}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Could not generate template: $e', backgroundColor: AppColors.error);
    }
  }

  int _columnNameToIndex(String colName) {
    int result = 0;
    for (int i = 0; i < colName.length; i++) {
      final code = colName.toUpperCase().codeUnitAt(i);
      if (code >= 65 && code <= 90) {
        result = result * 26 + (code - 64);
      }
    }
    return result - 1;
  }

  List<List<String>> _parseXlsxDirect(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    // 1. Extract Shared Strings dictionary
    final List<String> sharedStrings = [];
    ArchiveFile? sharedStringsFile;
    for (final file in archive.files) {
      if (file.name.toLowerCase() == 'xl/sharedstrings.xml') {
        sharedStringsFile = file;
        break;
      }
    }

    if (sharedStringsFile != null && sharedStringsFile.content != null) {
      final rawBytes = sharedStringsFile.content is List<int>
          ? (sharedStringsFile.content as List<int>)
          : List<int>.from(sharedStringsFile.content as dynamic);
      final content = utf8.decode(rawBytes, allowMalformed: true);
      final doc = XmlDocument.parse(content);
      for (final si in doc.findAllElements('si')) {
        final tElements = si.findAllElements('t');
        final text = tElements.map((e) => e.innerText).join();
        sharedStrings.add(text);
      }
    }

    // 2. Find primary worksheet
    ArchiveFile? sheetFile;
    for (final file in archive.files) {
      final lower = file.name.toLowerCase();
      if (lower.startsWith('xl/worksheets/sheet') && lower.endsWith('.xml')) {
        sheetFile = file;
        break;
      }
    }

    if (sheetFile == null || sheetFile.content == null) {
      throw Exception("No worksheet found inside Excel file");
    }

    final sheetRawBytes = sheetFile.content is List<int>
        ? (sheetFile.content as List<int>)
        : List<int>.from(sheetFile.content as dynamic);
    final sheetContent = utf8.decode(sheetRawBytes, allowMalformed: true);
    final sheetDoc = XmlDocument.parse(sheetContent);
    final List<List<String>> rows = [];

    for (final rowElem in sheetDoc.findAllElements('row')) {
      final List<String> rowData = [];
      int currentExpectedCol = 0;

      for (final cElem in rowElem.findAllElements('c')) {
        final rAttr = cElem.getAttribute('r');
        if (rAttr != null && rAttr.isNotEmpty) {
          final colLetters = rAttr.replaceAll(RegExp(r'[^a-zA-Z]'), '');
          final targetCol = _columnNameToIndex(colLetters);
          while (currentExpectedCol < targetCol) {
            rowData.add('');
            currentExpectedCol++;
          }
        }

        final type = cElem.getAttribute('t');
        final vElem = cElem.findElements('v').firstOrNull;
        final isElem = cElem.findElements('is').firstOrNull?.findElements('t').firstOrNull;

        String cellValue = '';
        if (type == 's' && vElem != null) {
          final idx = int.tryParse(vElem.innerText.trim()) ?? -1;
          if (idx >= 0 && idx < sharedStrings.length) {
            cellValue = sharedStrings[idx];
          }
        } else if (type == 'inlineStr' && isElem != null) {
          cellValue = isElem.innerText;
        } else if (type == 'b' && vElem != null) {
          cellValue = vElem.innerText.trim() == '1' ? 'TRUE' : 'FALSE';
        } else if (vElem != null) {
          cellValue = vElem.innerText;
        }

        rowData.add(cellValue);
        currentExpectedCol++;
      }

      if (rowData.any((cell) => cell.trim().isNotEmpty)) {
        rows.add(rowData);
      }
    }

    return rows;
  }

  double _parsePrice(dynamic val) {
    if (val == null) return 0.0;
    final str = val.toString().replaceAll('₹', '').replaceAll(',', '').replaceAll(' ', '').trim();
    return double.tryParse(str) ?? 0.0;
  }

  Future<void> pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final platformFile = result.files.first;
      final fileName = platformFile.name;
      final extension = (platformFile.extension ?? fileName.split('.').last).toLowerCase();

      if (extension != 'xlsx' && extension != 'xls' && extension != 'csv') {
        Fluttertoast.showToast(
          msg: 'Please select an Excel (.xlsx) or CSV (.csv) file',
          backgroundColor: AppColors.warning,
          textColor: Colors.white,
        );
        return;
      }

      selectedFileName.value = fileName;
      isParsing.value = true;

      Uint8List? bytes = platformFile.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (platformFile.path != null && platformFile.path!.isNotEmpty) {
          try {
            final localFile = File(platformFile.path!);
            if (await localFile.exists()) {
              bytes = await localFile.readAsBytes();
            }
          } catch (fileErr) {
            debugPrint('[IMPORT] Error reading file bytes: $fileErr');
          }
        }
      }

      if (bytes == null || bytes.isEmpty) {
        throw Exception("Could not read file data. Please grant permission or try again.");
      }

      List<String> headers = [];
      final List<Map<String, dynamic>> data = [];

      if (extension == 'csv') {
        final csvString = utf8.decode(bytes, allowMalformed: true);
        final fields = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
            .convert(csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));

        if (fields.isEmpty) throw Exception("CSV file is empty");

        headers = fields[0].map((e) => e.toString().trim()).where((h) => h.isNotEmpty).toList();
        for (int i = 1; i < fields.length; i++) {
          final row = fields[i];
          if (row.isEmpty || row.every((element) => element.toString().trim().isEmpty)) {
            continue;
          }

          final Map<String, dynamic> rowData = {};
          for (int j = 0; j < headers.length; j++) {
            rowData[headers[j]] = j < row.length ? row[j].toString().trim() : '';
          }
          if (rowData.values.any((val) => val.toString().isNotEmpty)) {
            data.add(rowData);
          }
        }
      } else {
        // Native OpenXML parser (100% crash-free on filtered/styled Excel tables)
        List<List<String>> rows = [];
        try {
          rows = _parseXlsxDirect(bytes);
        } catch (xmlErr) {
          debugPrint('[IMPORT] Direct XML parse failed: $xmlErr. Trying fallback decoder...');
          try {
            final excel = pkg_excel.Excel.decodeBytes(bytes);
            for (final sheet in excel.tables.values) {
              if (sheet.rows.isNotEmpty) {
                for (final r in sheet.rows) {
                  rows.add(r.map((c) => c?.value?.toString().trim() ?? '').toList());
                }
                break;
              }
            }
          } catch (fallbackErr) {
            throw Exception("Failed to read Excel data: $xmlErr");
          }
        }

        if (rows.isEmpty) {
          throw Exception("Excel sheet contains no data");
        }

        // Find header row (first row with non-empty cells)
        int headerRowIndex = -1;
        for (int i = 0; i < rows.length; i++) {
          final nonEmpties = rows[i].where((c) => c.trim().isNotEmpty).length;
          if (nonEmpties >= 1) {
            headerRowIndex = i;
            break;
          }
        }

        if (headerRowIndex == -1) throw Exception("No column headers found in Excel file");

        final rawHeaders = rows[headerRowIndex];
        for (int c = 0; c < rawHeaders.length; c++) {
          final h = rawHeaders[c].trim();
          headers.add(h.isNotEmpty ? h : 'Col_${c + 1}');
        }

        for (int i = headerRowIndex + 1; i < rows.length; i++) {
          final row = rows[i];
          final hasData = row.any((cell) => cell.trim().isNotEmpty);
          if (!hasData) continue;

          final Map<String, dynamic> rowData = {};
          for (int j = 0; j < headers.length; j++) {
            final headerKey = headers[j];
            if (headerKey.startsWith('Col_')) continue;
            rowData[headerKey] = j < row.length ? row[j].trim() : '';
          }
          if (rowData.values.any((val) => val.toString().trim().isNotEmpty)) {
            data.add(rowData);
          }
        }
      }

      if (data.isEmpty) {
        throw Exception("No valid data rows found in file.");
      }

      parsedData.assignAll(data);
      Fluttertoast.showToast(
        msg: 'Loaded ${data.length} rows successfully!',
        backgroundColor: AppColors.success,
        textColor: Colors.white,
      );
    } catch (e) {
      debugPrint('[IMPORT] File parsing error: $e');
      String msg = e.toString();
      if (msg.contains('Exception: ')) {
        msg = msg.replaceAll('Exception: ', '');
      }
      Fluttertoast.showToast(
        msg: 'Parsing Error: $msg',
        backgroundColor: AppColors.error,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      isParsing.value = false;
    }
  }

  // Normalizes header keys to standard backend field names
  String _normalizeKey(String rawKey) {
    final clean = rawKey.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    
    // Clients
    if (clean == 'name' || clean == 'clientname' || clean == 'customer' || clean == 'customername' || clean == 'company' || clean == 'party') return 'name';
    if (clean == 'email' || clean == 'clientemail' || clean == 'emailid' || clean == 'mail') return 'email';
    if (clean == 'phone' || clean == 'clientphone' || clean == 'mobile' || clean == 'phonenumber' || clean == 'contact' || clean == 'contactno') return 'phone';
    if (clean == 'address' || clean == 'clientaddress' || clean == 'location' || clean == 'city') return 'address';
    if (clean == 'gstin' || clean == 'gst' || clean == 'gstnumber' || clean == 'gstno') return 'gstin';
    if (clean == 'state' || clean == 'province') return 'state';

    // Inventory
    if (clean == 'itemname' || clean == 'item' || clean == 'product' || clean == 'productname' || clean == 'title') return 'itemName';
    if (clean == 'sku' || clean == 'skuno' || clean == 'itemcode' || clean == 'code') return 'sku';
    if (clean == 'description' || clean == 'desc' || clean == 'details') return 'description';
    if (clean == 'purchaseprice' || clean == 'cost' || clean == 'costprice' || clean == 'buyprice' || clean == 'buyingprice') return 'purchasePrice';
    if (clean == 'unitprice' || clean == 'price' || clean == 'rate' || clean == 'sellingprice' || clean == 'saleprice' || clean == 'mrp') return 'unitPrice';
    if (clean == 'currentstock' || clean == 'stock' || clean == 'quantity' || clean == 'qty' || clean == 'units' || clean == 'available') return 'currentStock';
    if (clean == 'status' || clean == 'availability') return 'status';

    // Invoices
    if (clean == 'invoicenumber' || clean == 'invoiceno' || clean == 'invno' || clean == 'invnum' || clean == 'billno' || clean == 'billnumber') return 'invoiceNumber';
    if (clean == 'date' || clean == 'invoicedate' || clean == 'billdate') return 'date';
    if (clean == 'clientname' || clean == 'customer' || clean == 'party' || clean == 'customername') return 'clientName';
    if (clean == 'advancepayment' || clean == 'advance' || clean == 'paidamount') return 'advancePayment';
    if (clean == 'discountpercentage' || clean == 'discount' || clean == 'discountpercent') return 'discountPercentage';

    return rawKey;
  }

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
    final Map<String, dynamic> normalized = {};
    for (var entry in row.entries) {
      normalized[_normalizeKey(entry.key)] = entry.value;
    }
    return normalized;
  }

  Future<void> importData() async {
    if (parsedData.isEmpty) {
      Fluttertoast.showToast(msg: 'No data found to import', backgroundColor: AppColors.warning);
      return;
    }

    isImporting.value = true;
    dynamic payload;

    try {
      final normalizedData = parsedData.map((row) => _normalizeRow(row)).toList();

      if (activeTab.value == 'invoices') {
        final Map<String, Map<String, dynamic>> invoiceMap = {};
        for (var row in normalizedData) {
          final invNum = (row['invoiceNumber']?.toString() ?? '').trim();
          final key = invNum.isNotEmpty ? invNum : 'INV_${invoiceMap.length + 1}';

          final String statusStr = (row['status']?.toString() ?? 'Unpaid').trim().toLowerCase();
          String finalStatus = 'Unpaid';
          if (statusStr.contains('paid') && !statusStr.contains('part') && !statusStr.contains('un')) {
            finalStatus = 'Paid';
          } else if (statusStr.contains('part')) {
            finalStatus = 'Partially Paid';
          } else if (statusStr.contains('pending')) {
            finalStatus = 'Pending';
          } else if (statusStr.contains('overdue')) {
            finalStatus = 'Overdue';
          } else if (statusStr.contains('cancel')) {
            finalStatus = 'Cancelled';
          }

          final clientName = (row['clientName'] ?? row['name'] ?? row['customer'] ?? '').toString().trim();
          if (clientName.isEmpty) continue;

          if (!invoiceMap.containsKey(key)) {
            invoiceMap[key] = {
              'invoiceNumber': invNum,
              'date': (row['date'] ?? '').toString().trim(),
              'clientName': clientName,
              'clientEmail': (row['clientEmail'] ?? row['email'] ?? '').toString().trim(),
              'clientPhone': (row['clientPhone'] ?? row['phone'] ?? '').toString().trim(),
              'status': finalStatus,
              'advancePayment': _parsePrice(row['advancePayment']),
              'discountPercentage': _parsePrice(row['discountPercentage']),
              'items': <Map<String, dynamic>>[],
            };
          }

          final itemName = (row['itemName'] ?? row['item'] ?? row['product'] ?? row['description'] ?? 'Item').toString().trim();
          final qty = _parsePrice(row['quantity'] ?? row['qty'] ?? '1');
          final rate = _parsePrice(row['rate'] ?? row['unitPrice'] ?? row['price'] ?? '0');

          (invoiceMap[key]?['items'] as List<Map<String, dynamic>>?)?.add({
            'description': itemName,
            'quantity': qty <= 0 ? 1 : qty,
            'rate': rate,
          });
        }
        payload = invoiceMap.values.where((inv) => (inv['items'] as List).isNotEmpty).toList();
      } else if (activeTab.value == 'inventory') {
        payload = normalizedData.map((row) {
          final itemName = (row['itemName'] ?? row['name'] ?? row['product'] ?? '').toString().trim();
          final String s = (row['status'] ?? 'active').toString().trim().toLowerCase();
          String status = 'active';
          if (s == 'inactive' || s == 'out of stock' || s == 'no' || s == '0') {
            status = 'inactive';
          }

          return {
            'itemName': itemName,
            'sku': (row['sku'] ?? '').toString().trim(),
            'description': (row['description'] ?? '').toString().trim(),
            'purchasePrice': _parsePrice(row['purchasePrice']),
            'unitPrice': _parsePrice(row['unitPrice']),
            'currentStock': _parsePrice(row['currentStock']),
            'status': status,
          };
        }).where((item) => (item['itemName'] as String).isNotEmpty).toList();
      } else {
        // Clients
        payload = normalizedData.map((row) {
          final name = (row['name'] ?? row['clientName'] ?? row['customer'] ?? '').toString().trim();
          return {
            'name': name,
            'email': (row['email'] ?? '').toString().trim(),
            'phone': (row['phone'] ?? '').toString().trim(),
            'address': (row['address'] ?? '').toString().trim(),
            'gstin': (row['gstin'] ?? '').toString().trim(),
            'state': (row['state'] ?? '').toString().trim(),
          };
        }).where((client) => (client['name'] as String).isNotEmpty).toList();
      }

      if (payload == null || (payload as List).isEmpty) {
        Fluttertoast.showToast(
          msg: 'No valid data found to import. Please check your columns.',
          backgroundColor: AppColors.error,
          textColor: Colors.white,
        );
        isImporting.value = false;
        return;
      }

      String endpoint = '';
      if (activeTab.value == 'clients') {
        endpoint = '${ApiConstants.clients}/bulk';
      } else if (activeTab.value == 'inventory') {
        endpoint = '${ApiConstants.inventory}/bulk';
      } else if (activeTab.value == 'invoices') {
        endpoint = '${ApiConstants.invoices}/bulk';
      }

      final response = await ApiService.post(endpoint, payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          Fluttertoast.showToast(
            msg: body['message'] ?? 'Import completed successfully!',
            backgroundColor: AppColors.success,
            textColor: Colors.white,
            toastLength: Toast.LENGTH_LONG,
          );
          Get.snackbar(
            'Success',
            body['message'] ?? 'Import successful',
            backgroundColor: Colors.green.shade700,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          clearData();
        } else {
          Fluttertoast.showToast(
            msg: body['message'] ?? 'Import failed',
            backgroundColor: AppColors.error,
            textColor: Colors.white,
          );
        }
      } else {
        String msg = 'Server error ${response.statusCode}';
        try {
          final body = jsonDecode(response.body);
          if (body['message'] != null) msg = body['message'];
        } catch (_) {}
        Fluttertoast.showToast(msg: msg, backgroundColor: AppColors.error, textColor: Colors.white);
      }
    } catch (e) {
      debugPrint('[IMPORT] Import submission failed: $e');
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception: ')) {
        errorMsg = errorMsg.replaceAll('Exception: ', '');
      }
      Fluttertoast.showToast(
        msg: 'Import Error: $errorMsg',
        backgroundColor: AppColors.error,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      isImporting.value = false;
    }
  }
}
