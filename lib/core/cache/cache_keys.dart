class CacheKeys {
  static String user(String userId) => 'user:$userId';
  static String workerJobs(String userId) => 'worker_jobs:$userId';
  static String workerApps(String userId) => 'worker_apps:$userId';
  static String workerAttendance(String userId) => 'worker_att:$userId';
  static String workerShifts(String userId) => 'worker_shifts:$userId';
  static String workerSwapRequests(String userId) => 'worker_swap:$userId';
  static String workerProfile(String userId) => 'worker_profile:$userId';
  static String workerMetrics(String userId) => 'worker_metrics:$userId';

  static String employerJobs(String userId) => 'employer_jobs:$userId';
  static String employerApplications(String userId) => 'employer_apps:$userId';
  static String employerProfile(String userId) => 'employer_profile:$userId';
  static String employerMetrics(String userId) => 'employer_metrics:$userId';

  static const businesses = 'businesses';
  static String businessTeams(String businessId) =>
      'business_teams:$businessId';
  static String businessData(String businessId) => 'business_data:$businessId';

  static String notifications(String userId) => 'notifications:$userId';
  static String metrics(String userId, String role) => 'metrics:$role:$userId';

  // Cache for location and attendance data
  static String attendanceLocation(String userId) =>
      'attendance_location:$userId';
  static String savedLocations(String userId) => 'saved_locations:$userId';
}
