import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:talent/core/config/payment_config.dart';
import 'package:talent/core/state/app_state.dart';

class JobPaymentScreen extends StatefulWidget {
  final String jobId;
  final double amount;
  final String currency;

  const JobPaymentScreen({
    super.key,
    required this.jobId,
    required this.amount,
    String? currency,
  }) : currency = currency ?? PaymentConfig.defaultCurrency;

  @override
  State<JobPaymentScreen> createState() => _JobPaymentScreenState();
}

class _JobPaymentScreenState extends State<JobPaymentScreen> {
  late final Razorpay _razorpay;
  bool _isProcessing = false;
  String? _currentOrderId;
  static const Map<String, String> _currencySymbols = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
  };

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Start payment process automatically when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPayment();
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      setState(() => _isProcessing = true);

      final appState = context.read<AppState>();
      final orderId = response.orderId ?? _currentOrderId;
      final paymentId = response.paymentId;
      final signature = response.signature;

      if (orderId == null || orderId.isEmpty) {
        throw Exception('Missing Razorpay order information.');
      }
      if (paymentId == null || paymentId.isEmpty) {
        throw Exception('Missing Razorpay payment identifier.');
      }
      if (signature == null || signature.isEmpty) {
        throw Exception('Missing Razorpay payment signature.');
      }

      await appState.verifyJobPostingPayment(
        jobId: widget.jobId,
        amount: widget.amount,
        currency: widget.currency,
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
        publishAfterPayment: true,
      );

      await appState.refreshActiveRole();

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('Payment successful. Job published.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error processing payment: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message ?? 'Unknown error'}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
      ),
    );
  }

  void _startPayment() async {
    final appState = context.read<AppState>();
    try {
      setState(() => _isProcessing = true);

      // Get order ID from your backend
      final orderId = await appState.createRazorpayOrder(
        amount: widget.amount,
        currency: widget.currency,
        jobId: widget.jobId,
      );
      _currentOrderId = orderId;

      final options = {
        'key': PaymentConfig.razorpayKeyId,
        'amount':
            (widget.amount * 100).toInt(), // Amount in smallest currency unit
        'name': 'WorkConnect',
        'order_id': orderId,
        'description': 'Payment for Job Posting',
        'timeout': PaymentConfig.paymentTimeoutSeconds,
        'prefill': {
          'contact': await appState.getUserPhone(),
          'email': await appState.getUserEmail(),
          'name':
              '${appState.currentUser?.firstName} ${appState.currentUser?.lastName}',
        },
        'theme': {
          'color': PaymentConfig.themeColor,
        }
      };

      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initializing payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Post Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Payment Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount:'),
                        Text(
                          _formatCurrency(widget.amount),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Type:'),
                        Text('Job Post Publishing'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isProcessing ? null : _startPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Processing...'),
                      ],
                    )
                  : Text('Pay ${_formatCurrency(widget.amount)}'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final code = widget.currency.toUpperCase();
    final symbol = _currencySymbols[code] ?? code;
    final amountText = amount.toStringAsFixed(2);
    final needsSpacing = symbol == code;
    return needsSpacing ? '$symbol $amountText' : '$symbol$amountText';
  }
}
