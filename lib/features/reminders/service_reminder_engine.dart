class ServiceReminderResult {
  final String customerName;
  final String mobileNumber;
  final String vehicleModel;
  final String registrationNumber;
  final DateTime lastServiceDate;
  final int lastServiceOdometerKm;
  final DateTime? projectedKmDueDate;
  final DateTime calendarDueDate;
  final int? projectedCurrentKm;
  final bool hasMileageProjection;
  final bool isOverdue;
  final bool isDueSoon;
  final String triggerReason;

  const ServiceReminderResult({
    required this.customerName,
    required this.mobileNumber,
    required this.vehicleModel,
    required this.registrationNumber,
    required this.lastServiceDate,
    required this.lastServiceOdometerKm,
    required this.projectedKmDueDate,
    required this.calendarDueDate,
    required this.projectedCurrentKm,
    required this.hasMileageProjection,
    required this.isOverdue,
    required this.isDueSoon,
    required this.triggerReason,
  });

  /// Builds a customer message containing only recorded facts and estimates.
  String buildWhatsAppUrl({
    required String workshopName,
    required String workshopPhone,
    required String workshopAddress,
  }) {
    final cleanPhone = mobileNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final phoneWithCountry = cleanPhone.startsWith('91')
        ? cleanPhone
        : '91$cleanPhone';

    final text = StringBuffer()
      ..writeln('Service reminder from $workshopName')
      ..writeln()
      ..writeln('Hello $customerName,')
      ..writeln(
        'Our records show that your $vehicleModel ($registrationNumber) may be due for service.',
      )
      ..writeln('Last recorded service: ${_formatDate(lastServiceDate)}')
      ..writeln('Odometer at that visit: $lastServiceOdometerKm km')
      ..writeln('Reminder basis: $triggerReason');

    if (hasMileageProjection && projectedCurrentKm != null) {
      text.writeln('Estimated current odometer: about $projectedCurrentKm km');
    }

    text
      ..writeln()
      ..writeln(
        'Please contact us to confirm your vehicle\'s needs or arrange a visit.',
      )
      ..writeln('$workshopPhone - $workshopAddress');

    final encodedText = Uri.encodeComponent(text.toString());
    return 'https://wa.me/$phoneWithCountry?text=$encodedText';
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class ServiceReminderEngine {
  /// Uses a calendar interval and only forecasts mileage from two valid readings.
  static ServiceReminderResult evaluate({
    required String customerName,
    required String mobileNumber,
    required String vehicleModel,
    required String registrationNumber,
    required DateTime lastServiceDate,
    required int lastServiceOdometerKm,
    DateTime? previousServiceDate,
    int? previousServiceOdometerKm,
    int intervalKm = 10000,
    int intervalDays = 180,
    DateTime? now,
  }) {
    if (intervalKm <= 0 || intervalDays <= 0) {
      throw ArgumentError('Service intervals must be greater than zero.');
    }
    if (lastServiceOdometerKm < 0) {
      throw ArgumentError('Odometer readings cannot be negative.');
    }

    final currentNow = now ?? DateTime.now();
    double? dailyAverageKm;
    if (previousServiceDate != null && previousServiceOdometerKm != null) {
      final daysBetween = lastServiceDate
          .difference(previousServiceDate)
          .inDays;
      final kmBetween = lastServiceOdometerKm - previousServiceOdometerKm;
      if (daysBetween > 0 && kmBetween > 0 && previousServiceOdometerKm >= 0) {
        dailyAverageKm = kmBetween / daysBetween;
      }
    }

    final daysSinceLastService = currentNow
        .difference(lastServiceDate)
        .inDays
        .clamp(0, 100000);
    final projectedCurrentKm = dailyAverageKm == null
        ? null
        : lastServiceOdometerKm +
              (dailyAverageKm * daysSinceLastService).round();
    final projectedKmDueDate = dailyAverageKm == null
        ? null
        : lastServiceDate.add(
            Duration(days: (intervalKm / dailyAverageKm).ceil()),
          );
    final calendarDueDate = lastServiceDate.add(Duration(days: intervalDays));
    final isKmFirst =
        projectedKmDueDate != null &&
        projectedKmDueDate.isBefore(calendarDueDate);
    final earliestDueDate = isKmFirst ? projectedKmDueDate : calendarDueDate;
    final isOverdue = currentNow.isAfter(earliestDueDate);
    final isDueSoon =
        !isOverdue && earliestDueDate.difference(currentNow).inDays <= 14;

    return ServiceReminderResult(
      customerName: customerName,
      mobileNumber: mobileNumber,
      vehicleModel: vehicleModel,
      registrationNumber: registrationNumber,
      lastServiceDate: lastServiceDate,
      lastServiceOdometerKm: lastServiceOdometerKm,
      projectedKmDueDate: projectedKmDueDate,
      calendarDueDate: calendarDueDate,
      projectedCurrentKm: projectedCurrentKm,
      hasMileageProjection: dailyAverageKm != null,
      isOverdue: isOverdue,
      isDueSoon: isDueSoon,
      triggerReason: isKmFirst
          ? '$intervalKm km mileage interval (based on recorded readings)'
          : '$intervalDays day calendar interval',
    );
  }
}
