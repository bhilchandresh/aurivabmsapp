import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/invoices/invoice_list_screen.dart';
import '../../features/clients/clients_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/quotations/quotations_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/suppliers/suppliers_screen.dart';
import '../../features/expenses/expenses_screen.dart';
import '../../features/team/team_screen.dart';
import '../../features/profile/profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDashboardKey = GlobalKey<NavigatorState>(debugLabel: 'shellDashboard');
final _shellNavigatorInvoicesKey = GlobalKey<NavigatorState>(debugLabel: 'shellInvoices');
final _shellNavigatorQuotationsKey = GlobalKey<NavigatorState>(debugLabel: 'shellQuotations');
final _shellNavigatorClientsKey = GlobalKey<NavigatorState>(debugLabel: 'shellClients');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return navigationShell;
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorInvoicesKey,
            routes: [
              GoRoute(
                path: '/invoices',
                builder: (context, state) => const InvoiceListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorQuotationsKey,
            routes: [
              GoRoute(
                path: '/quotations',
                builder: (context, state) => const QuotationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorClientsKey,
            routes: [
              GoRoute(
                path: '/clients',
                builder: (context, state) => const ClientsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Other routes accessed from Profile (pushed on top of the main layout)
      GoRoute(
        path: '/inventory',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: '/suppliers',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SuppliersScreen(),
      ),
      GoRoute(
        path: '/expenses',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExpensesScreen(),
      ),
      GoRoute(
        path: '/team',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TeamScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
