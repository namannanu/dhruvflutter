// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:talent/features/worker/models/availability.dart';

class AvailabilitySchedule extends StatefulWidget {
  final List<DayAvailability> availability;
  final ValueChanged<List<DayAvailability>> onAvailabilityChanged;

  const AvailabilitySchedule({
    super.key,
    required this.availability,
    required this.onAvailabilityChanged,
  });

  @override
  State<AvailabilitySchedule> createState() => _AvailabilityScheduleState();
}

class _AvailabilityScheduleState extends State<AvailabilitySchedule> {
  late List<DayAvailability> _availability;

  @override
  void initState() {
    super.initState();
    _availability = List.from(widget.availability);
  }

  @override
  void didUpdateWidget(AvailabilitySchedule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.availability != oldWidget.availability) {
      _availability = List.from(widget.availability);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Schedule',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _availability.length,
          itemBuilder: (context, index) {
            final day = _availability[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: Text(day.day),
                      value: day.isAvailable,
                      onChanged: (value) {
                        setState(() {
                          _availability[index] =
                              day.copyWith(isAvailable: value);
                          widget.onAvailabilityChanged(_availability);
                        });
                      },
                    ),
                    if (day.isAvailable) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_alarm),
                            label: const Text('Add Time Slot'),
                            onPressed: () async {
                              final startTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (startTime != null && mounted) {
                                final endTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (endTime != null && mounted) {
                                  setState(() {
                                    final newTimeSlot = TimeSlot(
                                      startTime.format(context),
                                      endTime.format(context),
                                    );
                                    _availability[index] = day.copyWith(
                                      timeSlots: [
                                        ...day.timeSlots,
                                        newTimeSlot
                                      ],
                                    );
                                    widget.onAvailabilityChanged(_availability);
                                  });
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      if (day.timeSlots.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: day.timeSlots.map((slot) {
                            return Chip(
                              label:
                                  Text('${slot.startTime} - ${slot.endTime}'),
                              onDeleted: () {
                                setState(() {
                                  _availability[index] = day.copyWith(
                                    timeSlots: day.timeSlots
                                        .where((s) => s != slot)
                                        .toList(),
                                  );
                                  widget.onAvailabilityChanged(_availability);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
