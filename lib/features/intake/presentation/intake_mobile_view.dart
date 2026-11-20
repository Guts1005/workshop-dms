import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../ui_kit/tokens/app_tokens.dart';
import '../../../ui_kit/widgets/belongings_pills_group.dart';
import '../../../ui_kit/widgets/fuel_intake_slider.dart';
import '../../../ui_kit/widgets/sharp_button.dart';
import '../../../ui_kit/widgets/sharp_card.dart';
import '../../vehicle/indian_number_plate.dart';
import '../models/intake_form_state.dart';
import 'intake_controller.dart';

/// Modern Progressive Step Wizard for Vehicle & Customer Intake (Page 1 Mobile)
/// - Focused one-task-at-a-time screen flow (no long scrolling form)
/// - Background state persistence on step advancement
/// - Zero horizontal scrolling at all costs
/// - Maximum tactile controls (buttons, chips, sliders) over manual typing
class IntakeMobileView extends StatefulWidget {
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
  State<IntakeMobileView> createState() => _IntakeMobileViewState();
}

class _IntakeMobileViewState extends State<IntakeMobileView> {
  int _currentStep = 0; // 0: Vehicle, 1: Customer, 2: Vehicle Status, 3: Scope

  static const List<String> _brands = [
    'MG',
    'Rivian',
    'Hyundai',
    'Tata',
    'Mahindra',
    'Maruti',
    'Toyota',
    'Kia',
    'Other',
  ];

  static const List<String> _servicePresets = [
    'Periodic Maintenance Service',
    'Front & Rear Brake Inspection',
    'AC Disinfection & Filter Clean',
    'Laser Wheel Alignment & Balancing',
    'Suspension & Undercarriage Check',
    'Engine Oil & Filter Change',
  ];

  void _nextStep() {
    if (_currentStep < 3) {
      final error = widget.controller.validateStep(_currentStep);
      if (error != null) return;
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _addServicePreset(String preset) {
    final current = widget.workController.text.trim();
    if (current.isEmpty) {
      widget.workController.text = preset;
    } else if (!current.contains(preset)) {
      widget.workController.text = '$current, $preset';
    }
    widget.controller.onRequestedWorkChanged(widget.workController.text);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTokens.base,
      child: SafeArea(
        child: Column(
          children: [
            // Step Progress Header
            _buildProgressHeader(),

            // Active Step Card (One Screen at a Time)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentStep),
                    child: _buildStepContent(),
                  ),
                ),
              ),
            ),

            // Navigation Button Bar
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  /// Plain application header. Internal form state stays out of the UI.
  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: AppTokens.surface,
        border: Border(
          bottom: BorderSide(color: AppTokens.borderLight, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'New application',
              style: AppTokens.fontBody(
                fontSize: 20.0,
                fontWeight: FontWeight.w800,
              ).copyWith(color: AppTokens.textPrimary),
            ),
          ),
          IconButton(
            tooltip: 'Close application',
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/');
              }
            },
            icon: const Icon(Icons.close, color: AppTokens.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1VehicleIdentity();
      case 1:
        return _buildStep2CustomerDetails();
      case 2:
        return _buildStep3VehicleStatus();
      case 3:
      default:
        return _buildStep4ScopeAndSubmit();
    }
  }

  /// Step 1: Vehicle Registration & Make (Minimal Typing, Mostly Buttons)
  Widget _buildStep1VehicleIdentity() {
    final state = widget.state;
    final isExisting = state.isExistingVehicle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live HSRP Plate Preview
        Center(
          child: IndianNumberPlate(
            registrationNumber: widget.regController.text,
            isCommercial: false,
          ),
        ),
        const SizedBox(height: 14.0),

        SharpCard(
          title: 'VEHICLE DETAILS',
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registration Number',
                style: AppTokens.fontBody(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6.0),
              TextFormField(
                key: const Key('input_registration'),
                controller: widget.regController,
                textCapitalization: TextCapitalization.characters,
                style: AppTokens.fontMonospace(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
                decoration: InputDecoration(
                  hintText: 'RJ 27 CA 1024',
                  hintStyle: AppTokens.fontMonospace(
                    color: AppTokens.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppTokens.surfaceSubtle,
                  border: const OutlineInputBorder(
                    borderRadius: AppTokens.inputRadius,
                    borderSide: BorderSide(color: AppTokens.borderLight),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                  suffixIcon: state.status == IntakeStatus.lookingUp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          ),
                        )
                      : const Icon(
                          Icons.search,
                          color: AppTokens.textSecondary,
                        ),
                ),
                onChanged: widget.controller.onRegistrationChanged,
              ),
              if (state.errors.containsKey('registration')) ...[
                const SizedBox(height: 4.0),
                Text(
                  state.errors['registration']!,
                  style: const TextStyle(
                    color: AppTokens.brandRed,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 14.0),

              // Single-Tap Brand Wordmark Selector
              Text(
                'Vehicle Make / Brand (Single Tap)',
                style: AppTokens.fontBody(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _brands.map((brand) {
                  final isSelected =
                      state.make.toUpperCase() == brand.toUpperCase();
                  return InkWell(
                    onTap: () {
                      widget.controller.onMakeChanged(brand);
                    },
                    borderRadius: AppTokens.pillRadius,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTokens.inverse
                            : AppTokens.surfaceSubtle,
                        borderRadius: AppTokens.pillRadius,
                        border: Border.all(
                          color: isSelected
                              ? AppTokens.inverse
                              : AppTokens.borderLight,
                        ),
                      ),
                      child: Text(
                        brand,
                        style: AppTokens.fontMonospace(
                          fontSize: 12.0,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppTokens.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14.0),

              // Model & Body Type
              Text(
                'Model Specification',
                style: AppTokens.fontBody(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6.0),
              TextFormField(
                key: const Key('input_model'),
                controller: widget.modelController,
                textCapitalization: TextCapitalization.words,
                style: AppTokens.fontBody(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. Hector 2.0 Sharp Pro',
                  filled: true,
                  fillColor: AppTokens.surfaceSubtle,
                  border: OutlineInputBorder(
                    borderRadius: AppTokens.inputRadius,
                    borderSide: BorderSide(color: AppTokens.borderLight),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                ),
                onChanged: widget.controller.onModelChanged,
              ),
              if (state.errors.containsKey('model')) ...[
                const SizedBox(height: 4.0),
                Text(
                  state.errors['model']!,
                  style: const TextStyle(
                    color: AppTokens.brandRed,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Vehicle body type',
                style: AppTokens.fontBody(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<VehicleBodyType>(
                initialValue: state.bodyTypeConfirmed ? state.bodyType : null,
                decoration: const InputDecoration(
                  hintText: 'Select body type',
                  filled: true,
                  fillColor: AppTokens.surfaceSubtle,
                  border: OutlineInputBorder(
                    borderRadius: AppTokens.inputRadius,
                  ),
                ),
                items: VehicleBodyType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (type) {
                  if (type != null) widget.controller.onBodyTypeChanged(type);
                },
              ),
              if (state.errors.containsKey('bodyType')) ...[
                const SizedBox(height: 4),
                Text(
                  state.errors['bodyType']!,
                  style: const TextStyle(
                    color: AppTokens.brandRed,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Recognized Vehicle Card
        if (isExisting) ...[
          const SizedBox(height: 12.0),
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: AppTokens.cardRadius,
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF16A34A),
                  size: 20.0,
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECOGNIZED IN SYSTEM',
                        style: AppTokens.fontMonospace(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                      Text(
                        '${state.make} ${state.model} • Last Service: ${state.lastRecordedKm ?? 0} KM',
                        style: AppTokens.fontBody(
                          fontSize: 11.5,
                          color: const Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Step 2: Customer Contact & WhatsApp Opt-In
  Widget _buildStep2CustomerDetails() {
    final state = widget.state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SharpCard(
          title: 'CUSTOMER DETAILS',
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mobile Phone Number (Primary Key)',
                style: AppTokens.fontBody(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6.0),
              TextFormField(
                key: const Key('input_phone'),
                controller: widget.phoneController,
                keyboardType: TextInputType.phone,
                style: AppTokens.fontMonospace(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  prefixText: '+91 ',
                  prefixStyle: AppTokens.fontMonospace(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w800,
                  ),
                  hintText: '98290 12345',
                  filled: true,
                  fillColor: AppTokens.surfaceSubtle,
                  border: const OutlineInputBorder(
                    borderRadius: AppTokens.inputRadius,
                    borderSide: BorderSide(color: AppTokens.borderLight),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                ),
                onChanged: widget.controller.onPhoneChanged,
              ),
              if (state.errors.containsKey('phone')) ...[
                const SizedBox(height: 4.0),
                Text(
                  state.errors['phone']!,
                  style: const TextStyle(
                    color: AppTokens.brandRed,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 14.0),

              Text(
                'Customer Full Name',
                style: AppTokens.fontBody(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6.0),
              TextFormField(
                key: const Key('input_name'),
                controller: widget.nameController,
                textCapitalization: TextCapitalization.words,
                style: AppTokens.fontBody(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. Vikram Singhal',
                  filled: true,
                  fillColor: AppTokens.surfaceSubtle,
                  border: OutlineInputBorder(
                    borderRadius: AppTokens.inputRadius,
                    borderSide: BorderSide(color: AppTokens.borderLight),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                ),
                onChanged: widget.controller.onNameChanged,
              ),
              if (state.errors.containsKey('name')) ...[
                const SizedBox(height: 4.0),
                Text(
                  state.errors['name']!,
                  style: const TextStyle(
                    color: AppTokens.brandRed,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 16.0),

              // WhatsApp Consent Switch
              InkWell(
                onTap: () => widget.controller.onWhatsappConsentChanged(
                  !state.whatsappConsent,
                ),
                borderRadius: AppTokens.cardRadius,
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: state.whatsappConsent
                        ? const Color(0xFFF0FDF4)
                        : AppTokens.surfaceSubtle,
                    borderRadius: AppTokens.cardRadius,
                    border: Border.all(
                      color: state.whatsappConsent
                          ? const Color(0xFFBBF7D0)
                          : AppTokens.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.whatsappConsent
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        color: state.whatsappConsent
                            ? const Color(0xFF16A34A)
                            : AppTokens.textSecondary,
                        size: 20.0,
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WhatsApp Job Card & Status Updates',
                              style: AppTokens.fontBody(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: state.whatsappConsent
                                    ? const Color(0xFF15803D)
                                    : AppTokens.textPrimary,
                              ),
                            ),
                            Text(
                              'Instant per-line estimate approval via WhatsApp template',
                              style: AppTokens.fontBody(
                                fontSize: 11.0,
                                color: state.whatsappConsent
                                    ? const Color(0xFF166534)
                                    : AppTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Step 3: Vehicle Status (Odometer + Fuel Slider + Belongings Pills)
  Widget _buildStep3VehicleStatus() {
    final state = widget.state;
    final lastKm = state.lastRecordedKm;
    final currentOdo = int.tryParse(widget.odometerController.text);
    final isRollback =
        lastKm != null && currentOdo != null && currentOdo < lastKm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Odometer Card
        SharpCard(
          title: 'VEHICLE CONDITION',
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Odometer Reading (KM)',
                style: AppTokens.fontBody(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6.0),
              TextFormField(
                key: const Key('input_odometer'),
                controller: widget.odometerController,
                keyboardType: TextInputType.number,
                style: AppTokens.fontMonospace(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  suffixText: 'KM',
                  suffixStyle: AppTokens.fontMonospace(
                    fontWeight: FontWeight.w900,
                  ),
                  hintText: '35000',
                  filled: true,
                  fillColor: AppTokens.surfaceSubtle,
                  border: const OutlineInputBorder(
                    borderRadius: AppTokens.inputRadius,
                    borderSide: BorderSide(color: AppTokens.borderLight),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                ),
                onChanged: widget.controller.onOdometerChanged,
              ),
              if (isRollback) ...[
                const SizedBox(height: 6.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: AppTokens.brandRed),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16.0,
                        color: AppTokens.brandRed,
                      ),
                      const SizedBox(width: 6.0),
                      Expanded(
                        child: Text(
                          'ROLLBACK ALERT: Entered ($currentOdo KM) is lower than last visit ($lastKm KM)',
                          style: AppTokens.fontMonospace(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.brandRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (state.errors.containsKey('odometer')) ...[
                const SizedBox(height: 4.0),
                Text(
                  state.errors['odometer']!,
                  style: const TextStyle(
                    color: AppTokens.brandRed,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14.0),

        // Fuel Slider (Zero Typing)
        FuelIntakeSlider(
          value: state.fuelLevelPercent / 100.0,
          isConfirmed: state.fuelLevelConfirmed,
          onChanged: (val) {
            widget.controller.onFuelLevelChanged((val * 100).round());
          },
        ),
        Material(
          color: Colors.transparent,
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: state.fuelLevelConfirmed,
            activeColor: AppTokens.inverse,
            title: const Text('Fuel level checked at the vehicle'),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (checked) {
              widget.controller.onFuelLevelConfirmationChanged(
                checked ?? false,
              );
            },
          ),
        ),
        if (state.errors.containsKey('fuelLevel'))
          Text(
            state.errors['fuelLevel']!,
            style: const TextStyle(
              color: AppTokens.brandRed,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: 14.0),

        // Belongings Quick-Toggles (Zero Typing)
        BelongingsPillsGroup(
          selectedItems: {
            if (state.belongings.spareTyre) 'Spare Wheel',
            if (state.belongings.jackAndToolKit) 'Jack & Toolkit',
            if (state.belongings.bootMat) 'Floor Mats & Boot Tray',
            if (state.belongings.valuablesRemoved) 'Fastag',
            if (state.belongings.pendriveOrAccessories) 'Dashcam & SD Card',
          },
          onChanged: (updated) {
            widget.controller.onBelongingsChanged(
              state.belongings.copyWith(
                spareTyre: updated.contains('Spare Wheel'),
                jackAndToolKit: updated.contains('Jack & Toolkit'),
                bootMat: updated.contains('Floor Mats & Boot Tray'),
                valuablesRemoved: updated.contains('Fastag'),
                pendriveOrAccessories: updated.contains('Dashcam & SD Card'),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Step 4: Scope of Work & Expected Delivery Date
  Widget _buildStep4ScopeAndSubmit() {
    final state = widget.state;
    final deliveryText = state.expectedDelivery != null
        ? DateFormat('EEE, dd MMM yyyy - hh:mm a')
              .format(state.expectedDelivery!)
        : 'SELECT EXPECTED DELIVERY DATE & TIME';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SharpCard(
          title: 'REQUESTED SERVICE',
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Single-Tap Common Service Presets',
                style: AppTokens.fontBody(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _servicePresets.map((preset) {
                  return InkWell(
                    onTap: () => _addServicePreset(preset),
                    borderRadius: AppTokens.pillRadius,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppTokens.surfaceSubtle,
                        borderRadius: AppTokens.pillRadius,
                        border: Border.all(color: AppTokens.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add,
                            size: 12.0,
                            color: AppTokens.textPrimary,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            preset,
                            style: AppTokens.fontBody(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                              color: AppTokens.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14.0),

              Text(
                'Requested Work & Observations',
                style: AppTokens.fontBody(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6.0),
              TextFormField(
                key: const Key('input_requested_work'),
                controller: widget.workController,
                maxLines: 3,
                style: AppTokens.fontBody(fontSize: 13.0),
                decoration: const InputDecoration(
                  hintText:
                      'Enter specific diagnostic concerns or customer notes...',
                  filled: true,
                  fillColor: AppTokens.surfaceSubtle,
                  border: OutlineInputBorder(
                    borderRadius: AppTokens.inputRadius,
                    borderSide: BorderSide(color: AppTokens.borderLight),
                  ),
                  contentPadding: EdgeInsets.all(12.0),
                ),
                onChanged: widget.controller.onRequestedWorkChanged,
              ),
              if (state.errors.containsKey('requestedWork')) ...[
                const SizedBox(height: 4.0),
                Text(
                  state.errors['requestedWork']!,
                  style: const TextStyle(
                    color: AppTokens.brandRed,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 14.0),

              // Expected Delivery Date-Time
              Text(
                'Committed Target Delivery Date',
                style: AppTokens.fontBody(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6.0),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate:
                        state.expectedDelivery ??
                        now.add(const Duration(days: 1)),
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 90)),
                  );
                  if (pickedDate != null && mounted) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 17, minute: 0),
                    );
                    if (pickedTime != null && mounted) {
                      final combined = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                      widget.controller.onExpectedDeliveryChanged(combined);
                    }
                  }
                },
                borderRadius: AppTokens.inputRadius,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.surfaceSubtle,
                    borderRadius: AppTokens.inputRadius,
                    border: Border.all(color: AppTokens.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_available_rounded,
                        size: 18.0,
                        color: AppTokens.textPrimary,
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          deliveryText,
                          style: AppTokens.fontMonospace(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: state.expectedDelivery != null
                                ? AppTokens.textPrimary
                                : AppTokens.textTertiary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: AppTokens.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Fixed Bottom Nav Bar (No Horizontal Scroll, High Touch Targets)
  Widget _buildBottomNav() {
    final state = widget.state;
    final isLastStep = _currentStep == 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTokens.borderLight, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTokens.textPrimary,
                side: const BorderSide(color: AppTokens.borderSolid),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppTokens.buttonRadius,
                ),
              ),
              child: const Text(
                '← BACK',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12.0),
          ],
          Expanded(
            child: SharpButton(
              label: isLastStep
                  ? (state.status == IntakeStatus.saving
                        ? 'GENERATING JOB CARD...'
                        : 'GENERATE INTAKE & PROCEED TO BAY CHECK-IN')
                  : 'CONTINUE →',
              icon: isLastStep
                  ? Icons.check_circle_outline
                  : Icons.arrow_forward_rounded,
              onPressed: state.status == IntakeStatus.saving
                  ? null
                  : (isLastStep ? widget.controller.submitIntake : _nextStep),
              height: 48.0,
            ),
          ),
        ],
      ),
    );
  }
}
