import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../ui_kit/tokens/app_tokens.dart';
import '../../../ui_kit/widgets/sharp_button.dart';
import '../../../ui_kit/widgets/sharp_card.dart';
import '../../../ui_kit/widgets/status_chip.dart';
import '../../billing/gst_engine.dart';
import '../../vehicle/indian_number_plate.dart';

/// Complete, Production-Grade Job Card & Estimate Builder Screen (Page 5)
/// Matches luxury Rivian + MG i-SMART automotive styling:
/// Luminous canvas, modular Bento grid, SAC 998729 labour billing, HSN automotive parts,
/// integer-paise GST computation, and WhatsApp digital dispatch.
class JobCardScreen extends StatefulWidget {
  final String? jobCardId;
  final String? registrationNumber;

  const JobCardScreen({
    super.key,
    this.jobCardId,
    this.registrationNumber,
  });

  @override
  State<JobCardScreen> createState() => _JobCardScreenState();
}

class _JobCardScreenState extends State<JobCardScreen> {
  late String _regNumber;
  late String _jobCardId;
  bool _isDispatched = false;
  bool _isApproved = false;

  // Pre-loaded realistic automotive labour lines (SAC 998729 - 18% GST)
  final List<InvoiceLineItem> _labourItems = [
    const InvoiceLineItem(
      id: 'L-01',
      type: LineItemType.labour,
      description: 'Comprehensive Periodic Maintenance Service (General Check-up & Fluids)',
      code: 'SAC 998729',
      quantity: 1,
      unitRatePaise: 120000, // ₹1,200.00
      gstRatePercent: 18,
    ),
    const InvoiceLineItem(
      id: 'L-02',
      type: LineItemType.labour,
      description: 'Front Brake Caliper Overhaul & Disc Pad Replacement',
      code: 'SAC 998729',
      quantity: 1,
      unitRatePaise: 65000, // ₹650.00
      gstRatePercent: 18,
    ),
    const InvoiceLineItem(
      id: 'L-03',
      type: LineItemType.labour,
      description: 'Air Conditioning System Inspection, Evaporator Disinfection & Filter Clean',
      code: 'SAC 998729',
      quantity: 1,
      unitRatePaise: 55000, // ₹550.00
      gstRatePercent: 18,
    ),
    const InvoiceLineItem(
      id: 'L-04',
      type: LineItemType.labour,
      description: '4-Wheel Computerized Laser Alignment & Dynamic Wheel Balancing',
      code: 'SAC 998729',
      quantity: 1,
      unitRatePaise: 80000, // ₹800.00
      gstRatePercent: 18,
    ),
  ];

  // Pre-loaded realistic automotive OEM parts lines (HSN Codes - 18% / 28% GST)
  final List<InvoiceLineItem> _partsItems = [
    const InvoiceLineItem(
      id: 'P-01',
      type: LineItemType.part,
      description: 'Mobil 1 ESP 5W-30 Fully Synthetic Engine Oil (3.5 Litres Pack)',
      code: 'HSN 2710',
      quantity: 1,
      unitRatePaise: 285000, // ₹2,850.00
      gstRatePercent: 18,
    ),
    const InvoiceLineItem(
      id: 'P-02',
      type: LineItemType.part,
      description: 'OEM Spin-on High Efficiency Lubricating Oil Filter',
      code: 'HSN 8421',
      quantity: 1,
      unitRatePaise: 48000, // ₹480.00
      gstRatePercent: 18,
    ),
    const InvoiceLineItem(
      id: 'P-03',
      type: LineItemType.part,
      description: 'MG OEM Heavy-Duty Front Ceramic Brake Pads Set',
      code: 'HSN 8708',
      quantity: 1,
      unitRatePaise: 320000, // ₹3,200.00
      gstRatePercent: 28, // 28% GST on brake friction components
    ),
    const InvoiceLineItem(
      id: 'P-04',
      type: LineItemType.part,
      description: 'Engine Air Intake Filter Cartridge (Multi-Layer Pleated)',
      code: 'HSN 8421',
      quantity: 1,
      unitRatePaise: 62000, // ₹620.00
      gstRatePercent: 18,
    ),
    const InvoiceLineItem(
      id: 'P-05',
      type: LineItemType.part,
      description: 'Pre-mixed OAT Long-Life Engine Coolant (1 Litre)',
      code: 'HSN 3820',
      quantity: 1,
      unitRatePaise: 32000, // ₹320.00
      gstRatePercent: 18,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _regNumber = widget.registrationNumber ?? 'RJ27CA1024';
    _jobCardId = widget.jobCardId ?? 'JC-2026-0849';
  }

  InvoiceTaxSummary _computeSummary() {
    final allItems = [..._labourItems, ..._partsItems];
    return AutomotiveGstEngine.calculate(
      items: allItems,
      isIntraState: true,
      totalPaidPaise: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900.0;
    final summary = _computeSummary();
    final grandTotalRupees = (summary.grandTotalPaise / 100).toStringAsFixed(2);
    final taxableLabourRupees = (summary.totalLabourTaxablePaise / 100).toStringAsFixed(2);
    final taxablePartsRupees = (summary.totalPartsTaxablePaise / 100).toStringAsFixed(2);
    final cgstRupees = (summary.cgstAmountPaise / 100).toStringAsFixed(2);
    final sgstRupees = (summary.sgstAmountPaise / 100).toStringAsFixed(2);
    final totalGstRupees = ((summary.cgstAmountPaise + summary.sgstAmountPaise) / 100).toStringAsFixed(2);

    return Scaffold(
      backgroundColor: AppTokens.base,
      body: SafeArea(
        child: Column(
          children: [
            // Top Stage Header
            _buildStageHeader(),

            // Scrollable Content Zone (Zero Horizontal Scroll)
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24.0 : 14.0,
                  vertical: 14.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Vehicle & Customer Hero Banner (Rivian + MG Aesthetic)
                        _buildVehicleCustomerHeroCard(),
                        const SizedBox(height: 14.0),

                        // Main Bento Workspace: 2-Column Split on Desktop, Stack on Mobile
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column: Labour Operations & Parts Catalogue (Flex 7)
                              Expanded(
                                flex: 7,
                                child: Column(
                                  children: [
                                    _buildLabourModule(),
                                    const SizedBox(height: 14.0),
                                    _buildPartsModule(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16.0),

                              // Right Column: GST Calculation Summary & Actions (Flex 5)
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    _buildGstSummaryBentoCard(
                                      taxableLabour: taxableLabourRupees,
                                      taxableParts: taxablePartsRupees,
                                      cgst: cgstRupees,
                                      sgst: sgstRupees,
                                      totalGst: totalGstRupees,
                                      grandTotal: grandTotalRupees,
                                    ),
                                    const SizedBox(height: 14.0),
                                    _buildQuickActionsCard(grandTotalRupees),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _buildLabourModule(),
                          const SizedBox(height: 14.0),
                          _buildPartsModule(),
                          const SizedBox(height: 14.0),
                          _buildGstSummaryBentoCard(
                            taxableLabour: taxableLabourRupees,
                            taxableParts: taxablePartsRupees,
                            cgst: cgstRupees,
                            sgst: sgstRupees,
                            totalGst: totalGstRupees,
                            grandTotal: grandTotalRupees,
                          ),
                          const SizedBox(height: 14.0),
                          _buildQuickActionsCard(grandTotalRupees),
                          const SizedBox(height: 20.0),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top Stage Header Bar
  Widget _buildStageHeader() {
    return Container(
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
                  '05',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                'PAGE 5: JOB CARD & ESTIMATE BUILDER',
                style: GoogleFonts.inter(
                  color: AppTokens.textPrimary,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          StatusChip(
            label: _isApproved ? 'APPROVED BY OWNER' : (_isDispatched ? 'DISPATCHED VIA WHATSAPP' : 'DRAFT ESTIMATE'),
            icon: _isApproved ? Icons.verified : (_isDispatched ? Icons.send_rounded : Icons.pending_outlined),
            type: _isApproved ? StatusType.ok : (_isDispatched ? StatusType.dueSoon : StatusType.neutral),
          ),
        ],
      ),
    );
  }

  /// Vehicle & Customer Hero Card
  Widget _buildVehicleCustomerHeroCard() {
    return SharpCard(
      title: 'VEHICLE DOSSIER & INTAKE CONTEXT',
      titleTrailing: Text(
        _jobCardId,
        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 11.5, color: AppTokens.brandRed),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Registration Plate
          IndianNumberPlate(
            registrationNumber: _regNumber,
            height: 44.0,
          ),
          const SizedBox(width: 16.0),

          // Context Details
          Expanded(
            child: Wrap(
              spacing: 20.0,
              runSpacing: 10.0,
              children: [
                _buildInfoColumn('MAKE / MODEL', 'MG HECTOR SHARP PRO (DIESEL)'),
                _buildInfoColumn('CUSTOMER', 'Rohan Sharma (+91 9829012345)'),
                _buildInfoColumn('INTAKE ODOMETER', '27,227 KM'),
                _buildInfoColumn('TARGET DELIVERY', DateFormat('dd MMM yyyy, 05:00 PM').format(DateTime.now().add(const Duration(days: 1)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10.0, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 2.0),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 12.0, fontWeight: FontWeight.w700, color: AppTokens.textPrimary),
        ),
      ],
    );
  }

  /// Labour Charges Bento Module
  Widget _buildLabourModule() {
    return SharpCard(
      title: '1. LABOUR OPERATIONS & DIAGNOSTICS (SAC 998729 • 18% GST)',
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: _labourItems.map((item) {
          final amt = (item.taxableAmountPaise / 100).toStringAsFixed(2);
          final gstAmt = (item.gstAmountPaise / 100).toStringAsFixed(2);
          return Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(Icons.build_outlined, color: Color(0xFF1D4ED8), size: 16.0),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description,
                        style: GoogleFonts.inter(fontSize: 12.0, fontWeight: FontWeight.bold, color: AppTokens.textPrimary),
                      ),
                      Text(
                        '${item.code} • Qty: ${item.quantity} hr • GST Rate: ${item.gstRatePercent}% (+₹$gstAmt)',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10.0),
                Text(
                  '₹$amt',
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTokens.textPrimary),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Spare Parts & Consumables Bento Module
  Widget _buildPartsModule() {
    return SharpCard(
      title: '2. OEM SPARE PARTS & CONSUMABLES (HSN SPECIFIED)',
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: _partsItems.map((item) {
          final amt = (item.taxableAmountPaise / 100).toStringAsFixed(2);
          final gstAmt = (item.gstAmountPaise / 100).toStringAsFixed(2);
          return Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFD97706), size: 16.0),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description,
                        style: GoogleFonts.inter(fontSize: 12.0, fontWeight: FontWeight.bold, color: AppTokens.textPrimary),
                      ),
                      Text(
                        '${item.code} • Units: ${item.quantity} • GST Rate: ${item.gstRatePercent}% (+₹$gstAmt)',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10.0),
                Text(
                  '₹$amt',
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTokens.textPrimary),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// GST Calculation Summary Bento Card
  Widget _buildGstSummaryBentoCard({
    required String taxableLabour,
    required String taxableParts,
    required String cgst,
    required String sgst,
    required String totalGst,
    required String grandTotal,
  }) {
    return SharpCard(
      title: '3. AUTOMOTIVE GST COMPUTATION BREAKDOWN',
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSummaryRow('Taxable Labour (SAC 998729)', '₹$taxableLabour'),
          _buildSummaryRow('Taxable Spare Parts (HSN)', '₹$taxableParts'),
          const Divider(height: 16.0, color: Color(0xFFE2E8F0)),
          _buildSummaryRow('Central GST (CGST)', '₹$cgst'),
          _buildSummaryRow('State GST (SGST / UTGST)', '₹$sgst'),
          _buildSummaryRow('Total Automotive GST', '₹$totalGst', isEmphasized: true),
          const Divider(height: 20.0, color: Color(0xFFCBD5E1), thickness: 1.2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ESTIMATE TOTAL (INCL. GST)',
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppTokens.textPrimary),
              ),
              Text(
                '₹$grandTotal',
                style: GoogleFonts.inter(fontSize: 22.0, fontWeight: FontWeight.w900, color: AppTokens.brandRed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isEmphasized = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isEmphasized ? FontWeight.bold : FontWeight.w500,
              color: isEmphasized ? AppTokens.textPrimary : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.0,
              fontWeight: isEmphasized ? FontWeight.w800 : FontWeight.w700,
              color: isEmphasized ? AppTokens.textPrimary : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  /// Quick Action Buttons Card
  Widget _buildQuickActionsCard(String grandTotalRupees) {
    return SharpCard(
      title: '4. ESTIMATE DISPATCH & AUTHORIZATION GATE',
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dispatch via WhatsApp button
          SharpButton(
            label: _isDispatched ? 'RESEND ESTIMATE ON WHATSAPP' : 'DISPATCH ESTIMATE VIA WHATSAPP (₹$grandTotalRupees)',
            icon: Icons.send_rounded,
            borderRadius: BorderRadius.circular(20.0),
            onPressed: () {
              setState(() => _isDispatched = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF15803D),
                  content: Text('Digital Estimate link sent to +91 9829012345 with per-line approval consent.'),
                ),
              );
            },
          ),
          const SizedBox(height: 10.0),

          // Simulate Owner Customer Approval
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              side: const BorderSide(color: Color(0xFF16A34A), width: 1.2),
            ),
            icon: const Icon(Icons.verified_user, color: Color(0xFF16A34A), size: 18.0),
            label: Text(
              _isApproved ? 'CUSTOMER APPROVAL VERIFIED (SMS / OTP)' : 'SIMULATE CUSTOMER APPROVAL SIGN-OFF',
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
            ),
            onPressed: () {
              setState(() {
                _isApproved = true;
                _isDispatched = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF15803D),
                  content: Text('Customer digitally approved all 9 estimate items via WhatsApp link.'),
                ),
              );
            },
          ),
          const SizedBox(height: 10.0),

          // Proceed to WIP Floor button
          SharpButton(
            label: 'ADVANCE VEHICLE TO WIP BOARD (STAGE 7)',
            icon: Icons.arrow_forward,
            borderRadius: BorderRadius.circular(20.0),
            onPressed: () {
              GoRouter.maybeOf(context)?.go('/wip-board');
            },
          ),
        ],
      ),
    );
  }
}
