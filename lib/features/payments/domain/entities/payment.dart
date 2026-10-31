enum PaymentType { advance, partial, finalPayment }

enum PaymentMethod { cash, bankTransfer, mobileWallet, other }

class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paymentType,
    required this.method,
    required this.paidAt,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final double amount;
  final PaymentType paymentType;
  final PaymentMethod method;
  final DateTime paidAt;
  final String note;
  final DateTime createdAt;

  factory Payment.fromJson(Map<String, dynamic> json) {
    final id = json['clientId'] ?? json['id'];
    final orderId = json['orderId'];
    final amount = json['amount'];
    final type = json['paymentType'];
    final method = json['method'];
    final paidAt = json['paidAt'];
    final createdAt = json['createdAt'];
    if (id is! String ||
        orderId is! String ||
        amount is! num ||
        type is! String ||
        method is! String ||
        paidAt is! String ||
        createdAt is! String) {
      throw const FormatException('The payment record is incomplete.');
    }

    return Payment(
      id: id,
      orderId: orderId,
      amount: amount.toDouble(),
      paymentType: _typeFromApi(type),
      method: _methodFromApi(method),
      paidAt: DateTime.parse(paidAt),
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(createdAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': id,
    'orderId': orderId,
    'amount': amount,
    'paymentType': _typeToApi(paymentType),
    'method': _methodToApi(method),
    'paidAt': paidAt.toUtc().toIso8601String(),
    'note': note,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}

PaymentType _typeFromApi(String type) => switch (type) {
  'advance' => PaymentType.advance,
  'partial' => PaymentType.partial,
  'final' => PaymentType.finalPayment,
  _ => throw FormatException('Unsupported payment type: $type'),
};

String _typeToApi(PaymentType type) => switch (type) {
  PaymentType.advance => 'advance',
  PaymentType.partial => 'partial',
  PaymentType.finalPayment => 'final',
};

PaymentMethod _methodFromApi(String method) => switch (method) {
  'cash' => PaymentMethod.cash,
  'bank_transfer' => PaymentMethod.bankTransfer,
  'mobile_wallet' => PaymentMethod.mobileWallet,
  'other' => PaymentMethod.other,
  _ => throw FormatException('Unsupported payment method: $method'),
};

String _methodToApi(PaymentMethod method) => switch (method) {
  PaymentMethod.cash => 'cash',
  PaymentMethod.bankTransfer => 'bank_transfer',
  PaymentMethod.mobileWallet => 'mobile_wallet',
  PaymentMethod.other => 'other',
};
