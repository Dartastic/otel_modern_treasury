// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_modern_treasury/otel_modern_treasury.dart';

/// Traces Modern Treasury calls with OpenTelemetry.
///
/// `otel_modern_treasury` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Modern Treasury call in
/// [tracedModernTreasury]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'modern-treasury-example');

  // Wraps a Modern Treasury API call in a CLIENT span.
  final modernTreasuryId = await tracedModernTreasury<String>(
    resource: 'payment_orders',
    operation: 'create',
    invoke: () async {
      // Make the Modern Treasury call here, then report what it returned.
      const id = 'modern_treasury_8f3a2c';
      return const ModernTreasuryCallResult(
          value: id,
          result: ModernTreasuryResult(
              paymentOrderId: 'payment_order.id',
              type: 'ach',
              direction: 'credit',
              status: 'approved',
              amountMinor: 1999,
              currency: 'usd',
              originatingAccountId: 'originatingaccount_8f3a2c',
              receivingAccountId: 'receivingaccount_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedModernTreasury create returned $modernTreasuryId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutModernTreasuryInstrumentationAsync.
  await runWithoutModernTreasuryInstrumentationAsync(
    () => tracedModernTreasury<String>(
      resource: 'payment_orders',
      operation: 'create',
      invoke: () async {
        const id = 'modern_treasury_8f3a2c';
        return const ModernTreasuryCallResult(
            value: id,
            result: ModernTreasuryResult(
                paymentOrderId: 'payment_order.id',
                type: 'ach',
                direction: 'credit',
                status: 'approved',
                amountMinor: 1999,
                currency: 'usd',
                originatingAccountId: 'originatingaccount_8f3a2c',
                receivingAccountId: 'receivingaccount_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
