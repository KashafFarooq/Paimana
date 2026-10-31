import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paimana/features/customers/presentation/providers/customer_providers.dart';
import 'package:paimana/features/orders/domain/entities/order.dart';
import 'package:paimana/features/orders/presentation/providers/order_providers.dart';
import 'package:paimana/shared/widgets/empty_state.dart';
import 'package:paimana/shared/widgets/section_title.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersState = ref.watch(customersProvider);
    final ordersState = ref.watch(ordersProvider);
    final customers = customersState.asData?.value ?? const [];
    final orders = ordersState.asData?.value ?? const <TailoringOrder>[];
    final today = DateUtils.dateOnly(DateTime.now());
    final todayOrders = orders
        .where((order) => DateUtils.isSameDay(order.dueDate, today))
        .length;
    final outstanding = orders.fold<double>(
      0,
      (total, order) => total + (order.totalAmount - order.paidAmount),
    );
    final revenue = orders.fold<double>(
      0,
      (total, order) => total + order.paidAmount,
    );
    final pending = orders
        .where(
          (order) =>
              order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled,
        )
        .length;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(customersProvider);
        ref.invalidate(ordersProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _WelcomeCard(onCreateOrder: () => context.go('/orders')),
          const SizedBox(height: 22),
          if (customersState.hasError || ordersState.hasError)
            _LoadError(
              message:
                  customersState.error?.toString() ??
                  ordersState.error?.toString() ??
                  'Your saved records could not be loaded.',
              onRetry: () {
                ref.invalidate(customersProvider);
                ref.invalidate(ordersProvider);
              },
            )
          else if (customersState.isLoading || ordersState.isLoading)
            const LinearProgressIndicator(minHeight: 2)
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 560 ? 4 : 2;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: width,
                      child: _MetricCard(
                        icon: Icons.event_available_rounded,
                        label: "Today's fittings",
                        value: '$todayOrders',
                        accent: const Color(0xFF5C8E73),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _MetricCard(
                        icon: Icons.pending_actions_rounded,
                        label: 'In progress',
                        value: '$pending',
                        accent: const Color(0xFFD59A52),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _MetricCard(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Collected',
                        value: _money(revenue),
                        accent: const Color(0xFF7182B4),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _MetricCard(
                        icon: Icons.payments_outlined,
                        label: 'Due to collect',
                        value: _money(outstanding),
                        accent: const Color(0xFFB36C76),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 26),
            SectionTitle(
              title: 'Quick actions',
              subtitle: 'Keep your work moving',
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Add customer',
                    onTap: () => context.go('/customers'),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_task_rounded,
                    label: 'New order',
                    onTap: () => context.go('/orders'),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Ask AI',
                    onTap: () => context.go('/assistant'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            SectionTitle(
              title: 'Recent orders',
              subtitle: 'Your latest tailoring work',
              action: TextButton(
                onPressed: () => context.go('/orders'),
                child: const Text('See all'),
              ),
            ),
            const SizedBox(height: 10),
            if (orders.isEmpty)
              const EmptyState(
                icon: Icons.content_cut_rounded,
                title: 'Your order book is ready',
                message:
                    'Add your first order to keep fittings, delivery dates and payments together.',
              )
            else
              ...orders.take(4).map((order) => _RecentOrderTile(order: order)),
            const SizedBox(height: 20),
            _CustomerNote(count: customers.length),
          ],
        ],
      ),
    );
  }

  static String _money(double amount) {
    return 'Rs. ${NumberFormat('#,##0.##').format(amount)}';
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onCreateOrder});

  final VoidCallback onCreateOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF17483D), Color(0xFF286555)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -2,
            top: 3,
            child: Icon(
              Icons.spa_outlined,
              size: 78,
              color: Colors.white.withValues(alpha: 0.13),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'OFFLINE-READY WORKSPACE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        letterSpacing: 0.7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'A little more time\nfor the craft.',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Your shop, customers and orders in one calm place.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 17),
              FilledButton.tonalIcon(
                onPressed: onCreateOrder,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create an order'),
                style: FilledButton.styleFrom(
                  foregroundColor: const Color(0xFF17483D),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: accent),
            ),
            const SizedBox(height: 17),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 7),
          child: Column(
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(height: 9),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order});

  final TailoringOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          foregroundColor: theme.colorScheme.primary,
          child: const Icon(Icons.checkroom_rounded),
        ),
        title: Text(
          order.customerName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${order.garment}  ·  due ${DateFormat.MMMd().format(order.dueDate)}',
        ),
        trailing: _StatusPill(status: order.status),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final label = status.name[0].toUpperCase() + status.name.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CustomerNote extends StatelessWidget {
  const _CustomerNote({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.people_alt_outlined,
          size: 17,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$count ${count == 1 ? 'customer' : 'customers'} in your book',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Could not load saved work'),
            const SizedBox(height: 6),
            Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
