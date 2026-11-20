import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui_kit/tokens/app_tokens.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/applications/presentation/applications_screen.dart';
import '../features/vehicles/presentation/vehicles_screen.dart';
import '../features/passport/presentation/digital_passport_screen.dart';
import '../features/intake/presentation/intake_screen.dart';
import '../features/bay_capture/bay_capture_screen.dart';
import '../features/condition_map/condition_map_screen.dart';
import '../features/mechanical_inspection/mechanical_inspection_screen.dart';
import '../features/whatsapp_dispatch/whatsapp_dispatch_screen.dart';
import '../features/work_in_progress/work_in_progress_screen.dart';
import '../features/job_card/presentation/job_card_screen.dart';
import 'placeholder_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Production-Grade Application Router
/// Exactly 3 simple top-level sections: Home, Applications, and Vehicles.
/// Internal workflow orchestration steps are accessible through active jobs.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // --- 3 Simple Top-Level Navigation Sections Shell ---
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
                color: AppTokens.surface,
                border: Border(
                  bottom: BorderSide(color: AppTokens.borderLight, width: 1.0),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    // Workshop Brand Icon & Name
                    InkWell(
                      onTap: () => navigationShell.goBranch(0),
                      borderRadius: AppTokens.inputRadius,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: const BoxDecoration(
                              color: AppTokens.brandRed,
                              borderRadius: AppTokens.inputRadius,
                            ),
                            child: const Icon(
                              Icons.build_circle,
                              color: AppTokens.textOnDark,
                              size: 20.0,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'WORKSHOP DMS',
                            style: GoogleFonts.inter(
                              color: AppTokens.textPrimary,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16.0),

                    // Desktop Header Navigation: Exactly 3 Simple Top-Level Sections
                    if (isDesktop) ...[
                      Expanded(
                        child: Row(
                          children: [
                            _buildDesktopHeaderTab(
                              0,
                              'HOME',
                              Icons.home_rounded,
                              navigationShell,
                            ),
                            const SizedBox(width: 6.0),
                            _buildDesktopHeaderTab(
                              1,
                              'APPLICATIONS',
                              Icons.assignment_rounded,
                              navigationShell,
                            ),
                            const SizedBox(width: 6.0),
                            _buildDesktopHeaderTab(
                              2,
                              'VEHICLES',
                              Icons.directions_car_rounded,
                              navigationShell,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Spacer(),
                    ],
                  ],
                ),
              ),
            ),
          ),
          body: navigationShell,
          // Mobile Bottom Navigation Bar: Exactly 3 Simple Primary Sections
          bottomNavigationBar: isDesktop
              ? null
              : SafeArea(
                  top: false,
                  child: Container(
                    height: 64.0,
                    decoration: const BoxDecoration(
                      color: AppTokens.surface,
                      border: Border(
                        top: BorderSide(
                          color: AppTokens.borderLight,
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildNavItem(
                            0,
                            'HOME',
                            Icons.home_rounded,
                            navigationShell,
                          ),
                        ),
                        Expanded(
                          child: _buildNavItem(
                            1,
                            'APPLICATIONS',
                            Icons.assignment_rounded,
                            navigationShell,
                          ),
                        ),
                        Expanded(
                          child: _buildNavItem(
                            2,
                            'VEHICLES',
                            Icons.directions_car_rounded,
                            navigationShell,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
      branches: [
        // Section 1: Home Command Hub
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),

        // Section 2: Applications Registry (Current & Past Jobs)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/applications',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return ApplicationsScreen(
                  initialPlate: extra?['registrationNumber'] as String?,
                );
              },
            ),
            GoRoute(
              path: '/jobs',
              builder: (context, state) => const ApplicationsScreen(),
            ),
            GoRoute(
              path: '/bays',
              builder: (context, state) => const ApplicationsScreen(),
            ),
            GoRoute(
              path: '/wip-board',
              builder: (context, state) => const ApplicationsScreen(),
            ),
          ],
        ),

        // Section 3: Searchable Vehicle Records & Health History
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/vehicles',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return VehiclesScreen(
                  initialPlate: extra?['registrationNumber'] as String?,
                );
              },
            ),
            GoRoute(
              path: '/passports',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return VehiclesScreen(
                  initialPlate: extra?['registrationNumber'] as String?,
                );
              },
            ),
          ],
        ),
      ],
    ),

    // --- Internal Job Workflow Execution Sub-Routes ---
    // Vehicle & Customer Intake (Start New Application)
    GoRoute(
      path: '/intake',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const IntakeScreen(),
    ),

    // Vehicle Photo Inspection
    GoRoute(
      path: '/bay-capture',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return BayCaptureScreen(
          jobCardId: extra?['jobCardId'] as String?,
          registrationNumber: extra?['registrationNumber'] as String?,
        );
      },
    ),

    // Vehicle condition report
    GoRoute(
      path: '/condition-map',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ConditionMapScreen(
          jobCardId: extra?['jobCardId'] as String?,
          registrationNumber: extra?['registrationNumber'] as String?,
        );
      },
    ),

    // Multi-Point Mechanical Inspection
    GoRoute(
      path: '/mechanical-inspection',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return MechanicalInspectionScreen(
          jobCardId: extra?['jobCardId'] as String?,
          registrationNumber: extra?['registrationNumber'] as String?,
        );
      },
    ),

    // Job Card & Estimate Builder
    GoRoute(
      path: '/job-card',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return JobCardScreen(
          jobCardId: extra?['jobCardId'] as String?,
          registrationNumber: extra?['registrationNumber'] as String?,
        );
      },
    ),

    // Customer Communication & Approval
    GoRoute(
      path: '/whatsapp-dispatch',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return WhatsAppDispatchScreen(
          jobCardId: extra?['jobCardId'] as String?,
        );
      },
    ),

    // Technician updates for approved work
    GoRoute(
      path: '/work-in-progress',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return WorkInProgressScreen(jobCardId: extra?['jobCardId'] as String?);
      },
    ),

    // QC & Road-Test Sign-off
    GoRoute(
      path: '/qc-gate',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PhasePlaceholderScreen(
        pageNumber: 8,
        title: 'QC & Road-Test Sign-off',
        description: 'Quality control verification and road-test sign-off prior to invoice generation.',
      ),
    ),

    // Automotive GST Invoicing
    GoRoute(
      path: '/gst-invoicing',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PhasePlaceholderScreen(
        pageNumber: 9,
        title: 'Automotive GST Invoicing',
        description: 'Integer paise calculations, CGST/SGST vs IGST split with SAC 998714.',
      ),
    ),

    // Payment & Handover
    GoRoute(
      path: '/payment-gate',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PhasePlaceholderScreen(
        pageNumber: 10,
        title: 'Payment & Vehicle Handover',
        description:
            'Swipe-to-confirm delivery verification and balance clearance.',
      ),
    ),

    // Detailed Vehicle Passport
    GoRoute(
      path: '/passport',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return DigitalPassportScreen(
          registrationNumber: extra?['registrationNumber'] as String?,
          model: extra?['model'] as String?,
        );
      },
    ),

    // Predictive Service Reminders
    GoRoute(
      path: '/reminders',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PhasePlaceholderScreen(
        pageNumber: 12,
        title: 'Predictive Service Reminders',
        description: 'KM/day calculation guarded against rollback and anomalous readings.',
      ),
    ),
  ],
);

Widget _buildDesktopHeaderTab(
  int index,
  String label,
  IconData icon,
  StatefulNavigationShell shell,
) {
  final isSelected = shell.currentIndex == index;
  return InkWell(
    borderRadius: AppTokens.cardRadius,
    onTap: () => shell.goBranch(index),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      constraints: const BoxConstraints(minHeight: AppTokens.minTouchTarget),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isSelected ? AppTokens.inverse : Colors.transparent,
        borderRadius: AppTokens.cardRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20.0,
            color: isSelected ? AppTokens.textOnDark : AppTokens.textSecondary,
          ),
          const SizedBox(width: 6.0),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected
                  ? AppTokens.textOnDark
                  : AppTokens.textSecondary,
              fontSize: 16.0,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildNavItem(
  int index,
  String label,
  IconData icon,
  StatefulNavigationShell shell,
) {
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
            size: 22.0,
            color: isSelected ? AppTokens.brandRed : AppTokens.textTertiary,
          ),
          const SizedBox(height: 2.0),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isSelected
                  ? AppTokens.textPrimary
                  : AppTokens.textSecondary,
              fontSize: 14.0,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
