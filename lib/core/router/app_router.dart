import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paimana/features/auth/presentation/screens/login_screen.dart';
import 'package:paimana/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'package:paimana/features/customers/presentation/screens/customers_screen.dart';
import 'package:paimana/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:paimana/features/orders/presentation/screens/orders_screen.dart';
import 'package:paimana/features/payments/presentation/screens/payments_screen.dart';
import 'package:paimana/features/settings/presentation/screens/settings_screen.dart';
import 'package:paimana/shared/widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(currentLocation: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomersScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/payments',
          builder: (context, state) => const PaymentsScreen(),
        ),
        GoRoute(
          path: '/assistant',
          builder: (context, state) => const AiAssistantScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text(state.error?.toString() ?? 'Page not found')),
  ),
);
