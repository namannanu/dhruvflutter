import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';

class WorkerAttendanceScreen extends StatefulWidget {
  const WorkerAttendanceScreen({super.key});

  @override
  State<WorkerAttendanceScreen> createState() => _WorkerAttendanceScreenState();
}

class _WorkerAttendanceScreenState extends State<WorkerAttendanceScreen> {
  late DateTime _now;
  Timer? _ticker;
  final Map<String, bool> _actionLoading = {};
  bool _isClockingIn =
      false; // Global flag to prevent multiple clock-in attempts

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final records = [...appState.workerAttendance]
      ..sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));

    final totalEarnings =
        records.fold<double>(0, (sum, record) => sum + record.earnings);
    final totalHours =
        records.fold<double>(0, (sum, record) => sum + record.totalHours);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            try {
              await context.read<AppState>().refreshWorkerAttendance();
            } catch (error) {
              if (!mounted) return;
              _showError(error);
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _Header(onBack: () => Navigator.of(context).maybePop()),
              const SizedBox(height: 12),
              _CurrentTimeCard(now: _now),
              const SizedBox(height: 16),
              _SummaryRow(
                totalEarnings: totalEarnings,
                totalHours: totalHours,
              ),
              const SizedBox(height: 16),
              if (records.isEmpty)
                _EmptyState(
                    onCreate: () =>
                        context.read<AppState>().refreshWorkerAttendance())
              else
                ...records.map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _AttendanceCard(
                      record: record,
                      isProcessing:
                          (_actionLoading[record.id] ?? false) || _isClockingIn,
                      onClockIn: () =>
                          _handleClockIn(appState: appState, record: record),
                      onClockOut: () => _handleClockOut(
                        appState: appState,
                        record: record,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleClockIn({
    required AppState appState,
    required AttendanceRecord record,
  }) async {
    if (!mounted || (_actionLoading[record.id] ?? false) || _isClockingIn) {
      return;
    }

    // Additional check: if the record status indicates already clocked in, show message
    if (record.status == AttendanceStatus.clockedIn) {
      _showSnack('You are already clocked in for this shift');
      return;
    }

    setState(() {
      _actionLoading[record.id] = true;
      _isClockingIn = true;
    });

    try {
      final updated = await appState.clockInWorkerAttendance(record.id);
      if (!mounted) return;
      final time = _formatTime(updated.clockIn);
      _showSnack(time == null ? 'Clock-in recorded' : 'Clocked in at $time');
    } catch (error) {
      if (!mounted) return;

      // Handle specific "already clocked in" error with user-friendly message
      final errorMessage = error.toString();
      if (errorMessage.contains('already clocked in')) {
        _showSnack('You are already clocked in for this shift');
      } else {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading.remove(record.id);
          _isClockingIn = false;
        });
      }
    }
  }

  Future<void> _handleClockOut({
    required AppState appState,
    required AttendanceRecord record,
  }) async {
    if (!mounted || (_actionLoading[record.id] ?? false)) return;

    setState(() => _actionLoading[record.id] = true);
    try {
      final updated = await appState.clockOutWorkerAttendance(
        record.id,
        hourlyRate: record.hourlyRate ?? 15.0, // Default hourly rate
      );
      if (!mounted) return;
      final time = _formatTime(updated.clockOut);
      _showSnack(time == null ? 'Clock-out recorded' : 'Clocked out at $time');
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _actionLoading.remove(record.id));
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }

  String? _formatTime(DateTime? time) {
    if (time == null) return null;
    return DateFormat('HH:mm').format(time);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Track your work hours',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrentTimeCard extends StatelessWidget {
  const _CurrentTimeCard({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            DateFormat('HH:mm:ss').format(now),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMMM d, y').format(now),
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.totalEarnings,
    required this.totalHours,
  });

  final double totalEarnings;
  final double totalHours;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            value: NumberFormat.simpleCurrency().format(totalEarnings),
            label: 'Total Earnings',
            valueColor: Colors.green.shade600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            value: '${totalHours.toStringAsFixed(1)}h',
            label: 'Total Hours',
            valueColor: Colors.blue.shade600,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.record,
    required this.isProcessing,
    required this.onClockIn,
    required this.onClockOut,
  });

  final AttendanceRecord record;
  final bool isProcessing;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _statusLabel(record.status);
    final statusColors = _statusColors(context, record.status);
    final scheduledRange =
        '${DateFormat('HH:mm').format(record.scheduledStart)} · ${DateFormat('HH:mm').format(record.scheduledEnd)}';
    final dateLabel = DateFormat.yMMMMd().format(record.scheduledStart);
    final clockIn = record.clockIn;
    final clockOut = record.clockOut;
    final showActual = clockIn != null || clockOut != null;
    final hourlyRate = record.hourlyRate;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.jobTitle?.isNotEmpty == true
                          ? record.jobTitle!
                          : 'Shift',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (record.companyName != null &&
                        record.companyName!.isNotEmpty)
                      Text(
                        record.companyName!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    if ((record.locationSummary ?? record.location)
                            ?.isNotEmpty ??
                        false)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.place_outlined,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                record.locationSummary ?? record.location!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColors.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColors.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scheduled',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scheduledRange,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showActual) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clock In',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              clockIn != null
                                  ? DateFormat('HH:mm').format(clockIn)
                                  : '--:--',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (record.isLate)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Text(
                                  '(Late)',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Clock Out',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clockOut != null
                            ? DateFormat('HH:mm').format(clockOut)
                            : '--:--',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (record.status == AttendanceStatus.completed) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hours Worked',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${record.totalHours.toStringAsFixed(2)}h',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Earnings',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormat.simpleCurrency().format(record.earnings),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (record.status == AttendanceStatus.scheduled)
                Expanded(
                  child: _ActionButton(
                    label: 'Clock In',
                    icon: Icons.timer_outlined,
                    color: Colors.green.shade600,
                    onPressed: isProcessing ? null : onClockIn,
                    isProcessing: isProcessing,
                  ),
                ),
              if (record.status == AttendanceStatus.clockedIn)
                Expanded(
                  child: _ActionButton(
                    label: 'Clock Out',
                    icon: Icons.timer_off_outlined,
                    color: Colors.red.shade600,
                    onPressed: isProcessing ? null : onClockOut,
                    isProcessing: isProcessing,
                  ),
                ),
              if (record.status == AttendanceStatus.completed)
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Shift Completed',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              if (record.status == AttendanceStatus.missed)
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Shift Missed',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (hourlyRate != null) ...[
            const SizedBox(height: 10),
            Text(
              'Rate: ${NumberFormat.simpleCurrency().format(hourlyRate)} / hr',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StatusColors _statusColors(BuildContext context, AttendanceStatus status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case AttendanceStatus.scheduled:
        return _StatusColors(
          background: const Color(0xFFE6EEFF),
          foreground: scheme.primary,
        );
      case AttendanceStatus.clockedIn:
        return _StatusColors(
          background: const Color(0xFFDCFCE7),
          foreground: Colors.green.shade700,
        );
      case AttendanceStatus.completed:
        return _StatusColors(
          background: Colors.grey.shade200,
          foreground: Colors.grey.shade800,
        );
      case AttendanceStatus.missed:
        return _StatusColors(
          background: const Color(0xFFFFE4E6),
          foreground: Colors.red.shade700,
        );
    }
  }

  String _statusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.scheduled:
        return 'Scheduled';
      case AttendanceStatus.clockedIn:
        return 'Clocked In';
      case AttendanceStatus.completed:
        return 'Completed';
      case AttendanceStatus.missed:
        return 'Missed';
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.isProcessing,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isProcessing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 42, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No attendance records yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your scheduled shifts and times will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onCreate,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _StatusColors {
  const _StatusColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
