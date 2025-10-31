// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:talent/core/config/payment_config.dart';
import 'package:talent/core/state/app_state.dart';

class PremiumPlanScreen extends StatefulWidget {
  const PremiumPlanScreen({super.key});

  @override
  State<PremiumPlanScreen> createState() => _PremiumPlanScreenState();
}

class _PremiumPlanScreenState extends State<PremiumPlanScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;
  bool _isVerifying = false; // Add flag to prevent multiple verifications

  // Premium plan pricing
  static const double monthlyPrice = 299.0;
  static const double yearlyPrice = 2999.0;
  static const String currency = 'INR';

  bool _isYearlyPlan = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Prevent multiple simultaneous verifications
    if (_isVerifying) {
      debugPrint(
          '⚠️ Payment verification already in progress, ignoring duplicate');
      return;
    }

    try {
      // Set processing state for payment verification
      setState(() {
        _isProcessing = true;
        _isVerifying = true;
      });

      final appState = context.read<AppState>();
      await appState.verifyPremiumPlanPayment(
        orderId: response.orderId!,
        paymentId: response.paymentId!,
        signature: response.signature!,
        planType: _isYearlyPlan ? 'yearly' : 'monthly',
        amount: _isYearlyPlan ? yearlyPrice : monthlyPrice,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Premium plan activated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isVerifying = false;
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: Colors.red,
      ),
    );
    setState(() => _isProcessing = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet: ${response.walletName}'),
      ),
    );
    setState(() => _isProcessing = false);
  }

  Future<void> _startPayment() async {
    debugPrint('🎯 Button pressed - Starting payment process');

    try {
      setState(() => _isProcessing = true);
      debugPrint('🔄 Processing state set to true');

      final appState = context.read<AppState>();
      final amount = _isYearlyPlan ? yearlyPrice : monthlyPrice;
      debugPrint(
          '💰 Payment amount: ₹$amount for ${_isYearlyPlan ? 'yearly' : 'monthly'} plan');

      // Create order
      debugPrint('📦 Creating premium plan order...');
      final orderId = await appState.createPremiumPlanOrder(
        amount: amount,
        currency: currency,
        planType: _isYearlyPlan ? 'yearly' : 'monthly',
      );
      debugPrint('✅ Order created successfully: $orderId');

      // Get user details
      final user = appState.currentUser;
      final profile = appState.workerProfile;
      debugPrint('👤 User: ${user?.email}, Profile: ${profile?.firstName}');

      final options = {
        'key': PaymentConfig.razorpayKeyId,
        'amount': (amount * 100).toInt(), // Amount in paise
        'name': 'TalentHire Premium',
        'description':
            _isYearlyPlan ? 'Yearly Premium Plan' : 'Monthly Premium Plan',
        'order_id': orderId,
        'prefill': {
          'contact': profile?.phone ?? user?.phone ?? '',
          'email': user?.email ?? '',
          'name':
              '${profile?.firstName ?? ''} ${profile?.lastName ?? ''}'.trim(),
        },
        'theme': {
          'color': PaymentConfig.themeColor,
        },
        'timeout': PaymentConfig.paymentTimeoutSeconds,
        'retry': {'enabled': true, 'max_count': 1},
      };

      // Open Razorpay payment UI
      debugPrint('🏦 Opening Razorpay payment UI...');
      _razorpay.open(options);

      // Reset processing state after opening Razorpay UI
      // The callbacks will handle the actual payment processing
      setState(() => _isProcessing = false);
      debugPrint('✅ Razorpay UI opened, processing state reset');
    } catch (e) {
      debugPrint('❌ Payment start failed: $e');
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Plan'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unlock Premium Features',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get unlimited access to all premium features',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Features
            Text(
              'Premium Features',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _buildFeatureItem(
              icon: Icons.work,
              title: 'Unlimited Job Applications',
              description: 'Apply to as many jobs as you want',
              isPremium: true,
            ),
            _buildFeatureItem(
              icon: Icons.star,
              title: 'Priority Support',
              description: 'Get priority customer support',
              isPremium: true,
            ),
            _buildFeatureItem(
              icon: Icons.analytics,
              title: 'Advanced Analytics',
              description: 'Track your application success rate',
              isPremium: true,
            ),
            _buildFeatureItem(
              icon: Icons.verified,
              title: 'Premium Badge',
              description: 'Show you are a premium member',
              isPremium: true,
            ),

            const SizedBox(height: 32),

            // Plan Selection
            Text(
              'Choose Your Plan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isYearlyPlan = false),
                    child: _buildPlanCard(
                      title: 'Monthly',
                      price: '299',
                      period: 'month',
                      description: 'Perfect for trying premium features',
                      isSelected: !_isYearlyPlan,
                      onTap: () => setState(() => _isYearlyPlan = false),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isYearlyPlan = true),
                    child: _buildPlanCard(
                      title: 'Yearly',
                      price: '2999',
                      period: 'year',
                      description: 'Best value! Save ₹590',
                      isSelected: _isYearlyPlan,
                      onTap: () => setState(() => _isYearlyPlan = true),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Payment Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () {
                        debugPrint(
                            '🔴 Premium button tapped - isProcessing: $_isProcessing');
                        debugPrint('🔴 About to call _startPayment()');
                        // Show a test message first
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('🔴 Button working! Starting payment...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        _startPayment();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Upgrade to Premium - ₹${_isYearlyPlan ? yearlyPrice.toInt() : monthlyPrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Terms
            Text(
              'By purchasing, you agree to our Terms of Service and Privacy Policy. Payment will be charged to your selected payment method.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isPremium,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPremium
                  ? theme.primaryColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isPremium ? theme.primaryColor : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withOpacity(0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : theme.dividerColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.primaryColor : null,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.primaryColor,
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '₹$price',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.primaryColor : null,
                    ),
                  ),
                  TextSpan(
                    text: '/$period',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
