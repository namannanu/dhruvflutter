part of 'app_state.dart';

extension PaymentExtensions on AppState {
  ServiceLocator get _service => ServiceLocator.instance;
  Future<String> createRazorpayOrder({
    required double amount,
    required String currency,
    required String jobId,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse(PaymentConfig.razorpayCreateOrderEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${getAccessToken()}',
        },
        body: jsonEncode({
          'amount': (amount * 100).toInt(), // Amount in paise
          'currency': currency,
          'jobId': jobId,
          'receipt': 'job_post_${DateTime.now().millisecondsSinceEpoch}',
          'notes': {'job_id': jobId, 'type': 'job_posting'}
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create order: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if ((data['status'] as String?)?.toLowerCase() != 'success') {
        throw Exception(data['message'] ?? 'Order creation failed');
      }

      final order = (data['data'] as Map?)?['order'] as Map?;
      final orderId = order?['id']?.toString();

      if (orderId == null) {
        throw Exception('No order ID received from server');
      }

      return orderId;
    } catch (e) {
      throw Exception('Failed to create payment order: $e');
    }
  }

  Future<void> verifyJobPostingPayment({
    required String jobId,
    required double amount,
    required String currency,
    required String orderId,
    required String paymentId,
    required String signature,
    bool publishAfterPayment = false,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse(PaymentConfig.razorpayVerifyEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${getAccessToken()}',
        },
        body: jsonEncode({
          'jobId': jobId,
          'amount': (amount * 100).toInt(),
          'currency': currency,
          'orderId': orderId,
          'paymentId': paymentId,
          'signature': signature,
          'status': 'completed',
          if (publishAfterPayment) 'publishAfterPayment': true,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Payment verification failed: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if ((data['status'] as String?)?.toLowerCase() != 'success') {
        throw Exception(data['message'] ?? 'Payment verification failed');
      }
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  Future<String> getUserPhone() async {
    if (currentUser == null) {
      throw Exception('User not logged in');
    }
    return currentUser?.phone ?? '';
  }

  Future<String> getUserEmail() async {
    if (currentUser == null) {
      throw Exception('User not logged in');
    }
    return currentUser?.email ?? '';
  }

  String getAccessToken() {
    if (currentUser == null) {
      throw Exception('Not authenticated');
    }
    final token = _service.auth.authToken;
    if (token == null) {
      throw Exception('No auth token available');
    }
    return token;
  }
}
