import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/employee_context.dart';
import '../../providers/employee_provider.dart';
import '../../services/tour_plan_service.dart';
import 'field_work_page.dart';

class TourPlansPage extends StatefulWidget {
  const TourPlansPage({super.key});
  @override
  State<TourPlansPage> createState() => _TourPlansPageState();
}

class _TourPlansPageState extends State<TourPlansPage> {
  final tourPlanService = TourPlanService();
  late Future<Map<String, dynamic>> _future;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final Map<String, Map<String, dynamic>> _drafts = {};
  late final String _employeeScope;
  String _status = 'Draft';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _employeeScope = _scopeFor(context.read<EmployeeProvider>().employee);
    _future = _loadMonth(_month);
  }

  String _key(int day) => '${_month.year}-${_month.month}-$day';
  String _keyFor(DateTime month, int day) =>
      '${month.year}-${month.month}-$day';
  String _monthPrefix(DateTime month) => '${month.year}-${month.month}-';
  // Calendar columns are Sunday through Saturday, so Sunday has offset 0.
  int get _leadingDays => DateTime(_month.year, _month.month, 1).weekday % 7;

  bool _isPreloadedHoliday(int day) {
    final date = DateTime(_month.year, _month.month, day);
    return date.weekday == DateTime.sunday;
  }

  String _scopeFor(EmployeeContext? employee) => [
        employee?.empId?.toString() ?? employee?.loginId ?? 'unknown',
        employee?.newGeoId?.toString() ?? '',
        employee?.geoLevel?.toString() ?? '',
        employee?.divisions.join(',') ?? '',
      ].join(':');

  Future<Map<String, dynamic>> _loadMonth(DateTime month) async {
    final data = await tourPlanService.loadMonth(month);
    final status = data['status']?.toString().toUpperCase();
    _status = 'Draft';
    if (status != 'A' && status != 'T') {
      final remoteDays = data['days'];
      if (remoteDays is List) {
        for (final value in remoteDays) {
          if (value is! Map) continue;
          final day = Map<String, dynamic>.from(value);
          final number = int.tryParse('${day['date']}');
          if (number == null) continue;
          _drafts.putIfAbsent(
            _keyFor(month, number),
            () => {...day, 'date': number},
          );
        }
      }

      final localDrafts = await tourPlanService.loadLocalDrafts(
        employeeScope: _employeeScope,
        month: month,
      );
      for (final entry in localDrafts.entries) {
        _drafts[_keyFor(month, entry.key)] = {
          ...entry.value,
          'date': entry.key,
        };
      }
    }
    return data;
  }

  DateTime get _fiscalYearStart {
    final now = DateTime.now();
    final year = now.month >= 4 ? now.year : now.year - 1;
    return DateTime(year, 4);
  }

  DateTime get _fiscalYearEnd =>
      DateTime(_fiscalYearStart.year + 1, _fiscalYearStart.month);

  bool get _canSubmit {
    final count = DateTime(_month.year, _month.month + 1, 0).day;
    for (var day = 1; day <= count; day++) {
      if (_isPreloadedHoliday(day)) continue;
      final entry = _drafts[_key(day)];
      final activity = entry?['activity'] as String?;
      final activityType = entry?['activity_type'] as String?;
      final route = entry?['route'] as String?;
      if (activity == null ||
          activity.isEmpty ||
          ((activityType == 'F' || activity == 'Field Work') &&
              (route == null || route.isEmpty))) {
        return false;
      }
    }
    return true;
  }

  List<Map<String, dynamic>> _draftDays() {
    final count = DateTime(_month.year, _month.month + 1, 0).day;
    return List.generate(count, (i) {
      final dayNumber = i + 1;
      final date = DateTime(_month.year, _month.month, dayNumber);
      final entry = _drafts[_key(dayNumber)];
      final preloadedHoliday = _isPreloadedHoliday(dayNumber);
      return {
        'date': '$dayNumber'.padLeft(2, '0'),
        'kind':
            entry == null ? (preloadedHoliday ? 'holiday' : 'empty') : 'draft',
        'title': entry?['route'] ??
            entry?['activity'] ??
            (preloadedHoliday ? 'Sunday' : _weekdayName(date)),
        'weekday': _weekdayName(date),
        'remarks': entry?['remarks'] ?? '',
        'activity': entry?['activity'] ?? (preloadedHoliday ? 'Sunday' : null),
        'route': entry?['route'],
        'counts': entry?['counts'] ?? <String, int>{},
      };
    });
  }

  List<Map<String, dynamic>> _finalizedDays(
    List<Map<String, dynamic>> plannedDays,
  ) {
    final daysByNumber = {
      for (final day in plannedDays)
        if (int.tryParse('${day['date']}') != null)
          int.parse('${day['date']}'): day,
    };
    final count = DateTime(_month.year, _month.month + 1, 0).day;
    for (var day = 1; day <= count; day++) {
      final date = DateTime(_month.year, _month.month, day);
      daysByNumber.putIfAbsent(
        day,
        () => {
          'date': '$day'.padLeft(2, '0'),
          'kind':
              date.weekday == DateTime.sunday ? 'holiday' : 'calendar-empty',
          'title': date.weekday == DateTime.sunday ? 'Sunday' : '',
          'weekday': _weekdayName(date),
          'counts': <String, int>{},
        },
      );
    }
    final days = daysByNumber.values.toList()
      ..sort((left, right) => int.parse('${left['date']}')
          .compareTo(int.parse('${right['date']}')));
    return days;
  }

  void _move(int amount) {
    final next = DateTime(_month.year, _month.month + amount);
    if (_monthNumber(next) >= _monthNumber(_fiscalYearStart) &&
        _monthNumber(next) <= _monthNumber(_fiscalYearEnd)) {
      setState(() {
        _month = next;
        _future = _loadMonth(next);
      });
    }
  }

  int _monthNumber(DateTime value) => value.year * 12 + value.month;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tour Plans')),
        body: FutureBuilder<dynamic>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _TourPlanLoading(
                month: _month,
                leadingDays: _leadingDays,
                dayCount: DateTime(_month.year, _month.month + 1, 0).day,
                previous: _monthNumber(_month) <= _monthNumber(_fiscalYearStart)
                    ? null
                    : () => _move(-1),
                next: _monthNumber(_month) >= _monthNumber(_fiscalYearEnd)
                    ? null
                    : () => _move(1),
              );
            }
            if (snapshot.hasError)
              return const Center(child: Text('Unable to load tour plans.'));
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final plannedDays = (snapshot.data['days'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            final planStatus =
                snapshot.data['status']?.toString().toUpperCase();
            final finalized = planStatus == 'A' || planStatus == 'T';
            final days = finalized ? _finalizedDays(plannedDays) : _draftDays();
            return LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 850;
              return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),
                  children: [
                    _MonthBar(
                        month: _month,
                        status: finalized
                            ? (planStatus == 'A'
                                ? 'Approved'
                                : 'Pending Authorization')
                            : _status,
                        previous: _monthNumber(_month) <=
                                _monthNumber(_fiscalYearStart)
                            ? null
                            : () => _move(-1),
                        next:
                            _monthNumber(_month) >= _monthNumber(_fiscalYearEnd)
                                ? null
                                : () => _move(1)),
                    const SizedBox(height: 12),
                    if (!finalized)
                      _EmptyBanner(
                        count: _drafts.keys
                            .where(
                                (key) => key.startsWith(_monthPrefix(_month)))
                            .length,
                      ),
                    if (wide) const _WeekHeader(),
                    Builder(builder: (context) {
                      final leading = wide ? _leadingDays : 0;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: days.length + leading,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: wide ? 7 : 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          mainAxisExtent: wide ? 144 : 172,
                        ),
                        itemBuilder: (context, index) {
                          if (index < leading) return const SizedBox.shrink();
                          final day = days[index - leading];
                          return _TourDayCard(
                            day: day,
                            compact: wide,
                            draft: !finalized,
                            onTap: !finalized && day['kind'] != 'holiday'
                                ? () => _editDay(context, day)
                                : finalized && day['kind'] == 'route'
                                    ? () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => RouteCustomersPage(
                                              route: {
                                                'routeNo': day['routeId'],
                                                'name': day['summary'],
                                              },
                                            ),
                                          ),
                                        )
                                    : null,
                          );
                        },
                      );
                    }),
                    if (!finalized) ...[
                      const SizedBox(height: 18),
                      FilledButton.icon(
                          onPressed: !_canSubmit || _submitting
                              ? null
                              : _submitForAuthorization,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded),
                          label: Text(_submitting
                              ? 'Sending for authorization...'
                              : 'Send for Auth')),
                    ],
                  ]);
            });
          },
        ),
      );

  Future<void> _editDay(BuildContext context, Map<String, dynamic> day) async {
    final number = int.parse('${day['date']}');
    final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _PlanEditor(
            day: number,
            month: _month,
            service: tourPlanService,
            initial: _drafts[_key(number)]));
    if (!mounted || result == null) return;
    final key = _key(number);
    final previous = _drafts[key];
    setState(() => _drafts[key] = {...result, 'date': number});
    try {
      await tourPlanService.saveLocalDrafts(
        employeeScope: _employeeScope,
        month: _month,
        drafts: {
          for (final entry in _drafts.entries)
            if (entry.key.startsWith(_monthPrefix(_month)))
              int.parse(entry.key.split('-').last): entry.value,
        },
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        if (previous == null) {
          _drafts.remove(key);
        } else {
          _drafts[key] = previous;
        }
      });
      _showMessage(
        error.message ?? 'The draft could not be saved on this device.',
        error: true,
      );
      return;
    }
    if (mounted) _showMessage('Draft saved on this device.');
  }

  Future<void> _submitForAuthorization() async {
    setState(() => _submitting = true);
    try {
      await tourPlanService.submit(
        month: _month,
        days: _drafts.entries
            .where((entry) => entry.key.startsWith(_monthPrefix(_month)))
            .map((entry) => entry.value),
      );
      String? cacheWarning;
      try {
        await tourPlanService.clearLocalDrafts(
          employeeScope: _employeeScope,
          month: _month,
        );
      } on PlatformException catch (error) {
        cacheWarning = error.message;
      }
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _status = 'Awaiting authorization';
        _future = tourPlanService.loadMonth(_month);
      });
      _showMessage(
        cacheWarning == null
            ? 'Tour plan sent for authorization successfully.'
            : 'Tour plan was submitted, but its local draft could not be cleared: $cacheWarning',
        error: cacheWarning != null,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(error.message, error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? Colors.red : null,
    ));
  }
}

class _TourPlanLoading extends StatelessWidget {
  const _TourPlanLoading({
    required this.month,
    required this.leadingDays,
    required this.dayCount,
    this.previous,
    this.next,
  });

  final DateTime month;
  final int leadingDays;
  final int dayCount;
  final VoidCallback? previous;
  final VoidCallback? next;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;
          final leading = wide ? leadingDays : 0;
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),
            children: [
              _MonthBar(
                month: month,
                status: 'Loading',
                previous: previous,
                next: next,
              ),
              const SizedBox(height: 8),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Loading tour plans...'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (wide) const _WeekHeader(),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dayCount + leading,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: wide ? 7 : 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: wide ? 144 : 172,
                ),
                itemBuilder: (context, index) => index < leading
                    ? const SizedBox.shrink()
                    : _TourDayPlaceholder(compact: wide),
              ),
            ],
          );
        },
      );
}

class _TourDayPlaceholder extends StatelessWidget {
  const _TourDayPlaceholder({
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) => Card(
        child: SizedBox(
          height: compact ? 114 : 150,
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: compact ? 26 : 30,
                      height: compact ? 26 : 30,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.62,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _MonthBar extends StatelessWidget {
  const _MonthBar(
      {required this.month, required this.status, this.previous, this.next});
  final DateTime month;
  final String status;
  final VoidCallback? previous;
  final VoidCallback? next;
  @override
  Widget build(BuildContext context) => Row(children: [
        IconButton(onPressed: previous, icon: const Icon(Icons.chevron_left)),
        Expanded(
            child: Column(children: [
          Text('${_monthName(month.month)} ${month.year}',
              style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy)),
          const SizedBox(height: 3),
          Chip(
              label: Text(status),
              visualDensity: VisualDensity.compact,
              backgroundColor: status == 'Approved'
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFF3CD))
        ])),
        IconButton(onPressed: next, icon: const Icon(Icons.chevron_right)),
      ]);
}

class _EmptyBanner extends StatelessWidget {
  const _EmptyBanner({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Card(
      color: const Color(0xFFEAF5FF),
      child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Icon(Icons.edit_calendar_rounded, color: AppColors.navy),
            const SizedBox(width: 10),
            const Expanded(
                child: Text(
                    'No finalized plan for this month. Tap any date to add a tour plan.',
                    style: TextStyle(color: AppColors.navy))),
            if (count > 0)
              Text('$count added',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
          ])));
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader();
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Text('Sun'),
        Text('Mon'),
        Text('Tue'),
        Text('Wed'),
        Text('Thu'),
        Text('Fri'),
        Text('Sat')
      ]));
}

class _TourDayCard extends StatelessWidget {
  const _TourDayCard(
      {required this.day,
      required this.compact,
      required this.draft,
      this.onTap});
  final Map<String, dynamic> day;
  final bool compact;
  final bool draft;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final kind = '${day['kind']}';
    final route = kind == 'route';
    final populatedDraft = draft && kind == 'draft' && day['route'] != null;
    final empty = kind == 'empty';
    final remark = day['remarks']?.toString() ?? '';
    final rawCounts = day['counts'];
    const countKeys = {
      'retailer',
      'chemist',
      'doctor',
      'vaidya',
      'stockist',
      'institution',
      'retailer_count',
      'chemist_count',
      'doctor_count',
      'vaidya_count',
      'stockist_count',
      'institution_count',
      'retailerCount',
      'chemistCount',
      'doctorCount',
      'vaidyaCount',
      'stockistCount',
      'institutionCount',
    };
    final counts = rawCounts is Map
        ? Map<String, dynamic>.from(rawCounts)
        : populatedDraft
            ? <String, dynamic>{}
            : Map<String, dynamic>.fromEntries(
                day.entries.where((entry) => countKeys.contains(entry.key)));
    final color = kind == 'holiday'
        ? Colors.red
        : kind == 'leave'
            ? Colors.orange
            : empty
                ? AppColors.muted
                : AppColors.navy;
    return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onTap,
            child: Padding(
                padding: EdgeInsets.all(compact ? 8 : 12),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            width: compact ? 29 : 34,
                            height: compact ? 29 : 34,
                            decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8)),
                            child: Center(
                                child: Text('${day['date']}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)))),
                        const SizedBox(width: 7),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('${day['title']}',
                                  maxLines: compact ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: color,
                                      fontSize: compact ? 11 : 14,
                                      fontWeight: FontWeight.bold)),
                              if (!compact &&
                                  populatedDraft &&
                                  day['weekday'] != null)
                                Text('${day['weekday']}',
                                    style: const TextStyle(
                                        color: AppColors.muted, fontSize: 10)),
                            ]))
                      ]),
                      if (route || populatedDraft) ...[
                        SizedBox(height: compact ? 5 : 7),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final item in counts.entries)
                                if (item.value != null) ...[
                                  _VisitCount(
                                    label: _countLabel(item.key),
                                    value: '${item.value}',
                                  ),
                                  const SizedBox(width: 4),
                                ],
                            ],
                          ),
                        ),
                      ] else if (empty)
                        Padding(
                            padding: EdgeInsets.only(top: compact ? 7 : 9),
                            child: Row(children: [
                              const Icon(Icons.add_circle_outline,
                                  size: 16, color: AppColors.muted),
                              const SizedBox(width: 5),
                              const Text('Tap to add',
                                  style: TextStyle(
                                      color: AppColors.muted, fontSize: 12))
                            ]))
                      else if (kind == 'leave' || kind == 'holiday')
                        Padding(
                            padding: EdgeInsets.only(top: compact ? 7 : 9),
                            child: Text(
                                kind == 'leave' ? 'Leave' : 'Non-working day',
                                style: TextStyle(color: color, fontSize: 12))),
                      if (remark.isNotEmpty)
                        Padding(
                            padding: EdgeInsets.only(top: compact ? 4 : 6),
                            child: _RemarkPreview(remark: remark)),
                    ]))));
  }
}

class _PlanEditor extends StatefulWidget {
  const _PlanEditor({
    required this.day,
    required this.month,
    required this.service,
    this.initial,
  });
  final int day;
  final DateTime month;
  final TourPlanService service;
  final Map<String, dynamic>? initial;
  @override
  State<_PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<_PlanEditor> {
  final formKey = GlobalKey<FormState>();
  final remarks = TextEditingController();
  late Future<List<TourPlanActivity>> _activitiesFuture;
  Future<List<TourPlanRoute>>? _routesFuture;
  List<TourPlanRoute> _routeOptions = const [];
  String? _activityCode;
  String? _activityDescription;
  int? _routeId;
  String? _routeLabel;
  Map<String, dynamic> _routeCounts = const {};
  int _routeVersion = 0;

  DateTime get _date =>
      DateTime(widget.month.year, widget.month.month, widget.day);
  bool get _routeDisabled => _activityCode != 'F';

  @override
  void initState() {
    super.initState();
    _activitiesFuture = widget.service.loadActivities();
    _activityCode = widget.initial == null
        ? 'F'
        : widget.initial?['activity_type']?.toString();
    _activityDescription = widget.initial == null
        ? 'Field Work'
        : widget.initial?['activity']?.toString();
    _routeId = int.tryParse('${widget.initial?['route_id'] ?? ''}') ??
        int.tryParse(
            (widget.initial?['route']?.toString() ?? '').split(' ').first);
    _routeLabel = widget.initial?['route']?.toString();
    final initialCounts = widget.initial?['counts'];
    if (initialCounts is Map) {
      _routeCounts = Map<String, dynamic>.from(initialCounts);
    }
    if (_activityCode == 'F' || _activityDescription == 'Field Work') {
      _routesFuture = widget.service.loadRoutes(_date);
    }
    remarks.text = '${widget.initial?['remarks'] ?? ''}';
  }

  void _selectActivity(TourPlanActivity? value) {
    setState(() {
      _activityCode = value?.code;
      _activityDescription = value?.description;
      _routeId = null;
      _routeLabel = null;
      _routeCounts = const {};
      _routeOptions = const [];
      _routeVersion++;
      _routesFuture =
          value?.code == 'F' ? widget.service.loadRoutes(_date) : null;
    });
  }

  TourPlanActivity? _selectedActivity(List<TourPlanActivity> activities) {
    for (final item in activities) {
      if (item.code == _activityCode ||
          item.description == _activityDescription) {
        return item;
      }
    }
    return null;
  }

  @override
  void dispose() {
    remarks.dispose();
    super.dispose();
  }

  Widget _activityField() => FutureBuilder<List<TourPlanActivity>>(
        future: _activitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LookupError(
              message: 'Unable to load activities: ${snapshot.error}',
              onRetry: () => setState(
                  () => _activitiesFuture = widget.service.loadActivities()),
            );
          }
          if (!snapshot.hasData) {
            return const LinearProgressIndicator();
          }
          final activities = snapshot.data!;
          final selectedActivity = _selectedActivity(activities);
          if (selectedActivity != null) {
            _activityCode = selectedActivity.code;
            _activityDescription = selectedActivity.description;
          }
          return DropdownButtonFormField<TourPlanActivity>(
            initialValue: selectedActivity,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'Activity',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: activities
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item.description),
                    ))
                .toList(),
            validator: (value) =>
                value == null ? 'Please select an activity' : null,
            onChanged: _selectActivity,
          );
        },
      );

  Widget _routeField() {
    if (_routeDisabled) {
      return const SizedBox.shrink();
    }
    final future = _routesFuture;
    if (future == null) return const LinearProgressIndicator();
    return FutureBuilder<List<TourPlanRoute>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LookupError(
            message: 'Unable to load routes: ${snapshot.error}',
            onRetry: () => setState(
                () => _routesFuture = widget.service.loadRoutes(_date)),
          );
        }
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final routes = snapshot.data!;
        _routeOptions = routes;
        if (routes.isEmpty) {
          return const Text('No routes are available for this date.');
        }
        TourPlanRoute? selectedRoute;
        for (final item in routes) {
          if (item.routeId == _routeId) {
            selectedRoute = item;
            break;
          }
        }
        if (selectedRoute != null) {
          _routeLabel = selectedRoute.label;
          _routeCounts = selectedRoute.customerCounts;
        }
        return DropdownButtonFormField<int>(
          key: ValueKey(_routeVersion),
          initialValue: selectedRoute?.routeId,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            labelText: 'Route',
            prefixIcon: Icon(Icons.route_outlined),
          ),
          items: routes
              .map((item) => DropdownMenuItem(
                    value: item.routeId,
                    child: Text(item.label),
                  ))
              .toList(),
          validator: (value) => _activityCode == 'F' && value == null
              ? 'Route is required for Field Work'
              : null,
          onChanged: (value) => setState(() {
            _routeId = value;
            for (final route in routes) {
              if (route.routeId == value) {
                _routeLabel = route.label;
                _routeCounts = route.customerCounts;
                break;
              }
            }
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Form(
          key: formKey,
          child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    'Plan for ${_weekdayName(DateTime(widget.month.year, widget.month.month, widget.day))}, ${widget.day} ${_monthName(widget.month.month)}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy)),
                const SizedBox(height: 18),
                _activityField(),
                const SizedBox(height: 12),
                _routeField(),
                const SizedBox(height: 12),
                TextField(
                    controller: remarks,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Remarks',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_outlined))),
                const SizedBox(height: 18),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        onPressed: () {
                          final activityMissing =
                              _activityCode == null || _activityCode!.isEmpty;
                          if (!formKey.currentState!.validate() ||
                              activityMissing ||
                              (_activityCode == 'F' && _routeId == null)) {
                            if (activityMissing) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Select an available activity.'),
                                ),
                              );
                            }
                            if (_activityCode == 'F' && _routeId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Select an available route for Field Work.'),
                                ),
                              );
                            }
                            return;
                          }
                          final selectedActivity =
                              _activityDescription?.trim().isNotEmpty == true
                                  ? _activityDescription
                                  : _activityCode;
                          final selectedRouteId =
                              _routeDisabled ? null : _routeId;
                          int? selectedRouteHq;
                          String? selectedRouteLabel;
                          if (selectedRouteId != null) {
                            for (final item in _routeOptions) {
                              if (item.routeId == selectedRouteId) {
                                selectedRouteLabel = item.label;
                                selectedRouteHq = item.tourHq;
                                break;
                              }
                            }
                            selectedRouteLabel ??=
                                _routeLabel ?? selectedRouteId.toString();
                          }
                          Navigator.pop(context, {
                            'activity_type': _activityCode,
                            'activity': selectedActivity,
                            'route_id': selectedRouteId,
                            'tour_hq': selectedRouteHq,
                            'route': selectedRouteLabel,
                            'counts': _routeCounts,
                            'remarks': remarks.text.trim(),
                          });
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Save draft'))),
              ]))));
}

class _LookupError extends StatelessWidget {
  const _LookupError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: Colors.red)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      );
}

class _VisitCount extends StatelessWidget {
  const _VisitCount({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
          color: const Color(0xFFEAF1FA),
          borderRadius: BorderRadius.circular(5)),
      child: Text('$label $value',
          style: const TextStyle(
              fontSize: 9,
              color: AppColors.navy,
              fontWeight: FontWeight.w600)));
}

class _RemarkPreview extends StatelessWidget {
  const _RemarkPreview({required this.remark});
  final String remark;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(children: [
              Icon(Icons.sticky_note_2_outlined, color: AppColors.navy),
              SizedBox(width: 8),
              Text('Remarks'),
            ]),
            content: SingleChildScrollView(child: Text(remark)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'))
            ],
          ),
        ),
        child: Row(children: [
          const Icon(Icons.sticky_note_2_outlined,
              size: 14, color: AppColors.muted),
          const SizedBox(width: 4),
          Expanded(
              child: Text(remark,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      decoration: TextDecoration.underline))),
        ]),
      );
}

String _monthName(int month) => const [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ][month];

String _weekdayName(DateTime date) => const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ][date.weekday - 1];

String _capitalize(String value) => value[0].toUpperCase() + value.substring(1);

String _countLabel(String value) => value == 'chemist'
    ? 'Chemist'
    : value.contains('/')
        ? value
        : _capitalize(value);
