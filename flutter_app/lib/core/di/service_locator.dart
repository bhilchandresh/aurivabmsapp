import 'package:get/get.dart';

class ServiceLocator {
  static T get<T>() => Get.find<T>();
}
