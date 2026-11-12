import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/non_field_activity_data.dart';
import '../../services/non_field_activity_service.dart';

class NonFieldActivityPage extends StatefulWidget {
  const NonFieldActivityPage({super.key});

  @override
  State<NonFieldActivityPage> createState() => _NonFieldActivityPageState();
}

class _NonFieldActivityPageState extends State<NonFieldActivityPage> {
  final NonFieldActivityService _service = NonFieldActivityService();
  late Future<List<NonFieldActivityRecord>> _activities;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _activities = _service.loadActivities();
  }

  Future<void> _refresh() async {
    final request = _service.loadActivities();
    setState(() => _activities = request);
    await request;
  }

  Future<void> _openForm({NonFieldActivityRecord? record}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NonFieldActivityFormPage(
          service: _service,
          record: record,
        ),
      ),
    );
    if (!mounted || saved != true) return;
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submitted for manager authorisation.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Non-field activity'),
              Text(
                'Your recent submissions',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('New activity'),
        ),
        body: FutureBuilder<List<NonFieldActivityRecord>>(
          future: _activities,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ActivityError(
                message: snapshot.error is ApiException
                    ? (snapshot.error as ApiException).message
                    : 'Unable to load activities.',
                onRetry: _refresh,
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final activities = snapshot.data!;
            final pending =
                activities.where((item) => item.statusCode == 'T').length;
            final confirmed =
                activities.where((item) => item.statusCode == 'A').length;
            final visibleActivities = activities.where((item) {
              return _statusFilter == 'All' || item.status == _statusFilter;
            }).toList(growable: false);

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  _OverviewCard(
                    total: activities.length,
                    pending: pending,
                    confirmed: confirmed,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'ACTIVITY HISTORY',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                        ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in [
                          'All',
                          'Pending',
                          'Confirmed',
                          'Rejected',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: _statusFilter == filter,
                              showCheckmark: false,
                              onSelected: (_) =>
                                  setState(() => _statusFilter = filter),
                              selectedColor:
                                  AppColors.navy.withValues(alpha: 0.12),
                              side: BorderSide(
                                color: _statusFilter == filter
                                    ? AppColors.navy
                                    : AppColors.border,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (visibleActivities.isEmpty)
                    _ActivityEmpty(
                      filtered: activities.isNotEmpty,
                      onAdd: () => _openForm(),
                    )
                  else
                    for (final activity in visibleActivities)
                      _ActivityCard(
                        activity: activity,
                        onTap: activity.canEdit
                            ? () => _openForm(record: activity)
                            : () => _showDetails(activity),
                      ),
                ],
              ),
            );
          },
        ),
      );

  void _showDetails(NonFieldActivityRecord activity) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.activity,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(_dateLabel(activity.date)),
              const SizedBox(height: 16),
              const Text('Remarks',
                  style: TextStyle(
                      color: AppColors.muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              Text(activity.remarks),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.total,
    required this.pending,
    required this.confirmed,
  });

  final int total;
  final int pending;
  final int confirmed;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navy, Color(0xFF155473)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity snapshot · last 3 months',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Text(
              '$total submissions',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _OverviewMetric(label: 'Pending', value: pending),
                const SizedBox(width: 24),
                _OverviewMetric(label: 'Confirmed', value: confirmed),
              ],
            ),
          ],
        ),
      );
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.onTap});

  final NonFieldActivityRecord activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(activity.statusCode);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_activityIcon(activity.activityType),
                    color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activity.activity,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(
                          label: activity.status,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _dateLabel(activity.date),
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    if (activity.remarks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        activity.remarks,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(height: 1.3),
                      ),
                    ],
                    if (activity.statusCode == 'X') ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to edit and resubmit',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _ActivityEmpty extends StatelessWidget {
  const _ActivityEmpty({required this.filtered, required this.onAdd});

  final bool filtered;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 18),
        child: Column(
          children: [
            Icon(
              filtered ? Icons.filter_list_off : Icons.event_note_outlined,
              size: 44,
              color: AppColors.muted,
            ),
            const SizedBox(height: 10),
            Text(
              filtered
                  ? 'No activities match this status.'
                  : 'No activities in the last three months.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            if (!filtered) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add an activity'),
              ),
            ],
          ],
        ),
      );
}

class NonFieldActivityFormPage extends StatefulWidget {
  const NonFieldActivityFormPage({
    super.key,
    required this.service,
    this.record,
  });

  final NonFieldActivityService service;
  final NonFieldActivityRecord? record;

  @override
  State<NonFieldActivityFormPage> createState() =>
      _NonFieldActivityFormPageState();
}

class _NonFieldActivityFormPageState extends State<NonFieldActivityFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _remarks = TextEditingController();
  late Future<List<NonFieldActivityType>> _options;
  late DateTime _date;
  String? _activityType;
  bool _saving = false;

  bool get _editing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _date = record?.date ?? DateTime.now();
    _activityType = record?.activityType;
    _remarks.text = record?.remarks ?? '';
    _options = widget.service.loadOptions();
  }

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  void _reloadOptions() {
    setState(() => _options = widget.service.loadOptions());
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: currentDate,
      lastDate: currentDate,
      helpText: 'Select activity date',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.service.save(
        date: _date,
        activityType: _activityType!,
        remarks: _remarks.text.trim(),
        activityId: widget.record?.id,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_editing ? 'Resubmit activity' : 'New activity'),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.navy, Color(0xFF155473)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.event_available_outlined,
                                color: Colors.white, size: 25),
                            SizedBox(height: 12),
                            Text(
                              'Log your workday',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Submit a non-field activity for manager review.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _FormLabel(
                        title: 'Activity date',
                        subtitle: 'Choose a date within the last three months',
                      ),
                      const SizedBox(height: 9),
                      InkWell(
                        onTap: _editing || _saving ? null : _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            prefixIcon:
                                const Icon(Icons.calendar_today_outlined),
                            suffixIcon: _editing
                                ? null
                                : const Icon(Icons.keyboard_arrow_down),
                            enabled: !_saving,
                          ),
                          child: Text(_dateLabel(_date)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _FormLabel(
                        title: 'Activity type',
                        subtitle:
                            'Select the activity that best describes your day',
                      ),
                      const SizedBox(height: 9),
                      FutureBuilder<List<NonFieldActivityType>>(
                        future: _options,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _FormLookupError(
                              message: snapshot.error is ApiException
                                  ? (snapshot.error as ApiException).message
                                  : 'Unable to load activity types.',
                              onRetry: _reloadOptions,
                            );
                          }
                          if (!snapshot.hasData) {
                            return const LinearProgressIndicator();
                          }
                          final options = snapshot.data!;
                          NonFieldActivityType? selected;
                          for (final option in options) {
                            if (option.code == _activityType) {
                              selected = option;
                              break;
                            }
                          }
                          return DropdownButtonFormField<String>(
                            initialValue: selected?.code,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.category_outlined),
                              hintText: 'Select activity',
                            ),
                            items: options
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item.code,
                                    child: Text(item.description),
                                  ),
                                )
                                .toList(growable: false),
                            validator: (value) => value == null
                                ? 'Please select an activity'
                                : null,
                            onChanged: _saving
                                ? null
                                : (value) =>
                                    setState(() => _activityType = value),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const _FormLabel(
                        title: 'Remarks',
                        subtitle: 'Add a short note for your manager',
                      ),
                      const SizedBox(height: 9),
                      TextFormField(
                        controller: _remarks,
                        enabled: !_saving,
                        maxLength: 500,
                        minLines: 4,
                        maxLines: 6,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'What did you work on?',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Please enter a remark'
                                : null,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(
                        _editing
                            ? 'Resubmit for approval'
                            : 'Submit for approval',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.navy,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      );
}

class _FormLookupError extends StatelessWidget {
  const _FormLookupError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: Colors.red)),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
}

class _ActivityError extends StatelessWidget {
  const _ActivityError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 42, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

Color _statusColor(String code) => switch (code) {
      'T' => const Color(0xFFB36B00),
      'A' => const Color(0xFF23834A),
      'X' => const Color(0xFFB42318),
      _ => AppColors.muted,
    };

IconData _activityIcon(String type) => switch (type.toUpperCase()) {
      'C' || 'CAM' => Icons.campaign_outlined,
      'E' => Icons.storefront_outlined,
      'I' => Icons.school_outlined,
      'M' => Icons.groups_outlined,
      'T' => Icons.menu_book_outlined,
      _ => Icons.work_outline,
    };

String _dateLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}
