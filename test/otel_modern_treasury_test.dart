// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_modern_treasury/otel_modern_treasury.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_modern_treasury-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('Wire credit payment_order create', () async {
    await tracedModernTreasury<String>(
      resource: 'payment_orders',
      operation: 'create',
      invoke: () async => const ModernTreasuryCallResult(
        value: 'ok',
        result: ModernTreasuryResult(
          paymentOrderId: 'po_1',
          type: 'wire',
          direction: 'credit',
          status: 'approved',
          amountMinor: 500000,
          currency: 'USD',
          originatingAccountId: 'acc-1',
          receivingAccountId: 'acc-2',
          statusCode: 201,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName(
      'modern_treasury payment_orders.create',
    )!);
    expect(a['modern_treasury.resource'], 'payment_orders');
    expect(a['modern_treasury.type'], 'wire');
    expect(a['modern_treasury.direction'], 'credit');
    expect(a['modern_treasury.status'], 'approved');
  });

  test('returned status maps to span error', () async {
    await tracedModernTreasury<String>(
      resource: 'payment_orders',
      operation: 'get',
      invoke: () async => const ModernTreasuryCallResult(
        value: 'ok',
        result: ModernTreasuryResult(status: 'returned'),
      ),
    );
    expect(
      spans.findSpanByName('modern_treasury payment_orders.get')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutModernTreasuryInstrumentationAsync(() async {
      await tracedModernTreasury<String>(
        resource: 'ledger_accounts',
        operation: 'list',
        invoke: () async => const ModernTreasuryCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('modern_treasury '), isEmpty);
  });
}
