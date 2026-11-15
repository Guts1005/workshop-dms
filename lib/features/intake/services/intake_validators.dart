/// Validation rules for Workshop Intake (Page 1)
/// Strictly verifies Indian RTO plates, Bharat (BH) series, Indian mobile numbers,
/// VIN formatting, and odometer delta logic.
class IntakeValidators {
  IntakeValidators._();

  /// Normalizes registration plate string by removing spaces, hyphens, and converting to uppercase.
  static String normalizeRegistration(String input) {
    return input.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
  }

  /// Normalizes Indian mobile number by removing +91, 0 prefix, spaces, and hyphens.
  static String normalizeMobile(String input) {
    String cleaned = input.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.startsWith('+91')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }

  /// Validates Indian vehicle registration number.
  /// Accepts:
  /// - Standard: 2 letters (State) + 1-2 digits (RTO) + 0-3 letters (Series) + 4 digits (e.g., RJ27CA1024, DL1C1234, MH021234)
  /// - Bharat (BH) Series: 2 digits (Year) + BH + 4 digits + 1-2 letters (e.g., 22BH1234AA)
  static String? validateRegistration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Registration number is required';
    }

    final normalized = normalizeRegistration(value);

    // Standard Indian RTO format
    final standardRegex = RegExp(r'^[A-Z]{2}[0-9]{1,2}[A-Z]{0,3}[0-9]{4}$');
    // Bharat (BH) series format: 2-digit year + 'BH' + 4 digits + 1-2 letters
    final bhSeriesRegex = RegExp(r'^[0-9]{2}BH[0-9]{4}[A-Z]{1,2}$');

    if (!standardRegex.hasMatch(normalized) && !bhSeriesRegex.hasMatch(normalized)) {
      return 'Invalid Indian registration plate format (e.g. RJ27CA1024 or 22BH1234AA)';
    }

    return null;
  }

  /// Validates Indian 10-digit mobile number.
  /// Allowed prefixes: +91, 91, 0, or plain 10 digits starting with 6, 7, 8, or 9.
  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }

    final normalized = normalizeMobile(value);

    if (normalized.length != 10) {
      return 'Mobile number must be exactly 10 digits';
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(normalized)) {
      return 'Enter a valid Indian mobile number starting with 6, 7, 8, or 9';
    }

    return null;
  }

  /// Validates customer name.
  static String? validateCustomerName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Customer name is required';
    }
    if (value.trim().length < 2) {
      return 'Customer name must be at least 2 characters';
    }
    return null;
  }

  /// Validates odometer reading.
  /// Checks for non-negative integer and prevents silent odometer rollback.
  static String? validateOdometer(String? value, {int? previousKm}) {
    if (value == null || value.trim().isEmpty) {
      return 'Odometer reading is required';
    }

    final km = int.tryParse(value.trim());
    if (km == null) {
      return 'Odometer must be a valid whole number';
    }

    if (km < 0) {
      return 'Odometer reading cannot be negative';
    }

    if (km > 1500000) {
      return 'Odometer reading exceeds reasonable maximum (1,500,000 km)';
    }

    if (previousKm != null && km < previousKm) {
      return 'Odometer reading ($km km) is less than previous recorded service ($previousKm km). Possible rollback!';
    }

    return null;
  }

  /// Validates VIN (Vehicle Identification Number).
  /// Optional, but if present must be exactly 17 alphanumeric characters, excluding I, O, Q.
  static String? validateVin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }

    final trimmed = value.trim().toUpperCase();
    if (trimmed.length != 17) {
      return 'VIN must be exactly 17 characters';
    }

    // Letters I, O, Q are not permitted in ISO 3779 VINs to avoid confusion with 1 and 0
    if (RegExp(r'[IOQ]').hasMatch(trimmed)) {
      return 'VIN cannot contain letters I, O, or Q (ISO 3779 standard)';
    }

    if (!RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(trimmed)) {
      return 'VIN contains invalid characters';
    }

    return null;
  }

  /// Validates expected delivery timestamp.
  static String? validateExpectedDelivery(DateTime? delivery) {
    if (delivery == null) {
      return 'Expected delivery date and time is required';
    }
    if (delivery.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
      return 'Expected delivery time cannot be in the past';
    }
    return null;
  }
}
