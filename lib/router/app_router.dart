import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/value_proposition_screen.dart';
import '../screens/onboarding/business_info_screen.dart';
import '../screens/onboarding/first_sales_screen.dart';
import '../screens/onboarding/first_result_screen.dart';
import '../screens/main/main_shell.dart';
import '../screens/radar/radar_screen.dart';
import '../screens/data_input/data_input_screen.dart';
import '../screens/data_input/sales_input_screen.dart';
import '../screens/data_input/expense_input_screen.dart';
import '../screens/data_input/deemed_purchase_screen.dart';
import '../screens/data_input/history_input_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/tax_detail/tax_detail_screen.dart';
import '../screens/simulator/simulator_screen.dart';
import '../screens/precision_tax/precision_tax_screen.dart';
import '../screens/glossary/glossary_screen.dart';
import '../screens/settings/privacy_policy_screen.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router(BuildContext context) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      redirect: (context, state) {
        // After splash, redirect based on onboarding status
        if (state.matchedLocation == '/splash') return null;
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Onboarding
        GoRoute(
          path: '/onboarding/value',
          builder: (context, state) => const ValuePropositionScreen(),
        ),
        GoRoute(
          path: '/onboarding/business-info',
          builder: (context, state) => const BusinessInfoScreen(),
        ),
        GoRoute(
          path: '/onboarding/first-sales',
          builder: (context, state) => const FirstSalesScreen(),
        ),
        GoRoute(
          path: '/onboarding/first-result',
          builder: (context, state) => const FirstResultScreen(),
        ),

        // Main Shell with Bottom Nav
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/radar',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const RadarScreen(),
              ),
            ),
            GoRoute(
              path: '/data',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const DataInputScreen(),
              ),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const SettingsScreen(),
              ),
            ),
          ],
        ),

        // Detail screens (outside shell)
        GoRoute(
          path: '/tax-detail/:type',
          builder: (context, state) {
            final type = state.pathParameters['type'] ?? 'vat';
            return TaxDetailScreen(taxType: type);
          },
        ),
        GoRoute(
          path: '/simulator',
          builder: (context, state) => const SimulatorScreen(),
        ),
        GoRoute(
          path: '/precision-tax',
          builder: (context, state) => const PrecisionTaxScreen(),
        ),
        GoRoute(
          path: '/glossary',
          builder: (context, state) => const GlossaryScreen(),
        ),
        GoRoute(
          path: '/privacy-policy',
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),
        GoRoute(
          path: '/settings/business-info',
          builder: (context, state) => const BusinessInfoScreen(isEditing: true),
        ),

        // Data input sub-screens
        GoRoute(
          path: '/data/sales-input',
          builder: (context, state) => const SalesInputScreen(),
        ),
        GoRoute(
          path: '/data/expense-input',
          builder: (context, state) => const ExpenseInputScreen(),
        ),
        GoRoute(
          path: '/data/deemed-purchase',
          builder: (context, state) => const DeemedPurchaseScreen(),
        ),
        GoRoute(
          path: '/data/history',
          builder: (context, state) => const HistoryInputScreen(),
        ),
      ],
    );
  }
}
