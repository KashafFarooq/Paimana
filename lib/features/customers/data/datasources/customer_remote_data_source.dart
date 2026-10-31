import 'package:dio/dio.dart';
import 'package:paimana/core/network/api_client.dart';
import 'package:paimana/features/customers/domain/entities/customer.dart';

class CustomerRemoteDataSource {
  CustomerRemoteDataSource({Dio? dio})
    : _dio = dio ?? apiClient;

  final Dio _dio;

  Future<List<Customer>> getAll() async {
    const pageSize = 100;
    final customers = <Customer>[];
    var page = 1;
    var total = 0;
    do {
      final response = await _dio.get<Map<String, dynamic>>(
        '/customers',
        queryParameters: {'page': page, 'limit': pageSize},
      );
      final data = _data(response.data);
      final items = data['items'];
      if (items is! List) {
        throw const FormatException('The API returned an invalid customer list.');
      }
      for (final item in items) {
        if (item is! Map) {
          throw const FormatException('The API returned an invalid customer.');
        }
        customers.add(_customerFromApi(Map<String, dynamic>.from(item)));
      }
      total = data['total'] is int ? data['total'] as int : customers.length;
      page++;
    } while (customers.length < total);
    return customers;
  }

  Future<void> upsert(Customer customer) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/customers',
      data: {
        'name': customer.name,
        'phone': customer.phone,
        'note': customer.note,
        'clientId': customer.id,
      },
    );
    final data = _data(response.data);
    if (data['customer'] is! Map<String, dynamic>) {
      throw const FormatException('The API did not confirm the customer save.');
    }
  }

  Future<void> delete(String id) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/customers/${Uri.encodeComponent(id)}',
    );
    _data(response.data);
  }

  Customer _customerFromApi(Map<String, dynamic> json) {
    final id = json['clientId'] ?? json['id'];
    if (id is! String) {
      throw const FormatException('The API customer is missing an identifier.');
    }
    return Customer.fromJson({...json, 'id': id});
  }

  Map<String, dynamic> _data(Map<String, dynamic>? response) {
    final data = response?['data'];
    if (response?['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('The API returned an invalid customer response.');
    }
    return data;
  }
}
