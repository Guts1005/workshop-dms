import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../ui_kit/tokens/app_tokens.dart';
import '../../../ui_kit/widgets/sharp_card.dart';
import '../../../ui_kit/widgets/status_chip.dart';

/// Complete, Production-Grade Workshop Floor & Shop Overview Dashboard (Page 13)
/// Matches luxury Rivian + MG i-SMART automotive styling:
/// Luminous canvas, modular Bento grid, live bay occupancy cards, and shop analytics.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900.0;

    return Scaffold(
      backgroundColor: AppTokens.base,
      body: SafeArea(
        child: Column(
          children: [
            // Stage Header Bar
            _buildStageHeader(),

            // Scrollable Content
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
                        // KPI Metric Bento Cards Row
                        _buildKpiMetricsRow(isDesktop),
                        const SizedBox(height: 16.0),

                        // Active Bay Floor Live Board (Rivian Cockpit Grid)
                        _buildBayFloorSection(context, isDesktop),
                        const SizedBox(height: 16.0),

                        // Quick Workflow Launchers
                        _buildQuickWorkflowLaunchers(context),
                        const SizedBox(height: 20.0),
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
                  '13',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                'PAGE 13: WORKSHOP LIVE SHOP FLOOR & METRICS',
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
            label: '6 / 8 BAYS ACTIVE',
            icon: Icons.garage_outlined,
            type: StatusType.ok,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetricsRow(bool isDesktop) {
    final kpis = [
      {'title': "TODAY'S REVENUE", 'val': '₹1,48,250', 'sub': '+14.2% vs yesterday', 'color': const Color(0xFF16A34A)},
      {'title': 'IN WORKSHOP BAYS', 'val': '6 VEHICLES', 'sub': '2 waiting for parts', 'color': AppTokens.brandRed},
      {'title': 'COMPLETED TODAY', 'val': '14 CHECK-INS', 'sub': '100% QC sign-off', 'color': const Color(0xFF2563EB)},
      {'title': 'AVG TURNAROUND', 'val': '2H 45M', 'sub': 'Under 3h service SLA', 'color': const Color(0xFFD97706)},
    ];

    if (isDesktop) {
      return Row(
        children: kpis.map((kpi) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(color: Color(0x04000000), blurRadius: 8.0, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kpi['title'] as String,
                    style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    kpi['val'] as String,
                    style: GoogleFonts.inter(fontSize: 20.0, fontWeight: FontWeight.w900, color: AppTokens.textPrimary),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    kpi['sub'] as String,
                    style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: kpi['color'] as Color),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    } else {
      return Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: kpis.map((kpi) {
          return SizedBox(
            width: 170.0,
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kpi['title'] as String,
                    style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    kpi['val'] as String,
                    style: GoogleFonts.inter(fontSize: 16.0, fontWeight: FontWeight.w900, color: AppTokens.textPrimary),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    kpi['sub'] as String,
                    style: GoogleFonts.inter(fontSize: 10.0, fontWeight: FontWeight.bold, color: kpi['color'] as Color),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildBayFloorSection(BuildContext context, bool isDesktop) {
    final bays = [
      {'bay': 'BAY 01', 'reg': 'RJ27CA1024', 'model': 'MG HECTOR SHARP PRO', 'task': 'Periodic Maintenance & Brake Overhaul', 'status': 'STAGE 05: JOB CARD', 'pct': 0.85, 'route': '/job-card'},
      {'bay': 'BAY 02', 'reg': 'DL01AB1234', 'model': 'MARUTI SWIFT VXI', 'task': '6-Point Inspection Photo Capture', 'status': 'STAGE 02: BAY CAPTURE', 'pct': 0.50, 'route': '/bay-capture'},
      {'bay': 'BAY 03', 'reg': 'MH02CD5678', 'model': 'HYUNDAI CRETA SX', 'task': 'Front Bumper Dent & 360° Mapping', 'status': 'STAGE 03: 360° MAP', 'pct': 0.35, 'route': '/condition-map'},
      {'bay': 'BAY 04', 'reg': 'KA05EF9012', 'model': 'MAHINDRA THAR 4X4', 'task': 'Suspension Alignment & QC Road Test', 'status': 'STAGE 08: QC GATE', 'pct': 0.95, 'route': '/intake'},
      {'bay': 'BAY 05', 'reg': 'DL08GH3456', 'model': 'TATA NEXON EV MAX', 'task': 'High-Voltage Battery Diagnostics', 'status': 'STAGE 04: INSPECTION', 'pct': 0.20, 'route': '/passport'},
      {'bay': 'BAY 06', 'reg': 'HR26IJ7890', 'model': 'TATA HARRIER XZA+', 'task': 'Final Wash, Digital Invoice & Release', 'status': 'STAGE 10: PAYMENT', 'pct': 1.0, 'route': '/intake'},
    ];

    return SharpCard(
      title: 'ACTIVE SHOP FLOOR BAYS (LIVE DISPATCH & PROGRESS)',
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: bays.map((bay) {
          final pct = bay['pct'] as double;
          final pctInt = (pct * 100).toInt();
          return Container(
            margin: const EdgeInsets.only(bottom: 10.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    bay['bay'] as String,
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11.0),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            bay['reg'] as String,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12.5, color: AppTokens.textPrimary),
                          ),
                          const SizedBox(width: 8.0),
                          Flexible(
                            child: Text(
                              '• ${bay['model']}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        bay['task'] as String,
                        style: const TextStyle(fontSize: 11.0, color: Color(0xFF475569)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      bay['status'] as String,
                      style: GoogleFonts.inter(fontSize: 10.0, fontWeight: FontWeight.w800, color: AppTokens.brandRed),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 60.0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: const Color(0xFFE2E8F0),
                              color: pct == 1.0 ? const Color(0xFF16A34A) : AppTokens.brandRed,
                              minHeight: 6.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Text('$pctInt%', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 14.0, color: Color(0xFF94A3B8)),
                  onPressed: () => GoRouter.maybeOf(context)?.go(bay['route'] as String),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickWorkflowLaunchers(BuildContext context) {
    return SharpCard(
      title: 'ONE-TOUCH WORKSHOP WORKFLOW JUMP',
      padding: const EdgeInsets.all(14.0),
      child: Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children: [
          _buildLauncherChip(context, '1. INTAKE', Icons.login, '/intake'),
          _buildLauncherChip(context, '2. CAPTURE', Icons.camera_alt_outlined, '/bay-capture'),
          _buildLauncherChip(context, '3. 360° MAP', Icons.crop_rotate, '/condition-map'),
          _buildLauncherChip(context, '5. JOB CARD', Icons.assignment_outlined, '/job-card'),
          _buildLauncherChip(context, '11. PASSPORT', Icons.verified_user_outlined, '/passport'),
        ],
      ),
    );
  }

  Widget _buildLauncherChip(BuildContext context, String label, IconData icon, String route) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10.0),
        onTap: () => GoRouter.maybeOf(context)?.go(route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.0, color: AppTokens.brandRed),
              const SizedBox(width: 6.0),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTokens.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
