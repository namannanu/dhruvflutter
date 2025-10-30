
class DayAvailability {
  final String day;
  bool isAvailable;
  List<TimeSlot> timeSlots;

  DayAvailability(
      {required this.day, this.isAvailable = false, List<TimeSlot>? timeSlots})
      : timeSlots = timeSlots ?? [];

  Map<String, dynamic> toMap() => {
        'day': day,
        'isAvailable': isAvailable,
        'timeSlots': timeSlots.map((e) => e.toMap()).toList(),
      };

  static DayAvailability fromMap(Map<String, dynamic> map) {
    return DayAvailability(
      day: map['day'] as String,
      isAvailable: (map['isAvailable'] as bool?) ?? false,
      timeSlots: (map['timeSlots'] as List?)
              ?.map((t) => TimeSlot.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  DayAvailability copyWith({
    bool? isAvailable,
    List<TimeSlot>? timeSlots,
  }) {
    return DayAvailability(
      day: day,
      isAvailable: isAvailable ?? this.isAvailable,
      timeSlots:
          timeSlots ?? this.timeSlots.map((slot) => slot.copy()).toList(),
    );
  }

  DayAvailability clone() => copyWith();
}

class TimeSlot {
  final String startTime;
  final String endTime;

  TimeSlot(this.startTime, this.endTime);

  Map<String, dynamic> toMap() => {'startTime': startTime, 'endTime': endTime};

  static TimeSlot fromMap(Map<String, dynamic> map) {
    return TimeSlot(map['startTime'] as String, map['endTime'] as String);
  }

  TimeSlot copy() => TimeSlot(startTime, endTime);
}
