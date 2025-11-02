# Free Application Limit Implementation

## Overview
Workers can apply to 2 free job applications, then need to upgrade to premium to apply to more jobs.

## Implementation Details

### Frontend (Flutter)
The application limit logic is implemented in `lib/core/state/payment_extensions.dart`:

```dart
bool canApplyToJob() {
  final profile = workerProfile;
  if (profile == null) return false;

  // Premium users can apply to unlimited jobs
  if (profile.isPremium) return true;

  // Free users can apply to maximum 2 jobs
  final applicationsCount = workerApplications.length;
  return applicationsCount < 2;
}

int getRemainingApplications() {
  final profile = workerProfile;
  if (profile == null) return 0;

  // Premium users have unlimited applications
  if (profile.isPremium) return -1; // -1 indicates unlimited

  // Free users can apply to maximum 2 jobs
  final applicationsCount = workerApplications.length;
  return (2 - applicationsCount).clamp(0, 2);
}
```

### Backend (Node.js)
The application limit is enforced in `src/modules/applications/application.controller.js`:

```javascript
const APPLICATION_FREE_QUOTA = 2;

// In createApplication function:
if (!req.user.premium && req.user.freeApplicationsUsed >= APPLICATION_FREE_QUOTA) {
  return next(new AppError('Free application limit reached. Upgrade to continue.', 402));
}
```

### User Interface Features

1. **Worker Dashboard**: Shows "Free applications left" metric
2. **Job Feed**: 
   - Apply button is disabled when limit reached
   - Shows remaining applications count
   - Premium upgrade dialog appears when limit exceeded
3. **Application Screen**: Shows premium upgrade options

### Premium Upgrade Flow

When free application limit is reached:
1. Apply button changes to "Upgrade to Premium to Apply"
2. Clicking shows premium upgrade dialog with benefits
3. Users can upgrade to premium for unlimited applications

### Files Updated for 2 Free Application Limit

**Frontend:**
- `lib/core/state/payment_extensions.dart` - Core limit logic
- `lib/features/auth/services/api_auth_service.dart` - Dashboard metrics
- `lib/core/state/app_state.dart` - Default metrics
- `lib/features/worker/services/api_worker_service.dart` - API service defaults

**Backend:**
- `src/modules/applications/application.controller.js` - Quota enforcement

### Testing

To test the free application limit:
1. Create a non-premium worker account
2. Apply to 2 jobs successfully
3. Attempt to apply to a 3rd job - should show premium upgrade prompt
4. Upgrade to premium
5. Verify unlimited applications are now allowed

### Error Handling

When free limit is exceeded:
- Backend returns 402 status with message "Free application limit reached. Upgrade to continue."
- Frontend catches this and shows premium upgrade dialog
- User is guided through upgrade process