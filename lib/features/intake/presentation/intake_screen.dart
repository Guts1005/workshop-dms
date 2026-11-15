import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../ui_kit/tokens/app_tokens.dart';
import '../../../ui_kit/widgets/sharp_button.dart';
import '../../../ui_kit/widgets/status_chip.dart';
import '../../vehicle/indian_number_plate.dart';
import '../models/intake_form_state.dart';
import 'intake_controller.dart';
import 'intake_desktop_view.dart';
import 'intake_mobile_view.dart';

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

    ref.listen<IntakeFormState>(intakeControllerProvider, (prev, next) {
      _syncControllersWithState(next);
    });

    if (state.status == IntakeStatus.success) {
      return _buildSuccessView(state);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Strict boundary: Desktop/Tablet (>= 900px) vs Mobile Phone (< 900px)
        final isMobile = constraints.maxWidth < 900.0;

        if (isMobile) {
          return IntakeMobileView(
            state: state,
            controller: controller,
            regController: _regController,
            vinController: _vinController,
            modelController: _modelController,
            nameController: _nameController,
            phoneController: _phoneController,
            odometerController: _odometerController,
            workController: _workController,
          );
        }

        return Scaffold(
          backgroundColor: AppTokens.base,
          body: IntakeDesktopView(
            state: state,
            controller: controller,
            regController: _regController,
            vinController: _vinController,
            modelController: _modelController,
            nameController: _nameController,
            phoneController: _phoneController,
            odometerController: _odometerController,
            workController: _workController,
          ),
        );
      },
    );
  }

  Widget _buildSuccessView(IntakeFormState state) {
    return Scaffold(
      backgroundColor: AppTokens.base,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550.0),
          padding: const EdgeInsets.all(28.0),
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
              const SizedBox(height: 20.0),
              Center(
                child: IndianNumberPlate(
                  registrationNumber: state.registrationNumber,
                  height: 48.0,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'JOB CARD CREATED',
                textAlign: TextAlign.center,
                style: AppTokens.fontMonospace(fontSize: 15.0, fontWeight: FontWeight.bold),
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
                'Vehicle: ${state.make} ${state.model}\nCustomer: ${state.customerName} (${state.customerPhone})\nStatus: RECEIVED (Awaiting Mandatory 6-Shot Bay Capture)',
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
