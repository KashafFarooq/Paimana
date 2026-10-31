import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paimana/core/sync/auto_sync_provider.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    required this.currentLocation,
    required this.child,
    super.key,
  });

  final String currentLocation;
  final Widget child;

  int get _selectedIndex {
    if (currentLocation.startsWith('/customers')) return 1;
    if (currentLocation.startsWith('/orders')) return 2;
    if (currentLocation.startsWith('/payments')) return 3;
    if (currentLocation.startsWith('/assistant')) return 4;
    return 0;
  }

  String get _title {
    if (currentLocation.startsWith('/customers')) return 'Customers';
    if (currentLocation.startsWith('/orders')) return 'Orders';
    if (currentLocation.startsWith('/payments')) return 'Payments';
    if (currentLocation.startsWith('/assistant')) return 'AI studio';
    if (currentLocation.startsWith('/settings')) return 'Settings';
    return 'Paimana';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(autoSyncProvider);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Text(_title),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (syncState.hasError)
            MaterialBanner(
              content: const Text(
                'Automatic sync failed. Retry when your connection is ready.',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      unawaited(ref.read(autoSyncProvider.notifier).retry()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          const destinations = [
            '/dashboard',
            '/customers',
            '/orders',
            '/payments',
            '/assistant',
          ];
          context.go(destinations[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.content_cut_rounded),
            selectedIcon: Icon(Icons.content_cut_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments_rounded),
            label: 'Payments',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'AI studio',
          ),
        ],
      ),
    );
  }
}
