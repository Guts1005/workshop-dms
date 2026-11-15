import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../ui_kit/tokens/app_tokens.dart';
import '../../../ui_kit/widgets/sharp_button.dart';
import '../../../ui_kit/widgets/status_chip.dart';
import '../../vehicle/indian_number_plate.dart';
import '../../vehicle/make_wordmark_chip.dart';
import '../../vehicle/vehicle_silhouettes.dart';
import '../models/intake_form_state.dart';
import 'intake_controller.dart';

/// Dedicated Mobile View for Vehicle & Customer Intake (Page 1)
/// Strict constraints: ZERO horizontal scrolling, touch-optimized (48px+ targets),
/// sticky primary action, and high-contrast automotive cluster styling.
class IntakeMobileView extends StatelessWidget {
  final IntakeFormState state;
  final IntakeController controller;
  final TextEditingController regController;
  final TextEditingController vinController;
  final TextEditingController modelController;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController odometerController;
  final TextEditingController workController;

  const IntakeMobileView({
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
    final deliveryText = state.expectedDelivery != null
        ? DateFormat('EEE, dd MMM yyyy - hh:mm a').format(state.expectedDelivery!)
        : 'SELECT EXPECTED DELIVERY DATE & TIME';

    return Scaffold(
      backgroundColor: AppTokens.base,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Content Zone (Strictly Vertical Only - No Horizontal Scrolling)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Sub-header
                    _buildMobileHeader(),
                    const SizedBox(height: 16.0),

                    // Error Banner (if any)
                    if (state.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        color: AppTokens.redOrange,
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    // Card 1: Live Vehicle Identity & CAD Hero
                    _buildMobileVehicleHero(),
                    const SizedBox(height: 16.0),

                    // Card 1.5: Previous Service Records (if recognized)
                    if (state.isExistingVehicle && state.previousHistory.isNotEmpty) ...[
                      _buildMobilePreviousHistory(),
                      const SizedBox(height: 16.0),
                    ],

                    // Card 2: Customer Contact & Digital Consent
                    _buildMobileCustomerCard(),
                    const SizedBox(height: 16.0),

                    // Card 3: Odometer & Fuel Telemetry
                    _buildMobileTelemetryCard(),
                    const SizedBox(height: 16.0),

                    // Card 4: Requested Work & Delivery Time
                    _buildMobileRequestedWorkCard(context, deliveryText),
                    const SizedBox(height: 16.0),

                    // Card 5: In-Vehicle Inventory Checklist
                    _buildMobileBelongingsCard(),
                    const SizedBox(height: 80.0), // Padding for sticky bottom button
                  ],
                ),
              ),
            ),

            // Sticky Bottom Primary CTA Bar (Thumb-Accessible on Mobile)
            _buildStickyBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppTokens.inverse,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
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
              const SizedBox(width: 8.0),
              Text(
                'PAGE 1: VEHICLE & CUSTOMER INTAKE',
                style: AppTokens.fontMonospace(
                  color: AppTokens.textOnDark,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
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
              label: 'NEW',
              icon: Icons.add,
              type: StatusType.neutral,
            ),
        ],
      ),
    );
  }

  Widget _buildMobileVehicleHero() {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Authentic Indian HSRP Number Plate (Centered & Prominent)
          Center(
            child: IndianNumberPlate(
              registrationNumber: state.registrationNumber,
              height: 48.0,
            ),
          ),
          const SizedBox(height: 14.0),

          // High-Tech Automotive CAD Blueprint Cluster Box
          Container(
            height: 120.0,
            decoration: BoxDecoration(
              color: AppTokens.inverse, // Stealth dark cluster
              border: Border.all(color: AppTokens.borderSolid, width: 1.0),
            ),
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    size: const Size(double.infinity, 70.0),
                    painter: VehicleSilhouettePainter(
                      bodyType: state.bodyType,
                      strokeColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.make,
                      style: AppTokens.fontMonospace(color: AppTokens.orange, fontSize: 11.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      state.model.isNotEmpty ? state.model.toUpperCase() : 'MODEL PENDING',
                      style: AppTokens.fontMonospace(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      state.bodyType.label,
                      style: AppTokens.fontMonospace(color: AppTokens.surface, fontSize: 11.0),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14.0),

          // Registration Plate Input
          TextField(
            key: const Key('input_registration'),
            controller: regController,
            decoration: InputDecoration(
              labelText: 'REGISTRATION NUMBER (RTO FORMAT)',
              hintText: 'e.g. RJ27CA1024 or MH12DE1432',
              errorText: state.errors['registration'],
              filled: true,
              fillColor: AppTokens.raised,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
            ),
            style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 15.0),
            onChanged: controller.onRegistrationChanged,
          ),
          const SizedBox(height: 12.0),

          // VIN Input
          TextField(
            key: const Key('input_vin'),
            controller: vinController,
            decoration: InputDecoration(
              labelText: 'VIN / CHASSIS NUMBER (17 CHARACTERS - OPTIONAL)',
              hintText: 'e.g. MA3EWA12S00123456',
              errorText: state.errors['vin'],
              filled: true,
              fillColor: AppTokens.raised,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
            ),
            style: AppTokens.fontMonospace(fontSize: 13.0),
            onChanged: controller.onVinChanged,
          ),
          const SizedBox(height: 14.0),

          // Popular Makes: Responsive 4-Column Wrap (Strictly No Horizontal Scroll)
          const Text('SELECT MAKE:', style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 12.0),

          // Make Dropdown & Model Input
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  key: const Key('dropdown_make'),
                  isExpanded: true,
                  initialValue: state.make,
                  decoration: const InputDecoration(
                    labelText: 'MAKE',
                    filled: true,
                    fillColor: AppTokens.raised,
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
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
              ),
              const SizedBox(width: 8.0),
              Expanded(
                flex: 3,
                child: TextField(
                  key: const Key('input_model'),
                  controller: modelController,
                  decoration: InputDecoration(
                    labelText: 'MODEL & VARIANT',
                    hintText: 'e.g. HECTOR / CRETA',
                    errorText: state.errors['model'],
                    filled: true,
                    fillColor: AppTokens.raised,
                    border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
                  ),
                  onChanged: controller.onModelChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Body Silhouette 3-Column Responsive Wrap (Strictly No Horizontal Scroll)
          const Text('BODY PROFILE SILHOUETTE:', style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6.0),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: VehicleBodyType.values.map((type) {
              final isSelected = state.bodyType == type;
              return InkWell(
                key: Key('body_type_${type.name}'),
                onTap: () => controller.onBodyTypeChanged(type),
                child: Container(
                  width: 98.0,
                  height: 64.0,
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTokens.inverse : AppTokens.raised,
                    border: Border.all(color: AppTokens.borderSolid, width: 1.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 48.0,
                        height: 20.0,
                        child: CustomPaint(
                          painter: VehicleSilhouettePainter(
                            bodyType: type,
                            strokeColor: isSelected ? AppTokens.raised : AppTokens.borderSolid,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        type.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? AppTokens.textOnDark : AppTokens.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 9.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePreviousHistory() {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.raised,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'PREVIOUS SERVICE RECORDS (${state.previousHistory.length})',
                  style: AppTokens.fontMonospace(fontWeight: FontWeight.w900, fontSize: 12.0),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                color: AppTokens.surface,
                child: Text(
                  'LAST RECORDED: ${state.lastRecordedKm} KM',
                  style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 10.0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          ...state.previousHistory.map((item) {
            final dateStr = DateFormat('dd MMM yyyy').format(item.serviceDate);
            final amountRupees = (item.totalAmountPaise / 100).toStringAsFixed(2);
            return Container(
              margin: const EdgeInsets.only(bottom: 6.0),
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                border: Border.all(color: AppTokens.borderSolid, width: 1.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.circle, size: 7.0, color: AppTokens.green),
                            const SizedBox(width: 4.0),
                            Expanded(
                              child: Text(
                                'ORDER #${item.orderId}',
                                style: AppTokens.fontMonospace(fontWeight: FontWeight.w800, fontSize: 11.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2.0),
                        Text('$dateStr • ${item.feedback}', style: const TextStyle(fontSize: 11.0, color: AppTokens.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${item.odometerKm} KM', style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 11.5)),
                      Text('₹$amountRupees', style: AppTokens.fontMonospace(color: AppTokens.green, fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ],
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTokens.borderSolid, width: 1.0),
                      color: AppTokens.raised,
                    ),
                    child: const Icon(Icons.picture_as_pdf, size: 14.0, color: AppTokens.redOrange),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileCustomerCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '2. CUSTOMER & WHATSAPP DISPATCH',
                style: AppTokens.fontMonospace(fontWeight: FontWeight.w900, fontSize: 12.0),
              ),
              if (state.isExistingCustomer)
                const StatusChip(
                  label: 'RETURNING',
                  icon: Icons.person,
                  type: StatusType.ok,
                ),
            ],
          ),
          const SizedBox(height: 12.0),
          TextField(
            key: const Key('input_phone'),
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'MOBILE PHONE (+91)',
              hintText: '10 digits e.g. 9829012345',
              errorText: state.errors['phone'],
              filled: true,
              fillColor: AppTokens.raised,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            ),
            style: AppTokens.fontMonospace(fontWeight: FontWeight.bold),
            onChanged: controller.onPhoneChanged,
          ),
          const SizedBox(height: 10.0),
          TextField(
            key: const Key('input_name'),
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'CUSTOMER FULL NAME',
              hintText: 'Full name',
              errorText: state.errors['name'],
              filled: true,
              fillColor: AppTokens.raised,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            ),
            onChanged: controller.onNameChanged,
          ),
          const SizedBox(height: 12.0),
          _buildMobileCheckbox(
            key: const Key('checkbox_whatsapp'),
            label: 'WhatsApp Consent for Estimates & Digital Passport',
            value: state.whatsappConsent,
            onChanged: controller.onWhatsappConsentChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTelemetryCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '3. ODOMETER & FUEL TELEMETRY',
            style: AppTokens.fontMonospace(fontWeight: FontWeight.w900, fontSize: 12.0),
          ),
          const SizedBox(height: 12.0),
          TextField(
            key: const Key('input_odometer'),
            controller: odometerController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'CURRENT ODOMETER READING (KM)',
              hintText: 'e.g. 28450',
              errorText: state.errors['odometer'],
              filled: true,
              fillColor: AppTokens.raised,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
              suffixText: 'KM',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            ),
            style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 15.0),
            onChanged: controller.onOdometerChanged,
          ),
          const SizedBox(height: 14.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FUEL GAUGE READING:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.0)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                color: AppTokens.raised,
                child: Text(
                  '${state.fuelLevelPercent}%',
                  style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 12.0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          // 5-Segmented Fuel Blocks (Fits Screen Perfectly with Zero Horizontal Scroll)
          Row(
            children: [0, 25, 50, 75, 100].map((pct) {
              final isSel = state.fuelLevelPercent == pct;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: InkWell(
                    key: Key('fuel_pct_$pct'),
                    onTap: () => controller.onFuelLevelChanged(pct),
                    child: Container(
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: isSel ? AppTokens.inverse : AppTokens.raised,
                        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        pct == 0 ? 'E' : (pct == 100 ? 'F' : '$pct%'),
                        style: TextStyle(
                          color: isSel ? AppTokens.textOnDark : AppTokens.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.0,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileRequestedWorkCard(BuildContext context, String deliveryText) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '4. REQUESTED WORK & DELIVERY PROMISE',
            style: AppTokens.fontMonospace(fontWeight: FontWeight.w900, fontSize: 12.0),
          ),
          const SizedBox(height: 12.0),
          TextField(
            key: const Key('input_requested_work'),
            controller: workController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'CUSTOMER COMPLAINTS / SERVICES',
              hintText: 'e.g. Periodic Service, Brake pad check, AC cooling',
              errorText: state.errors['requestedWork'],
              filled: true,
              fillColor: AppTokens.raised,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
              contentPadding: const EdgeInsets.all(12.0),
            ),
            onChanged: controller.onRequestedWorkChanged,
          ),
          const SizedBox(height: 12.0),
          InkWell(
            key: const Key('btn_pick_delivery'),
            onTap: () async {
              final now = DateTime.now();
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: now.add(const Duration(days: 1)),
                firstDate: now,
                lastDate: now.add(const Duration(days: 30)),
              );
              if (pickedDate != null) {
                if (!context.mounted) return;
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
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppTokens.raised,
                border: Border.all(
                  color: state.errors.containsKey('expectedDelivery') ? AppTokens.redOrange : AppTokens.borderSolid,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 18.0),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      deliveryText,
                      style: AppTokens.fontMonospace(
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                        color: state.expectedDelivery == null ? AppTokens.textSecondary : AppTokens.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.errors.containsKey('expectedDelivery')) ...[
            const SizedBox(height: 4.0),
            Text(
              state.errors['expectedDelivery']!,
              style: const TextStyle(color: AppTokens.redOrange, fontSize: 11.0),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileBelongingsCard() {
    final b = state.belongings;
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '5. BELONGINGS INVENTORY',
            style: AppTokens.fontMonospace(fontWeight: FontWeight.w900, fontSize: 12.0),
          ),
          const SizedBox(height: 8.0),
          _buildMobileCheckbox(
            key: const Key('belonging_jack'),
            label: 'Jack & Tool Kit Present',
            value: b.jackAndToolKit,
            onChanged: (v) => controller.onBelongingItemToggled('jackAndToolKit', v),
          ),
          _buildMobileCheckbox(
            key: const Key('belonging_tyre'),
            label: 'Spare Tyre / Stepney Present',
            value: b.spareTyre,
            onChanged: (v) => controller.onBelongingItemToggled('spareTyre', v),
          ),
          _buildMobileCheckbox(
            key: const Key('belonging_mat'),
            label: 'Boot Mat Present',
            value: b.bootMat,
            onChanged: (v) => controller.onBelongingItemToggled('bootMat', v),
          ),
          _buildMobileCheckbox(
            key: const Key('belonging_valuables'),
            label: 'Valuables & Cash Removed',
            value: b.valuablesRemoved,
            onChanged: (v) => controller.onBelongingItemToggled('valuablesRemoved', v),
          ),
          _buildMobileCheckbox(
            key: const Key('belonging_pendrive'),
            label: 'Pen Drive / Accessories Inside',
            value: b.pendriveOrAccessories,
            onChanged: (v) => controller.onBelongingItemToggled('pendriveOrAccessories', v),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCheckbox({
    required Key key,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      key: key,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Container(
              width: 22.0,
              height: 22.0,
              decoration: BoxDecoration(
                color: value ? AppTokens.inverse : AppTokens.raised,
                border: Border.all(color: AppTokens.borderSolid, width: 1.0),
              ),
              child: value
                  ? const Icon(Icons.check, size: 16.0, color: AppTokens.textOnDark)
                  : null,
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: const BoxDecoration(
        color: AppTokens.inverse,
        border: Border(top: BorderSide(color: Color(0xFF333333), width: 1.0)),
      ),
      child: state.status == IntakeStatus.saving
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : SharpButton(
              label: 'GENERATE INTAKE & PROCEED TO BAY CHECK-IN',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await controller.submitIntake();
                if (ok) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Vehicle Intake recorded. Proceeding to Bay Capture.')),
                  );
                }
              },
            ),
    );
  }
}
