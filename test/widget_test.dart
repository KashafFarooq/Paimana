import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paimana/core/router/app_router.dart';
import 'package:paimana/core/storage/hive_record_store.dart';
import 'package:paimana/main.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    await Hive.close();
    hiveDirectory = await Directory.systemTemp.createTemp('paimana-test-');
    Hive.init(hiveDirectory.path);
    await HiveRecordStore.initialize(
      encryptionKey: List<int>.generate(32, (index) => index),
    );
  });
  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('migrates existing local records into encrypted boxes', () async {
    await Hive.close();
    final legacyCustomers = await Hive.openBox<String>('customers');
    await legacyCustomers.put('local::customer-1', '{"name":"Ayesha"}');
    await legacyCustomers.close();

    await HiveRecordStore.initialize(
      encryptionKey: List<int>.generate(32, (index) => index),
    );

    expect(await Hive.boxExists('customers'), isFalse);
    expect(
      Hive.box<String>(HiveRecordStore.customersBoxName)
          .get('local::customer-1'),
      '{"name":"Ayesha"}',
    );
  });

  testWidgets('dashboard opens with an honest empty state', (tester) async {
    appRouter.go('/login');
    await tester.pumpWidget(const ProviderScope(child: PaimanaApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue offline'));
    await tester.pumpAndSettle();

    expect(find.text('A little more time\nfor the craft.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Your order book is ready'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Your order book is ready'), findsOneWidget);
  });

  testWidgets('customer form validates and saves locally', (tester) async {
    appRouter.go('/login');
    await tester.pumpWidget(const ProviderScope(child: PaimanaApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue offline'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Customers').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add first customer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save customer'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a customer name'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Ayesha Khan');
    await tester.enterText(find.byType(TextFormField).at(1), '03001234567');
    await tester.tap(find.text('Save customer'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    final storedCustomers = Hive.box<String>(
      HiveRecordStore.customersBoxName,
    ).values;
    expect(storedCustomers, hasLength(1));
    expect(storedCustomers.single, contains('Ayesha Khan'));
    expect(storedCustomers.single, contains('03001234567'));
  });
}
