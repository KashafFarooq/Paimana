import 'package:flutter_test/flutter_test.dart';
import 'package:paimana/features/payments/domain/entities/payment.dart';

void main() {
  test('payment JSON preserves API enums and offline client identifiers', () {
    final payment = Payment.fromJson({
      'id': 'local-payment-1',
      'clientId': 'local-payment-1',
      'orderId': 'local-order-1',
      'amount': 7000,
      'paymentType': 'final',
      'method': 'mobile_wallet',
      'paidAt': '2026-10-28T08:00:00.000Z',
      'note': 'Paid by wallet',
      'createdAt': '2026-10-28T08:00:00.000Z',
    });

    expect(payment.id, 'local-payment-1');
    expect(payment.orderId, 'local-order-1');
    expect(payment.paymentType, PaymentType.finalPayment);
    expect(payment.method, PaymentMethod.mobileWallet);
    expect(payment.toJson()['paymentType'], 'final');
    expect(payment.toJson()['method'], 'mobile_wallet');
  });
}
