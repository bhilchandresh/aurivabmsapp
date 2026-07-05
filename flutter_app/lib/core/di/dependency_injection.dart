import 'package:get/get.dart';
import '../services/session_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../auth/security/secure_storage_service.dart';
import '../auth/security/token_manager.dart';
import '../auth/services/permission_manager.dart';
import '../auth/data/auth_local_data_source.dart';
import '../auth/data/auth_remote_data_source.dart';
import '../auth/data/auth_repository.dart';

import 'package:flutter/foundation.dart';
import '../monitoring/monitoring_config.dart';
import '../monitoring/logger_service.dart';
import '../monitoring/crash_service.dart';
import '../monitoring/analytics_service.dart';
import '../monitoring/performance_service.dart';
import '../monitoring/monitoring_service.dart';

import '../../features/clients/clients_controller.dart';
import '../../features/suppliers/suppliers_controller.dart';
import '../../features/inventory/inventory_controller.dart';
import '../../features/expenses/expenses_controller.dart';

class DependencyInjection {
  static Future<void> init() async {
    const storage = FlutterSecureStorage();
    final secureStorage = SecureStorageService(storage);
    Get.lazyPut<SecureStorageService>(() => secureStorage, fenix: true);

    final sessionManager = SessionManager();
    await sessionManager.init();
    Get.lazyPut<SessionManager>(() => sessionManager, fenix: true);

    // Monitoring bindings
    final config = kDebugMode ? MonitoringConfig.development() : MonitoringConfig.production();
    final loggerService = LoggerService(config);
    Get.lazyPut<LoggerService>(() => loggerService, fenix: true);

    final crashService = CrashService(config, sessionManager);
    Get.lazyPut<CrashService>(() => crashService, fenix: true);

    final analyticsService = AnalyticsService(config, sessionManager);
    Get.lazyPut<AnalyticsService>(() => analyticsService, fenix: true);

    final performanceService = PerformanceService(config);
    Get.lazyPut<PerformanceService>(() => performanceService, fenix: true);

    final monitoringService = MonitoringService(
      logger: loggerService,
      crash: crashService,
      analytics: analyticsService,
      performance: performanceService,
      config: config,
    );
    Get.lazyPut<MonitoringService>(() => monitoringService, fenix: true);

    final localDS = AuthLocalDataSource(secureStorage);
    Get.lazyPut<AuthLocalDataSource>(() => localDS, fenix: true);

    final remoteDS = AuthRemoteDataSource();
    Get.lazyPut<AuthRemoteDataSource>(() => remoteDS, fenix: true);

    final authRepository = AuthRepository(localDS, remoteDS, sessionManager);
    Get.lazyPut<AuthRepository>(() => authRepository, fenix: true);

    final tokenManager = TokenManager(
      onRefreshTrigger: () => authRepository.refreshToken(),
      onSessionExpired: () => sessionManager.expireSession(),
    );
    Get.lazyPut<TokenManager>(() => tokenManager, fenix: true);

    final permissionManager = PermissionManager(sessionManager);
    Get.lazyPut<PermissionManager>(() => permissionManager, fenix: true);

    // Controllers
    Get.lazyPut<ClientsController>(() => ClientsController(), fenix: true);
    Get.lazyPut<SuppliersController>(() => SuppliersController(), fenix: true);
    Get.lazyPut<InventoryController>(() => InventoryController(), fenix: true);
    Get.lazyPut<ExpensesController>(() => ExpensesController(), fenix: true);
  }
}
