import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:paimana/features/customers/presentation/providers/customer_providers.dart';
import 'package:paimana/features/orders/domain/entities/order.dart';
import 'package:paimana/features/orders/presentation/providers/order_providers.dart';
import 'package:paimana/features/payments/presentation/providers/payment_providers.dart';
import 'package:paimana/shared/widgets/empty_state.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    return orders.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load orders'),
              const SizedBox(height: 8),
              Text(error.toString(), textAlign: TextAlign.center),
              TextButton(
                onPressed: () => ref.invalidate(ordersProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.content_cut_outlined,
            title: 'No orders on the table',
            message:
                'Start an order to track the design, due date and advance payment.',
            action: FilledButton.icon(
              onPressed: () => _showOrderForm(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create order'),
            ),
          );
        }
        final sorted = [...items]
          ..sort((first, second) => first.dueDate.compareTo(second.dueDate));
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${items.length} ${items.length == 1 ? 'order' : 'orders'} in progress',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showOrderForm(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text('New order'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...sorted.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OrderCard(
                  order: order,
                  onStatusChanged: (status) {
                    ref
                        .read(ordersProvider.notifier)
                        .updateStatus(order.copyWith(status: status));
                  },
                  onDelete: () => _deleteOrder(context, ref, order),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showOrderForm(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final customers = ref.read(customersProvider).asData?.value ?? const [];
    final result = await showModalBottomSheet<_OrderFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _OrderForm(
        customerNames: customers
            .map((customer) => customer.name)
            .toSet()
            .toList(),
      ),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(ordersProvider.notifier)
          .add(
            customerName: result.customerName,
            garment: result.garment,
            dueDate: result.dueDate,
            totalAmount: result.totalAmount,
            paidAmount: result.paidAmount,
            note: result.note,
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save order: $error')));
      }
    }
  }

  static Future<void> _deleteOrder(
    BuildContext context,
    WidgetRef ref,
    TailoringOrder order,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this order?'),
        content: Text(
          '${order.garment} for ${order.customerName}. Its payment history will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep order'),
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
      await ref.read(paymentsProvider.notifier).deleteForOrder(order.id);
      await ref.read(ordersProvider.notifier).delete(order.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove order: $error')),
        );
      }
    }
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onStatusChanged,
    required this.onDelete,
  });

  final TailoringOrder order;
  final ValueChanged<OrderStatus> onStatusChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueText = DateFormat('EEE, d MMM').format(order.dueDate);
    final remaining = order.totalAmount - order.paidAmount;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 10, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.customerName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PopupMenuButton<OrderStatus>(
                  tooltip: 'Change order status',
                  initialValue: order.status,
                  onSelected: onStatusChanged,
                  itemBuilder: (context) => OrderStatus.values
                      .map(
                        (status) => PopupMenuItem(
                          value: status,
                          child: Text(_statusLabel(status)),
                        ),
                      )
                      .toList(),
                  child: _StatusLabel(status: order.status),
                ),
                IconButton(
                  tooltip: 'Remove order',
                  onPressed: onDelete,
                  icon: const Icon(Icons.more_vert_rounded),
                ),
              ],
            ),
            Text(
              order.garment,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 17,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text('Due $dueText'),
                const Spacer(),
                Text(
                  'Rs. ${NumberFormat('#,##0.##').format(order.totalAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 11),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: order.totalAmount == 0
                    ? 0
                    : (order.paidAmount / order.totalAmount).clamp(0, 1),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Rs. ${NumberFormat('#,##0.##').format(order.paidAmount)} paid  ·  Rs. ${NumberFormat('#,##0.##').format(remaining)} remaining',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (order.note.isNotEmpty) ...[
              const SizedBox(height: 9),
              Text(
                order.note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status == OrderStatus.delivered
        ? const Color(0xFF43856C)
        : status == OrderStatus.cancelled
        ? const Color(0xFFB36C76)
        : const Color(0xFFD59A52);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _statusLabel(OrderStatus status) {
  return switch (status) {
    OrderStatus.pending => 'Pending',
    OrderStatus.cutting => 'Cutting',
    OrderStatus.stitching => 'Stitching',
    OrderStatus.ready => 'Ready',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Cancelled',
  };
}

class _OrderFormResult {
  const _OrderFormResult({
    required this.customerName,
    required this.garment,
    required this.dueDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.note,
  });

  final String customerName;
  final String garment;
  final DateTime dueDate;
  final double totalAmount;
  final double paidAmount;
  final String note;
}

class _OrderForm extends StatefulWidget {
  const _OrderForm({required this.customerNames});

  final List<String> customerNames;

  @override
  State<_OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<_OrderForm> {
  static const _manualCustomer = '__manual__';

  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _garmentController = TextEditingController();
  final _priceController = TextEditingController();
  final _advanceController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedCustomer;

  @override
  void dispose() {
    _customerController.dispose();
    _garmentController.dispose();
    _priceController.dispose();
    _advanceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomers = widget.customerNames.isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New order', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (hasCustomers) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedCustomer,
                  decoration: const InputDecoration(labelText: 'Customer *'),
                  items: [
                    ...widget.customerNames.map(
                      (name) =>
                          DropdownMenuItem(value: name, child: Text(name)),
                    ),
                    const DropdownMenuItem(
                      value: _manualCustomer,
                      child: Text('Enter a different name'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _selectedCustomer = value;
                    _customerController.clear();
                  }),
                  validator: (value) =>
                      value == null ? 'Choose or enter a customer' : null,
                ),
                if (_selectedCustomer == _manualCustomer) ...[
                  const SizedBox(height: 10),
                  _customerField(),
                ],
              ] else
                _customerField(),
              const SizedBox(height: 11),
              TextFormField(
                controller: _garmentController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Garment / design *',
                  hintText: 'e.g. 3-piece suit',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a garment or design'
                    : null,
              ),
              const SizedBox(height: 11),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(
                  'Delivery date: ${DateFormat.yMMMd().format(_dueDate)}',
                ),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Total (Rs.) *',
                      ),
                      validator: (value) =>
                          _validateAmount(value, 'Enter a valid total'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _advanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Advance (Rs.)',
                      ),
                      validator: _validateAdvance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Order notes'),
              ),
              const SizedBox(height: 17),
              FilledButton(
                onPressed: _save,
                child: const Text('Save order on this device'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customerField() {
    return TextFormField(
      controller: _customerController,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(labelText: 'Customer name *'),
      validator: (value) => value == null || value.trim().isEmpty
          ? 'Enter a customer name'
          : null,
    );
  }

  String? _validateAmount(String? value, String message) {
    final amount = double.tryParse(value ?? '');
    return amount == null || !amount.isFinite || amount <= 0 ? message : null;
  }

  String? _validateAdvance(String? value) {
    final advance = double.tryParse(value ?? '');
    final total = double.tryParse(_priceController.text);
    if (advance == null || !advance.isFinite || advance < 0) {
      return 'Enter a valid advance';
    }
    if (total != null && advance > total) return 'Cannot exceed total';
    return null;
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected != null) setState(() => _dueDate = selected);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final customerName =
        _selectedCustomer == _manualCustomer || _selectedCustomer == null
        ? _customerController.text.trim()
        : _selectedCustomer!;
    Navigator.pop(
      context,
      _OrderFormResult(
        customerName: customerName,
        garment: _garmentController.text.trim(),
        dueDate: _dueDate,
        totalAmount: double.parse(_priceController.text),
        paidAmount: double.parse(_advanceController.text),
        note: _noteController.text.trim(),
      ),
    );
  }
}
