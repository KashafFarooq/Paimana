import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:paimana/features/orders/domain/entities/order.dart';
import 'package:paimana/features/orders/presentation/providers/order_providers.dart';
import 'package:paimana/features/payments/domain/entities/payment.dart';
import 'package:paimana/features/payments/presentation/providers/payment_providers.dart';
import 'package:paimana/shared/widgets/empty_state.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(paymentsProvider);
    final orders = ref.watch(ordersProvider).asData?.value ?? const [];
    final ordersById = {for (final order in orders) order.id: order};

    return payments.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load payment history'),
              const SizedBox(height: 8),
              Text(error.toString(), textAlign: TextAlign.center),
              TextButton(
                onPressed: () => ref.invalidate(paymentsProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
      data: (items) {
        final paymentsByOrder = <String, double>{};
        for (final payment in items) {
          paymentsByOrder.update(
            payment.orderId,
            (total) => total + payment.amount,
            ifAbsent: () => payment.amount,
          );
        }
        final displayItems = [...items];
        for (final order in orders) {
          final openingBalance =
              order.paidAmount - (paymentsByOrder[order.id] ?? 0);
          if (openingBalance > 0.000001) {
            displayItems.add(
              Payment(
                id: 'opening-balance:${order.id}',
                orderId: order.id,
                amount: openingBalance,
                paymentType: PaymentType.advance,
                method: PaymentMethod.other,
                paidAt: order.createdAt,
                note: 'Opening balance from order setup',
                createdAt: order.createdAt,
              ),
            );
          }
        }
        final sorted = [...displayItems]
          ..sort((first, second) => second.paidAt.compareTo(first.paidAt));
        if (sorted.isEmpty) {
          return EmptyState(
            icon: Icons.payments_outlined,
            title: 'No payments recorded',
            message:
                'Record advances and installments to keep each order balance up to date.',
            action: FilledButton.icon(
              onPressed: () => _showPaymentForm(context, ref, orders),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Record payment'),
            ),
          );
        }

        final total = sorted.fold<double>(
          0,
          (sum, payment) => sum + payment.amount,
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${sorted.length} ${sorted.length == 1 ? 'payment' : 'payments'} · Rs. ${NumberFormat('#,##0.##').format(total)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showPaymentForm(context, ref, orders),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text('Record'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...sorted.map((payment) {
              final order = ordersById[payment.orderId];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PaymentCard(
                  payment: payment,
                  orderTitle: order == null
                      ? 'Order ${payment.orderId}'
                      : '${order.customerName} · ${order.garment}',
                  onDelete: payment.id.startsWith('opening-balance:')
                      ? null
                      : () => _deletePayment(context, ref, payment),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  static Future<void> _showPaymentForm(
    BuildContext context,
    WidgetRef ref,
    List<TailoringOrder> orders,
  ) async {
    final availableOrders = orders
        .where((order) => order.totalAmount > order.paidAmount)
        .toList(growable: false);
    if (availableOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no unpaid orders to collect.')),
      );
      return;
    }

    final result = await showModalBottomSheet<_PaymentFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _PaymentForm(orders: availableOrders),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(paymentsProvider.notifier).add(
        orderId: result.orderId,
        amount: result.amount,
        paymentType: result.paymentType,
        method: result.method,
        paidAt: result.paidAt,
        note: result.note,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not record payment: $error')),
        );
      }
    }
  }

  static Future<void> _deletePayment(
    BuildContext context,
    WidgetRef ref,
    Payment payment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this payment?'),
        content: Text(
          'Rs. ${NumberFormat('#,##0.##').format(payment.amount)} will be added back to the order balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep payment'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(paymentsProvider.notifier).delete(payment.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove payment: $error')),
        );
      }
    }
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.orderTitle,
    required this.onDelete,
  });

  final Payment payment;
  final String orderTitle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
          child: const Icon(Icons.payments_outlined),
        ),
        title: Text(
          'Rs. ${NumberFormat('#,##0.##').format(payment.amount)} · ${_paymentTypeLabel(payment.paymentType)}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '$orderTitle\n${DateFormat('d MMM yyyy').format(payment.paidAt)} · ${_paymentMethodLabel(payment.method)}'
                '${payment.note.isEmpty ? '' : '\n${payment.note}'}',
          ),
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Remove payment',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ),
    );
  }
}

class _PaymentFormResult {
  const _PaymentFormResult({
    required this.orderId,
    required this.amount,
    required this.paymentType,
    required this.method,
    required this.paidAt,
    required this.note,
  });

  final String orderId;
  final double amount;
  final PaymentType paymentType;
  final PaymentMethod method;
  final DateTime paidAt;
  final String note;
}

class _PaymentForm extends StatefulWidget {
  const _PaymentForm({required this.orders});

  final List<TailoringOrder> orders;

  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late String _orderId;
  PaymentType _paymentType = PaymentType.advance;
  PaymentMethod _method = PaymentMethod.cash;
  DateTime _paidAt = DateTime.now();

  TailoringOrder get _selectedOrder =>
      widget.orders.firstWhere((order) => order.id == _orderId);

  double get _remaining =>
      _selectedOrder.totalAmount - _selectedOrder.paidAmount;

  @override
  void initState() {
    super.initState();
    _orderId = widget.orders.first.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Record a payment',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _orderId,
                decoration: const InputDecoration(labelText: 'Order'),
                items: widget.orders
                    .map(
                      (order) => DropdownMenuItem(
                        value: order.id,
                        child: Text(
                          '${order.customerName} · ${order.garment}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _orderId = value);
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 10),
                child: Text(
                  'Remaining balance: Rs. ${NumberFormat('#,##0.##').format(_remaining)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'Rs. ',
                ),
                validator: _validateAmount,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentType>(
                initialValue: _paymentType,
                decoration: const InputDecoration(labelText: 'Payment type'),
                items: PaymentType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_paymentTypeLabel(type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _paymentType = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Method'),
                items: PaymentMethod.values
                    .map(
                      (method) => DropdownMenuItem(
                        value: method,
                        child: Text(_paymentMethodLabel(method)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(DateFormat('d MMM yyyy').format(_paidAt)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  alignLabelWithHint: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _submit,
                child: const Text('Save payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null || !amount.isFinite || amount <= 0) {
      return 'Enter an amount greater than zero';
    }
    if (amount > _remaining) return 'Amount exceeds the remaining balance';
    if (_paymentType == PaymentType.finalPayment &&
        (amount - _remaining).abs() > 0.000001) {
      return 'A final payment must clear the remaining balance';
    }
    return null;
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => _paidAt = selected);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _PaymentFormResult(
        orderId: _orderId,
        amount: double.parse(_amountController.text.trim()),
        paymentType: _paymentType,
        method: _method,
        paidAt: _paidAt,
        note: _noteController.text.trim(),
      ),
    );
  }
}

String _paymentTypeLabel(PaymentType type) => switch (type) {
  PaymentType.advance => 'Advance',
  PaymentType.partial => 'Partial',
  PaymentType.finalPayment => 'Final',
};

String _paymentMethodLabel(PaymentMethod method) => switch (method) {
  PaymentMethod.cash => 'Cash',
  PaymentMethod.bankTransfer => 'Bank transfer',
  PaymentMethod.mobileWallet => 'Mobile wallet',
  PaymentMethod.other => 'Other',
};
