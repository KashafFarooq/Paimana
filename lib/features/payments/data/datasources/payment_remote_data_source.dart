import 'package:dio/dio.dart';
import 'package:paimana/core/network/api_client.dart';
import 'package:paimana/features/payments/domain/entities/payment.dart';

class PaymentRemoteDataSource {
  PaymentRemoteDataSource({Dio? dio}) : _dio = dio ?? apiClient;

  final Dio _dio;

  Future<List<Payment>> getAll() async {
    const pageSize = 100;
    final payments = <Payment>[];
    var page = 1;
    var total = 0;
    do {
      final response = await _dio.get<Map<String, dynamic>>(
        '/payments',
        queryParameters: {'page': page, 'limit': pageSize},
      );
      final data = _data(response.data);
      final items = data['items'];
      if (items is! List) {
        throw const FormatException('The API returned an invalid payment list.');
      }
      for (final item in items) {
        if (item is! Map) {
          throw const FormatException('The API returned an invalid payment.');
        }
        payments.add(Payment.fromJson(Map<String, dynamic>.from(item)));
      }
      total = data['total'] is int ? data['total'] as int : payments.length;
      page++;
    } while (payments.length < total);
    return payments;
  }

  Future<void> save(Payment payment) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/payments',
      data: {
        'orderId': payment.orderId,
        'clientId': payment.id,
        'amount': payment.amount,
        'paymentType': _typeToApi(payment.paymentType),
        'method': _methodToApi(payment.method),
        'paidAt': payment.paidAt.toUtc().toIso8601String(),
        'note': payment.note,
      },
    );
    final data = _data(response.data);
    if (data['payment'] is! Map<String, dynamic>) {
      throw const FormatException('The API did not confirm the payment save.');
    }
  }

  Future<void> delete(String id) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/payments/${Uri.encodeComponent(id)}',
    );
    _data(response.data);
  }

  Map<String, dynamic> _data(Map<String, dynamic>? response) {
    final data = response?['data'];
    if (response?['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('The API returned an invalid payment response.');
    }
    return data;
  }

  String _methodToApi(PaymentMethod method) => switch (method) {
    PaymentMethod.cash => 'cash',
    PaymentMethod.bankTransfer => 'bank_transfer',
    PaymentMethod.mobileWallet => 'mobile_wallet',
    PaymentMethod.other => 'other',
  };

  String _typeToApi(PaymentType type) => switch (type) {
    PaymentType.advance => 'advance',
    PaymentType.partial => 'partial',
    PaymentType.finalPayment => 'final',
  };
}
