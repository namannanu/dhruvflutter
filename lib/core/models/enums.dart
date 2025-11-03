enum JobStatus {
  active,
  filled,
  closed,
  paused,
  expired,
  deleted,
  completed,
  draft;

  static JobStatus fromString(String value) {
    final normalized = value.toLowerCase();
    switch (normalized) {
      case 'active':
      case 'open':
      case 'published':
      case 'ready':
        return JobStatus.active;
      case 'filled':
      case 'hired':
        return JobStatus.filled;
      case 'closed':
      case 'inactive':
      case 'archived':
        return JobStatus.closed;
      case 'paused':
        return JobStatus.paused;
      case 'expired':
        return JobStatus.expired;
      case 'deleted':
      case 'removed':
        return JobStatus.deleted;
      case 'completed':
      case 'finished':
        return JobStatus.completed;
      case 'draft':
      case 'unpublished':
        return JobStatus.draft;
      default:
        try {
          return JobStatus.values.firstWhere(
            (status) => status.name.toLowerCase() == normalized,
          );
        } catch (_) {
          return JobStatus.active;
        }
    }
  }
}

enum ApplicationStatus {
  pending,
  accepted,
  rejected,
  hired,
  completed,
  cancelled;

  static ApplicationStatus fromString(String value) {
    final normalized = value.toLowerCase();
    switch (normalized) {
      case 'pending':
      case 'in_review':
      case 'in-review':
      case 'review':
      case 'new':
        return ApplicationStatus.pending;
      case 'accepted':
        return ApplicationStatus.accepted;
      case 'offer_accepted':
      case 'hired':
        return ApplicationStatus.hired;
      case 'rejected':
      case 'declined':
        return ApplicationStatus.rejected;
      case 'withdrawn':
      case 'cancelled':
      case 'canceled':
        return ApplicationStatus.cancelled;
      case 'completed':
        return ApplicationStatus.completed;
      default:
        try {
          return ApplicationStatus.values.firstWhere(
            (status) => status.name.toLowerCase() == normalized,
          );
        } catch (_) {
          return ApplicationStatus.pending;
        }
    }
  }
}
