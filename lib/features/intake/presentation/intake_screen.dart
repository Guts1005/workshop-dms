import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../ui_kit/tokens/app_tokens.dart';
import '../../../ui_kit/widgets/sharp_button.dart';
import '../../../ui_kit/widgets/status_chip.dart';
import '../models/intake_form_state.dart';
import 'intake_controller.dart';

class IntakeScreen extends ConsumerStatefulWidget {
  const IntakeScreen({super.key});

  @override
  ConsumerState<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends ConsumerState<IntakeScreen> {
  final _regController = TextEditingController();
  final _vinController = TextEditingController();
  final _modelController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _odometerController = TextEditingController();
  final _workController = TextEditingController();

  @override
  void dispose() {
    _regController.dispose();
    _vinController.dispose();
    _modelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _odometerController.dispose();
    _workController.dispose();
    super.dispose();
  }

  void _syncControllersWithState(IntakeFormState state) {
    if (_regController.text != state.registrationNumber && state.registrationNumber.isNotEmpty) {
      _regController.value = TextEditingValue(
        text: state.registrationNumber,
        selection: TextSelection.collapsed(offset: state.registrationNumber.length),
      );
    }
    if (_vinController.text != state.vin && state.vin.isNotEmpty) {
      _vinController.value = TextEditingValue(
        text: state.vin,
        selection: TextSelection.collapsed(offset: state.vin.length),
      );
    }
    if (_modelController.text != state.model && state.model.isNotEmpty) {
      _modelController.value = TextEditingValue(
        text: state.model,
        selection: TextSelection.collapsed(offset: state.model.length),
      );
    }
    if (_nameController.text != state.customerName && state.customerName.isNotEmpty) {
      _nameController.value = TextEditingValue(
        text: state.customerName,
        selection: TextSelection.collapsed(offset: state.customerName.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(intakeControllerProvider);
    final controller = ref.read(intakeControllerProvider.notifier);

    // Sync controllers when state updates from background lookups
    ref.listen<IntakeFormState>(intakeControllerProvider, (prev, next) {
      _syncControllersWithState(next);
    });

    if (state.status == IntakeStatus.success) {
      return _buildSuccessView(state);
    }

    return Scaffold(
      backgroundColor: AppTokens.base,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header
            _buildSectionHeader('PAGE 1: VEHICLE & CUSTOMER INTAKE', 'STAGE A: FUNCTIONAL INTAKE PIPELINE'),
            const SizedBox(height: 16.0),

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

            // Section 1: Vehicle Identity
            _buildVehicleIdentityCard(state, controller),
            const SizedBox(height: 16.0),

            // Section 1.5: Previous Service History (MG Screenshot pattern)
            if (state.isExistingVehicle && state.previousHistory.isNotEmpty) ...[
              _buildPreviousHistoryCard(state),
              const SizedBox(height: 16.0),
            ],

            // Section 2: Customer Details & WhatsApp Opt-In
            _buildCustomerDetailsCard(state, controller),
            const SizedBox(height: 16.0),

            // Section 3: Odometer & Fuel Level
            _buildOdometerAndFuelCard(state, controller),
            const SizedBox(height: 16.0),

            // Section 4: Requested Work & Delivery Schedule
            _buildRequestedWorkCard(state, controller),
            const SizedBox(height: 16.0),

            // Section 5: Belongings Inventory
            _buildBelongingsCard(state, controller),
            const SizedBox(height: 24.0),

            // Submit Action
            if (state.status == IntakeStatus.saving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: AppTokens.inverse),
                ),
              )
            else
              SharpButton(
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
            const SizedBox(height: 48.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: AppTokens.inverse,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTokens.fontMonospace(
                color: AppTokens.textOnDark,
                fontSize: 14.0,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8.0),
          StatusChip(
            label: subtitle,
            icon: Icons.check_circle_outline,
            type: StatusType.ok,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleIdentityCard(IntakeFormState state, IntakeController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '1. VEHICLE REGISTRATION & IDENTITY',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.0),
              ),
              if (state.isExistingVehicle)
                const StatusChip(
                  label: 'RECOGNISED IN SYSTEM',
                  icon: Icons.verified,
                  type: StatusType.ok,
                ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Registration Number Input
          TextField(
            key: const Key('input_registration'),
            controller: _regController,
            decoration: InputDecoration(
              labelText: 'REGISTRATION NUMBER (RTO FORMAT)',
              hintText: 'e.g. RJ27CA1024 or MH12DE1432',
              errorText: state.errors['registration'],
              filled: true,
              fillColor: AppTokens.raised,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
            style: AppTokens.fontMonospace(fontWeight: FontWeight.bold),
            onChanged: controller.onRegistrationChanged,
          ),
          const SizedBox(height: 12.0),

          // VIN Input
          TextField(
            key: const Key('input_vin'),
            controller: _vinController,
            decoration: InputDecoration(
              labelText: 'VIN / CHASSIS NUMBER (17 CHARACTERS - OPTIONAL)',
              hintText: 'e.g. MA3EWA12S00123456',
              errorText: state.errors['vin'],
              filled: true,
              fillColor: AppTokens.raised,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
            style: AppTokens.fontMonospace(),
            onChanged: controller.onVinChanged,
          ),
          const SizedBox(height: 12.0),

          // Make & Model Row
          Row(
            children: [
              // Make Dropdown
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  key: const Key('dropdown_make'),
                  initialValue: state.make,
                  decoration: const InputDecoration(
                    labelText: 'MAKE',
                    filled: true,
                    fillColor: AppTokens.raised,
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MARUTI SUZUKI', child: Text('MARUTI SUZUKI')),
                    DropdownMenuItem(value: 'HYUNDAI', child: Text('HYUNDAI')),
                    DropdownMenuItem(value: 'TATA', child: Text('TATA')),
                    DropdownMenuItem(value: 'MAHINDRA', child: Text('MAHINDRA')),
                    DropdownMenuItem(value: 'MG MOTOR', child: Text('MG MOTOR')),
                    DropdownMenuItem(value: 'TOYOTA', child: Text('TOYOTA')),
                    DropdownMenuItem(value: 'HONDA', child: Text('HONDA')),
                    DropdownMenuItem(value: 'KIA', child: Text('KIA')),
                    DropdownMenuItem(value: 'VOLKSWAGEN', child: Text('VOLKSWAGEN')),
                    DropdownMenuItem(value: 'SKODA', child: Text('SKODA')),
                    DropdownMenuItem(value: 'OTHER', child: Text('OTHER')),
                  ],
                  onChanged: (v) {
                    if (v != null) controller.onMakeChanged(v);
                  },
                ),
              ),
              const SizedBox(width: 12.0),
              // Model Input
              Expanded(
                flex: 3,
                child: TextField(
                  key: const Key('input_model'),
                  controller: _modelController,
                  decoration: InputDecoration(
                    labelText: 'MODEL & VARIANT',
                    hintText: 'e.g. HECTOR PLUS / CRETA SX',
                    errorText: state.errors['model'],
                    filled: true,
                    fillColor: AppTokens.raised,
                    border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                  ),
                  onChanged: controller.onModelChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Body Type Selection
          const Text('BODY PROFILE SILHOUETTE:', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: VehicleBodyType.values.map((type) {
              final isSelected = state.bodyType == type;
              return InkWell(
                key: Key('body_type_${type.name}'),
                onTap: () => controller.onBodyTypeChanged(type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTokens.inverse : AppTokens.raised,
                    border: Border.all(color: AppTokens.borderSolid, width: 1.0),
                  ),
                  child: Text(
                    type.label,
                    style: TextStyle(
                      color: isSelected ? AppTokens.textOnDark : AppTokens.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
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

  Widget _buildPreviousHistoryCard(IntakeFormState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.raised,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PREVIOUS SERVICE RECORDS (${state.previousHistory.length})',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.0),
              ),
              Text(
                'LAST RECORDED: ${state.lastRecordedKm} KM',
                style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 12.0),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          ...state.previousHistory.map((item) {
            final dateStr = DateFormat('dd MMM yyyy').format(item.serviceDate);
            final amountRupees = (item.totalAmountPaise / 100).toStringAsFixed(2);
            return Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.all(12.0),
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
                        Text('Order: ${item.orderId}', style: AppTokens.fontMonospace(fontWeight: FontWeight.bold)),
                        Text('Date: $dateStr', style: const TextStyle(fontSize: 12.0, color: AppTokens.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${item.odometerKm} KM', style: AppTokens.fontMonospace(fontWeight: FontWeight.bold)),
                      Text('₹$amountRupees', style: AppTokens.fontMonospace(color: AppTokens.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCustomerDetailsCard(IntakeFormState state, IntakeController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '2. CUSTOMER CONTACT & CONSENT',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.0),
              ),
              if (state.isExistingCustomer)
                const StatusChip(
                  label: 'RETURNING CUSTOMER',
                  icon: Icons.person_pin,
                  type: StatusType.ok,
                ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Mobile Phone
          TextField(
            key: const Key('input_phone'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'MOBILE PHONE (+91)',
              hintText: '10 digits e.g. 9829012345',
              errorText: state.errors['phone'],
              filled: true,
              fillColor: AppTokens.raised,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
            style: AppTokens.fontMonospace(),
            onChanged: controller.onPhoneChanged,
          ),
          const SizedBox(height: 12.0),

          // Customer Name
          TextField(
            key: const Key('input_name'),
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'CUSTOMER FULL NAME',
              hintText: 'Enter full name',
              errorText: state.errors['name'],
              filled: true,
              fillColor: AppTokens.raised,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
            onChanged: controller.onNameChanged,
          ),
          const SizedBox(height: 12.0),

          // WhatsApp Consent Checkbox
          _buildCheckboxRow(
            key: const Key('checkbox_whatsapp'),
            label: 'Customer consents to receive Estimates, Digital Passport & Invoices on WhatsApp & SMS',
            value: state.whatsappConsent,
            onChanged: controller.onWhatsappConsentChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildOdometerAndFuelCard(IntakeFormState state, IntakeController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '3. ODOMETER & FUEL LEVEL AT INTAKE',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.0),
          ),
          const SizedBox(height: 12.0),

          // Odometer Reading
          TextField(
            key: const Key('input_odometer'),
            controller: _odometerController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'CURRENT ODOMETER READING (KM)',
              hintText: 'e.g. 28450',
              errorText: state.errors['odometer'],
              filled: true,
              fillColor: AppTokens.raised,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
              suffixText: 'KM',
            ),
            style: AppTokens.fontMonospace(fontWeight: FontWeight.bold),
            onChanged: controller.onOdometerChanged,
          ),
          const SizedBox(height: 16.0),

          // Fuel Level Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FUEL GAUGE READING:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
              Text(
                '${state.fuelLevelPercent}%',
                style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 14.0),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
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
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: isSel ? AppTokens.inverse : AppTokens.raised,
                        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        pct == 0 ? 'EMPTY' : (pct == 100 ? 'FULL' : '$pct%'),
                        style: TextStyle(
                          color: isSel ? AppTokens.textOnDark : AppTokens.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
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

  Widget _buildRequestedWorkCard(IntakeFormState state, IntakeController controller) {
    final deliveryText = state.expectedDelivery != null
        ? DateFormat('EEE, dd MMM yyyy - hh:mm a').format(state.expectedDelivery!)
        : 'SELECT EXPECTED DELIVERY DATE & TIME';

    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '4. REQUESTED WORK & EXPECTED DELIVERY',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.0),
          ),
          const SizedBox(height: 12.0),

          // Requested Work / Complaints
          TextField(
            key: const Key('input_requested_work'),
            controller: _workController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'CUSTOMER COMPLAINTS / REQUESTED SERVICE',
              hintText: 'e.g. Periodic Maintenance Service, Front suspension noise over bumps, AC cooling check',
              errorText: state.errors['requestedWork'],
              filled: true,
              fillColor: AppTokens.raised,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
            onChanged: controller.onRequestedWorkChanged,
          ),
          const SizedBox(height: 12.0),

          // Expected Delivery Date Picker
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
              if (pickedDate != null && mounted) {
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
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: AppTokens.raised,
                border: Border.all(
                  color: state.errors.containsKey('expectedDelivery') ? AppTokens.redOrange : AppTokens.borderSolid,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20.0),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      deliveryText,
                      style: AppTokens.fontMonospace(
                        fontWeight: FontWeight.bold,
                        color: state.expectedDelivery == null ? AppTokens.textSecondary : AppTokens.textPrimary,
                      ),
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
              style: const TextStyle(color: AppTokens.redOrange, fontSize: 12.0),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBelongingsCard(IntakeFormState state, IntakeController controller) {
    final b = state.belongings;
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '5. CUSTOMER BELONGINGS & INVENTORY CHECKLIST',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.0),
          ),
          const SizedBox(height: 8.0),
          _buildCheckboxRow(
            key: const Key('belonging_jack'),
            label: 'Jack & Tool Kit Present',
            value: b.jackAndToolKit,
            onChanged: (v) => controller.onBelongingItemToggled('jackAndToolKit', v),
          ),
          _buildCheckboxRow(
            key: const Key('belonging_tyre'),
            label: 'Spare Tyre / Stepney Present',
            value: b.spareTyre,
            onChanged: (v) => controller.onBelongingItemToggled('spareTyre', v),
          ),
          _buildCheckboxRow(
            key: const Key('belonging_mat'),
            label: 'Boot Mat Present',
            value: b.bootMat,
            onChanged: (v) => controller.onBelongingItemToggled('bootMat', v),
          ),
          _buildCheckboxRow(
            key: const Key('belonging_valuables'),
            label: 'Valuables & Cash Removed by Customer',
            value: b.valuablesRemoved,
            onChanged: (v) => controller.onBelongingItemToggled('valuablesRemoved', v),
          ),
          _buildCheckboxRow(
            key: const Key('belonging_pendrive'),
            label: 'Pen Drive / Dongle / Accessories In-Car',
            value: b.pendriveOrAccessories,
            onChanged: (v) => controller.onBelongingItemToggled('pendriveOrAccessories', v),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxRow({
    required Key key,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      key: key,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 24.0,
              height: 24.0,
              decoration: BoxDecoration(
                color: value ? AppTokens.inverse : AppTokens.raised,
                border: Border.all(color: AppTokens.borderSolid, width: 1.0),
              ),
              child: value
                  ? const Icon(Icons.check, size: 18.0, color: AppTokens.textOnDark)
                  : null,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(IntakeFormState state) {
    return Scaffold(
      backgroundColor: AppTokens.base,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550.0),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppTokens.surface,
            border: Border.all(color: AppTokens.borderSolid, width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StatusChip(
                label: 'VEHICLE INTAKE LOGGED SUCCESSFULLY',
                icon: Icons.check_circle,
                type: StatusType.ok,
              ),
              const SizedBox(height: 16.0),
              Text(
                'JOB CARD CREATED',
                textAlign: TextAlign.center,
                style: AppTokens.fontMonospace(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                color: AppTokens.raised,
                child: SelectableText(
                  state.createdJobCardId ?? 'N/A',
                  textAlign: TextAlign.center,
                  style: AppTokens.fontMonospace(fontSize: 14.0, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Vehicle: ${state.make} ${state.model} (${state.registrationNumber})\nCustomer: ${state.customerName} (${state.customerPhone})\nStatus: RECEIVED (Awaiting Mandatory 6-Shot Bay Capture)',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.0, height: 1.5),
              ),
              const SizedBox(height: 24.0),
              SharpButton(
                key: const Key('btn_advance_capture'),
                label: 'PROCEED TO BAY CAPTURE (6 MANDATORY SHOTS)',
                onPressed: () {
                  context.go('/bay-capture');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
