// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_modern_treasury_suppression.dart';

const _tracerName = 'dartastic_otel_libs_modern_treasury';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class ModernTreasuryResult {
  const ModernTreasuryResult({
    this.paymentOrderId,
    this.type,
    this.direction,
    this.status,
    this.amountMinor,
    this.currency,
    this.originatingAccountId,
    this.receivingAccountId,
    this.statusCode,
  });

  /// `payment_order.id`.
  final String? paymentOrderId;

  /// `ach`, `wire`, `rtp`, `fednow`, `book`, `check`, `eft`, `sepa`,
  /// `bacs`, `interac`, `signet`, `provxchange`. Big spread in
  /// settlement SLA + cost.
  final String? type;

  /// `credit` (outbound to recipient) or `debit` (pull from sender).
  /// Different liability + clearance windows.
  final String? direction;

  /// `approved` / `pending` / `processing` / `sent` / `completed` /
  /// `returned` / `failed` / `cancelled` / `needs_approval`.
  final String? status;
  final int? amountMinor;
  final String? currency;

  /// Modern Treasury account ids — internal customer-level routing.
  final String? originatingAccountId;
  final String? receivingAccountId;
  final int? statusCode;
}

class ModernTreasuryCallResult<T> {
  const ModernTreasuryCallResult({required this.value, this.result});
  final T value;
  final ModernTreasuryResult? result;
}

/// Wraps a Modern Treasury API call in a CLIENT span. [resource] is
/// `payment_orders`, `ledger_accounts`, `ledger_transactions`,
/// `incoming_payment_details`, `expected_payments`, etc. [operation]
/// is `create` / `update` / `approve` / `cancel` / `list` / `get`.
Future<T> tracedModernTreasury<T>({
  required String resource,
  required String operation,
  required Future<ModernTreasuryCallResult<T>> Function() invoke,
}) async {
  if (modernTreasuryInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'modern_treasury',
    'rpc.method': '$resource.$operation',
    'modern_treasury.resource': resource,
  };

  final span = _tracer().startSpan(
    'modern_treasury $resource.$operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.paymentOrderId != null) {
        extras.add(OTel.attributeString(
          'modern_treasury.payment_order.id',
          r.result!.paymentOrderId!,
        ));
      }
      if (r.result!.type != null) {
        extras.add(OTel.attributeString(
          'modern_treasury.type',
          r.result!.type!,
        ));
      }
      if (r.result!.direction != null) {
        extras.add(OTel.attributeString(
          'modern_treasury.direction',
          r.result!.direction!,
        ));
      }
      if (r.result!.status != null) {
        extras.add(OTel.attributeString(
          'modern_treasury.status',
          r.result!.status!,
        ));
        if (r.result!.status == 'returned' ||
            r.result!.status == 'failed' ||
            r.result!.status == 'cancelled') {
          span.setStatus(
            SpanStatusCode.Error,
            'Modern Treasury status ${r.result!.status}',
          );
        }
      }
      if (r.result!.amountMinor != null) {
        extras.add(OTel.attributeInt(
          'modern_treasury.amount.minor',
          r.result!.amountMinor!,
        ));
      }
      if (r.result!.currency != null) {
        extras.add(OTel.attributeString(
          'modern_treasury.currency',
          r.result!.currency!,
        ));
      }
      if (r.result!.originatingAccountId != null) {
        extras.add(OTel.attributeString(
          'modern_treasury.originating_account.id',
          r.result!.originatingAccountId!,
        ));
      }
      if (r.result!.receivingAccountId != null) {
        extras.add(OTel.attributeString(
          'modern_treasury.receiving_account.id',
          r.result!.receivingAccountId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Modern Treasury HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
