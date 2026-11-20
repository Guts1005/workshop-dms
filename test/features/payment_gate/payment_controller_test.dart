import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/payment_gate/payment_controller.dart';
import 'package:workshop_dms/features/payment_gate/payment_models.dart';
import 'package:workshop_dms/features/payment_gate/payment_repository.dart';

void main() {
  group('PaymentController', () {
    test(
      'rejects invalid and over-balance payments before repository writes',
      () async {
        final repository = _FakePaymentRepository();
        final controller = PaymentController(repository: repository);
        await controller.load('job-1');

        expect(
          await controller.record(
            amountText: 'abc',
            method: PaymentMethod.upi,
            reference: '',
          ),
          isFalse,
        );
        expect(
          await controller.record(
            amountText: '100.01',
            method: PaymentMethod.upi,
            reference: '',
          ),
          isFalse,
        );
        expect(repository.recordCalls, 0);
      },
    );

    test('records payments in integer paise', () async {
      final repository = _FakePaymentRepository();
      final controller = PaymentController(repository: repository);
      await controller.load('job-1');

      expect(
        await controller.record(
          amountText: '42.75',
          method: PaymentMethod.cash,
          reference: 'receipt-7',
        ),
        isTrue,
      );
      expect(repository.lastAmountPaise, 4275);
      expect(repository.lastMethod, PaymentMethod.cash);
      expect(controller.state.workspace!.balancePaise, 5725);
    });

    test('reuses a request id after an uncertain payment response', () async {
      final repository = _FakePaymentRepository()..failAfterNextCommit = true;
      final controller = PaymentController(repository: repository);
      await controller.load('job-1');

      expect(
        await controller.record(
          amountText: '42.75',
          method: PaymentMethod.cash,
          reference: 'receipt-7',
        ),
        isFalse,
      );
      final firstRequestId = repository.lastRequestId;

      expect(
        await controller.record(
          amountText: '42.75',
          method: PaymentMethod.cash,
          reference: 'receipt-7',
        ),
        isTrue,
      );
      expect(repository.lastRequestId, firstRequestId);
      expect(repository.paidPaise, 4275);
    });

    test(
      'uses a new request id when retrying changed payment details',
      () async {
        final repository = _FakePaymentRepository()..failAfterNextCommit = true;
        final controller = PaymentController(repository: repository);
        await controller.load('job-1');

        expect(
          await controller.record(
            amountText: '42.75',
            method: PaymentMethod.cash,
            reference: 'receipt-7',
          ),
          isFalse,
        );
        final firstRequestId = repository.lastRequestId;
        expect(
          await controller.record(
            amountText: '57.25',
            method: PaymentMethod.cash,
            reference: 'receipt-8',
          ),
          isTrue,
        );

        expect(repository.lastRequestId, isNot(firstRequestId));
        expect(repository.paidPaise, 10000);
      },
    );

    test('retains payment request id when post-commit refresh fails', () async {
      final repository = _FakePaymentRepository();
      final controller = PaymentController(repository: repository);
      await controller.load('job-1');
      repository.failNextLoad = true;

      expect(
        await controller.record(
          amountText: '42.75',
          method: PaymentMethod.cash,
          reference: 'receipt-7',
        ),
        isFalse,
      );
      final firstRequestId = repository.lastRequestId;
      expect(
        await controller.record(
          amountText: '42.75',
          method: PaymentMethod.cash,
          reference: 'receipt-7',
        ),
        isTrue,
      );

      expect(repository.lastRequestId, firstRequestId);
      expect(repository.paidPaise, 4275);
    });

    test('recovers when delivery commits but response is lost', () async {
      final repository = _FakePaymentRepository()..failAfterNextDelivery = true;
      final controller = PaymentController(repository: repository);
      await controller.load('job-1');

      expect(await controller.deliver('approved credit'), isTrue);
      expect(controller.state.workspace?.deliveredAt, isNotNull);
      expect(controller.state.errorMessage, isNull);
    });

    test(
      'only owner can hand over with an outstanding balance and reason',
      () async {
        final repository = _FakePaymentRepository(isOwner: false);
        final controller = PaymentController(repository: repository);
        await controller.load('job-1');

        expect(await controller.deliver('credit approved'), isFalse);
        expect(repository.deliveryCalls, 0);
        expect(
          controller.state.errorMessage,
          contains('balance must be cleared'),
        );
      },
    );
  });

  test('formats rupees consistently', () {
    expect(formatPaymentRupees(7250), '₹72.50');
    expect(formatPaymentRupees(0), '₹0.00');
  });
}

class _FakePaymentRepository implements PaymentRepository {
  _FakePaymentRepository({this.isOwner = true});
  final bool isOwner;
  int recordCalls = 0;
  int deliveryCalls = 0;
  int? lastAmountPaise;
  PaymentMethod? lastMethod;
  String? lastRequestId;
  int paidPaise = 0;
  bool failAfterNextCommit = false;
  bool failAfterNextDelivery = false;
  bool failNextLoad = false;
  DateTime? deliveredAt;
  final _requests = <String>{};

  @override
  Future<PaymentWorkspace> load(String jobCardId) async {
    if (failNextLoad) {
      failNextLoad = false;
      throw StateError('Refresh failed');
    }
    return PaymentWorkspace(
      jobCardId: jobCardId,
      registrationNumber: 'KA01AB1234',
      customerName: 'Sample Customer',
      invoiceNumber: 'INV/2026-27/00001',
      invoiceTotalPaise: 10000,
      payments: [
        if (paidPaise > 0)
          PaymentEntry(
            amountPaise: paidPaise,
            method: lastMethod ?? PaymentMethod.cash,
            reference: '',
            receivedBy: 'advisor',
            createdAt: DateTime.utc(2026),
          ),
      ],
      isOwner: isOwner,
      deliveredAt: deliveredAt,
      creditOverrideReason: null,
    );
  }

  @override
  Future<void> record({
    required String jobCardId,
    required int amountPaise,
    required PaymentMethod method,
    required String reference,
    required String requestId,
  }) async {
    recordCalls++;
    lastAmountPaise = amountPaise;
    lastMethod = method;
    lastRequestId = requestId;
    if (_requests.add(requestId)) paidPaise += amountPaise;
    if (failAfterNextCommit) {
      failAfterNextCommit = false;
      throw StateError('Response lost after database commit');
    }
  }

  @override
  Future<void> deliver({
    required String jobCardId,
    required String creditOverrideReason,
  }) async {
    deliveryCalls++;
    deliveredAt = DateTime.utc(2026, 11, 21);
    if (failAfterNextDelivery) {
      failAfterNextDelivery = false;
      throw StateError('Response lost after database commit');
    }
  }
}
