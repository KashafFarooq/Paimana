// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TailoringOrder _$TailoringOrderFromJson(Map<String, dynamic> json) =>
    _TailoringOrder(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      garment: json['garment'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      status:
          $enumDecodeNullable(_$OrderStatusEnumMap, json['status']) ??
          OrderStatus.pending,
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TailoringOrderToJson(_TailoringOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customerName': instance.customerName,
      'garment': instance.garment,
      'dueDate': instance.dueDate.toIso8601String(),
      'totalAmount': instance.totalAmount,
      'paidAmount': instance.paidAmount,
      'status': _$OrderStatusEnumMap[instance.status]!,
      'note': instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.cutting: 'cutting',
  OrderStatus.stitching: 'stitching',
  OrderStatus.ready: 'ready',
  OrderStatus.delivered: 'delivered',
  OrderStatus.cancelled: 'cancelled',
};
