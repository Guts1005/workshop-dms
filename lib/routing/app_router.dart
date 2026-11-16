import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui_kit/tokens/app_tokens.dart';
import '../features/intake/presentation/intake_screen.dart';
import '../features/bay_capture/bay_capture_screen.dart';
import '../features/condition_map/condition_map_screen.dart';
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
            preferredSize: const Size.fromHeight(52.0),
            child: AppBar(
              backgroundColor: AppTokens.inverse,
              foregroundColor: AppTokens.textOnDark,
              elevation: 0,
              titleSpacing: 14.0,
              title: Row(
                children: [
                  // Workshop Brand Icon
                  Container(
                    padding: const EdgeInsets.all(5.0),
                    color: AppTokens.redOrange,
                    child: const Icon(Icons.build_circle, color: Colors.white, size: 16.0),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'WORKSHOP DMS',
                    style: AppTokens.fontMonospace(
                      color: AppTokens.textOnDark,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
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
                          const SizedBox(width: 6.0),
                          InkWell(
                            onTap: () => _showAllStagesSheet(context, navigationShell),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF282828),
                                border: Border.all(color: const Color(0xFF444444), width: 1.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.grid_view_sharp, color: Colors.white, size: 13.0),
                                  const SizedBox(width: 5.0),
                                  Text(
                                    '13 STAGES ▾',
                                    style: AppTokens.fontMonospace(
                                      color: Colors.white,
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
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
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF282828),
                        border: Border.all(color: const Color(0xFF444444), width: 1.0),
                      ),
                      child: Text(
                        _getStageCode(navigationShell.currentIndex),
                        style: AppTokens.fontMonospace(
                          color: AppTokens.orange,
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
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
                        border: Border.all(color: const Color(0xFF444444), width: 1.0),
                      ),
                      child: Text(
                        'BAY 04 • WORKSHOP FLOOR',
                        style: AppTokens.fontMonospace(
                          color: AppTokens.surface,
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14.0),
                  ],
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7.0,
                        height: 7.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5.0),
                      Text(
                        'ONLINE',
                        style: AppTokens.fontMonospace(
                          color: const Color(0xFF00E676),
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
          body: navigationShell,
          // Mobile Bottom Bar (Thumb-Accessible, No desktop bottom clutter)
          bottomNavigationBar: isDesktop
              ? null
              : Container(
                  height: 56.0,
                  decoration: const BoxDecoration(
                    color: AppTokens.inverse,
                    border: Border(top: BorderSide(color: Color(0xFF333333), width: 1.0)),
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
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.grid_view_sharp, color: Colors.white, size: 16.0),
                                SizedBox(height: 3.0),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'ALL STAGES',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
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
            builder: (context, state) => const PhasePlaceholderScreen(
              pageNumber: 5,
              title: 'Job Card & Estimate Builder',
              description: 'Labour under SAC 998714, spare parts with effective-dated GST table, voice notes, per-line approval structure.',
            ),
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
            builder: (context, state) => const PhasePlaceholderScreen(
              pageNumber: 11,
              title: 'Digital Health Passport (Customer Facing)',
              description: 'Hero photo, plate blurred until owner shares, component wear estimates, hash-signed PDF export.',
            ),
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
            builder: (context, state) => const PhasePlaceholderScreen(
              pageNumber: 13,
              title: 'Home Dashboard & Shop Overview',
              description: 'Workshop status overview, active bays, revenue metrics, urgent alerts.',
            ),
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
    onTap: () => shell.goBranch(index),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2E2E2E) : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isSelected ? AppTokens.redOrange : Colors.transparent,
            width: 2.5,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13.0,
            color: isSelected ? AppTokens.textOnDark : const Color(0xFF999999),
          ),
          const SizedBox(width: 5.0),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTokens.textOnDark : const Color(0xFF999999),
              fontSize: 11.0,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontFamily: 'monospace',
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
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF282828) : Colors.transparent,
        border: Border(
          top: BorderSide(
            color: isSelected ? AppTokens.redOrange : Colors.transparent,
            width: 3.0,
          ),
          right: const BorderSide(color: Color(0xFF333333), width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16.0,
            color: isSelected ? AppTokens.textOnDark : const Color(0xFF888888),
          ),
          const SizedBox(height: 3.0),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppTokens.textOnDark : const Color(0xFF888888),
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontFamily: 'monospace',
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
    '1. INTAKE (Active Registration & Customer)',
    '2. BAY CAPTURE (6 Mandatory Shots)',
    '3. 360° CONDITION MAP (Damage Zones)',
    '4. MECHANICAL INSPECTION (Brakes, Tyres, Battery)',
    '5. JOB CARD & ESTIMATE (SAC 998714 / Parts)',
    '6. WHATSAPP DISPATCH (Approvals & Declines)',
    '7. WORK IN PROGRESS BOARD (Bay Clock & Stock)',
    '8. QC & ROAD TEST GATE (Safety Sign-off)',
    '9. GST INVOICING (CGST/SGST/IGST Engine)',
    '10. PAYMENT & RELEASE GATE (Zero Balance Gate)',
    '11. DIGITAL HEALTH PASSPORT (QR & Public Web)',
    '12. SERVICE REMINDERS (KM & Time Triggers)',
    '13. HOME DASHBOARD (Shop Metrics & Active Bays)',
  ];

  showModalBottomSheet(
    context: context,
    backgroundColor: AppTokens.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (ctx) {
      return Container(
        height: 500.0,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          border: Border.all(color: AppTokens.borderSolid, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4.0),
                      color: AppTokens.redOrange,
                      child: const Icon(Icons.grid_view_sharp, color: Colors.white, size: 14.0),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'WORKSHOP PIPELINE: 13 STAGES',
                      style: AppTokens.fontMonospace(fontWeight: FontWeight.w900, fontSize: 13.0),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Expanded(
              child: ListView.separated(
                itemCount: stages.length,
                separatorBuilder: (ctx, idx) => const Divider(height: 1.0, color: AppTokens.dividerPassive),
                itemBuilder: (ctx, idx) {
                  final isCurrent = shell.currentIndex == idx;
                  return ListTile(
                    dense: true,
                    selected: isCurrent,
                    selectedTileColor: AppTokens.inverse,
                    title: Text(
                      stages[idx],
                      style: AppTokens.fontMonospace(
                        color: isCurrent ? AppTokens.textOnDark : AppTokens.textPrimary,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle, color: AppTokens.redOrange, size: 18.0)
                        : const Icon(Icons.chevron_right, size: 16.0),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      shell.goBranch(idx);
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
