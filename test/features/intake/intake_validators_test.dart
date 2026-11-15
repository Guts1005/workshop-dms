import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/intake/services/intake_validators.dart';

void main() {
  group('IntakeValidators Tests', () {
    group('Registration plate validation', () {
      test('Accepts valid standard Indian RTO formats', () {
        expect(IntakeValidators.validateRegistration('RJ27CA1024'), isNull);
        expect(IntakeValidators.validateRegistration('rj-27-ca-1024'), isNull);
        expect(IntakeValidators.validateRegistration('MH 02 BG 4567'), isNull);
        expect(IntakeValidators.validateRegistration('DL 1C AA 1111'), isNull);
        expect(IntakeValidators.validateRegistration('KA03HA9999'), isNull);
        expect(IntakeValidators.validateRegistration('HR26DK8337'), isNull);
      });

      test('Accepts Bharat (BH) series format', () {
        expect(IntakeValidators.validateRegistration('22BH1234AA'), isNull);
        expect(IntakeValidators.validateRegistration('23 BH 5678 B'), isNull);
      });

      test('Rejects invalid registration plate formats', () {
        expect(IntakeValidators.validateRegistration(''), isNotNull);
        expect(IntakeValidators.validateRegistration(null), isNotNull);
        expect(IntakeValidators.validateRegistration('INVALID123'), isNotNull);
        expect(IntakeValidators.validateRegistration('RJ27'), isNotNull);
        expect(IntakeValidators.validateRegistration('1234567890'), isNotNull);
      });

      test('Normalizes registration string correctly', () {
        expect(IntakeValidators.normalizeRegistration('rj-27 ca 1024'), 'RJ27CA1024');
      });
    });

    group('Mobile number validation', () {
      test('Accepts valid 10-digit Indian numbers with different prefixes', () {
        expect(IntakeValidators.validateMobile('9829012345'), isNull);
        expect(IntakeValidators.validateMobile('+91 9829012345'), isNull);
        expect(IntakeValidators.validateMobile('+91-98290-12345'), isNull);
        expect(IntakeValidators.validateMobile('09829012345'), isNull);
        expect(IntakeValidators.validateMobile('7890123456'), isNull);
        expect(IntakeValidators.validateMobile('6378123456'), isNull);
      });

      test('Rejects invalid mobile numbers', () {
        expect(IntakeValidators.validateMobile(null), isNotNull);
        expect(IntakeValidators.validateMobile(''), isNotNull);
        expect(IntakeValidators.validateMobile('1234567890'), isNotNull); // Doesn't start with 6-9
        expect(IntakeValidators.validateMobile('98290'), isNotNull); // Too short
        expect(IntakeValidators.validateMobile('982901234567'), isNotNull); // Too long
        expect(IntakeValidators.validateMobile('abcdefghij'), isNotNull);
      });

      test('Normalizes mobile numbers correctly', () {
        expect(IntakeValidators.normalizeMobile('+91 98290 12345'), '9829012345');
        expect(IntakeValidators.normalizeMobile('09829012345'), '9829012345');
      });
    });

    group('Customer name validation', () {
      test('Accepts valid names', () {
        expect(IntakeValidators.validateCustomerName('Rajesh Sharma'), isNull);
        expect(IntakeValidators.validateCustomerName('Om'), isNull);
      });

      test('Rejects empty or single char names', () {
        expect(IntakeValidators.validateCustomerName(null), isNotNull);
        expect(IntakeValidators.validateCustomerName(''), isNotNull);
        expect(IntakeValidators.validateCustomerName('A'), isNotNull);
      });
    });

    group('Odometer validation', () {
      test('Accepts valid readings', () {
        expect(IntakeValidators.validateOdometer('45000'), isNull);
        expect(IntakeValidators.validateOdometer('0'), isNull);
        expect(IntakeValidators.validateOdometer('124500'), isNull);
      });

      test('Rejects invalid odometer readings', () {
        expect(IntakeValidators.validateOdometer(null), isNotNull);
        expect(IntakeValidators.validateOdometer(''), isNotNull);
        expect(IntakeValidators.validateOdometer('-500'), isNotNull);
        expect(IntakeValidators.validateOdometer('abc'), isNotNull);
        expect(IntakeValidators.validateOdometer('2000000'), isNotNull); // Exceeds max
      });

      test('Flags rollback when reading is lower than previous recorded service', () {
        expect(IntakeValidators.validateOdometer('25000', previousKm: 30000), contains('rollback'));
        expect(IntakeValidators.validateOdometer('32000', previousKm: 30000), isNull);
      });
    });

    group('VIN validation', () {
      test('Accepts null or empty (optional)', () {
        expect(IntakeValidators.validateVin(null), isNull);
        expect(IntakeValidators.validateVin(''), isNull);
      });

      test('Accepts valid 17-character VIN', () {
        expect(IntakeValidators.validateVin('MA3EWA12S00123456'), isNull);
      });

      test('Rejects VIN with forbidden characters (I, O, Q) or wrong length', () {
        expect(IntakeValidators.validateVin('MA3EWA12S0012345'), isNotNull); // 16 chars
        expect(IntakeValidators.validateVin('MA3EWA12S001234567'), isNotNull); // 18 chars
        expect(IntakeValidators.validateVin('MA3EWA12I00123456'), contains('ISO 3779')); // contains 'I'
        expect(IntakeValidators.validateVin('MA3EWA12O00123456'), contains('ISO 3779')); // contains 'O'
        expect(IntakeValidators.validateVin('MA3EWA12Q00123456'), contains('ISO 3779')); // contains 'Q'
      });
    });

    group('Expected delivery validation', () {
      test('Accepts future delivery date', () {
        final future = DateTime.now().add(const Duration(days: 1));
        expect(IntakeValidators.validateExpectedDelivery(future), isNull);
      });

      test('Rejects past delivery date', () {
        final past = DateTime.now().subtract(const Duration(hours: 2));
        expect(IntakeValidators.validateExpectedDelivery(past), isNotNull);
        expect(IntakeValidators.validateExpectedDelivery(null), isNotNull);
      });
    });
  });
}
