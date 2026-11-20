import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../ui_kit/tokens/app_tokens.dart';
import '../../../ui_kit/widgets/sharp_card.dart';
import '../../../data/supabase/workshop_database.dart';

/// Production-Grade Home Command Hub (Destination 1 of 3)
/// Stays short, focused, and operational:
/// - One clear "Start New Application" primary action button
/// - A small "Needs attention" list (plain status + what remains)
/// - Recent applications with plain status and remaining items
/// - Fast plate search bar with bounded quick chips
/// - Strictly zero stage numbers, levels, or steppers
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    try {
      final apps = await WorkshopDatabase(Supabase.instance.client)
          .applications();
      if (mounted) setState(() => _applications = apps);
    } catch (_) {
      if (mounted) setState(() => _applications = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900.0;

    return Scaffold(
      backgroundColor: AppTokens.base,
      body: SafeArea(
        child: Column(
          children: [
            // Short, Focused Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24.0 : 16.0,
                  vertical: 16.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. One Clear Primary Action: Start New Application
                        _buildStartApplicationBanner(context, isDesktop),
                        const SizedBox(height: 16.0),

                        // Actionable items are shown before recent work.
                        const SizedBox(height: 16.0),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          _buildNeedsAttentionSection(context, isDesktop),
                          const SizedBox(height: 16.0),

                          // Recent applications show plain status and what's left.
                          _buildRecentApplicationsSection(context, isDesktop),
                        ],
                        const SizedBox(height: 24.0),
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

  /// One Clear Primary Action: Start New Application
  Widget _buildStartApplicationBanner(BuildContext context, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.inverse,
        borderRadius: AppTokens.cardRadius,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/intake'),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 20.0 : 16.0),
            child: Row(
              children: [
                // Prominent Red Plus Icon Badge
                Container(
                  width: isDesktop ? 50.0 : AppTokens.minTouchTarget,
                  height: isDesktop ? 50.0 : AppTokens.minTouchTarget,
                  decoration: const BoxDecoration(
                    color: AppTokens.brandRed,
                    borderRadius: AppTokens.buttonRadius,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppTokens.textOnDark,
                    size: 28.0,
                  ),
                ),
                const SizedBox(width: 16.0),

                // Main CTA Text Block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'START NEW APPLICATION',
                        style: GoogleFonts.inter(
                          color: AppTokens.textOnDark,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3.0),
                      Text(
                        'Fast check-in for vehicle identity, customer contact, and requested service scope',
                        style: GoogleFonts.inter(
                          color: AppTokens.textOnDark,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12.0),

                // Action Pill
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 96.0,
                    minHeight: AppTokens.minTouchTarget,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 10.0,
                  ),
                  decoration: const BoxDecoration(
                    color: AppTokens.brandRed,
                    borderRadius: AppTokens.inputRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isDesktop ? 'START APPLICATION' : 'START',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Quick Registration Plate Search Section
  Widget _buildNeedsAttentionSection(BuildContext context, bool isDesktop) {
    final attentionItems = _applications
        .where((app) => (app['pendingItems'] as List).isNotEmpty)
        .take(3)
        .map(
          (app) => {
            ...app,
            'actionLabel': 'CONTINUE APPLICATION',
            'route': '/condition-map',
          },
        )
        .toList();

    return SharpCard(
      title: 'NEEDS ATTENTION (${attentionItems.length})',
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: attentionItems.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Nothing needs attention.'),
                ),
              ]
            : attentionItems.map((item) {
                final plate = item['plate'] as String;
                final model = item['model'] as String;
                final status = item['status'] as String;
                final remainingHint = item['remainingHint'] as String;
                final actionLabel = item['actionLabel'] as String;
                final route = item['route'] as String;
                final plateBadge = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 3.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.base,
                    borderRadius: AppTokens.inputRadius,
                    border: Border.all(color: AppTokens.borderSolid),
                  ),
                  child: Text(
                    plate,
                    style: GoogleFonts.inter(
                      color: AppTokens.textPrimary,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
                final modelLabel = Text(
                  model,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTokens.textPrimary,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w800,
                  ),
                );
                final statusBadge = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'Waiting for approval'
                        ? AppTokens.orange
                        : AppTokens.blue,
                    borderRadius: AppTokens.inputRadius,
                  ),
                  child: Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: status == 'Waiting for approval'
                          ? AppTokens.inverse
                          : AppTokens.raised,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
                final hint = Text(
                  remainingHint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTokens.textSecondary,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                  ),
                );
                final actionButton = InkWell(
                  borderRadius: AppTokens.inputRadius,
                  onTap: () => context.push(
                    route,
                    extra: {
                      'jobCardId': item['id'],
                      'registrationNumber': plate,
                    },
                  ),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: AppTokens.minTouchTarget,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                    decoration: const BoxDecoration(
                      color: AppTokens.inverse,
                      borderRadius: AppTokens.inputRadius,
                    ),
                    child: Text(
                      actionLabel,
                      style: GoogleFonts.inter(
                        color: AppTokens.textOnDark,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: AppTokens.surfaceSubtle,
                    borderRadius: AppTokens.cardRadius,
                    border: Border.all(color: AppTokens.borderLight),
                  ),
                  child: isDesktop
                      ? Row(
                          children: [
                            plateBadge,
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: modelLabel),
                                      const SizedBox(width: 6.0),
                                      statusBadge,
                                    ],
                                  ),
                                  const SizedBox(height: 2.0),
                                  hint,
                                ],
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            actionButton,
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [Expanded(child: modelLabel)]),
                            const SizedBox(height: 6.0),
                            Wrap(
                              spacing: AppTokens.minTouchGap,
                              runSpacing: AppTokens.minTouchGap,
                              children: [
                                plateBadge,
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 190.0,
                                  ),
                                  child: statusBadge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6.0),
                            hint,
                            const SizedBox(height: 6.0),
                            Align(
                              alignment: Alignment.centerRight,
                              child: actionButton,
                            ),
                          ],
                        ),
                );
              }).toList(),
      ),
    );
  }

  /// Recent Applications (Plain Status + What Remains)
  Widget _buildRecentApplicationsSection(BuildContext context, bool isDesktop) {
    final recentApps = _applications.take(3).toList();

    return SharpCard(
      title: 'RECENT APPLICATIONS',
      titleTrailing: InkWell(
        onTap: () => context.go('/applications'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isDesktop ? 'VIEW ALL IN APPLICATIONS' : 'VIEW ALL',
              style: GoogleFonts.inter(
                color: AppTokens.inverse,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4.0),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 12.0,
              color: AppTokens.inverse,
            ),
          ],
        ),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: recentApps.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Your applications will appear here.'),
                ),
              ]
            : recentApps.map((app) {
                final plate = app['plate']!;
                final model = app['model']!;
                final customer = app['customerName']!;
                final status = app['status']!;
                final remainingHint = app['remainingHint']!;
                final route = app['route']!;

                Color badgeBg;
                Color badgeText;
                if (status == 'Ready for pickup') {
                  badgeBg = AppTokens.green;
                  badgeText = AppTokens.raised;
                } else if (status == 'Waiting for approval') {
                  badgeBg = AppTokens.orange;
                  badgeText = AppTokens.inverse;
                } else {
                  badgeBg = AppTokens.blue;
                  badgeText = AppTokens.raised;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppTokens.surface,
                    borderRadius: AppTokens.cardRadius,
                    border: Border.all(color: AppTokens.borderLight),
                  ),
                  child: InkWell(
                    onTap: () => context.push(
                      route,
                      extra: {
                        'jobCardId': app['id'],
                        'registrationNumber': plate,
                      },
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      model,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: AppTokens.textPrimary,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 4.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: AppTokens.inputRadius,
                                    ),
                                    child: Text(
                                      status,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: badgeText,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3.0),
                              Text(
                                '$plate • $customer',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: AppTokens.textTertiary,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3.0),
                              Text(
                                remainingHint,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: AppTokens.textSecondary,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTokens.textTertiary,
                          size: 18.0,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
      ),
    );
  }
}
