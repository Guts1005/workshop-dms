import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase/workshop_database.dart';
import '../../../ui_kit/tokens/app_tokens.dart';

class BayFloorScreen extends StatefulWidget {
  const BayFloorScreen({super.key});

  @override
  State<BayFloorScreen> createState() => _BayFloorScreenState();
}

class _BayFloorScreenState extends State<BayFloorScreen> {
  late Future<List<Map<String, dynamic>>> _applications;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() =>
      _applications = WorkshopDatabase(Supabase.instance.client).applications();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTokens.base,
    appBar: AppBar(
      title: const Text('Active applications'),
      actions: [
        IconButton(
          onPressed: () => setState(_reload),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _applications,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _MessageState(
            icon: Icons.cloud_off_outlined,
            title: 'Applications could not load',
            message: 'Check your connection, then try again.',
            action: () => setState(_reload),
          );
        }
        final active = (snapshot.data ?? const <Map<String, dynamic>>[])
            .where(
              (row) =>
                  !const {'DELIVERED', 'CANCELLED'}.contains(row['statusCode']),
            )
            .toList();
        if (active.isEmpty) {
          return _MessageState(
            icon: Icons.directions_car_outlined,
            title: 'No active applications',
            message: 'New customer check-ins will appear here.',
            action: () => context.push('/intake'),
            actionLabel: 'Start an application',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => setState(_reload),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: active.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final app = active[index];
              return Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              app['plate'] as String? ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          Text(
                            app['status'] as String? ?? 'Open',
                            style: const TextStyle(
                              color: AppTokens.brandRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${app['model'] ?? ''} · ${app['customerName'] ?? ''}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        app['serviceType'] as String? ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        app['remainingHint'] as String? ?? '',
                        style: const TextStyle(color: AppTokens.textSecondary),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => context.push(
                            '/condition-map',
                            extra: {
                              'jobCardId': app['id'],
                              'registrationNumber': app['plate'],
                            },
                          ),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Open condition report'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    this.actionLabel = 'Try again',
  });
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback action;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: AppTokens.textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton(onPressed: action, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}
