/// Utility functions for formatting job information consistently across the app
class JobDisplayUtils {
  /// Format recurrence/frequency for display
  static String formatRecurrence(String recurrence) {
    final value = recurrence.trim().toLowerCase();
    switch (value) {
      case 'once':
      case 'one-time':
      case 'one time':
        return 'One-time';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'custom':
        return 'Custom schedule';
      case 'daily':
        return 'Daily';
      default:
        return value.isNotEmpty ? _capitalize(value) : 'One-time';
    }
  }

  /// Get icon for recurrence type
  static String getRecurrenceIcon(String recurrence) {
    final value = recurrence.trim().toLowerCase();
    switch (value) {
      case 'once':
      case 'one-time':
      case 'one time':
        return '📅'; // Calendar for one-time jobs
      case 'weekly':
        return '🔄'; // Repeat icon for weekly
      case 'monthly':
        return '📆'; // Month calendar for monthly
      case 'custom':
        return '⚙️'; // Settings for custom
      case 'daily':
        return '🌅'; // Sunrise for daily
      default:
        return '📅';
    }
  }

  /// Get description for recurrence type
  static String getRecurrenceDescription(String recurrence) {
    final value = recurrence.trim().toLowerCase();
    switch (value) {
      case 'once':
      case 'one-time':
      case 'one time':
        return 'Single shift or project';
      case 'weekly':
        return 'Repeats every week';
      case 'monthly':
        return 'Repeats every month';
      case 'custom':
        return 'Custom schedule';
      case 'daily':
        return 'Repeats daily';
      default:
        return 'Single shift or project';
    }
  }

  /// Capitalize first letter of a string
  static String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }
}
