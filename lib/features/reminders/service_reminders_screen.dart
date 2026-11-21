import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../ui_kit/tokens/app_tokens.dart';
import 'service_reminder_models.dart';
import 'service_reminder_repository.dart';

class ServiceRemindersScreen extends StatefulWidget {
  const ServiceRemindersScreen({super.key, this.repository});

  final ServiceReminderRepository? repository;

  @override
  State<ServiceRemindersScreen> createState() => _ServiceRemindersScreenState();
}

class _ServiceRemindersScreenState extends State<ServiceRemindersScreen> {
  late final ServiceReminderRepository _repository;
  late Future<ServiceReminderWorkspace> _workspace;
  int _workspaceRevision = 0;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        SupabaseServiceReminderRepository(Supabase.instance.client);
    _workspace = _repository.load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTokens.base,
    appBar: AppBar(
      title: const Text('Service reminders'),
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh reminders',
          onPressed: () => setState(() {
            _workspace = _repository.load();
            _workspaceRevision++;
          }),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<ServiceReminderWorkspace>(
      key: ValueKey(_workspaceRevision),
      future: _workspace,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _loadError(snapshot.error);
        }
        final workspace = snapshot.data!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  workspace.workshopName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'A short list of vehicles due for a check-in, based on your workshop interval and completed visits.',
                  style: TextStyle(color: AppTokens.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 16),
                _settingsCard(workspace),
                const SizedBox(height: 18),
                if (workspace.settings == null)
                  _emptyCard(
                    icon: Icons.tune,
                    title: 'Set your reminder interval',
                    body: 'Choose the interval your workshop recommends. Reminders stay off until you set it.',
                  )
                else
                  _reminderList(workspace),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _settingsCard(ServiceReminderWorkspace workspace) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppTokens.brandRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              workspace.settings == null
                  ? 'Reminder interval not set'
                  : 'Every ${workspace.settings!.intervalKm} km or ${workspace.settings!.intervalDays} days · heads-up ${workspace.settings!.dueSoonDays} days early',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (workspace.canEditSettings)
            TextButton(
              onPressed: () => _editSettings(workspace.settings),
              child: Text(workspace.settings == null ? 'Set' : 'Edit'),
            ),
        ],
      ),
    ),
  );

  Widget _reminderList(ServiceReminderWorkspace workspace) {
    final actionable = workspace.reminders
        .where((item) => item.result.isOverdue || item.result.isDueSoon)
        .toList();
    if (actionable.isEmpty) {
      return _emptyCard(
        icon: Icons.check_circle_outline,
        title: 'No vehicles due for a reminder',
        body: workspace.reminders.isEmpty
            ? 'No completed vehicle visits are recorded yet.'
            : 'Your saved visits are outside the reminder window.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NEEDS A CHECK-IN (${actionable.length})',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        const SizedBox(height: 10),
        for (final reminder in actionable) ...[
          _reminderCard(reminder, workspace.workshopName),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _reminderCard(VehicleServiceReminder reminder, String workshopName) {
    final result = reminder.result;
    final dueLabel = result.isOverdue ? 'OVERDUE' : 'DUE SOON';
    final lastVisit = _formatDate(result.lastServiceDate);
    final nextVisit = _formatDate(result.nextDueDate);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.registrationNumber,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Chip(
                  label: Text(dueLabel),
                  backgroundColor: result.isOverdue
                      ? AppTokens.brandRed.withValues(alpha: .12)
                      : AppTokens.orange.withValues(alpha: .2),
                ),
              ],
            ),
            Text('${result.customerName} · ${result.vehicleModel}'),
            const SizedBox(height: 10),
            Text('Last completed visit: $lastVisit'),
            Text('Odometer at check-in: ${result.lastServiceOdometerKm} km'),
            Text('Suggested check-in: $nextVisit'),
            Text(
              result.triggerReason,
              style: const TextStyle(color: AppTokens.textSecondary),
            ),
            if (result.hasMileageProjection &&
                result.projectedCurrentKm != null) ...[
              const SizedBox(height: 3),
              Text(
                'Estimated odometer: about ${result.projectedCurrentKm} km',
                style: const TextStyle(color: AppTokens.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            if (reminder.whatsappConsent)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () =>
                      _prepareWhatsAppReminder(reminder, workshopName),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Prepare WhatsApp reminder'),
                ),
              )
            else
              const Row(
                children: [
                  Icon(Icons.lock_outline, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'WhatsApp consent not recorded',
                    style: TextStyle(color: AppTokens.textSecondary),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String body,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTokens.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(color: AppTokens.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _loadError(Object? error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 10),
          const Text('Service reminders could not load.'),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => setState(() {
              _workspace = _repository.load();
              _workspaceRevision++;
            }),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
          if (error != null) ...[
            const SizedBox(height: 6),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTokens.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Future<void> _editSettings(ServiceReminderSettings? current) async {
    final settings = await showDialog<ServiceReminderSettings>(
      context: context,
      builder: (_) => _ReminderSettingsDialog(current: current),
    );
    if (settings == null || !mounted) return;
    try {
      await _repository.saveSettings(settings);
      final updatedWorkspace = await _repository.load();
      if (mounted) {
        setState(() {
          _workspace = Future.value(updatedWorkspace);
          _workspaceRevision++;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save interval: $error')),
        );
      }
    }
  }

  Future<void> _prepareWhatsAppReminder(
    VehicleServiceReminder reminder,
    String workshopName,
  ) async {
    try {
      if (!await _repository.hasWhatsAppConsent(reminder.customerId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp consent is no longer recorded.'),
            ),
          );
          setState(() {
            _workspace = _repository.load();
            _workspaceRevision++;
          });
        }
        return;
      }
      final url = Uri.parse(
        reminder.result.buildWhatsAppUrl(workshopName: workshopName),
      );
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not confirm WhatsApp consent. Try again.'),
          ),
        );
      }
    }
  }

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

class _ReminderSettingsDialog extends StatefulWidget {
  const _ReminderSettingsDialog({required this.current});

  final ServiceReminderSettings? current;

  @override
  State<_ReminderSettingsDialog> createState() =>
      _ReminderSettingsDialogState();
}

class _ReminderSettingsDialogState extends State<_ReminderSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _intervalKm;
  late final TextEditingController _intervalDays;
  late final TextEditingController _dueSoonDays;

  @override
  void initState() {
    super.initState();
    _intervalKm = TextEditingController(
      text: widget.current?.intervalKm.toString() ?? '',
    );
    _intervalDays = TextEditingController(
      text: widget.current?.intervalDays.toString() ?? '',
    );
    _dueSoonDays = TextEditingController(
      text: widget.current?.dueSoonDays.toString() ?? '14',
    );
  }

  @override
  void dispose() {
    _intervalKm.dispose();
    _intervalDays.dispose();
    _dueSoonDays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Reminder interval'),
    content: SizedBox(
      width: 380,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Use the interval your workshop recommends. Reminders use the earlier of the distance or calendar interval.',
              style: TextStyle(color: AppTokens.textSecondary),
            ),
            const SizedBox(height: 14),
            _positiveIntegerField(
              _intervalKm,
              label: 'Kilometres between visits',
              max: 1000000,
            ),
            const SizedBox(height: 10),
            _positiveIntegerField(
              _intervalDays,
              label: 'Days between visits',
              max: 3650,
            ),
            const SizedBox(height: 10),
            _positiveIntegerField(
              _dueSoonDays,
              label: 'Show a heads-up this many days early',
              max: 90,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save interval')),
    ],
  );

  Widget _positiveIntegerField(
    TextEditingController controller, {
    required String label,
    required int max,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      final number = int.tryParse(value?.trim() ?? '');
      if (number == null || number < 1 || number > max) {
        return 'Enter a number from 1 to $max';
      }
      return null;
    },
  );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ServiceReminderSettings(
        intervalKm: int.parse(_intervalKm.text.trim()),
        intervalDays: int.parse(_intervalDays.text.trim()),
        dueSoonDays: int.parse(_dueSoonDays.text.trim()),
      ),
    );
  }
}
