import 'package:get/get.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/suppliers/suppliers_screen.dart';
import '../features/expenses/expenses_screen.dart';
import '../features/team/team_screen.dart';
import '../features/settings/settings_screen.dart';
import 'main_layout.dart';

class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const main = '/main';
  static const inventory = '/inventory';
  static const suppliers = '/suppliers';
  static const expenses = '/expenses';
  static const team = '/team';
  static const settings = '/settings';

  static final pages = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      transition: Transition.fade,
    ),
    GetPage(
      name: main,
      page: () => const MainLayout(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: inventory,
      page: () => const InventoryScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: suppliers,
      page: () => const SuppliersScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: expenses,
      page: () => const ExpensesScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: team,
      page: () => const TeamScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
  ];
}
