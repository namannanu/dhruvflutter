// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/attendance.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/core/widgets/access_tag.dart';

class EmployeeAttendanceManagementScreen extends StatefulWidget {
  const EmployeeAttendanceManagementScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<EmployeeAttendanceManagementScreen> createState() =>
      _EmployeeAttendanceManagementScreenState();
}

class _EmployeeAttendanceManagementScreenState
    extends State<EmployeeAttendanceManagementScreen> {
  late DateTime _selectedDate;
  String _statusFilter = 'all';
  String? _scheduleWorkerId;
  final String _scheduleStatusFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  // Map<String, dynamic>? _selectedWorker; // Unused field removed
  String _sortBy = 'time'; // time, worker, status
  String _sortOrder = 'asc'; // asc, desc
  String _timeFilter = 'all'; // all, past, present, future

  // Safe numeric conversion methods to prevent NaN/Infinity values
  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) {
      if (value.isNaN || value.isInfinite) return 0.0;
      return value;
    }
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed?.isNaN == true || parsed?.isInfinite == true) return 0.0;
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  String _normalizeStatusFilter(String? value) {
    switch (value?.toLowerCase()) {
      case 'scheduled':
        return 'scheduled';
      case 'clocked-in':
      case 'clockedin':
        return 'clocked-in';
      case 'completed':
        return 'completed';
      case 'missed':
        return 'missed';
      default:
        return 'all';
    }
  }

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _selectedDate = appState.attendanceSelectedDate;
    _statusFilter = _normalizeStatusFilter(appState.attendanceStatusFilter);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refresh(silent: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh({
    DateTime? date,
    String? status,
    bool silent = false,
  }) async {
    if (!mounted) return;
    final targetDate = date ?? _selectedDate;
    final targetStatus = _normalizeStatusFilter(status ?? _statusFilter);
    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await appState.loadAttendanceDashboard(
        date: targetDate,
        status: targetStatus,
      );
    } catch (error) {
      if (!silent && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to load attendance data: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      await _refresh(date: picked);
    }
  }

  Future<void> _changeStatus(String status) async {
    final normalized = _normalizeStatusFilter(status);
    setState(() {
      _statusFilter = normalized;
    });
    await _refresh(status: normalized);
  }

  Future<void> _loadWorkerSchedule(String workerId,
      {bool silently = false}) async {
    if (workerId.isEmpty) return;

    if (_scheduleWorkerId != workerId) {
      setState(() {
        _scheduleWorkerId = workerId;
      });
    }

    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await appState.loadWorkerAttendanceSchedule(
        workerId: workerId,
        status: _scheduleStatusFilter,
      );
    } catch (error) {
      if (!silently && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to load worker schedule: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchWorkers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final appState = context.read<AppState>();
      print('🔍 Searching workers via API: $query');

      final uri = Uri.parse(
          'https://dhruvbackend.vercel.app/api/attendance/search/workers?name=${Uri.encodeComponent(query)}');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${appState.service.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final workersData = data['data'] as List? ?? [];

        final results = workersData
            .map((workerData) => {
                  'id': workerData['id'] ?? workerData['_id'] ?? '',
                  'name': workerData['name'] ??
                      '${workerData['firstName'] ?? ''} ${workerData['lastName'] ?? ''}'
                          .trim(),
                  'email': workerData['email'] ?? '',
                  'totalShifts': workerData['totalShifts'] ?? 0,
                  'completedHours': _safeDouble(workerData['completedHours']),
                  'averageRating': _safeDouble(workerData['averageRating']),
                })
            .toList();

        setState(() {
          _searchResults = results;
          _isSearching = false;
        });

        print('✓ Found ${results.length} workers matching "$query"');
      } else {
        print(
            '⚠️ Worker search API error: ${response.statusCode} - ${response.body}');
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (error) {
      print('❌ Error searching workers: $error');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _selectWorkerFromSearch(Map<String, dynamic> workerData) {
    setState(() {
      // _selectedWorker = workerData; // Removed unused assignment
      _searchController.clear();
      _searchResults = [];
    });
    _loadWorkerSchedule(workerData['id'] as String);
  }

  List<AttendanceRecord> _getSortedFilteredRecords(
      List<AttendanceRecord> records) {
    // Apply time filter
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final List<AttendanceRecord> filtered = records.where((record) {
      final recordDate = DateTime(record.scheduledStart.year,
          record.scheduledStart.month, record.scheduledStart.day);

      switch (_timeFilter) {
        case 'past':
          return recordDate.isBefore(today);
        case 'present':
          return recordDate.isAtSameMomentAs(today);
        case 'future':
          return recordDate.isAfter(today) ||
              recordDate.isAtSameMomentAs(tomorrow);
        default:
          return true;
      }
    }).toList();

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'worker':
          comparison = (a.workerName ?? '').compareTo(b.workerName ?? '');
          break;
        case 'status':
          comparison = a.status.index.compareTo(b.status.index);
          break;
        case 'time':
        default:
          comparison = a.scheduledStart.compareTo(b.scheduledStart);
          break;
      }

      return _sortOrder == 'desc' ? -comparison : comparison;
    });

    return filtered;
  }

  Future<void> _exportAttendance(
    List<AttendanceRecord> records,
    DateTime date,
  ) async {
    try {
      final csvText = _generateCsvText(records);

      // Copy to clipboard as a simple export solution
      await Clipboard.setData(ClipboardData(text: csvText));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance report copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export attendance: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _generateCsvText(List<AttendanceRecord> records) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(
        'Worker Name,Job Title,Date,Scheduled Start,Scheduled End,Clock In,Clock Out,Hours,Rate,Earnings,Status,Location');

    // Data
    for (final record in records) {
      buffer.writeln([
        record.workerName ?? 'Unknown',
        record.jobTitle ?? 'Unknown',
        _formatDate(record.scheduledStart),
        _formatTime(record.scheduledStart),
        _formatTime(record.scheduledEnd),
        record.clockIn != null ? _formatTime(record.clockIn!) : '--',
        record.clockOut != null ? _formatTime(record.clockOut!) : '--',
        record.totalHours.toStringAsFixed(2),
        '\$${(record.hourlyRate ?? 0).toStringAsFixed(2)}',
        '\$${record.earnings.toStringAsFixed(2)}',
        _statusLabel(record.status),
        record.locationSummary ?? 'Unknown',
      ].join(','));
    }

    return buffer.toString();
  }

  Future<void> _handleMarkComplete(String recordId) async {
    final appState = context.read<AppState>();
    try {
      await appState.markEmployerAttendanceComplete(recordId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked as complete'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark complete: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleEditHours(AttendanceRecord record) async {
    final controller =
        TextEditingController(text: record.totalHours.toString());
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Hours - ${record.workerName ?? 'Unknown Worker'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job: ${record.jobTitle ?? 'Unknown'}'),
            Text('Date: ${_formatDate(record.scheduledStart)}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Hours Worked',
                border: OutlineInputBorder(),
                suffixText: 'hours',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final hours = double.tryParse(controller.text);
              if (hours != null && hours >= 0) {
                Navigator.of(context).pop(hours);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final appState = context.read<AppState>();
      try {
        await appState.updateEmployerAttendanceHours(
          attendanceId: record.id,
          totalHours: result,
          hourlyRate: record.hourlyRate,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hours updated to ${result.toStringAsFixed(2)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update hours: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final dashboard = appState.attendanceDashboard;
        final isLoading = appState.isAttendanceBusy;
        final records = dashboard?.records ?? [];
        final sortedRecords = _getSortedFilteredRecords(records);
        final summary = dashboard?.summary ??
            const AttendanceDashboardSummary(
              totalWorkers: 0,
              completedShifts: 0,
              totalHours: 0,
              totalPayroll: 0,
              lateArrivals: 0,
            );

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(context, sortedRecords),
          body: RefreshIndicator(
            onRefresh: () => _refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFilters(context, isLoading: isLoading),
                  const SizedBox(height: 16),
                  _buildSummaryCards(context, summary),
                  const SizedBox(height: 16),
                  _buildSortingControls(),
                  const SizedBox(height: 16),
                  if (isLoading && sortedRecords.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (sortedRecords.isEmpty)
                    _buildEmptyState()
                  else
                    _buildRecordList(context, sortedRecords),
                  const SizedBox(height: 16),
                  _buildWorkerScheduleSection(context, records),
                  if (summary.totalPayroll > 0) _buildPayrollSummary(summary),
                  const SizedBox(height: 80), // Bottom padding
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, List<AttendanceRecord> records) {
    return AppBar(
      title: const Text('Attendance Management'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: widget.onBack,
      ),
      actions: [
        if (records.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportAttendance(records, _selectedDate),
            tooltip: 'Export to CSV',
          ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, {required bool isLoading}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 8),
                              Text(_formatDate(_selectedDate)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('All Status')),
                          DropdownMenuItem(
                              value: 'scheduled', child: Text('Scheduled')),
                          DropdownMenuItem(
                              value: 'clocked-in', child: Text('Clocked In')),
                          DropdownMenuItem(
                              value: 'completed', child: Text('Completed')),
                          DropdownMenuItem(
                              value: 'missed', child: Text('Missed')),
                        ],
                        onChanged: isLoading
                            ? null
                            : (value) {
                                if (value != null) _changeStatus(value);
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Time Period',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all', _timeFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Past', 'past', _timeFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Today', 'present', _timeFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Future', 'future', _timeFilter),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String current) {
    final isSelected = current == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _timeFilter = value;
          });
        }
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
    );
  }

  Widget _buildSummaryCards(
      BuildContext context, AttendanceDashboardSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            value: '${summary.totalWorkers}',
            label: 'Total Workers',
            valueColor: Colors.blue[600]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            value: '${summary.completedShifts}',
            label: 'Completed',
            valueColor: Colors.green[600]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            value: '${summary.totalHours.toStringAsFixed(1)}h',
            label: 'Total Hours',
            valueColor: Colors.purple[600]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            value: '\$${summary.totalPayroll.toStringAsFixed(2)}',
            label: 'Total Payroll',
            valueColor: Colors.orange[600]!,
          ),
        ),
      ],
    );
  }

  Widget _buildSortingControls() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('Sort by:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _sortBy,
              underline: Container(),
              items: const [
                DropdownMenuItem(value: 'time', child: Text('Time')),
                DropdownMenuItem(value: 'worker', child: Text('Worker')),
                DropdownMenuItem(value: 'status', child: Text('Status')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sortBy = value;
                  });
                }
              },
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(_sortOrder == 'asc'
                  ? Icons.arrow_upward
                  : Icons.arrow_downward),
              onPressed: () {
                setState(() {
                  _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
                });
              },
              tooltip: _sortOrder == 'asc' ? 'Ascending' : 'Descending',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No attendance records',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'No workers scheduled for this date and filter',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordList(
      BuildContext context, List<AttendanceRecord> records) {
    return Column(
      children: records
          .map((record) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AttendanceCard(
                  record: record,
                  onMarkComplete: record.status == AttendanceStatus.clockedIn
                      ? () => _handleMarkComplete(record.id)
                      : null,
                  onEditHours: () => _handleEditHours(record),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildWorkerScheduleSection(
      BuildContext context, List<AttendanceRecord> records) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Worker Search & Schedule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search workers by name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon:
                    _isSearching ? const CircularProgressIndicator() : null,
              ),
              onChanged: (value) {
                _searchWorkers(value);
              },
            ),
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final worker = _searchResults[index];
                    return ListTile(
                      title: Text(worker['name'] as String),
                      subtitle: Text(worker['email'] as String),
                      trailing: Text('${worker['totalShifts']} shifts'),
                      onTap: () => _selectWorkerFromSearch(worker),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPayrollSummary(AttendanceDashboardSummary summary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payroll Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _summaryRow('Total Hours Worked:',
                '${summary.totalHours.toStringAsFixed(1)} hours'),
            _summaryRow('Total Payroll:',
                '\$${summary.totalPayroll.toStringAsFixed(2)}'),
            _summaryRow('Workers Paid:', '${summary.completedShifts}'),
            if (summary.lateArrivals > 0)
              _summaryRow('Late Arrivals:', '${summary.lateArrivals}',
                  valueColor: Colors.red),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Implementation needed: Implement payroll processing
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payroll processing feature coming soon'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Process Payroll',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.record,
    required this.onMarkComplete,
    required this.onEditHours,
  });

  final AttendanceRecord record;
  final VoidCallback? onMarkComplete;
  final VoidCallback onEditHours;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accessInfo = appState.ownershipAccessInfo(record.businessId);
    final statusStyle = _statusColors(record.status);

    return AccessTagPositioned(
      accessInfo: accessInfo,
      size: AccessTagSize.medium,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                _AvatarBadge(name: record.workerName ?? 'Unknown'),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.workerName ?? 'Unknown Worker',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${record.jobTitle ?? 'Unknown'} • ${record.locationSummary ?? 'Unknown'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${(record.hourlyRate ?? 0).toStringAsFixed(2)}/hr',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusStyle.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusStyle.icon,
                              size: 16, color: statusStyle.foreground),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel(record.status),
                            style: TextStyle(
                              color: statusStyle.foreground,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Time Details
            Row(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        title: 'Scheduled',
                        subtitle:
                            '${_formatTime(record.scheduledStart)} - ${_formatTime(record.scheduledEnd)}',
                        background: Colors.grey[50]!,
                        titleColor: Colors.grey[600]!,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoTile(
                        title: 'Earnings',
                        subtitle: '\$${record.earnings.toStringAsFixed(2)}',
                        background: Colors.green[50]!,
                        titleColor: Colors.green[600]!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        title: 'Clock In',
                        subtitle: record.clockIn != null
                            ? _formatTime(record.clockIn!)
                            : '--:--',
                        background: Colors.blue[50]!,
                        titleColor: Colors.blue[600]!,
                        trailingTag: record.isLate
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Late',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoTile(
                        title: 'Clock Out',
                        subtitle: record.clockOut != null
                            ? _formatTime(record.clockOut!)
                            : '--:--',
                        background: Colors.red[50]!,
                        titleColor: Colors.red[600]!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
            // Actions
            Row(
              children: [
                if (onMarkComplete != null)
                  ElevatedButton(
                    onPressed: onMarkComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Mark Complete',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                if (onMarkComplete != null) const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                            '${record.workerName ?? 'Unknown Worker'} Details'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailsRow('Job:', record.jobTitle ?? 'Unknown'),
                            _detailsRow(
                                'Date:', _formatDate(record.scheduledStart)),
                            _detailsRow('Scheduled:',
                                '${_formatTime(record.scheduledStart)} - ${_formatTime(record.scheduledEnd)}'),
                            _detailsRow('Actual:',
                                '${record.clockIn != null ? _formatTime(record.clockIn!) : '--'} - ${record.clockOut != null ? _formatTime(record.clockOut!) : '--'}'),
                            _detailsRow('Hours:',
                                '${record.totalHours.toStringAsFixed(2)}h'),
                            _detailsRow('Rate:',
                                '\$${(record.hourlyRate ?? 0).toStringAsFixed(2)}/hr'),
                            _detailsRow('Earnings:',
                                '\$${record.earnings.toStringAsFixed(2)}'),
                            _detailsRow('Status:', _statusLabel(record.status)),
                            _detailsRow('Location:',
                                record.locationSummary ?? 'Unknown'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onEditHours,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Edit Hours'),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
}

_StatusStyle _statusColors(AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.scheduled:
      return _StatusStyle(
        background: Colors.blue[100]!,
        foreground: Colors.blue[700]!,
        icon: Icons.schedule,
      );
    case AttendanceStatus.clockedIn:
      return _StatusStyle(
        background: Colors.green[100]!,
        foreground: Colors.green[700]!,
        icon: Icons.access_time,
      );
    case AttendanceStatus.completed:
      return _StatusStyle(
        background: Colors.grey[100]!,
        foreground: Colors.grey[700]!,
        icon: Icons.check_circle,
      );
    case AttendanceStatus.missed:
      return _StatusStyle(
        background: Colors.red[100]!,
        foreground: Colors.red[700]!,
        icon: Icons.cancel,
      );
  }
}

Widget _detailsRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

String _formatTime(DateTime dateTime) {
  return DateFormat('h:mm a').format(dateTime.toLocal());
}

String _formatDate(DateTime dateTime) {
  return DateFormat('y-MM-dd').format(dateTime.toLocal());
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

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[500]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.subtitle,
    required this.background,
    required this.titleColor,
    this.trailingTag,
  });

  final String title;
  final String subtitle;
  final Color background;
  final Color titleColor;
  final Widget? trailingTag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: titleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailingTag != null) trailingTag!,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
