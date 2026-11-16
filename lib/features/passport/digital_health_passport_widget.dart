import 'package:flutter/material.dart';
import '../../ui_kit/tokens/app_tokens.dart';
import '../../ui_kit/widgets/sharp_card.dart';
import '../../ui_kit/widgets/status_chip.dart';
import '../vehicle/vehicle_silhouettes.dart';

class ServiceHistoryEntry {
  final String orderId;
  final String serviceType;
  final String workshopName;
  final DateTime serviceDate;
  final int odometerKm;
  final int? previousOdometerKm;
  final int? daysSincePrevious;
  final int totalAmountPaise;
  final String status;
  final String feedbackRating;
  final List<String> partsReplaced;
  final List<String> labourJobs;
  final Map<String, String> wearMetrics;

  const ServiceHistoryEntry({
    required this.orderId,
    required this.serviceType,
    required this.workshopName,
    required this.serviceDate,
    required this.odometerKm,
    this.previousOdometerKm,
    this.daysSincePrevious,
    required this.totalAmountPaise,
    this.status = 'Completed',
    this.feedbackRating = 'Exceptional',
    this.partsReplaced = const [],
    this.labourJobs = const [],
    this.wearMetrics = const {},
  });
}

class DigitalHealthPassportWidget extends StatelessWidget {
  final String vehicleModel;
  final String registrationNumber;
  final VehicleBodyType bodyType;
  final List<ServiceHistoryEntry> serviceHistory;
  final VoidCallback? onDownloadPdf;

  const DigitalHealthPassportWidget({
    super.key,
    required this.vehicleModel,
    required this.registrationNumber,
    required this.bodyType,
    required this.serviceHistory,
    this.onDownloadPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTokens.base,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Passport Hero Header ---
            SharpCard(
              backgroundColor: AppTokens.surface,
              child: Row(
                children: [
                  // Vector Silhouette
                  VehicleSilhouetteWidget(
                    bodyType: bodyType,
                    width: 140.0,
                    height: 60.0,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              vehicleModel.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.w900,
                                color: AppTokens.textPrimary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const Spacer(),
                            const StatusChip(
                              label: 'HEALTHY PASSPORT',
                              icon: Icons.verified_user_outlined,
                              type: StatusType.ok,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4.0),
                        // Number plate chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: AppTokens.raised,
                            border: Border.all(color: AppTokens.borderSolid, width: 1.0),
                          ),
                          child: Text(
                            registrationNumber.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              fontSize: 13.0,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // --- History Section Header ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              color: AppTokens.inverse,
              child: const Row(
                children: [
                  Icon(Icons.history_edu, color: AppTokens.textOnDark, size: 18.0),
                  SizedBox(width: 8.0),
                  Text(
                    'VERIFIED SERVICE HISTORY & HEALTH LOG',
                    style: TextStyle(
                      color: AppTokens.textOnDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.0,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),

            // --- History Cards (Adapted from MG App Screenshot with Dense Industrial Polish) ---
            ...serviceHistory.map((entry) => _buildServiceHistoryCard(entry)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceHistoryCard(ServiceHistoryEntry entry) {
    final double inr = entry.totalAmountPaise / 100.0;
    final kmDelta = (entry.previousOdometerKm != null)
        ? entry.odometerKm - entry.previousOdometerKm!
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: SharpCard(
        backgroundColor: AppTokens.raised,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Service Type & Order Id
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.serviceType,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w800,
                          color: AppTokens.textPrimary,
                        ),
                      ),
                      Text(
                        entry.workshopName,
                        style: const TextStyle(
                          fontSize: 13.0,
                          color: AppTokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('ORDER ID', style: TextStyle(fontSize: 10.0, color: AppTokens.textSecondary, fontWeight: FontWeight.w700)),
                    Text(
                      entry.orderId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Middle Row: Date, KM Reading, Delta, Feedback
            Container(
              padding: const EdgeInsets.all(8.0),
              color: AppTokens.surface,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SERVICE DATE', style: TextStyle(fontSize: 10.0, color: AppTokens.textSecondary, fontWeight: FontWeight.w700)),
                      Text(
                        _formatDate(entry.serviceDate),
                        style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ODOMETER', style: TextStyle(fontSize: 10.0, color: AppTokens.textSecondary, fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          const Icon(Icons.speed, size: 14.0, color: AppTokens.textPrimary),
                          const SizedBox(width: 4.0),
                          Text(
                            '${entry.odometerKm} KM',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (kmDelta != null && entry.daysSincePrevious != null) ...[
                            const SizedBox(width: 6.0),
                            Text(
                              '(+$kmDelta KM in ${entry.daysSincePrevious}d)',
                              style: const TextStyle(fontSize: 10.0, color: AppTokens.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  StatusChip(
                    label: entry.feedbackRating,
                    icon: Icons.thumb_up_alt_outlined,
                    type: StatusType.ok,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),

            // Bottom Bar: Status, Invoiced Rupee Amount, Download PDF
            Row(
              children: [
                Row(
                  children: [
                    Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: const BoxDecoration(
                        color: AppTokens.green,
                        shape: BoxShape.rectangle,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      entry.status.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.green,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '₹${inr.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 17.0,
                    fontWeight: FontWeight.w900,
                    color: AppTokens.textPrimary,
                  ),
                ),
                const SizedBox(width: 12.0),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: AppTokens.redOrange, size: 24.0),
                  onPressed: onDownloadPdf,
                  tooltip: 'Download Verified GST Invoice',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
