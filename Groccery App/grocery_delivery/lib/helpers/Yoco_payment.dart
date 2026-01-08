import 'package:http/http.dart' as http;
import 'package:delivery/config/secrets.dart';

/// CRITICAL SECURITY WARNING:
/// This class should NOT exist in the client-side application!
/// Payment processing with secret keys MUST be done on a secure backend server.
///
/// Current implementation is a SECURITY VULNERABILITY.
///
/// Recommended Architecture:
/// 1. Client sends payment request to YOUR secure backend API
/// 2. Backend validates the order and amount
/// 3. Backend calls Yoco API with secret key (stored securely on server)
/// 4. Backend returns result to client
///
/// TODO: Remove this class and implement proper backend payment processing

@Deprecated('SECURITY RISK: Move payment processing to secure backend')
class YocoPayment {
  // WARNING: This should be a backend endpoint, not direct Yoco URL
  final String backendPaymentUrl = Secrets.paymentApiUrl;

  /// DEPRECATED: Do not use this method
  /// Payment processing must be done server-side
  @Deprecated('SECURITY RISK: This exposes payment logic client-side')
  Future<void> processPayment({
    required String orderId,
    required int amountInCents,
    required String currency,
  }) async {
    // This method should call YOUR backend API instead
    // Example:
    // final response = await http.post(
    //   Uri.parse(backendPaymentUrl),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'orderId': orderId,
    //     'amountInCents': amountInCents,
    //     'currency': currency,
    //   }),
    // );

    throw UnimplementedError(
      'Payment processing must be implemented on secure backend. '
      'Never process payments with secret keys in client-side code.'
    );
  }
}
