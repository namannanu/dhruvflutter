// ignore_for_file: avoid_print

class PaymentConfig {
  PaymentConfig._();

  // Razorpay Keys
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_ROzpR9FCBfPSds', // Default test key
  );

  static const String razorpayKeySecret = String.fromEnvironment(
    'RAZORPAY_KEY_SECRET',
    defaultValue: '', // No default for security
  );

  // Base URLs
  static const String paymentApiBaseUrl = 'https://dhruvbackend.vercel.app/api';

  // API Endpoints
  static const String createOrderEndpoint = '/payments/razorpay/order';
  static const String verifyPaymentEndpoint = '/payments/verify';

  // Payment Configuration
  static const int paymentTimeoutSeconds = 300;
  static const String defaultCurrency = 'INR';

  // Theme Configuration
  static const String themeColor = '#1976D2'; // Material Blue

  // Full Endpoint URLs
  static String get razorpayCreateOrderEndpoint =>
      '$paymentApiBaseUrl$createOrderEndpoint';

  static String get razorpayVerifyEndpoint =>
      '$paymentApiBaseUrl$verifyPaymentEndpoint';
}
