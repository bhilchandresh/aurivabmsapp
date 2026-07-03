// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/utils/api_service.dart';
import '../models/system_log_model.dart';

class SuperAdminLogsController extends GetxController {
  var isLoading = true.obs;
  var logsList = <SystemLogModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    try {
      isLoading.value = true;
      final response = await ApiService.get('/auth/logs');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          logsList.value = list.map((e) => SystemLogModel.fromJson(e)).toList();
        }
      } else {
        print('Error fetching logs: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception fetching logs: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
