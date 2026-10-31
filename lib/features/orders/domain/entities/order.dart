import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

enum OrderStatus { pending, cutting, stitching, ready, delivered, cancelled }

@freezed
abstract class TailoringOrder with _$TailoringOrder {
  const factory TailoringOrder({
    required String id,
    required String customerName,
    required String garment,
    required DateTime dueDate,
    required double totalAmount,
    @Default(0) double paidAmount,
    @Default(OrderStatus.pending) OrderStatus status,
    @Default('') String note,
    required DateTime createdAt,
  }) = _TailoringOrder;

  factory TailoringOrder.fromJson(Map<String, dynamic> json) =>
      _$TailoringOrderFromJson(json);
}
