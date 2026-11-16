import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../ui_kit/tokens/app_tokens.dart';
import '../../../ui_kit/widgets/sharp_button.dart';
import '../../../ui_kit/widgets/sharp_card.dart';
import '../../../ui_kit/widgets/status_chip.dart';
import '../../vehicle/indian_number_plate.dart';
import '../../vehicle/make_wordmark_chip.dart';
import '../../vehicle/vehicle_silhouettes.dart';
import '../models/intake_form_state.dart';
import 'intake_controller.dart';

/// Dedicated Tablet / Desktop View for Vehicle & Customer Intake (Page 1)
/// Rivian-grade 2-column split architecture, stealth CAD telemetry stage,
/// authentic MG service history recreation, and ZERO horizontal scroll.
class IntakeDesktopView extends StatelessWidget {
  final IntakeFormState state;
  final IntakeController controller;
  final TextEditingController regController;
  final TextEditingController vinController;
  final TextEditingController modelController;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController odometerController;
  final TextEditingController workController;

  const IntakeDesktopView({
    super.key,
    required this.state,
    required this.controller,
    required this.regController,
    required this.vinController,
    required this.modelController,
    required this.nameController,
    required this.phoneController,
    required this.odometerController,
    required this.workController,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400.0),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Sleek Breadcrumb Bar (Non-redundant, light surface)
              _buildDesktopHeader(),
              const SizedBox(height: 16.0),

              if (state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppTokens.redOrange,
                    border: Border.all(color: AppTokens.borderSolid, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 20.0),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
              ],

              // 2-Column Split: Left Rail (Vehicle & History) + Right Workspace (Form & Belongings)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Rail (Flex 5, ~42% width): Vehicle Identity & Telemetry Hero
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildVehicleHeroCard(),
                        if (state.isExistingVehicle && state.previousHistory.isNotEmpty) ...[
                          const SizedBox(height: 16.0),
                          _buildPreviousHistoryCard(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 20.0),

                  // Right Pane (Flex 7, ~58% width): Intake Workspace
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        _buildCustomerDetailsCard(),
                        const SizedBox(height: 16.0),
                        _buildOdometerAndFuelCard(),
                        const SizedBox(height: 16.0),
                        _buildRequestedWorkCard(context),
                        const SizedBox(height: 16.0),
                        _buildBelongingsCard(),
                        const SizedBox(height: 20.0),
                        _buildSubmitAction(context),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Sleek Breadcrumb (Satisfies test expectation 'PAGE 1: VEHICLE & CUSTOMER INTAKE')
  Widget _buildDesktopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: const Color(0xFFC8C6C0), width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
                color: AppTokens.redOrange,
                child: Text(
                  '01',
                  style: AppTokens.fontMonospace(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Text(
                'PAGE 1: VEHICLE & CUSTOMER INTAKE',
                style: AppTokens.fontMonospace(
                  color: AppTokens.textPrimary,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 12.0),
              Text(
                '• RIVIAN TELEMETRY HUB',
                style: AppTokens.fontMonospace(
                  color: const Color(0xFF666666),
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (state.isExistingVehicle)
            const StatusChip(
              label: 'RECOGNISED IN SYSTEM',
              icon: Icons.verified,
              type: StatusType.ok,
            )
          else
            const StatusChip(
              label: 'NEW CUSTOMER INTAKE',
              icon: Icons.add,
              type: StatusType.neutral,
            ),
        ],
      ),
    );
  }

  /// Left Rail: Vehicle Identity & CAD Hero Stage
  Widget _buildVehicleHeroCard() {
    return SharpCard(
      title: '1. VEHICLE REGISTRATION & IDENTITY',
      titleTrailing: state.isExistingVehicle
          ? const Icon(Icons.verified, color: Color(0xFF00E676), size: 16.0)
          : null,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centered Authentic HSRP Number Plate
          Center(
            child: IndianNumberPlate(
              registrationNumber: state.registrationNumber,
              height: 52.0,
            ),
          ),
          const SizedBox(height: 14.0),

          // Stealth Dark CAD Telemetry Pod
          Container(
            height: 140.0,
            decoration: BoxDecoration(
              color: const Color(0xFF161719),
              border: Border.all(color: const Color(0xFF2C2E33), width: 1.0),
            ),
            padding: const EdgeInsets.all(14.0),
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    size: const Size(double.infinity, 80.0),
                    painter: VehicleSilhouettePainter(
                      bodyType: state.bodyType,
                      strokeColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.make,
                      style: AppTokens.fontMonospace(
                        color: AppTokens.orange,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Text(
                          state.model.isNotEmpty ? state.model.toUpperCase() : 'MODEL PENDING',
                          textAlign: TextAlign.center,
                          style: AppTokens.fontMonospace(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Text(
                      state.bodyType.label,
                      style: AppTokens.fontMonospace(
                        color: const Color(0xFF999999),
                        fontSize: 11.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Registration Plate Input
          _buildMicroLabel('REGISTRATION NUMBER (RTO FORMAT)', isRequired: true),
          const SizedBox(height: 4.0),
          TextField(
            key: const Key('input_registration'),
            controller: regController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'e.g. RJ27CA1024 or DL01AB1234',
              errorText: state.errors['registration'],
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Container(
                margin: const EdgeInsets.only(right: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
                color: const Color(0xFF003399),
                child: const Text('IND', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.0)),
              ),
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFFCCCCCC))),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTokens.redOrange, width: 2.0)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 13.0),
            ),
            style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 15.0),
            onChanged: controller.onRegistrationChanged,
          ),
          const SizedBox(height: 12.0),

          // VIN Input
          _buildMicroLabel('VIN / CHASSIS NUMBER (17 DIGITS - OPTIONAL)'),
          const SizedBox(height: 4.0),
          TextField(
            key: const Key('input_vin'),
            controller: vinController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'e.g. MA3EWA12S00123456',
              errorText: state.errors['vin'],
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18.0, color: Color(0xFF666666)),
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFFCCCCCC))),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTokens.redOrange, width: 2.0)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 13.0),
            ),
            style: AppTokens.fontMonospace(fontSize: 13.5),
            onChanged: controller.onVinChanged,
          ),
          const SizedBox(height: 14.0),

          // Popular Makes (Wrap - strictly zero horizontal scroll)
          _buildMicroLabel('POPULAR MAKES (TAP TO SELECT):'),
          const SizedBox(height: 6.0),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: [
              'MARUTI SUZUKI',
              'HYUNDAI',
              'TATA',
              'MAHINDRA',
              'MG MOTOR',
              'TOYOTA',
              'KIA',
              'HONDA',
            ].map((makeName) {
              return MakeWordmarkChip(
                make: makeName,
                isSelected: state.make == makeName,
                onTap: () => controller.onMakeChanged(makeName),
              );
            }).toList(),
          ),
          const SizedBox(height: 14.0),

          // Make Dropdown & Model Input
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMicroLabel('MAKE'),
                    const SizedBox(height: 4.0),
                    DropdownButtonFormField<String>(
                      key: const Key('dropdown_make'),
                      isExpanded: true,
                      initialValue: state.make,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFFCCCCCC))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTokens.redOrange, width: 2.0)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'MARUTI SUZUKI', child: Text('MARUTI')),
                        DropdownMenuItem(value: 'HYUNDAI', child: Text('HYUNDAI')),
                        DropdownMenuItem(value: 'TATA', child: Text('TATA')),
                        DropdownMenuItem(value: 'MAHINDRA', child: Text('MAHINDRA')),
                        DropdownMenuItem(value: 'MG MOTOR', child: Text('MG MOTOR')),
                        DropdownMenuItem(value: 'TOYOTA', child: Text('TOYOTA')),
                        DropdownMenuItem(value: 'HONDA', child: Text('HONDA')),
                        DropdownMenuItem(value: 'KIA', child: Text('KIA')),
                        DropdownMenuItem(value: 'VOLKSWAGEN', child: Text('VW')),
                        DropdownMenuItem(value: 'SKODA', child: Text('SKODA')),
                        DropdownMenuItem(value: 'OTHER', child: Text('OTHER')),
                      ],
                      onChanged: (v) {
                        if (v != null) controller.onMakeChanged(v);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMicroLabel('MODEL & VARIANT', isRequired: true),
                    const SizedBox(height: 4.0),
                    TextField(
                      key: const Key('input_model'),
                      controller: modelController,
                      decoration: InputDecoration(
                        hintText: 'e.g. HECTOR PLUS or SWIFT VXI',
                        errorText: state.errors['model'],
                        filled: true,
                        fillColor: Colors.white,
                        border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFFCCCCCC))),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTokens.redOrange, width: 2.0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
                      ),
                      onChanged: controller.onModelChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Body Profile Silhouettes (Grid)
          _buildMicroLabel('BODY PROFILE SILHOUETTE:'),
          const SizedBox(height: 6.0),
          _buildBodySilhouetteGrid(),
        ],
      ),
    );
  }

  Widget _buildBodySilhouetteGrid() {
    final types = [
      VehicleBodyType.hatchback,
      VehicleBodyType.sedan,
      VehicleBodyType.sub4mSuv,
      VehicleBodyType.midFullSuv,
      VehicleBodyType.mpv,
      VehicleBodyType.pickupVan,
      VehicleBodyType.generic,
    ];

    return Wrap(
      spacing: 6.0,
      runSpacing: 6.0,
      children: types.map((bt) {
        final isSel = state.bodyType == bt;
        return InkWell(
          onTap: () => controller.onBodyTypeChanged(bt),
          child: Container(
            width: 118.0,
            height: 68.0,
            decoration: BoxDecoration(
              color: isSel ? AppTokens.inverse : Colors.white,
              border: Border.all(
                color: isSel ? AppTokens.redOrange : const Color(0xFFCCCCCC),
                width: isSel ? 2.0 : 1.0,
              ),
            ),
            padding: const EdgeInsets.all(4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 34.0,
                  child: CustomPaint(
                    size: const Size(90.0, 34.0),
                    painter: VehicleSilhouettePainter(
                      bodyType: bt,
                      strokeColor: isSel ? Colors.white : AppTokens.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 2.0),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    bt.label,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: isSel ? Colors.white : AppTokens.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Left Rail: Verified Previous Service Records (MG Udaipur Layout from media_1794684843470_c564c74e.jpg)
  Widget _buildPreviousHistoryCard() {
    return SharpCard(
      title: 'PREVIOUS SERVICE RECORDS (${state.previousHistory.length})',
      titleTrailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
        color: AppTokens.surface,
        child: Text(
          'LAST RECORDED: ${state.lastRecordedKm} KM',
          style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 10.5),
        ),
      ),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: state.previousHistory.map((item) {
          final dateStr = DateFormat('dd MMM yyyy').format(item.serviceDate);
          final amountRupees = (item.totalAmountPaise / 100).toStringAsFixed(2);
          return Container(
            margin: const EdgeInsets.only(bottom: 10.0),
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFD0CFC9), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Status badge & Order Id
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 8.0,
                            height: 8.0,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00E676),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6.0),
                          Expanded(
                            child: Text(
                              'ORDER #${item.orderId}',
                              style: AppTokens.fontMonospace(
                                fontWeight: FontWeight.w900,
                                fontSize: 12.0,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      color: const Color(0xFFE8F5E9),
                      child: Text(
                        '★ ${item.feedback.toUpperCase()}',
                        style: AppTokens.fontMonospace(
                          color: const Color(0xFF2E6B3F),
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),

                // Center Row: Workshop & Odometer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'MG MOTORS • $dateStr',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF666666), fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.speed, size: 13.0, color: Color(0xFF666666)),
                        const SizedBox(width: 4.0),
                        Text(
                          '${item.odometerKm} KM',
                          style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 14.0, color: Color(0xFFEEEEEE)),

                // Bottom Row: Price & PDF Invoice Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '₹$amountRupees',
                        style: AppTokens.fontMonospace(
                          color: AppTokens.green,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: AppTokens.surface,
                        border: Border.all(color: const Color(0xFFCCCCCC), width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.picture_as_pdf, size: 12.0, color: AppTokens.redOrange),
                          const SizedBox(width: 4.0),
                          Text(
                            'VIEW INVOICE',
                            style: AppTokens.fontMonospace(fontSize: 10.0, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Right Pane: Customer Contact & Digital Consent
  Widget _buildCustomerDetailsCard() {
    return SharpCard(
      title: '2. CUSTOMER CONTACT & DIGITAL CONSENT',
      titleTrailing: state.isExistingCustomer
          ? const StatusChip(label: 'RETURNING CUSTOMER', icon: Icons.person, type: StatusType.ok)
          : null,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMicroLabel('MOBILE PHONE (+91)', isRequired: true),
                    const SizedBox(height: 4.0),
                    TextField(
                      key: const Key('input_phone'),
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '10 digits e.g. 9829012345',
                        errorText: state.errors['phone'],
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Container(
                          margin: const EdgeInsets.only(right: 8.0),
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                          color: AppTokens.surface,
                          child: const Text('+91', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0)),
                        ),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFFCCCCCC))),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTokens.redOrange, width: 2.0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                      ),
                      style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 14.0),
                      onChanged: controller.onPhoneChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMicroLabel('CUSTOMER FULL NAME', isRequired: true),
                    const SizedBox(height: 4.0),
                    TextField(
                      key: const Key('input_name'),
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Full name',
                        errorText: state.errors['name'],
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.person_outline, size: 18.0, color: Color(0xFF666666)),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFFCCCCCC))),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTokens.redOrange, width: 2.0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                      ),
                      onChanged: controller.onNameChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Digital WhatsApp & SMS Consent Checkbox
          InkWell(
            key: const Key('checkbox_whatsapp'),
            onTap: () => controller.onWhatsappConsentChanged(!state.whatsappConsent),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: state.whatsappConsent ? const Color(0xFFF0EFEB) : Colors.white,
                border: Border.all(
                  color: state.whatsappConsent ? AppTokens.inverse : const Color(0xFFCCCCCC),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20.0,
                    height: 20.0,
                    decoration: BoxDecoration(
                      color: state.whatsappConsent ? AppTokens.inverse : Colors.white,
                      border: Border.all(color: AppTokens.borderSolid, width: 1.0),
                    ),
                    child: state.whatsappConsent
                        ? const Icon(Icons.check, size: 14.0, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10.0),
                  const Expanded(
                    child: Text(
                      'Customer consents to receive Estimates, Digital Passport & Invoices on WhatsApp & SMS',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Right Pane: Odometer & Fuel Telemetry
  Widget _buildOdometerAndFuelCard() {
    return SharpCard(
      title: '3. ODOMETER & FUEL LEVEL AT INTAKE',
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMicroLabel('CURRENT ODOMETER READING (KM)', isRequired: true),
                    const SizedBox(height: 4.0),
                    TextField(
                      key: const Key('input_odometer'),
                      controller: odometerController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g. 28450',
                        errorText: state.errors['odometer'],
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.speed, size: 18.0, color: Color(0xFF666666)),
                        suffixText: 'KM',
                        border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFFCCCCCC))),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTokens.redOrange, width: 2.0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                      ),
                      style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 15.0),
                      onChanged: controller.onOdometerChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMicroLabel('FUEL TANK LEVEL:'),
                        Text(
                          '${state.fuelLevelPercent}%',
                          style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 13.0, color: AppTokens.orange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    _buildSegmentedFuelMeter(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedFuelMeter() {
    return Column(
      children: [
        Row(
          children: List.generate(8, (i) {
            final threshold = (i + 1) * 12.5;
            final isFilled = state.fuelLevelPercent >= threshold - 6.0;
            final isLow = state.fuelLevelPercent <= 25;
            final blockColor = isFilled
                ? (isLow ? AppTokens.orange : AppTokens.green)
                : const Color(0xFFDDDDDD);

            return Expanded(
              child: GestureDetector(
                onTap: () => controller.onFuelLevelChanged(((i + 1) * 12.5).clamp(0, 100).toInt()),
                child: Container(
                  height: 22.0,
                  margin: EdgeInsets.only(right: i < 7 ? 4.0 : 0.0),
                  color: blockColor,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('E', style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 11.0, color: const Color(0xFF888888))),
            Text('1/4', style: AppTokens.fontMonospace(fontSize: 10.0, color: const Color(0xFF888888))),
            Text('1/2', style: AppTokens.fontMonospace(fontSize: 10.0, color: const Color(0xFF888888))),
            Text('3/4', style: AppTokens.fontMonospace(fontSize: 10.0, color: const Color(0xFF888888))),
            Text('F', style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 11.0, color: const Color(0xFF888888))),
          ],
        ),
      ],
    );
  }

  /// Right Pane: Requested Work & Expected Delivery
  Widget _buildRequestedWorkCard(BuildContext context) {
    final deliveryText = state.expectedDelivery != null
        ? DateFormat('EEE, dd MMM yyyy - hh:mm a').format(state.expectedDelivery!)
        : 'SELECT EXPECTED DELIVERY DATE & TIME';

    return SharpCard(
      title: '4. REQUESTED WORK & TARGET DELIVERY',
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMicroLabel('CUSTOMER REPORTED CONCERNS / SERVICE SCOPE:'),
          const SizedBox(height: 4.0),
          TextField(
            key: const Key('input_requested_work'),
            controller: workController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. Periodic maintenance, brake pad vibration, AC cooling check...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFFCCCCCC))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTokens.redOrange, width: 2.0)),
              contentPadding: EdgeInsets.all(12.0),
            ),
            onChanged: controller.onRequestedWorkChanged,
          ),
          const SizedBox(height: 12.0),

          _buildMicroLabel('TARGET DELIVERY DATE & TIME:'),
          const SizedBox(height: 4.0),
          InkWell(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (pickedDate != null && context.mounted) {
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 17, minute: 0),
                );
                final combined = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime?.hour ?? 17,
                  pickedTime?.minute ?? 0,
                );
                controller.onExpectedDeliveryChanged(combined);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFCCCCCC), width: 1.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16.0, color: Color(0xFF555555)),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      deliveryText,
                      style: AppTokens.fontMonospace(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Right Pane: Belongings Checklist
  Widget _buildBelongingsCard() {
    return SharpCard(
      title: '5. IN-VEHICLE INVENTORY & VALUABLES CHECKLIST',
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCheckboxTile(
                  label: 'Jack, Tommy & Tool Kit in boot',
                  value: state.belongings.jackAndToolKit,
                  onChanged: (v) => controller.onBelongingItemToggled('jackAndToolKit', v),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _buildCheckboxTile(
                  label: 'Spare Tyre / Stepney present',
                  value: state.belongings.spareTyre,
                  onChanged: (v) => controller.onBelongingItemToggled('spareTyre', v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(
                child: _buildCheckboxTile(
                  label: 'Boot Mat & floor liners in place',
                  value: state.belongings.bootMat,
                  onChanged: (v) => controller.onBelongingItemToggled('bootMat', v),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _buildCheckboxTile(
                  label: 'Personal valuables removed by owner',
                  value: state.belongings.valuablesRemoved,
                  onChanged: (v) => controller.onBelongingItemToggled('valuablesRemoved', v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(
                child: _buildCheckboxTile(
                  label: 'Pendrive, Toll Tags & Media accessories logged',
                  value: state.belongings.pendriveOrAccessories,
                  onChanged: (v) => controller.onBelongingItemToggled('pendriveOrAccessories', v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: value ? const Color(0xFFF0EFEB) : Colors.white,
          border: Border.all(color: value ? AppTokens.inverse : const Color(0xFFCCCCCC), width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 18.0,
              height: 18.0,
              decoration: BoxDecoration(
                color: value ? AppTokens.inverse : Colors.white,
                border: Border.all(color: AppTokens.borderSolid, width: 1.0),
              ),
              child: value
                  ? const Icon(Icons.check, size: 14.0, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitAction(BuildContext context) {
    if (state.status == IntakeStatus.saving) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(color: AppTokens.inverse),
        ),
      );
    }

    return SharpButton(
      label: 'GENERATE INTAKE & PROCEED TO BAY CHECK-IN',
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final ok = await controller.submitIntake();
        if (ok && context.mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Vehicle Intake recorded. Proceeding to Bay Capture.')),
          );
          GoRouter.maybeOf(context)?.go('/bay-capture');
        }
      },
    );
  }

  Widget _buildMicroLabel(String text, {bool isRequired = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            text,
            style: AppTokens.fontMonospace(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF444444),
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4.0),
          const Text('*', style: TextStyle(color: AppTokens.redOrange, fontWeight: FontWeight.bold, fontSize: 12.0)),
        ],
      ],
    );
  }
}
