import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ui_kit/tokens/app_tokens.dart';
import '../features/intake/presentation/intake_screen.dart';
import '../features/bay_capture/bay_capture_screen.dart';
import '../features/condition_map/condition_map_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/job_card/presentation/job_card_screen.dart';
import '../features/passport/presentation/digital_passport_screen.dart';
import 'placeholder_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/intake',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 900.0;

        return Scaffold(
          backgroundColor: AppTokens.base,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(54.0),
            child: Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    // Workshop Brand Icon
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: AppTokens.brandRed,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(Icons.build_circle, color: Colors.white, size: 16.0),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'WORKSHOP DMS',
                      style: GoogleFonts.inter(
                        color: AppTokens.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 14.0),

                    // Desktop: Horizontal Stage Navigation Stepper in Header
                    if (isDesktop) ...[
                      Expanded(
                        child: Row(
                          children: [
                            _buildDesktopHeaderTab(0, '1. INTAKE', Icons.login, navigationShell),
                            const SizedBox(width: 4.0),
                            _buildDesktopHeaderTab(1, '2. CAPTURE', Icons.camera_alt_outlined, navigationShell),
                            const SizedBox(width: 4.0),
                            _buildDesktopHeaderTab(2, '3. 360° MAP', Icons.crop_rotate, navigationShell),
                            const SizedBox(width: 4.0),
                            _buildDesktopHeaderTab(4, '5. JOB CARD', Icons.assignment_outlined, navigationShell),
                            const SizedBox(width: 4.0),
                            _buildDesktopHeaderTab(10, '11. PASSPORT', Icons.verified_user_outlined, navigationShell),
                            const SizedBox(width: 6.0),
                            InkWell(
                              borderRadius: BorderRadius.circular(16.0),
                              onTap: () => _showAllStagesSheet(context, navigationShell),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16.0),
                                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.grid_view_rounded, color: AppTokens.brandRed, size: 13.0),
                                    const SizedBox(width: 5.0),
                                    Text(
                                      '13 STAGES ▾',
                                      style: GoogleFonts.inter(
                                        color: AppTokens.textPrimary,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Mobile: Compact Stage Indicator Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(
                          _getStageCode(navigationShell.currentIndex),
                          style: GoogleFonts.inter(
                            color: AppTokens.brandRed,
                            fontSize: 10.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],

                    // Workshop Floor & Online Status
                    if (isDesktop) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          'BAY 04 • WORKSHOP FLOOR',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF475569),
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                    ],
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7.0,
                          height: 7.0,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5.0),
                        Text(
                          'ONLINE',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF16A34A),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: navigationShell,
          // Mobile Bottom Bar (Thumb-Accessible, No desktop bottom clutter)
          bottomNavigationBar: isDesktop
              ? null
              : Container(
                  height: 58.0,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 10.0,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildNavItem(0, '1. INTAKE', Icons.login, navigationShell)),
                      Expanded(child: _buildNavItem(1, '2. CAPTURE', Icons.camera_alt_outlined, navigationShell)),
                      Expanded(child: _buildNavItem(2, '3. 360° MAP', Icons.crop_rotate, navigationShell)),
                      Expanded(child: _buildNavItem(4, '5. JOB CARD', Icons.assignment_outlined, navigationShell)),
                      Expanded(
                        child: InkWell(
                          onTap: () => _showAllStagesSheet(context, navigationShell),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.grid_view_rounded, color: Color(0xFF64748B), size: 18.0),
                                const SizedBox(height: 3.0),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'ALL STAGES',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF64748B),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
      branches: [
        // Branch 0: Page 1 - Vehicle & Customer Intake
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/intake',
            builder: (context, state) => const IntakeScreen(),
          ),
        ]),
        // Branch 1: Page 2 - Bay Check-in Capture
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/bay-capture',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return BayCaptureScreen(
                jobCardId: extra?['jobCardId'] as String?,
                registrationNumber: extra?['registrationNumber'] as String?,
              );
            },
          ),
        ]),
        // Branch 2: Page 3 - 360° Condition Map
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/condition-map',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return ConditionMapScreen(
                jobCardId: extra?['jobCardId'] as String?,
                registrationNumber: extra?['registrationNumber'] as String?,
              );
            },
          ),
        ]),
        // Branch 3: Page 4 - Mechanical Inspection
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/mechanical-inspection',
            builder: (context, state) => const PhasePlaceholderScreen(
              pageNumber: 4,
              title: 'Multi-Point Mechanical Inspection',
              description: 'Traffic-light checklist with real measurements (brake pad mm, tyre tread depth, battery CCA/volts) feeding passport wear telemetry.',
            ),
          ),
        ]),
        // Branch 4: Page 5 - Job Card & Estimate
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/job-card',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return JobCardScreen(
                jobCardId: extra?['jobCardId'] as String?,
                registrationNumber: extra?['registrationNumber'] as String?,
              );
            },
          ),
        ]),
        // Branch 5: Page 6 - WhatsApp Dispatch
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/whatsapp-dispatch',
            builder: (context, state) => const PhasePlaceholderScreen(
              pageNumber: 6,
              title: 'WhatsApp Dispatch & Per-Line Approval',
              description: 'Approve, decline, revise, or expire. Declined lines persist to vehicle record and surface at the next visit.',
            ),
          ),
        ]),
        // Branch 6: Page 7 - Work in Progress Board
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/wip-board',
            builder: (context, state) => const PhasePlaceholderScreen(
              pageNumber: 7,
              title: 'Work in Progress / Bay Floor Board',
              description: 'Technician assignment, dense status grid, time clock, auto-deduct inventory, old vs new part photos, change orders.',
            ),
          ),
        ]),
        // Branch 7: Page 8 - QC Gate
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/qc-gate',
            builder: (context, state) => const PhasePlaceholderScreen(
              pageNumber: 8,
              title: 'QC & Road-Test Sign-off Gate',
              description: 'Strict quality control inspection and road-test sign-off gate before billing can open.',
            ),
          ),
        ]),
        // Branch 8: Page 9 - GST Invoicing
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/gst-invoicing',
            builder: (context, state) => const PhasePlaceholderScreen(
              pageNumber: 9,
              title: 'Automotive GST Invoicing',
              description: 'Effective-dated rate table as data, integer paise calculations, CGST/SGST vs IGST split.',
            ),
          ),
        ]),
        // Branch 9: Page 10 - Payment Gate & Release
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/payment-gate',
            builder: (context, state) => const PhasePlaceholderScreen(
              pageNumber: 10,
              title: 'Strict Payment Gate & Vehicle Release',
              description: 'Swipe-to-confirm delivery, blocks unless balance == 0 or credit override is authorized, logs to debtors ledger.',
            ),
          ),
        ]),
        // Branch 10: Page 11 - Digital Health Passport
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/passport',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return DigitalPassportScreen(
                registrationNumber: extra?['registrationNumber'] as String?,
                model: extra?['model'] as String?,
              );
            },
          ),
        ]),
        // Branch 11: Page 12 - Service Reminders
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/reminders',
            builder: (context, state) => const PhasePlaceholderScreen(
              pageNumber: 12,
              title: 'Dual-Trigger Service Reminders',
              description: 'KM/day formula guarded against first visits, same-day visits, and odometer rollbacks. WhatsApp utility template.',
            ),
          ),
        ]),
        // Branch 12: Page 13 - Home Dashboard
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
        ]),
      ],
    ),
  ],
);

String _getStageCode(int index) {
  switch (index) {
    case 0:
      return 'STAGE 01: INTAKE';
    case 1:
      return 'STAGE 02: CAPTURE';
    case 2:
      return 'STAGE 03: 360° MAP';
    case 3:
      return 'STAGE 04: INSPECT';
    case 4:
      return 'STAGE 05: JOB CARD';
    default:
      return 'STAGE ${index + 1}';
  }
}

Widget _buildDesktopHeaderTab(int index, String label, IconData icon, StatefulNavigationShell shell) {
  final isSelected = shell.currentIndex == index;
  return InkWell(
    borderRadius: BorderRadius.circular(16.0),
    onTap: () => shell.goBranch(index),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13.0,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
          const SizedBox(width: 5.0),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : const Color(0xFF475569),
              fontSize: 11.0,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildNavItem(int index, String label, IconData icon, StatefulNavigationShell shell) {
  final isSelected = shell.currentIndex == index;
  return InkWell(
    onTap: () => shell.goBranch(index),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18.0,
            color: isSelected ? AppTokens.brandRed : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 3.0),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isSelected ? AppTokens.textPrimary : const Color(0xFF94A3B8),
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showAllStagesSheet(BuildContext context, StatefulNavigationShell shell) {
  final stages = [
    {'title': '1. INTAKE', 'desc': 'Active Registration & Customer Details', 'live': true, 'branch': 0},
    {'title': '2. BAY CAPTURE', 'desc': '6 Mandatory Check-in Camera Shots', 'live': true, 'branch': 1},
    {'title': '3. 360° CONDITION MAP', 'desc': 'Interactive Digital Damage Pins', 'live': true, 'branch': 2},
    {'title': '4. MECHANICAL INSPECTION', 'desc': 'Brakes, Tyres, Battery Telemetry', 'live': false, 'branch': 3},
    {'title': '5. JOB CARD & ESTIMATE', 'desc': 'SAC 998729 Labour & OEM Spare Parts', 'live': true, 'branch': 4},
    {'title': '6. WHATSAPP DISPATCH', 'desc': 'Per-Line Customer Approval Consent', 'live': false, 'branch': 5},
    {'title': '7. WORK IN PROGRESS BOARD', 'desc': 'Live Bay Floor Board & Technician Log', 'live': false, 'branch': 6},
    {'title': '8. QC & ROAD TEST GATE', 'desc': 'Strict Safety Inspection Sign-off', 'live': false, 'branch': 7},
    {'title': '9. GST INVOICING', 'desc': 'Automotive Rate Tables & CGST/SGST', 'live': false, 'branch': 8},
    {'title': '10. PAYMENT & RELEASE GATE', 'desc': 'Zero-Balance Swipe to Release', 'live': false, 'branch': 9},
    {'title': '11. DIGITAL HEALTH PASSPORT', 'desc': 'Cryptographically Signed Vehicle Record', 'live': true, 'branch': 10},
    {'title': '12. SERVICE REMINDERS', 'desc': 'Dual-Trigger Predictive Maintenance', 'live': false, 'branch': 11},
    {'title': '13. SHOP FLOOR DASHBOARD', 'desc': 'Live Workshop Metrics & Bay Status', 'live': true, 'branch': 12},
  ];

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
    ),
    builder: (ctx) {
      return Container(
        height: 540.0,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: AppTokens.brandRed,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 16.0),
                    ),
                    const SizedBox(width: 10.0),
                    Text(
                      'WORKSHOP PIPELINE: 13 STAGES',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13.5, color: AppTokens.textPrimary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Expanded(
              child: ListView.separated(
                itemCount: stages.length,
                separatorBuilder: (ctx, idx) => const Divider(height: 1.0, color: Color(0xFFE2E8F0)),
                itemBuilder: (ctx, idx) {
                  final s = stages[idx];
                  final branchIdx = s['branch'] as int;
                  final isCurrent = shell.currentIndex == branchIdx;
                  final isLive = s['live'] as bool;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    selected: isCurrent,
                    selectedTileColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    title: Row(
                      children: [
                        Text(
                          s['title'] as String,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.0,
                            color: isCurrent ? AppTokens.brandRed : AppTokens.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        if (isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Text(
                              '● LIVE',
                              style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 9.0),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      s['desc'] as String,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle, color: AppTokens.brandRed, size: 18.0)
                        : const Icon(Icons.arrow_forward_ios, size: 12.0, color: Color(0xFFCBD5E1)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      shell.goBranch(branchIdx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
