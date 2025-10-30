import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/payment_record.dart';
import 'package:talent/core/state/app_state.dart';

class EmployerBillingScreen extends StatefulWidget {
  const EmployerBillingScreen({super.key});

  @override
  State<EmployerBillingScreen> createState() => _EmployerBillingScreenState();
}

class _EmployerBillingScreenState extends State<EmployerBillingScreen> {
  static const Map<String, String> _currencySymbols = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      appState.loadJobPaymentHistory(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing & Payments'),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final payments = appState.jobPayments;
          final isLoading = appState.isLoadingJobPayments;

          if (isLoading && payments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!isLoading && payments.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => context
                  .read<AppState>()
                  .loadJobPaymentHistory(forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No payment history yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Payments for published job posts will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 120),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context
                .read<AppState>()
                .loadJobPaymentHistory(forceRefresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final payment = payments[index];
                return _buildPaymentTile(payment);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentTile(JobPaymentRecord payment) {
    final amountText = _formatCurrency(payment.amount, payment.currency);
    final statusChip = _buildStatusChip(payment.status);
    final createdAt =
        DateFormat.yMMMd().add_jm().format(payment.createdAt.toLocal());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  amountText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                statusChip,
              ],
            ),
            const SizedBox(height: 8),
            Text(
              payment.description ?? 'Job posting payment',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (payment.jobTitle != null)
              Text(
                payment.jobTitle!,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            if (payment.businessName != null)
              Text(
                payment.businessName!,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reference',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      payment.reference,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  createdAt,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color background;
    Color foreground;
    String label;

    switch (status.toLowerCase()) {
      case 'succeeded':
        background = Colors.green[50]!;
        foreground = Colors.green[800]!;
        label = 'Succeeded';
        break;
      case 'failed':
        background = Colors.red[50]!;
        foreground = Colors.red[800]!;
        label = 'Failed';
        break;
      case 'pending':
      default:
        background = Colors.orange[50]!;
        foreground = Colors.orange[800]!;
        label = status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatCurrency(double amount, String currency) {
    final code = currency.toUpperCase();
    final symbol = _currencySymbols[code] ?? code;
    final amountText = amount.toStringAsFixed(2);
    final needsSpacing = symbol == code;
    return needsSpacing ? '$symbol $amountText' : '$symbol$amountText';
  }
}
