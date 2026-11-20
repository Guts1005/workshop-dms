class ServiceReminderResult {
  final String customerName;
  final String mobileNumber;
  final String vehicleModel;
  final String registrationNumber;
  final DateTime lastServiceDate;
  final int lastServiceOdometerKm;
  final DateTime projectedKmDueDate;
  final DateTime calendarDueDate;
  final int projectedCurrentKm;
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
    required this.isOverdue,
    required this.isDueSoon,
    required this.triggerReason,
  });

  /// Builds the direct WhatsApp click-to-chat URL
  String buildWhatsAppUrl({
    required String workshopName,
    required String workshopPhone,
    required String workshopAddress,
  }) {
    final cleanPhone = mobileNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final phoneWithCountry = cleanPhone.startsWith('91')
        ? cleanPhone
        : '91$cleanPhone';

    final text = StringBuffer();
    text.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    text.writeln('🔧 *$workshopName — SERVICE DUE ALERT*');
    text.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    text.writeln('Namaste *$customerName ji*,\n');
    text.writeln(
      'Your *$vehicleModel ($registrationNumber)* is now due for scheduled maintenance.\n',
    );
    text.writeln('📊 *Vehicle Snapshot:*');
    text.writeln(
      '• Last Serviced: ${_formatDate(lastServiceDate)} (@ $lastServiceOdometerKm KM)',
    );
    text.writeln('• Current Est. Odometer: ~$projectedCurrentKm KM');
    text.writeln('• Trigger: $triggerReason\n');
    text.writeln('🛠️ *Recommended for this Visit:*');
    text.writeln('✓ Engine Oil (5W-30 Synthetic) & Filter');
    text.writeln('✓ Brake Pad Inspection & Fluid Top-up');
    text.writeln('✓ Complete 360° Safety & Suspension Scan\n');
    text.writeln('📄 *View Your Car\'s Live Health Passport:*');
    text.writeln('https://workshop.app/passport/$registrationNumber\n');
    text.writeln(
      'To reserve your bay slot or arrange a doorstep pickup, simply reply to this message or call us at $workshopPhone.\n',
    );
    text.writeln('*Work Done Right, Priced Fair.*');
    text.writeln('📍 $workshopAddress');
    text.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

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
  /// Evaluates whether a customer is due or overdue based on Dual-Trigger (Time vs Projected Mileage)
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
    int intervalDays = 180, // 6 months
    DateTime? now,
  }) {
    final currentNow = now ?? DateTime.now();

    // 1. Calculate Daily Driving Average
    double dailyAverageKm =
        40.0; // Sane automotive default in India if no previous visit exists
    if (previousServiceDate != null && previousServiceOdometerKm != null) {
      final daysBetween = lastServiceDate
          .difference(previousServiceDate)
          .inDays;
      final kmBetween = lastServiceOdometerKm - previousServiceOdometerKm;
      if (daysBetween > 0 && kmBetween > 0) {
        dailyAverageKm = kmBetween / daysBetween;
      }
    }

    // 2. Project Current KM today
    final daysSinceLastService = currentNow.difference(lastServiceDate).inDays;
    final projectedCurrentKm =
        lastServiceOdometerKm + (dailyAverageKm * daysSinceLastService).round();

    // 3. Target dates
    final targetKm = lastServiceOdometerKm + intervalKm;
    final daysToTargetKm = dailyAverageKm > 0
        ? ((targetKm - lastServiceOdometerKm) / dailyAverageKm).round()
        : intervalDays;
    final projectedKmDueDate = lastServiceDate.add(
      Duration(days: daysToTargetKm),
    );
    final calendarDueDate = lastServiceDate.add(Duration(days: intervalDays));

    // Whichever trigger happens first
    final earliestDueDate = projectedKmDueDate.isBefore(calendarDueDate)
        ? projectedKmDueDate
        : calendarDueDate;
    final isKmFirst = projectedKmDueDate.isBefore(calendarDueDate);

    final daysRemaining = earliestDueDate.difference(currentNow).inDays;
    final isOverdue = daysRemaining < 0;
    final isDueSoon = daysRemaining >= 0 && daysRemaining <= 14;

    final triggerReason = isKmFirst
        ? '$intervalKm KM Interval (Projected daily avg: ${dailyAverageKm.toStringAsFixed(1)} KM/day)'
        : '$intervalDays Days Calendar Interval';

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
      isOverdue: isOverdue,
      isDueSoon: isDueSoon,
      triggerReason: triggerReason,
    );
  }
}
