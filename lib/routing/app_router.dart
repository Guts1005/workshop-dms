import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui_kit/tokens/app_tokens.dart';
import '../features/intake/presentation/intake_screen.dart';
import 'placeholder_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/intake',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          backgroundColor: AppTokens.base,
          appBar: AppBar(
            backgroundColor: AppTokens.inverse,
            foregroundColor: AppTokens.textOnDark,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5.0),
                  color: AppTokens.redOrange,
                  child: const Icon(Icons.build_circle, color: Colors.white, size: 16.0),
                ),
                const SizedBox(width: 10.0),
                Text(
                  'WORKSHOP DMS',
                  style: AppTokens.fontMonospace(
                    color: AppTokens.textOnDark,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 16.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
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
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: const BoxDecoration(
                        color: AppTokens.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      'ONLINE',
                      style: AppTokens.fontMonospace(
                        color: AppTokens.green,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: navigationShell,
          bottomNavigationBar: Container(
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
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.grid_view_sharp, color: Colors.white, size: 16.0),
                          const SizedBox(height: 3.0),
                          Text(
                            'ALL STAGES',
                            style: AppTokens.fontMonospace(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
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
        // Branch 1: Page 1 - Vehicle & Customer Intake
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/intake',
            builder: (context, state) => const IntakeScreen(),
          ),
        ]),
        // Branch 2: Page 2 - Bay Check-in Capture
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/bay-capture',
            builder: (context, state) => const PhasePlaceholderScreen(
              pageNumber: 2,
              title: 'Bay Check-in Capture (6 Mandatory Shots)',
              description: '4-corner 45° perspective shots + plate close-up + odometer cluster. Camera overlay, manager override, SHA-256 integrity hash.',
            ),
          ),
        ]),
        // Branch 3: Page 3 - 360° Condition Map
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/condition-map',
            builder: (context, state) => const PhasePlaceholderScreen(
              pageNumber: 3,
              title: '360° Condition Map & Pre-Work Sign-off',
              description: '4-view orthographic CustomPainter, numbered pin drops, photo per pin, customer pre-work sign-off swipe.',
            ),
          ),
        ]),
        // Branch 4: Page 4 - Mechanical Inspection
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
        // Branch 5: Page 5 - Job Card & Estimate
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
        // Branch 6: Page 6 - WhatsApp Dispatch
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
        // Branch 7: Page 7 - Work in Progress Board
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
        // Branch 8: Page 8 - QC Gate
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
        // Branch 9: Page 9 - GST Invoicing
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
        // Branch 10: Page 10 - Payment Gate & Release
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
        // Branch 11: Page 11 - Digital Health Passport
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
        // Branch 12: Page 12 - Service Reminders
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
        // Branch 13: Page 13 - Home Dashboard
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

Widget _buildNavItem(int index, String label, IconData icon, StatefulNavigationShell shell) {
  final isSelected = shell.currentIndex == index;
  return InkWell(
    onTap: () => shell.goBranch(index),
    child: Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2E2E2E) : Colors.transparent,
        border: Border(
          top: BorderSide(
            color: isSelected ? AppTokens.redOrange : Colors.transparent,
            width: 3.0,
          ),
          right: const BorderSide(color: Color(0xFF333333), width: 1.0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16.0,
            color: isSelected ? AppTokens.textOnDark : const Color(0xFF888888),
          ),
          const SizedBox(height: 3.0),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppTokens.textOnDark : const Color(0xFF888888),
              fontSize: 10.0,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
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
        height: 480.0,
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
                Text(
                  'WORKSHOP PIPELINE: 13 STAGES',
                  style: AppTokens.fontMonospace(fontWeight: FontWeight.w900, fontSize: 13.0),
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
