import 'package:flutter/material.dart';
import 'core/theme/tokens.dart';
import 'core/widgets/sharp_button.dart';
import 'core/widgets/sharp_card.dart';
import 'core/widgets/status_chip.dart';
import 'core/widgets/sharp_text_field.dart';
import 'features/vehicle/vehicle_silhouettes.dart';
import 'features/vehicle/make_wordmark_chip.dart';
import 'features/condition_map/condition_map_widget.dart';
import 'features/bay_capture/bay_capture_models.dart';
import 'features/billing/gst_engine.dart';
import 'features/reminders/service_reminder_engine.dart';
import 'features/passport/digital_health_passport_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WorkshopDmsApp());
}

class WorkshopDmsApp extends StatelessWidget {
  const WorkshopDmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workshop DMS - Digital Health Passport',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppTokens.base,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.light(
          primary: AppTokens.inverse,
          surface: AppTokens.surface,
        ),
      ),
      home: const WorkshopHomeScreen(),
    );
  }
}

class WorkshopHomeScreen extends StatefulWidget {
  const WorkshopHomeScreen({super.key});

  @override
  State<WorkshopHomeScreen> createState() => _WorkshopHomeScreenState();
}

class _WorkshopHomeScreenState extends State<WorkshopHomeScreen> {
  int _selectedTabIndex = 0;

  // State: Vehicle Intake & Identity
  String _selectedMake = 'MG MOTOR';
  final VehicleBodyType _selectedBodyType = VehicleBodyType.midFullSuv;
  final _regNumberController = TextEditingController(text: 'RJ 27 CA 1024');
  final _modelController = TextEditingController(text: 'MG HECTOR PLUS');
  final _customerNameController = TextEditingController(text: 'BHAVYAM SHARMA');
  final _phoneController = TextEditingController(text: '9876543210');
  final _odometerController = TextEditingController(text: '27227');

  // State: 360 Condition Map Pins
  final List<DamagePin> _conditionPins = [
    const DamagePin(
      id: 1,
      view: ConditionView.side,
      relativePosition: Offset(0.35, 0.60),
      type: DefectType.dent,
      severity: DefectSeverity.minor,
      note: 'Driver door bottom crease',
    ),
    const DamagePin(
      id: 2,
      view: ConditionView.front,
      relativePosition: Offset(0.24, 0.46),
      type: DefectType.surfaceScuff,
      severity: DefectSeverity.minor,
      note: 'Left bumper edge scuff',
    ),
  ];

  // State: Bay Check-in Photos
  final Map<CheckInShotType, bool> _bayShotsCaptured = {
    CheckInShotType.frontLeft45: true,
    CheckInShotType.frontRight45: true,
    CheckInShotType.rearLeft45: true,
    CheckInShotType.rearRight45: true,
    CheckInShotType.plateCloseup: true,
    CheckInShotType.odometerReading: true,
  };

  // State: Invoicing Items
  final List<InvoiceLineItem> _invoiceItems = [
    const InvoiceLineItem(
      id: '1',
      type: LineItemType.part,
      description: 'Fully Synthetic Engine Oil 5W30 (5L)',
      code: '27101980',
      quantity: 1,
      unitRatePaise: 380000,
      gstRatePercent: 18,
    ),
    const InvoiceLineItem(
      id: '2',
      type: LineItemType.part,
      description: 'OEM Oil Filter Cartridge',
      code: '84212300',
      quantity: 1,
      unitRatePaise: 45000,
      gstRatePercent: 18,
    ),
    const InvoiceLineItem(
      id: '3',
      type: LineItemType.labour,
      description: 'PMS General Periodic Service & 50-Point Inspection',
      code: '998729',
      quantity: 1,
      unitRatePaise: 220000,
      gstRatePercent: 18,
    ),
    const InvoiceLineItem(
      id: '4',
      type: LineItemType.labour,
      description: 'Brake Caliper Pin Cleaning & Greasing',
      code: '998729',
      quantity: 1,
      unitRatePaise: 65000,
      gstRatePercent: 18,
    ),
  ];

  int _advancePaidPaise = 200000; // ₹2,000.00 advance
  String _jobCardStatus = 'WORK IN PROGRESS';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(),
            _buildNavigationTabs(),
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  _buildIntakeScreen(),
                  _buildConditionMapScreen(),
                  _buildJobCardPipelineScreen(),
                  _buildBillingScreen(),
                  _buildPassportScreen(),
                  _buildRemindersScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      height: 56.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      color: AppTokens.inverse,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.build_circle_sharp, color: AppTokens.textOnDark, size: 24.0),
            const SizedBox(width: 10.0),
            const Text(
              'SPEEDCRAFT WORKSHOP DMS',
              style: TextStyle(
                color: AppTokens.textOnDark,
                fontSize: 16.0,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 24.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              color: AppTokens.surface,
              child: const Text(
                'LIVE BAY: ACTIVE',
                style: TextStyle(
                  color: AppTokens.textPrimary,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            const StatusChip(
              label: 'SYNCED (OFFLINE FIRST)',
              icon: Icons.cloud_done,
              type: StatusType.ok,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTabs() {
    final tabs = [
      '1. INTAKE & 6-SHOTS',
      '2. 360° CONDITION',
      '3. LIVE STATUS',
      '4. GST BILLING',
      '5. HEALTH PASSPORT',
      '6. SERVICE REMINDERS',
    ];

    return Container(
      height: 48.0,
      color: AppTokens.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, i) {
          final isActive = _selectedTabIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: isActive ? AppTokens.raised : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppTokens.redOrange : AppTokens.borderSolid,
                    width: isActive ? 4.0 : 1.0,
                  ),
                  right: const BorderSide(color: AppTokens.borderSolid, width: 1.0),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                tabs[i],
                style: TextStyle(
                  color: isActive ? AppTokens.redOrange : AppTokens.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.0,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- TAB 1: INTAKE & 6-SHOTS ---
  Widget _buildIntakeScreen() {
    final completedShots = _bayShotsCaptured.values.where((v) => v).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SharpCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STEP 1: VEHICLE REGISTRATION & DETAILS',
                        style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12.0),
                      Row(
                        children: [
                          Expanded(
                            child: SharpTextField(
                              label: 'REGISTRATION NUMBER',
                              controller: _regNumberController,
                              isMonospace: true,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: SharpTextField(
                              label: 'CURRENT ODOMETER (KM)',
                              controller: _odometerController,
                              keyboardType: TextInputType.number,
                              isMonospace: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Row(
                        children: [
                          Expanded(
                            child: SharpTextField(
                              label: 'CUSTOMER FULL NAME',
                              controller: _customerNameController,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: SharpTextField(
                              label: 'WHATSAPP MOBILE NUMBER',
                              controller: _phoneController,
                              prefixText: '+91',
                              keyboardType: TextInputType.phone,
                              isMonospace: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'MANUFACTURER (SELECT WORDMARK):',
                        style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, color: AppTokens.textSecondary),
                      ),
                      const SizedBox(height: 8.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: kIndianVehicleMakes.take(8).map((make) {
                          return MakeWordmarkChip(
                            make: make,
                            isSelected: _selectedMake == make,
                            onTap: () => setState(() => _selectedMake = make),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                flex: 2,
                child: SharpCard(
                  backgroundColor: AppTokens.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'BAY CAMERA EVIDENCE (6 SHOTS)',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            '$completedShots / 6',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                              color: completedShots == 6 ? AppTokens.green : AppTokens.redOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        'OPERATIONAL GATE: Job Card cannot open until all 6 shots are logged with SHA-256 integrity hashes.',
                        style: TextStyle(fontSize: 11.0, color: AppTokens.textSecondary),
                      ),
                      const SizedBox(height: 12.0),
                      ...CheckInShotType.values.take(6).map((shot) {
                        final isDone = _bayShotsCaptured[shot] ?? false;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6.0),
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                          color: AppTokens.raised,
                          child: Row(
                            children: [
                              Icon(
                                isDone ? Icons.check_box : Icons.check_box_outline_blank,
                                color: isDone ? AppTokens.green : AppTokens.redOrange,
                                size: 18.0,
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  shot.title,
                                  style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (isDone)
                                const Text(
                                  'SHA-256 OK',
                                  style: TextStyle(fontSize: 9.0, fontFamily: 'monospace', color: AppTokens.textSecondary),
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12.0),
                      SharpButton(
                        label: 'TRIGGER REAR BAY CAMERA',
                        icon: Icons.camera_alt,
                        width: double.infinity,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Rear Camera Shutter Activated with 45° Wireframe Overlay')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 2: 360 CONDITION MAP ---
  Widget _buildConditionMapScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ConditionMapWidget(
                  pins: _conditionPins,
                  onPinAdded: (pin) {
                    setState(() => _conditionPins.add(pin));
                  },
                ),
              ),
              const SizedBox(width: 16.0),
              SizedBox(
                width: 320.0,
                child: SharpCard(
                  backgroundColor: AppTokens.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LOGGED DEFECT PINS',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.0),
                      ),
                      const SizedBox(height: 8.0),
                      ..._conditionPins.map((pin) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.all(8.0),
                          color: AppTokens.raised,
                          child: Row(
                            children: [
                              Container(
                                width: 24.0,
                                height: 24.0,
                                color: AppTokens.redOrange,
                                alignment: Alignment.center,
                                child: Text(
                                  '${pin.id}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pin.type.label,
                                      style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.w800),
                                    ),
                                    Text(
                                      pin.severity.label,
                                      style: const TextStyle(fontSize: 10.0, color: AppTokens.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12.0),
                      SharpButton(
                        label: 'GENERATE PRE-WORK SIGN-OFF',
                        variant: SharpButtonVariant.secondary,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 3: LIVE STATUS PIPELINE ---
  Widget _buildJobCardPipelineScreen() {
    final stages = [
      'VEHICLE RECEIVED',
      'INSPECTION PENDING',
      'ESTIMATE SENT',
      'WORK IN PROGRESS',
      'DELIVERED',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SharpCard(
            backgroundColor: AppTokens.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('5-STAGE LIVE WORKSHOP PIPELINE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.0)),
                const SizedBox(height: 12.0),
                Row(
                  children: stages.map((stage) {
                    final isActive = _jobCardStatus == stage;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _jobCardStatus = stage),
                        child: Container(
                          height: 48.0,
                          margin: const EdgeInsets.only(right: 6.0),
                          decoration: BoxDecoration(
                            color: isActive ? AppTokens.inverse : AppTokens.raised,
                            border: Border.all(color: AppTokens.borderSolid, width: 1.0),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            stage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isActive ? AppTokens.textOnDark : AppTokens.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 4: GST BILLING & PAYMENT GATE ---
  Widget _buildBillingScreen() {
    final taxSummary = AutomotiveGstEngine.calculate(
      items: _invoiceItems,
      isIntraState: true,
      totalPaidPaise: _advancePaidPaise,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Line Item Table
          Expanded(
            flex: 3,
            child: SharpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AUTOMOTIVE GST INVOICE BREAKDOWN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.0)),
                  const SizedBox(height: 12.0),
                  Table(
                    border: TableBorder.all(color: AppTokens.borderSolid, width: 1.0),
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: AppTokens.surface),
                        children: [
                          Padding(padding: EdgeInsets.all(8.0), child: Text('ITEM / LABOUR', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.0))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('HSN/SAC', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.0))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('QTY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.0))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('RATE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.0))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('GST %', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.0))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.0))),
                        ],
                      ),
                      ..._invoiceItems.map((item) {
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(8.0), child: Text(item.description, style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600))),
                            Padding(padding: const EdgeInsets.all(8.0), child: Text(item.code, style: const TextStyle(fontSize: 11.0, fontFamily: 'monospace'))),
                            Padding(padding: const EdgeInsets.all(8.0), child: Text('${item.quantity}', style: const TextStyle(fontSize: 12.0))),
                            Padding(padding: const EdgeInsets.all(8.0), child: Text(AutomotiveGstEngine.formatRupees(item.unitRatePaise), style: const TextStyle(fontSize: 11.0, fontFamily: 'monospace'))),
                            Padding(padding: const EdgeInsets.all(8.0), child: Text('${item.gstRatePercent}%', style: const TextStyle(fontSize: 11.0))),
                            Padding(padding: const EdgeInsets.all(8.0), child: Text(AutomotiveGstEngine.formatRupees(item.totalAmountPaise), style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16.0),

          // Right: Strict Payment Gate
          Expanded(
            flex: 2,
            child: SharpCard(
              backgroundColor: AppTokens.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('STRICT PAYMENT GATE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.0)),
                  const SizedBox(height: 12.0),
                  _buildFinancialRow('TAXABLE AMOUNT:', AutomotiveGstEngine.formatRupees(taxSummary.totalTaxablePaise)),
                  _buildFinancialRow('CGST (9%):', AutomotiveGstEngine.formatRupees(taxSummary.cgstAmountPaise)),
                  _buildFinancialRow('SGST (9%):', AutomotiveGstEngine.formatRupees(taxSummary.sgstAmountPaise)),
                  const Divider(color: AppTokens.borderSolid, thickness: 1.0),
                  _buildFinancialRow('GRAND TOTAL (INCL. GST):', AutomotiveGstEngine.formatRupees(taxSummary.grandTotalPaise), isBold: true),
                  _buildFinancialRow('ADVANCE PAID:', AutomotiveGstEngine.formatRupees(taxSummary.totalPaidPaise)),
                  _buildFinancialRow(
                    'BALANCE DUE:',
                    AutomotiveGstEngine.formatRupees(taxSummary.balanceDuePaise),
                    isBold: true,
                    color: taxSummary.balanceDuePaise > 0 ? AppTokens.redOrange : AppTokens.green,
                  ),
                  const SizedBox(height: 16.0),
                  SharpButton(
                    label: 'RECORD PAYMENT (UPI / CASH)',
                    icon: Icons.payments,
                    onPressed: () {
                      setState(() => _advancePaidPaise = taxSummary.grandTotalPaise);
                    },
                  ),
                  const SizedBox(height: 8.0),
                  SharpButton(
                    label: 'MARK AS DELIVERED',
                    variant: SharpButtonVariant.destructive,
                    onPressed: () {
                      if (taxSummary.balanceDuePaise > 0) {
                        _showPaymentGateBlockDialog(context, taxSummary.balanceDuePaise);
                      } else {
                        setState(() => _jobCardStatus = 'DELIVERED');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vehicle Delivered. Keys Released.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String title, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 12.0, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.0,
              fontFamily: 'monospace',
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: color ?? AppTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentGateBlockDialog(BuildContext context, int balancePaise) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTokens.raised,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Container(
            padding: const EdgeInsets.all(12.0),
            color: AppTokens.redOrange,
            child: const Text('⚠️ DELIVERY BLOCKED: UNPAID BALANCE', style: TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.w900)),
          ),
          titlePadding: EdgeInsets.zero,
          content: Text(
            'Vehicle cannot be marked as Delivered while an outstanding balance of ${AutomotiveGstEngine.formatRupees(balancePaise)} exists.\n\nCollect full payment or enter Credit Override approval.',
            style: const TextStyle(fontSize: 13.0),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTokens.inverse, foregroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _jobCardStatus = 'DELIVERED');
              },
              child: const Text('APPROVE CREDIT OVERRIDE'),
            ),
          ],
        );
      },
    );
  }

  // --- TAB 5: HEALTH PASSPORT ---
  Widget _buildPassportScreen() {
    final sampleHistory = [
      ServiceHistoryEntry(
        orderId: 'N330302623',
        serviceType: 'Preventive Maintenance-Paid Service (PMS)',
        workshopName: 'MG Udaipur',
        serviceDate: DateTime(2026, 6, 18),
        odometerKm: 27227,
        previousOdometerKm: 23279,
        daysSincePrevious: 78,
        totalAmountPaise: 747672,
      ),
      ServiceHistoryEntry(
        orderId: 'N330301684',
        serviceType: 'General Repair & Suspension Check',
        workshopName: 'MG Udaipur',
        serviceDate: DateTime(2026, 3, 31),
        odometerKm: 23279,
        previousOdometerKm: 20711,
        daysSincePrevious: 51,
        totalAmountPaise: 0,
      ),
      ServiceHistoryEntry(
        orderId: 'N330301285',
        serviceType: 'Preventive Maintenance-Paid Service (PMS)',
        workshopName: 'MG Udaipur',
        serviceDate: DateTime(2026, 2, 9),
        odometerKm: 20711,
        totalAmountPaise: 924582,
      ),
    ];

    return DigitalHealthPassportWidget(
      vehicleModel: _modelController.text,
      registrationNumber: _regNumberController.text,
      bodyType: _selectedBodyType,
      serviceHistory: sampleHistory,
      onDownloadPdf: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating GST Invoice PDF...')),
        );
      },
    );
  }

  // --- TAB 6: SERVICE REMINDERS ---
  Widget _buildRemindersScreen() {
    final reminder = ServiceReminderEngine.evaluate(
      customerName: _customerNameController.text,
      mobileNumber: _phoneController.text,
      vehicleModel: _modelController.text,
      registrationNumber: _regNumberController.text,
      lastServiceDate: DateTime(2026, 6, 18),
      lastServiceOdometerKm: 27227,
      previousServiceDate: DateTime(2026, 3, 31),
      previousServiceOdometerKm: 23279,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SharpCard(
            backgroundColor: AppTokens.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DUAL-TRIGGER SERVICE REMINDERS (TIME VS. MILEAGE)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.0)),
                const SizedBox(height: 8.0),
                const Text('Calculates daily driving rate from past visit intervals to predict when 10,000 KM threshold will be crossed.', style: TextStyle(fontSize: 11.0, color: AppTokens.textSecondary)),
                const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  color: AppTokens.raised,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(reminder.customerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.0)),
                          Text('${reminder.vehicleModel} • ${reminder.registrationNumber}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12.0, color: AppTokens.textSecondary)),
                        ],
                      ),
                      const Spacer(),
                      StatusChip(
                        label: reminder.isOverdue ? 'OVERDUE' : (reminder.isDueSoon ? 'DUE SOON' : 'UPCOMING'),
                        icon: Icons.calendar_month,
                        type: reminder.isOverdue ? StatusType.critical : (reminder.isDueSoon ? StatusType.dueSoon : StatusType.ok),
                      ),
                      const SizedBox(width: 16.0),
                      SharpButton(
                        label: 'SEND WHATSAPP ALERT',
                        icon: Icons.send,
                        onPressed: () {
                          final url = reminder.buildWhatsAppUrl(
                            workshopName: 'SPEEDCRAFT MOTORS',
                            workshopPhone: '+91-98765-43210',
                            workshopAddress: 'Plot 42, Auto Zone, Udaipur',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('WhatsApp click-to-chat triggered: $url')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
