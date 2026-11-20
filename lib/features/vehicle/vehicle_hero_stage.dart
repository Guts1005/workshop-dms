import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../ui_kit/tokens/app_tokens.dart';
import 'indian_number_plate.dart';
import 'vehicle_silhouettes.dart';

/// Modern Automotive Hero Stage (Rivian + MG i-SMART Luxury Aesthetic)
/// Features glanceable telemetry numbers, photorealistic vehicle renders with
/// ground contact shadows, authentic HSRP plate, and tactile quick-action pill buttons.
class VehicleHeroStage extends StatelessWidget {
  final String registrationNumber;
  final String make;
  final String model;
  final VehicleBodyType bodyType;
  final String odometerKm;
  final bool isExistingVehicle;
  final VoidCallback? onBayCaptureTap;
  final VoidCallback? onConditionMapTap;
  final VoidCallback? onJobCardTap;
  final bool showQuickActions;

  const VehicleHeroStage({
    super.key,
    required this.registrationNumber,
    required this.make,
    required this.model,
    required this.bodyType,
    required this.odometerKm,
    this.isExistingVehicle = false,
    this.onBayCaptureTap,
    this.onConditionMapTap,
    this.onJobCardTap,
    this.showQuickActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayOdo = odometerKm.trim().isNotEmpty
        ? '$odometerKm KM'
        : 'Not recorded';

    final displayModel = model.trim().isNotEmpty
        ? '$make ${model.toUpperCase()}'
        : (make.trim().isNotEmpty ? make : 'Vehicle details unavailable');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 18.0,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Rivian Glanceable Telemetry Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayOdo,
                      style: GoogleFonts.inter(
                        fontSize: 32.0,
                        fontWeight: FontWeight.w900,
                        color: AppTokens.textPrimary,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Row(
                      children: [
                        Container(
                          width: 6.0,
                          height: 6.0,
                          decoration: BoxDecoration(
                            color: isExistingVehicle
                                ? AppTokens.green
                                : AppTokens.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Flexible(
                          child: Text(
                            displayModel,
                            style: GoogleFonts.inter(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: AppTokens.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Pill Tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: isExistingVehicle
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: isExistingVehicle
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFBFDBFE),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isExistingVehicle
                          ? Icons.verified
                          : Icons.cloud_done_outlined,
                      size: 13.0,
                      color: isExistingVehicle
                          ? const Color(0xFF15803D)
                          : const Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      isExistingVehicle ? 'VERIFIED' : 'ONLINE',
                      style: TextStyle(
                        color: isExistingVehicle
                            ? const Color(0xFF15803D)
                            : const Color(0xFF1D4ED8),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // 2. Photorealistic Car Visual with Ground Contact Shadow
          Center(
            child: SizedBox(
              height: 145.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle Rivian-style watermark in background
                  Positioned(
                    top: 12.0,
                    child: Text(
                      displayOdo,
                      style: GoogleFonts.inter(
                        fontSize: 44.0,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFF8FAFC),
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),

                  // Ground diffuse contact shadow
                  Positioned(
                    bottom: 10.0,
                    child: Container(
                      width: 250.0,
                      height: 12.0,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(250, 12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x35000000),
                            blurRadius: 20.0,
                            spreadRadius: 2.0,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Photorealistic vehicle rendering
                  _buildCarRender(context),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10.0),

          // 3. Indian HSRP Number Plate (Centered & Prominent)
          Center(
            child: IndianNumberPlate(
              registrationNumber: registrationNumber,
              height: 48.0,
            ),
          ),
          const SizedBox(height: 16.0),

          // 4. Rivian Quick-Action Pill Controls
          if (showQuickActions)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPillAction(
                  icon: Icons.camera_alt_outlined,
                  label: '6-PT CAPTURE',
                  onTap: onBayCaptureTap,
                ),
                const SizedBox(width: 8.0),
                _buildPillAction(
                  icon: Icons.crop_rotate,
                  label: 'CONDITION REPORT',
                  onTap: onConditionMapTap,
                ),
                const SizedBox(width: 8.0),
                _buildPillAction(
                  icon: Icons.assignment_outlined,
                  label: 'JOB CARD',
                  onTap: onJobCardTap,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCarRender(BuildContext context) {
    final cleanMake = make.toUpperCase();
    final cleanModel = model.toUpperCase();

    if (cleanMake.contains('MG') || cleanModel.contains('HECTOR')) {
      return Image.asset(
        'assets/images/mg_hector_red.png',
        height: 125.0,
        fit: BoxFit.contain,
      );
    }
    return SizedBox(
      width: 220.0,
      height: 90.0,
      child: CustomPaint(
        painter: VehicleSilhouettePainter(
          bodyType: bodyType,
          strokeColor: AppTokens.textPrimary,
        ),
      ),
    );
  }

  Widget _buildPillAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20.0),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13.0, color: AppTokens.textPrimary),
              const SizedBox(width: 5.0),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
