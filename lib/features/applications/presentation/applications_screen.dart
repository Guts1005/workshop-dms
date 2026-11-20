import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../ui_kit/tokens/app_tokens.dart';
import '../../../ui_kit/widgets/sharp_card.dart';
import '../../../ui_kit/widgets/status_chip.dart';
import '../../../data/supabase/workshop_database.dart';

/// Production-Grade Applications Screen (Destination 2 of 3)
/// Lists and searches current and past workshop applications / jobs:
/// - Plain human statuses: "Being serviced", "Waiting for approval", "Ready for pickup", "Completed"
/// - Brief remaining-items hint (not a level or workflow stage number)
/// - Searchable by registration plate, customer name, vehicle model, or service type
/// - Detailed information kept behind a tap (clean bottom sheet)
/// - Zero horizontal scrolling, pure AppTokens styling
class ApplicationsScreen extends StatefulWidget {
  final String? initialPlate;

  const ApplicationsScreen({super.key, this.initialPlate});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'ALL';
  String? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final initialPlate = widget.initialPlate;
    if (initialPlate != null && initialPlate.isNotEmpty) {
      _searchQuery = initialPlate;
      _searchController.text = initialPlate;
    }
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final rows = await WorkshopDatabase(Supabase.instance.client)
          .applications();
      if (!mounted) return;
      setState(() {
        _applications
          ..clear()
          ..addAll(
            rows.map(
              (app) => {
                ...app,
                'statusType': _statusType(app['statusCode'] as String),
                'statusColor': _statusColor(app['statusCode'] as String),
              },
            ),
          );
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _loadError =
            'Could not load applications. Check the connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static StatusType _statusType(String status) => switch (status) {
    'READY_FOR_PICKUP' || 'DELIVERED' => StatusType.ok,
    'CANCELLED' => StatusType.critical,
    _ => StatusType.dueSoon,
  };

  static Color _statusColor(String status) => switch (status) {
    'READY_FOR_PICKUP' || 'DELIVERED' => AppTokens.green,
    'CANCELLED' => AppTokens.redOrange,
    _ => AppTokens.blue,
  };

  final List<Map<String, dynamic>> _applications = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900.0;

    final filteredList = _applications.where((app) {
      final matchesQuery =
          _searchQuery.isEmpty ||
          app['plate'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          app['model'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          app['customerName'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          app['serviceType'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      if (!matchesQuery) {
        return false;
      }

      if (_selectedFilter == 'ALL') {
        return true;
      }
      if (_selectedFilter == 'BEING_SERVICED') {
        return app['status'] == 'Being serviced';
      }
      if (_selectedFilter == 'WAITING_APPROVAL') {
        return app['status'] == 'Waiting for approval';
      }
      if (_selectedFilter == 'READY_FOR_PICKUP') {
        return app['status'] == 'Ready for pickup';
      }
      if (_selectedFilter == 'COMPLETED') {
        return app['status'] == 'Completed';
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTokens.base,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            _buildApplicationsHeader(isDesktop, filteredList.length),

            // Search Bar & Filter Pills (Responsive Bounded Wrap)
            _buildSearchAndFilters(isDesktop),

            // Applications List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                  ? _buildLoadError()
                  : filteredList.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 24.0 : 16.0,
                        vertical: 16.0,
                      ),
                      itemCount: filteredList.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12.0),
                      itemBuilder: (context, index) {
                        final app = filteredList[index];
                        return _buildApplicationCard(context, app, isDesktop);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsHeader(bool isDesktop, int count) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24.0 : 16.0,
        vertical: 12.0,
      ),
      decoration: const BoxDecoration(
        color: AppTokens.surface,
        border: Border(
          bottom: BorderSide(color: AppTokens.borderLight, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Applications',
              style: GoogleFonts.inter(
                color: AppTokens.textPrimary,
                fontSize: 20.0,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(
              minHeight: AppTokens.minTouchTarget,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: AppTokens.base,
              border: Border.all(color: AppTokens.borderSolid),
            ),
            child: Text(
              '$count ${count == 1 ? 'application' : 'applications'}',
              style: GoogleFonts.inter(
                color: AppTokens.textPrimary,
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24.0 : 16.0,
        vertical: 12.0,
      ),
      decoration: const BoxDecoration(
        color: AppTokens.surface,
        border: Border(
          bottom: BorderSide(color: AppTokens.borderLight, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Field
          Container(
            height: 52.0,
            decoration: BoxDecoration(
              color: AppTokens.base,
              borderRadius: AppTokens.inputRadius,
              border: Border.all(color: AppTokens.borderSolid),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: AppTokens.textPrimary,
                  size: 20.0,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by plate (e.g. RJ27CA1024), customer name, or service...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14.0,
                        color: AppTokens.textTertiary,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTokens.textPrimary,
                      size: 20.0,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10.0),

          // Filter Pills (Wrap - Zero Horizontal Scroll)
          Wrap(
            spacing: AppTokens.minTouchGap,
            runSpacing: AppTokens.minTouchGap,
            children: [
              _buildFilterChip('ALL', 'All Applications'),
              _buildFilterChip('BEING_SERVICED', 'Being Serviced'),
              _buildFilterChip('WAITING_APPROVAL', 'Waiting for Approval'),
              _buildFilterChip('READY_FOR_PICKUP', 'Ready for Pickup'),
              _buildFilterChip('COMPLETED', 'Completed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return InkWell(
      borderRadius: AppTokens.cardRadius,
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppTokens.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? AppTokens.inverse : AppTokens.base,
          borderRadius: AppTokens.cardRadius,
          border: Border.all(
            color: isSelected ? AppTokens.inverse : AppTokens.borderLight,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? AppTokens.textOnDark : AppTokens.textSecondary,
            fontSize: 14.0,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Clean, Scannable Application Card (Avoids Text-Heavy Overload)
  Widget _buildApplicationCard(
    BuildContext context,
    Map<String, dynamic> app,
    bool isDesktop,
  ) {
    final plate = app['plate'] as String;
    final model = app['model'] as String;
    final service = app['serviceType'] as String;
    final status = app['status'] as String;
    final remainingHint = app['remainingHint'] as String;

    Color badgeBg;
    Color badgeText;
    if (status == 'Ready for pickup') {
      badgeBg = AppTokens.green;
      badgeText = AppTokens.raised;
    } else if (status == 'Waiting for approval') {
      badgeBg = AppTokens.orange;
      badgeText = AppTokens.inverse;
    } else if (status == 'Being serviced') {
      badgeBg = AppTokens.blue;
      badgeText = AppTokens.raised;
    } else {
      badgeBg = AppTokens.surfaceSubtle;
      badgeText = AppTokens.textSecondary;
    }

    return Material(
      color: AppTokens.surface,
      child: InkWell(
        onTap: () => _showApplicationDetailModal(context, app),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTokens.borderSolid, width: 1.0),
          ),
          padding: EdgeInsets.all(isDesktop ? 20.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppTokens.textPrimary,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          service,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppTokens.textSecondary,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTokens.textPrimary,
                    size: 24.0,
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Wrap(
                spacing: AppTokens.minTouchGap,
                runSpacing: AppTokens.minTouchGap,
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: AppTokens.minTouchTarget,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      color: AppTokens.base,
                      border: Border.all(color: AppTokens.borderSolid),
                    ),
                    child: Text(
                      plate,
                      style: GoogleFonts.jetBrainsMono(
                        color: AppTokens.textPrimary,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: AppTokens.minTouchTarget,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    color: badgeBg,
                    child: Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: badgeText,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                color: AppTokens.surfaceSubtle,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20.0,
                      color: AppTokens.textPrimary,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        remainingHint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppTokens.textPrimary,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Detailed Information Kept Behind a Tap (Bottom Sheet Modal)
  void _showApplicationDetailModal(
    BuildContext context,
    Map<String, dynamic> app,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final pending = (app['pendingItems'] as List<String>?) ?? [];

        return Container(
          decoration: const BoxDecoration(
            color: AppTokens.surface,
            borderRadius: AppTokens.zeroRadius,
          ),
          padding: const EdgeInsets.all(16.0),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 40.0,
                      height: 4.0,
                      decoration: const BoxDecoration(
                        color: AppTokens.borderLight,
                        borderRadius: AppTokens.pillRadius,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Header with Plate and Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app['plate'] as String,
                            style: GoogleFonts.inter(
                              color: AppTokens.textPrimary,
                              fontSize: 18.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            app['model'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppTokens.textSecondary,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(modalContext).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14.0),

                  // Status & Hint Callout
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppTokens.surfaceSubtle,
                      borderRadius: AppTokens.inputRadius,
                      border: Border.all(color: AppTokens.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT STATUS: ${app['status']}'.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: AppTokens.textPrimary,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          app['remainingHint'] as String,
                          style: GoogleFonts.inter(
                            color: AppTokens.textSecondary,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Customer & Assignment Pod
                  SharpCard(
                    title: 'CONTACT & ASSIGNMENT',
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Customer',
                          '${app['customerName']} (${app['customerPhone']})',
                        ),
                        const SizedBox(height: 6.0),
                        _buildDetailRow(
                          'Assigned Technician',
                          '${app['technician']} • ${app['bay']}',
                        ),
                        const SizedBox(height: 6.0),
                        _buildDetailRow(
                          'Service Requested',
                          app['serviceType'] as String,
                        ),
                        const SizedBox(height: 6.0),
                        _buildDetailRow(
                          'Est. Completion',
                          app['estimatedCompletion'] as String,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Keep the user's next actions visible without exposing
                  // internal workflow or AI processing stages.
                  if (pending.isNotEmpty) ...[
                    Text(
                      'WHAT’S LEFT',
                      style: GoogleFonts.inter(
                        color: AppTokens.brandRed,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    ...pending.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.pending_actions_rounded,
                              color: AppTokens.brandRed,
                              size: 20.0,
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.inter(
                                  color: AppTokens.textPrimary,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ],

                  // Only expose workspaces that are implemented.
                  if (app['route'] == '/bay-capture' ||
                      app['route'] == '/job-card' ||
                      app['route'] == '/condition-map')
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(modalContext).pop();
                        context.push(
                          app['route'] as String,
                          extra: {
                            'jobCardId': app['id'],
                            'registrationNumber': app['plate'],
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.inverse,
                        foregroundColor: AppTokens.textOnDark,
                        minimumSize: const Size.fromHeight(
                          AppTokens.minTouchTarget,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppTokens.zeroRadius,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        (app['nextActionLabel'] as String? ??
                                'Open application')
                            .toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTokens.textSecondary,
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppTokens.textPrimary,
              fontSize: 16.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 40.0,
              color: AppTokens.textTertiary,
            ),
            const SizedBox(height: 12.0),
            Text(
              _searchQuery.isEmpty
                  ? 'No applications yet'
                  : 'No applications match your search',
              style: GoogleFonts.inter(
                color: AppTokens.textPrimary,
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              _searchQuery.isEmpty
                  ? 'Create an application to start recording workshop work.'
                  : 'Try a different plate, customer name, or status filter.',
              style: GoogleFonts.inter(
                color: AppTokens.textSecondary,
                fontSize: 12.0,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => context.push('/intake'),
                icon: const Icon(Icons.add),
                label: const Text('Create application'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: AppTokens.textTertiary,
          ),
          const SizedBox(height: 10),
          const Text('Applications could not be loaded.'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loadApplications,
            child: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
