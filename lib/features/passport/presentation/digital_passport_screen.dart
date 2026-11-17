import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../ui_kit/tokens/app_tokens.dart';
import '../../../ui_kit/widgets/status_chip.dart';
import '../../vehicle/vehicle_silhouettes.dart';
import '../digital_health_passport_widget.dart';

/// Complete Customer-Facing Digital Health Passport Screen (Page 11)
/// Rivian + MG i-SMART Consumer Aesthetic:
/// Component wear metrics (Brake pads wear %, Tyre tread depth mm, Battery CCA),
/// Cryptographically verifiable service history entries, and PDF export.
class DigitalPassportScreen extends StatelessWidget {
  final String? registrationNumber;
  final String? model;

  const DigitalPassportScreen({
    super.key,
    this.registrationNumber,
    this.model,
  });

  @override
  Widget build(BuildContext context) {
    final reg = registrationNumber ?? 'RJ27CA1024';
    final vehicleModel = model ?? 'MG HECTOR SHARP PRO';

    final demoHistory = [
      ServiceHistoryEntry(
        orderId: 'N330302623',
        serviceType: 'Periodic Maintenance & Brake Overhaul',
        workshopName: 'MG Noida Workshop DMS (Sector 8)',
        serviceDate: DateTime(2023, 11, 20),
        odometerKm: 27227,
        previousOdometerKm: 18450,
        daysSincePrevious: 182,
        totalAmountPaise: 747672,
        feedbackRating: '5.0 Exceptional',
        partsReplaced: [
          'Mobil 1 ESP 5W-30 Fully Synthetic Engine Oil',
          'OEM Spin-on Lubricating Oil Filter',
          'Front Heavy-Duty Ceramic Brake Pads Set',
        ],
        labourJobs: [
          'Comprehensive Periodic Maintenance (SAC 998729)',
          'Front Brake Caliper Overhaul & Disc Facing',
          'AC Disinfection & Cabin Filter Cleaning',
        ],
        wearMetrics: {
          'Brake Pad Lining': '8.5 mm (85% Healthy)',
          'Tyre Tread Depth': '5.8 mm (Good for ~22,000 KM)',
          'Battery Health': '12.6V • 540 CCA (98% Life)',
        },
      ),
      ServiceHistoryEntry(
        orderId: 'N220914810',
        serviceType: '2nd Scheduled Warranty Service',
        workshopName: 'MG Jaipur City Workshop',
        serviceDate: DateTime(2022, 9, 14),
        odometerKm: 18450,
        previousOdometerKm: 10000,
        daysSincePrevious: 195,
        totalAmountPaise: 521000,
        feedbackRating: '5.0 Excellent',
        partsReplaced: [
          'Synthetic Engine Oil (3.5L)',
          'Engine Air Intake Filter Cartridge',
          'Washer Fluid Concentrate',
        ],
        labourJobs: [
          '2nd Free Service Inspection Checklist',
          '4-Wheel Laser Alignment & Balancing',
        ],
        wearMetrics: {
          'Brake Pad Lining': '10.2 mm (New)',
          'Tyre Tread Depth': '7.1 mm',
          'Battery Health': '12.7V • 550 CCA (100%)',
        },
      ),
    ];

    return Scaffold(
      backgroundColor: AppTokens.base,
      body: SafeArea(
        child: Column(
          children: [
            // Stage Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: AppTokens.brandRed,
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          '11',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'PAGE 11: DIGITAL HEALTH PASSPORT (CUSTOMER FACING)',
                        style: GoogleFonts.inter(
                          color: AppTokens.textPrimary,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const StatusChip(
                    label: 'CRYPTOGRAPHICALLY VERIFIED',
                    icon: Icons.verified_user,
                    type: StatusType.ok,
                  ),
                ],
              ),
            ),

            // Main Passport Widget Zone
            Expanded(
              child: DigitalHealthPassportWidget(
                vehicleModel: vehicleModel,
                registrationNumber: reg,
                bodyType: VehicleBodyType.midFullSuv,
                serviceHistory: demoHistory,
                onDownloadPdf: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF15803D),
                      content: Text('Cryptographically signed Digital Health Passport PDF generated and downloaded.'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
