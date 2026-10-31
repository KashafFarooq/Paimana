import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:paimana/features/customers/domain/entities/customer.dart';
import 'package:paimana/features/customers/presentation/providers/customer_providers.dart';
import 'package:paimana/shared/widgets/empty_state.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: TextField(
            controller: _searchController,
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search name or phone',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ),
        Expanded(
          child: customers.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(customersProvider),
            ),
            data: (items) {
              final filtered = items.where((customer) {
                return customer.name.toLowerCase().contains(_query) ||
                    customer.phone.toLowerCase().contains(_query);
              }).toList();
              if (filtered.isEmpty) {
                return EmptyState(
                  icon: _query.isEmpty
                      ? Icons.people_outline_rounded
                      : Icons.search_off_rounded,
                  title: _query.isEmpty ? 'No customers yet' : 'No matches',
                  message: _query.isEmpty
                      ? 'Keep every client and their fitting notes close at hand.'
                      : 'Try a different name or phone number.',
                  action: _query.isEmpty
                      ? FilledButton.icon(
                          onPressed: _showAddCustomer,
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Add first customer'),
                        )
                      : null,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: 9),
                itemBuilder: (context, index) => _CustomerCard(
                  customer: filtered[index],
                  onDelete: () => _deleteCustomer(filtered[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddCustomer() async {
    final details = await showModalBottomSheet<_CustomerFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _CustomerForm(),
    );
    if (details == null || !mounted) return;
    try {
      await ref
          .read(customersProvider.notifier)
          .add(name: details.name, phone: details.phone, note: details.note);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove customer?'),
        content: Text('${customer.name} will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
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
      await ref.read(customersProvider.notifier).delete(customer.id);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not save customer: $error')));
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.onDelete});

  final Customer customer;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = customer.name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
        .join();
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          foregroundColor: theme.colorScheme.primary,
          child: Text(
            initials,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            customer.phone.isEmpty
                ? 'Added ${DateFormat.MMMd().format(customer.createdAt)}'
                : '${customer.phone}  ·  ${DateFormat.MMMd().format(customer.createdAt)}',
          ),
        ),
        trailing: IconButton(
          tooltip: 'Remove customer',
          onPressed: onDelete,
          icon: const Icon(Icons.more_vert_rounded),
        ),
      ),
    );
  }
}

class _CustomerFormResult {
  const _CustomerFormResult(this.name, this.phone, this.note);

  final String name;
  final String phone;
  final String note;
}

class _CustomerForm extends StatefulWidget {
  const _CustomerForm();

  @override
  State<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<_CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            Text('New customer', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name *'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a customer name'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Fitting notes'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  _CustomerFormResult(
                    _nameController.text,
                    _phoneController.text,
                    _noteController.text,
                  ),
                );
              },
              child: const Text('Save customer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 34),
            const SizedBox(height: 12),
            const Text('Could not open customers'),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
