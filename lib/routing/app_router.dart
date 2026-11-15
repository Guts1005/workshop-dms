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
                const Icon(Icons.build_circle_sharp, color: AppTokens.textOnDark, size: 22.0),
                const SizedBox(width: 8.0),
                Text(
                  'WORKSHOP DMS',
                  style: AppTokens.fontMonospace(
                    color: AppTokens.textOnDark,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                  color: AppTokens.surface,
                  child: Text(
                    'GOVERNED PIPELINE: ACTIVE',
                    style: AppTokens.fontMonospace(
                      color: AppTokens.textPrimary,
                      fontSize: 10.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: navigationShell,
          bottomNavigationBar: Container(
            height: 52.0,
            decoration: const BoxDecoration(
              color: AppTokens.surface,
              border: Border(top: BorderSide(color: AppTokens.borderSolid, width: 1.0)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildNavItem(0, '1. INTAKE', navigationShell),
                _buildNavItem(1, '2. CAPTURE', navigationShell),
                _buildNavItem(2, '3. 360° MAP', navigationShell),
                _buildNavItem(3, '4. INSPECT', navigationShell),
                _buildNavItem(4, '5. JOB CARD', navigationShell),
                _buildNavItem(5, '6. WHATSAPP', navigationShell),
                _buildNavItem(6, '7. WIP BOARD', navigationShell),
                _buildNavItem(7, '8. QC GATE', navigationShell),
                _buildNavItem(8, '9. GST BILL', navigationShell),
                _buildNavItem(9, '10. PAYMENT', navigationShell),
                _buildNavItem(10, '11. PASSPORT', navigationShell),
                _buildNavItem(11, '12. REMIND', navigationShell),
                _buildNavItem(12, '13. SHOP', navigationShell),
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

Widget _buildNavItem(int index, String label, StatefulNavigationShell shell) {
  final isSelected = shell.currentIndex == index;
  return GestureDetector(
    onTap: () => shell.goBranch(index),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      decoration: BoxDecoration(
        color: isSelected ? AppTokens.raised : Colors.transparent,
        border: Border(
          right: const BorderSide(color: AppTokens.borderSolid, width: 1.0),
          bottom: BorderSide(
            color: isSelected ? AppTokens.redOrange : Colors.transparent,
            width: 3.0,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTokens.redOrange : AppTokens.textPrimary,
          fontSize: 11.0,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
    ),
  );
}
