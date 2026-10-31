// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TailoringOrder {

 String get id; String get customerName; String get garment; DateTime get dueDate; double get totalAmount; double get paidAmount; OrderStatus get status; String get note; DateTime get createdAt;
/// Create a copy of TailoringOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TailoringOrderCopyWith<TailoringOrder> get copyWith => _$TailoringOrderCopyWithImpl<TailoringOrder>(this as TailoringOrder, _$identity);

  /// Serializes this TailoringOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TailoringOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.garment, garment) || other.garment == garment)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.status, status) || other.status == status)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,customerName,garment,dueDate,totalAmount,paidAmount,status,note,createdAt);

@override
String toString() {
  return 'TailoringOrder(id: $id, customerName: $customerName, garment: $garment, dueDate: $dueDate, totalAmount: $totalAmount, paidAmount: $paidAmount, status: $status, note: $note, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TailoringOrderCopyWith<$Res>  {
  factory $TailoringOrderCopyWith(TailoringOrder value, $Res Function(TailoringOrder) _then) = _$TailoringOrderCopyWithImpl;
@useResult
$Res call({
 String id, String customerName, String garment, DateTime dueDate, double totalAmount, double paidAmount, OrderStatus status, String note, DateTime createdAt
});




}
/// @nodoc
class _$TailoringOrderCopyWithImpl<$Res>
    implements $TailoringOrderCopyWith<$Res> {
  _$TailoringOrderCopyWithImpl(this._self, this._then);

  final TailoringOrder _self;
  final $Res Function(TailoringOrder) _then;

/// Create a copy of TailoringOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? customerName = null,Object? garment = null,Object? dueDate = null,Object? totalAmount = null,Object? paidAmount = null,Object? status = null,Object? note = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,customerName: null == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String,garment: null == garment ? _self.garment : garment // ignore: cast_nullable_to_non_nullable
as String,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TailoringOrder].
extension TailoringOrderPatterns on TailoringOrder {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TailoringOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TailoringOrder() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TailoringOrder value)  $default,){
final _that = this;
switch (_that) {
case _TailoringOrder():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TailoringOrder value)?  $default,){
final _that = this;
switch (_that) {
case _TailoringOrder() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String customerName,  String garment,  DateTime dueDate,  double totalAmount,  double paidAmount,  OrderStatus status,  String note,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TailoringOrder() when $default != null:
return $default(_that.id,_that.customerName,_that.garment,_that.dueDate,_that.totalAmount,_that.paidAmount,_that.status,_that.note,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String customerName,  String garment,  DateTime dueDate,  double totalAmount,  double paidAmount,  OrderStatus status,  String note,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _TailoringOrder():
return $default(_that.id,_that.customerName,_that.garment,_that.dueDate,_that.totalAmount,_that.paidAmount,_that.status,_that.note,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String customerName,  String garment,  DateTime dueDate,  double totalAmount,  double paidAmount,  OrderStatus status,  String note,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TailoringOrder() when $default != null:
return $default(_that.id,_that.customerName,_that.garment,_that.dueDate,_that.totalAmount,_that.paidAmount,_that.status,_that.note,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TailoringOrder implements TailoringOrder {
  const _TailoringOrder({required this.id, required this.customerName, required this.garment, required this.dueDate, required this.totalAmount, this.paidAmount = 0, this.status = OrderStatus.pending, this.note = '', required this.createdAt});
  factory _TailoringOrder.fromJson(Map<String, dynamic> json) => _$TailoringOrderFromJson(json);

@override final  String id;
@override final  String customerName;
@override final  String garment;
@override final  DateTime dueDate;
@override final  double totalAmount;
@override@JsonKey() final  double paidAmount;
@override@JsonKey() final  OrderStatus status;
@override@JsonKey() final  String note;
@override final  DateTime createdAt;

/// Create a copy of TailoringOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TailoringOrderCopyWith<_TailoringOrder> get copyWith => __$TailoringOrderCopyWithImpl<_TailoringOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TailoringOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TailoringOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.garment, garment) || other.garment == garment)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.status, status) || other.status == status)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,customerName,garment,dueDate,totalAmount,paidAmount,status,note,createdAt);

@override
String toString() {
  return 'TailoringOrder(id: $id, customerName: $customerName, garment: $garment, dueDate: $dueDate, totalAmount: $totalAmount, paidAmount: $paidAmount, status: $status, note: $note, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TailoringOrderCopyWith<$Res> implements $TailoringOrderCopyWith<$Res> {
  factory _$TailoringOrderCopyWith(_TailoringOrder value, $Res Function(_TailoringOrder) _then) = __$TailoringOrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String customerName, String garment, DateTime dueDate, double totalAmount, double paidAmount, OrderStatus status, String note, DateTime createdAt
});




}
/// @nodoc
class __$TailoringOrderCopyWithImpl<$Res>
    implements _$TailoringOrderCopyWith<$Res> {
  __$TailoringOrderCopyWithImpl(this._self, this._then);

  final _TailoringOrder _self;
  final $Res Function(_TailoringOrder) _then;

/// Create a copy of TailoringOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? customerName = null,Object? garment = null,Object? dueDate = null,Object? totalAmount = null,Object? paidAmount = null,Object? status = null,Object? note = null,Object? createdAt = null,}) {
  return _then(_TailoringOrder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,customerName: null == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String,garment: null == garment ? _self.garment : garment // ignore: cast_nullable_to_non_nullable
as String,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
