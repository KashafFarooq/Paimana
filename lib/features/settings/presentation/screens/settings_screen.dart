import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paimana/core/config/app_config.dart';
import 'package:paimana/core/storage/hive_record_store.dart';
import 'package:paimana/core/storage/token_storage.dart';
import 'package:paimana/features/auth/presentation/providers/auth_provider.dart';
import 'package:paimana/features/customers/presentation/providers/customer_providers.dart';
import 'package:paimana/features/orders/presentation/providers/order_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersSync = ref.watch(customersProvider);
    final ordersSync = ref.watch(ordersProvider);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          'Your workspace',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                AppConfig.hasApi
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(
              AppConfig.hasApi ? 'Backend configured' : 'Offline mode',
            ),
            subtitle: Text(
              AppConfig.hasApi
                  ? AppConfig.apiBaseUrl
                  : 'Customers and orders are saved securely on this device.',
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Offline changes', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        FutureBuilder<int>(
          future: _pendingSyncCount(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.error_outline_rounded),
                  title: const Text('Could not read the sync queue'),
                  subtitle: Text(snapshot.error.toString()),
                ),
              );
            }
            final pending = snapshot.data ?? 0;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.sync_rounded),
                title: Text(
                  pending == 0
                      ? 'All saved changes are synced'
                      : '$pending ${pending == 1 ? 'change' : 'changes'} waiting to sync',
                ),
                subtitle: Text(
                  customersSync.hasError || ordersSync.hasError
                      ? 'Sync failed. Your saved changes remain on this device.'
                      : AppConfig.hasApi
                      ? 'Pending work is retained on this device until the server is available.'
                      : 'Configure the backend to sync your offline work.',
                ),
                trailing: IconButton(
                  tooltip: 'Sync now',
                  onPressed: !AppConfig.hasApi
                      ? null
                      : () {
                          ref.invalidate(customersProvider);
                          ref.invalidate(ordersProvider);
                        },
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Text('Connect your REST API', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set API_BASE_URL when you start the app. Use 10.0.2.2 for an Android emulator, localhost for Chrome on this computer, or this computer’s private LAN IP for a physical phone. Local HTTP is debug-only.',
                  style: TextStyle(height: 1.45),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const SelectableText(
                    'flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api/v1',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Privacy', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Customer and order records are stored in the app’s local Hive database. '
              'AI requests are sent to the configured backend only when you submit them. '
              'AI results stay editable and are never saved automatically.',
              style: TextStyle(height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Paimana', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const Card(
          child: ListTile(
            leading: Icon(Icons.auto_awesome_rounded),
            title: Text('Smart order assistant'),
            subtitle: Text('Built for the craft and care of tailoring.'),
            trailing: Text('v1.0.0'),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign out'),
            subtitle: const Text('Clear this device’s saved session.'),
            onTap: () async {
              try {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Signed out on this device. The server could not be notified: $error',
                      ),
                    ),
                  );
                  context.go('/login');
                }
              }
            },
          ),
        ),
      ],
    );
  }

  static Future<int> _pendingSyncCount() async {
    final scope = AppConfig.hasApi
        ? await TokenStorage().readAccountId() ?? 'local'
        : 'local';
    final store = HiveRecordStore();
    final customers = await store.readQueue('customer', scope: scope);
    final orders = await store.readQueue('order', scope: scope);
    return customers.length + orders.length;
  }
}
