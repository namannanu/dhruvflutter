// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/employment.dart';
import 'package:talent/core/state/app_state.dart';

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _feedbackController = TextEditingController();
  int _feedbackRating = 5;
  String? _selectedEmployerId;
  bool _isSubmittingFeedback = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  List<_EmployerOption> _buildEmployerOptions(List<EmploymentRecord> history) {
    final options = <String, _EmployerOption>{};
    for (final record in history) {
      final employerId = record.employerId;
      if (employerId.isEmpty) continue;
      final name = (record.employerName?.isNotEmpty ?? false)
          ? record.employerName!
          : 'Employer';
      options.putIfAbsent(
          employerId, () => _EmployerOption(id: employerId, name: name));
    }
    final result = options.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  Widget _buildRatingSelector() {
    return Row(
      children: [
        const Text('Rating:'),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          final starIndex = index + 1;
          final isFilled = starIndex <= _feedbackRating;
          return IconButton(
            icon: Icon(
              isFilled ? Icons.star : Icons.star_border,
              color: isFilled ? Colors.amber : Colors.grey,
            ),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => setState(() => _feedbackRating = starIndex),
          );
        }),
      ],
    );
  }

  Future<void> _submitFeedback(AppState appState) async {
    final employerId = _selectedEmployerId;
    if (employerId == null || employerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an employer to review.')),
      );
      return;
    }

    setState(() => _isSubmittingFeedback = true);
    try {
      await appState.submitEmployerFeedback(
        employerId: employerId,
        rating: _feedbackRating,
        comment: _feedbackController.text,
      );
      _feedbackController.clear();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit feedback: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingFeedback = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final employmentHistory = appState.workerEmploymentHistory;
    final employerOptions = _buildEmployerOptions(employmentHistory);
    final isHistoryLoading = appState.isLoadingEmploymentHistory;

    final hasEmployers = employerOptions.isNotEmpty;

    if (_selectedEmployerId == null && hasEmployers) {
      final firstId = employerOptions.first.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_selectedEmployerId != firstId) {
          setState(() => _selectedEmployerId = firstId);
        }
      });
    }

    if (_selectedEmployerId != null &&
        employerOptions.every((option) => option.id != _selectedEmployerId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedEmployerId = null);
      });
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.feedback_outlined, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Share Feedback with Employers',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isHistoryLoading && !hasEmployers)
              const Center(child: CircularProgressIndicator()),
            if (!isHistoryLoading && !hasEmployers)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'You can leave feedback for employers after you have worked a job with them.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            if (hasEmployers) ...[
              DropdownButtonFormField<String>(
                value: _selectedEmployerId,
                decoration: const InputDecoration(
                  labelText: 'Select employer',
                  border: OutlineInputBorder(),
                ),
                items: employerOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option.id,
                        child: Text(option.name),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmittingFeedback
                    ? null
                    : (value) => setState(() => _selectedEmployerId = value),
              ),
              const SizedBox(height: 16),
              _buildRatingSelector(),
              const SizedBox(height: 16),
              TextField(
                controller: _feedbackController,
                decoration: const InputDecoration(
                  labelText: 'Share details about your experience',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmittingFeedback
                      ? null
                      : () => _submitFeedback(appState),
                  icon: _isSubmittingFeedback
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    _isSubmittingFeedback ? 'Submitting...' : 'Submit feedback',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmployerOption {
  const _EmployerOption({required this.id, required this.name});

  final String id;
  final String name;
}
