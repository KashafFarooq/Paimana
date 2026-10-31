import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveRecordStore {
  static const customersBoxName = 'customers_encrypted_v1';
  static const ordersBoxName = 'orders_encrypted_v1';
  static const paymentsBoxName = 'payments_encrypted_v1';
  static const offlineQueueBoxName = 'offline_queue_encrypted_v1';
  static const _encryptionKeyStorageKey = 'hive_encryption_key';

  static Future<void> initialize({List<int>? encryptionKey}) async {
    final key = encryptionKey ?? await _readOrCreateEncryptionKey();
    if (key.length != 32) {
      throw const FormatException('Hive encryption keys must contain 32 bytes.');
    }
    final cipher = HiveAesCipher(key);
    final customers = await Hive.openBox<String>(
      customersBoxName,
      encryptionCipher: cipher,
    );
    final orders = await Hive.openBox<String>(
      ordersBoxName,
      encryptionCipher: cipher,
    );
    final payments = await Hive.openBox<String>(
      paymentsBoxName,
      encryptionCipher: cipher,
    );
    final queue = await Hive.openBox<String>(
      offlineQueueBoxName,
      encryptionCipher: cipher,
    );
    await _migrateLegacyBox('customers', customers);
    await _migrateLegacyBox('orders', orders);
    await _migrateLegacyBox('payments', payments);
    await _migrateLegacyBox('offline_queue', queue);
  }

  static Future<void> _migrateLegacyBox(
    String legacyName,
    Box<String> encryptedBox,
  ) async {
    if (!await Hive.boxExists(legacyName)) return;

    final legacyBox = await Hive.openBox<String>(legacyName);
    for (final key in legacyBox.keys.whereType<String>()) {
      if (encryptedBox.containsKey(key)) continue;
      final value = legacyBox.get(key);
      if (value != null) await encryptedBox.put(key, value);
    }
    await encryptedBox.flush();
    await legacyBox.close();
    await Hive.deleteBoxFromDisk(legacyName);
  }

  static Future<List<int>> _readOrCreateEncryptionKey() async {
    const storage = FlutterSecureStorage();
    final savedKey = await storage.read(key: _encryptionKeyStorageKey);
    if (savedKey != null) {
      try {
        return base64Url.decode(savedKey);
      } on FormatException {
        throw const FormatException(
          'The saved Hive encryption key is invalid.',
        );
      }
    }

    final random = Random.secure();
    final key = List<int>.generate(32, (_) => random.nextInt(256));
    await storage.write(
      key: _encryptionKeyStorageKey,
      value: base64UrlEncode(key),
    );
    return key;
  }

  Future<List<T>> readAll<T>(
    String boxName,
    T Function(Map<String, dynamic>) decode, {
    required String scope,
  }
  ) async {
    final box = Hive.box<String>(boxName);
    final prefix = '$scope::';
    final records = <T>[];
    for (final key in box.keys.whereType<String>()) {
      if (!key.startsWith(prefix)) continue;
      final value = box.get(key);
      if (value == null) continue;
      final json = jsonDecode(value);
      if (json is! Map) {
        throw const FormatException('Stored record is not a JSON object.');
      }
      records.add(decode(Map<String, dynamic>.from(json)));
    }
    return records;
  }

  Future<void> write<T>(
    String boxName,
    String key,
    T value,
    Map<String, dynamic> Function(T) encode, {
    required String scope,
  }
  ) async {
    await Hive.box<String>(boxName).put(
      '$scope::$key',
      jsonEncode(encode(value)),
    );
  }

  Future<void> delete(
    String boxName,
    String key, {
    required String scope,
  }) async {
    await Hive.box<String>(boxName).delete('$scope::$key');
  }

  Future<void> enqueue({
    required String entity,
    required String id,
    required String operation,
    required Map<String, dynamic> payload,
    required String scope,
  }) async {
    final entry = <String, dynamic>{
      'scope': scope,
      'entity': entity,
      'id': id,
      'operation': operation,
      'payload': payload,
      'queuedAt': DateTime.now().toUtc().toIso8601String(),
    };
    await Hive.box<String>(offlineQueueBoxName).put(
      '$scope::$entity:$id',
      jsonEncode(entry),
    );
  }

  Future<List<Map<String, dynamic>>> readQueue(
    String entity, {
    required String scope,
  }) async {
    final box = Hive.box<String>(offlineQueueBoxName);
    final entries = <Map<String, dynamic>>[];
    for (final value in box.values) {
      final decoded = jsonDecode(value);
      if (decoded is! Map) {
        throw const FormatException('Stored sync operation is not a JSON object.');
      }
      final entry = Map<String, dynamic>.from(decoded);
      if (entry['entity'] == entity && entry['scope'] == scope) {
        entries.add(entry);
      }
    }
    entries.sort((first, second) {
      final firstDate = DateTime.parse(first['queuedAt'] as String);
      final secondDate = DateTime.parse(second['queuedAt'] as String);
      return firstDate.compareTo(secondDate);
    });
    return entries;
  }

  Future<void> removeFromQueue({
    required String entity,
    required String id,
    required String scope,
  }) async {
    await Hive.box<String>(offlineQueueBoxName).delete('$scope::$entity:$id');
  }
}
