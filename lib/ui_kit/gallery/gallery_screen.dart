import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/vehicle/indian_number_plate.dart';
import '../../features/vehicle/vehicle_silhouettes.dart';
import '../tokens/app_tokens.dart';
import '../widgets/belongings_pills_group.dart';
import '../widgets/calibrated_wear_input.dart';
import '../widgets/concentric_shutter_button.dart';
import '../widgets/fuel_intake_slider.dart';
import '../widgets/severity_pin.dart';
import '../widgets/sharp_card.dart';
import '../widgets/traffic_light_matrix.dart';

/// Review Gate Gallery Screen (/gallery)
/// Displays every production component across all operational states.
/// Serves as the visual verification gate before features merge into production pages.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  // Interactive state for gallery testing
  double _fuelLevel = 0.50;
  Set<String> _selectedBelongings = {'Fastag', 'Spare Wheel'};
  DiagnosticStatus _brakeStatus = DiagnosticStatus.advisory;
  DiagnosticStatus _tyreStatus = DiagnosticStatus.critical;
  DiagnosticStatus _batteryStatus = DiagnosticStatus.pass;
  double? _brakeThicknessMm = 3.2;
  double? _tyreTreadMm = 1.4;
  double? _batteryVolts = 12.6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.base,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          color: AppTokens.textPrimary,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UI KIT COMPONENT GALLERY',
              style: AppTokens.fontMonospace(
                fontSize: 14.0,
                fontWeight: FontWeight.w900,
                color: AppTokens.textPrimary,
              ),
            ),
            Text(
              'Review Gate: Bounded Geometry & Token Compositions',
              style: AppTokens.fontBody(
                fontSize: 11.0,
                color: AppTokens.textSecondary,
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1.0, color: AppTokens.borderLight),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildBucket2ArtworkSection(),
          const SizedBox(height: 20.0),
          _buildBucket1CompositionsSection(),
          const SizedBox(height: 40.0),
        ],
      ),
    );
  }

  /// Bucket 2: New Artwork & Pure Geometry (Slop-Contained)
  Widget _buildBucket2ArtworkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'BUCKET 2: NEW ARTWORK & PURE GEOMETRY',
          'Mathematical CustomPaint & vector geometry. Exact dimensions, zero stylistic liberties.',
          AppTokens.brandRed,
        ),
        const SizedBox(height: 12.0),

        // 1. Concentric Shutter Rings (All States)
        SharpCard(
          title: 'CONCENTRIC SHUTTER BUTTON (72x72 outer, 52x52 inner)',
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mathematically guaranteed concentricity via CustomPainter (0.0px offset):',
                style: AppTokens.fontBody(
                  fontSize: 12.0,
                  color: AppTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 16.0),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 16.0,
                  runSpacing: 16.0,
                  children: [
                    _buildStateColumn(
                      label: 'Resting',
                      widget: const ConcentricShutterButton(
                        state: ShutterButtonState.resting,
                      ),
                    ),
                    _buildStateColumn(
                      label: 'Pressed',
                      widget: const ConcentricShutterButton(
                        state: ShutterButtonState.pressed,
                      ),
                    ),
                    _buildStateColumn(
                      label: 'Framing Locked',
                      widget: const ConcentricShutterButton(
                        state: ShutterButtonState.lockedReady,
                      ),
                    ),
                    _buildStateColumn(
                      label: 'Disabled',
                      widget: const ConcentricShutterButton(
                        state: ShutterButtonState.disabled,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14.0),

        // 2. Indian HSRP Plates (All States)
        SharpCard(
          title: 'INDIAN HIGH SECURITY REGISTRATION PLATES (HSRP)',
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Authentic blue IND strip with Ashok Chakra, laser tracking layout, mono font:',
                style: AppTokens.fontBody(
                  fontSize: 12.0,
                  color: AppTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 14.0),
              const IndianNumberPlate(
                registrationNumber: 'RJ 27 CA 1024',
                isCommercial: false,
              ),
              const SizedBox(height: 10.0),
              const IndianNumberPlate(
                registrationNumber: 'HR 26 EB 9415',
                isCommercial: true,
              ),
              const SizedBox(height: 10.0),
              const IndianNumberPlate(
                registrationNumber: '',
                isCommercial: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14.0),

        // 3. Severity Pins (All States)
        SharpCard(
          title: 'CONDITION DEFECT SEVERITY PINS (28x34 pt geometry)',
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'L1 (Amber #F59E0B), L2 (Orange #EA580C), L3 (Brand Red #E03131), normalized 0..1 coords:',
                style: AppTokens.fontBody(
                  fontSize: 12.0,
                  color: AppTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 16.0),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 20.0,
                  runSpacing: 16.0,
                  children: [
                    _buildStateColumn(
                      label: 'L1: Minor',
                      widget: const SeverityPinWidget(
                        level: DefectSeverityLevel.l1,
                      ),
                    ),
                    _buildStateColumn(
                      label: 'L2: Medium',
                      widget: const SeverityPinWidget(
                        level: DefectSeverityLevel.l2,
                      ),
                    ),
                    _buildStateColumn(
                      label: 'L3: Critical',
                      widget: const SeverityPinWidget(
                        level: DefectSeverityLevel.l3,
                      ),
                    ),
                    _buildStateColumn(
                      label: 'L3: Selected',
                      widget: const SeverityPinWidget(
                        level: DefectSeverityLevel.l3,
                        isSelected: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14.0),

        // 4. Vehicle Body Type Silhouettes
        SharpCard(
          title: 'STANDARDIZED VEHICLE BODY SILHOUETTES',
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Standardized CAD proportion wireframes (placed & scaled, zero procedural blobs):',
                style: AppTokens.fontBody(
                  fontSize: 12.0,
                  color: AppTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 14.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStateColumn(
                    label: 'Sedan',
                    widget: const VehicleSilhouetteWidget(
                      bodyType: VehicleBodyType.sedan,
                      width: 140.0,
                      height: 50.0,
                    ),
                  ),
                  _buildStateColumn(
                    label: 'SUV',
                    widget: const VehicleSilhouetteWidget(
                      bodyType: VehicleBodyType.midFullSuv,
                      width: 140.0,
                      height: 50.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Bucket 1: Compositions of Existing Primitives (Token Values Only)
  Widget _buildBucket1CompositionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'BUCKET 1: TOKEN COMPOSITIONS',
          'Composed from AppTokens directly in Flutter. Zero new Figma art, zero slop risk.',
          AppTokens.green,
        ),
        const SizedBox(height: 12.0),

        // Fuel Slider
        FuelIntakeSlider(
          value: _fuelLevel,
          onChanged: (val) => setState(() => _fuelLevel = val),
        ),
        const SizedBox(height: 14.0),

        // Belongings Verification
        BelongingsPillsGroup(
          selectedItems: _selectedBelongings,
          onChanged: (updated) => setState(() => _selectedBelongings = updated),
        ),
        const SizedBox(height: 14.0),

        // Multi-Point Diagnostics Matrix
        SharpCard(
          title: 'TRAFFIC-LIGHT INSPECTION MATRIX (R / A / G)',
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              TrafficLightItemRow(
                title: 'Front Brake Friction Pads',
                subtitle: 'Minimum thickness requirement: 3.0 mm',
                status: _brakeStatus,
                onStatusChanged: (s) => setState(() => _brakeStatus = s),
              ),
              TrafficLightItemRow(
                title: 'Tyre Tread Depth (All 4 Tyres)',
                subtitle: 'Legal minimum wear limit: 1.6 mm',
                status: _tyreStatus,
                onStatusChanged: (s) => setState(() => _tyreStatus = s),
              ),
              TrafficLightItemRow(
                title: '12V Lead-Acid / AGM Battery Health',
                subtitle: 'Nominal resting terminal voltage: 12.6V',
                status: _batteryStatus,
                onStatusChanged: (s) => setState(() => _batteryStatus = s),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14.0),

        // Calibrated Wear Gauges
        SharpCard(
          title: 'CALIBRATED WEAR MEASUREMENT INPUTS',
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              CalibratedWearInput(
                label: 'Front Left Brake Pad Thickness',
                unit: 'mm',
                value: _brakeThicknessMm,
                criticalThreshold: 2.0,
                advisoryThreshold: 4.0,
                onChanged: (val) => setState(() => _brakeThicknessMm = val),
              ),
              const SizedBox(height: 8.0),
              CalibratedWearInput(
                label: 'Front Right Tyre Tread Depth',
                unit: 'mm',
                value: _tyreTreadMm,
                criticalThreshold: 1.6,
                advisoryThreshold: 3.0,
                onChanged: (val) => setState(() => _tyreTreadMm = val),
              ),
              const SizedBox(height: 8.0),
              CalibratedWearInput(
                label: '12V Battery Resting Voltage',
                unit: 'V',
                value: _batteryVolts,
                criticalThreshold: 11.8,
                advisoryThreshold: 12.2,
                onChanged: (val) => setState(() => _batteryVolts = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTokens.cardRadius,
        border: Border.all(color: AppTokens.borderLight),
        boxShadow: AppTokens.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  title,
                  style: AppTokens.fontMonospace(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w900,
                    color: AppTokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            subtitle,
            style: AppTokens.fontBody(
              fontSize: 11.5,
              color: AppTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateColumn({required String label, required Widget widget}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget,
        const SizedBox(height: 8.0),
        Text(
          label,
          style: AppTokens.fontMonospace(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}
