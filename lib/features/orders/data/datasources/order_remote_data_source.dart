import 'package:dio/dio.dart';
import 'package:paimana/core/network/api_client.dart';
import 'package:paimana/features/orders/domain/entities/order.dart';

class OrderRemoteDataSource {
  OrderRemoteDataSource({Dio? dio})
    : _dio = dio ?? apiClient;

  final Dio _dio;

  Future<List<TailoringOrder>> getAll() async {
    const pageSize = 100;
    final orders = <TailoringOrder>[];
    var page = 1;
    var total = 0;
    do {
      final response = await _dio.get<Map<String, dynamic>>(
        '/orders',
        queryParameters: {'page': page, 'limit': pageSize},
      );
      final data = _data(response.data);
      final items = data['items'];
      if (items is! List) {
        throw const FormatException('The API returned an invalid order list.');
      }
      for (final item in items) {
        if (item is! Map) {
          throw const FormatException('The API returned an invalid order.');
        }
        orders.add(_orderFromApi(Map<String, dynamic>.from(item)));
      }
      total = data['total'] is int ? data['total'] as int : orders.length;
      page++;
    } while (orders.length < total);
    return orders;
  }

  Future<void> upsert(TailoringOrder order) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/orders',
      data: {
        'customerName': order.customerName,
        'garment': order.garment,
        'dueDate': order.dueDate.toUtc().toIso8601String(),
        'totalAmount': order.totalAmount,
        'paidAmount': order.paidAmount,
        'status': order.status.name,
        'note': order.note,
        'clientId': order.id,
      },
    );
    final data = _data(response.data);
    if (data['order'] is! Map<String, dynamic>) {
      throw const FormatException('The API did not confirm the order save.');
    }
  }

  Future<void> delete(String id) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/orders/${Uri.encodeComponent(id)}',
    );
    _data(response.data);
  }

  TailoringOrder _orderFromApi(Map<String, dynamic> json) {
    final id = json['clientId'] ?? json['id'];
    if (id is! String) {
      throw const FormatException('The API order is missing an identifier.');
    }
    return TailoringOrder.fromJson({...json, 'id': id});
  }

  Map<String, dynamic> _data(Map<String, dynamic>? response) {
    final data = response?['data'];
    if (response?['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('The API returned an invalid order response.');
    }
    return data;
  }
}
