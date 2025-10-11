# Comprehensive Permission System Implementation

This document explains how to use the implemented role-based access control (RBAC) system for your team management application.

## Overview

The permission system ensures that team members can only access features and operations that match their assigned permissions. This creates a secure, scalable system where permissions determine exactly what each user can do.

## Frontend Implementation

### 1. Permission Service (`PermissionService`)

**Location**: `/lib/core/services/permission_service.dart`

**Purpose**: Centralized service for checking user permissions.

**Key Methods**:
- `hasPermission(String permission)` - Check if user has a specific permission
- `hasAnyPermission(List<String> permissions)` - Check if user has any of the specified permissions
- `hasAllPermissions(List<String> permissions)` - Check if user has all specified permissions
- `canPerformAction(String action)` - Check if user can perform a specific action

**Usage Example**:
```dart
final permissionService = PermissionService(context: context);
if (permissionService.hasPermission('create_jobs')) {
  // User can create jobs
}
```

### 2. Permission Widgets (`permission_widgets.dart`)

**Location**: `/lib/core/widgets/permission_widgets.dart`

**Available Widgets**:

#### PermissionGuard
Conditionally shows/hides content based on permissions:
```dart
PermissionGuard(
  permission: 'create_jobs',
  child: ElevatedButton(
    onPressed: () => createJob(),
    child: Text('Create Job'),
  ),
)
```

#### PermissionAwareButton
Button that automatically disables based on permissions:
```dart
PermissionAwareButton(
  permission: 'edit_business',
  onPressed: () => editBusiness(),
  child: Text('Edit Business'),
)
```

#### PermissionAwareFAB
Floating Action Button that shows/hides based on permissions:
```dart
PermissionAwareFAB(
  permission: 'invite_team_members',
  onPressed: () => inviteTeamMember(),
  child: Icon(Icons.person_add),
)
```

### 3. Navigation with Permissions (`permission_aware_navigation.dart`)

**Location**: `/lib/core/widgets/permission_aware_navigation.dart`

Shows navigation items only to users with appropriate permissions:
```dart
PermissionAwareNavigationDrawer() // Complete navigation drawer
PermissionAwareBottomNavigation() // Bottom navigation bar
PermissionAwareAppBar() // App bar with permission-based actions
```

## Backend Implementation

### 1. Permission Middleware (`permissionMiddleware.js`)

**Location**: `/src/shared/middlewares/permissionMiddleware.js`

**Key Functions**:
- `requirePermissions(permissions, options)` - Middleware to require specific permissions
- `autoCheckPermissions()` - Automatically check permissions based on endpoint
- `getUserPermissions(userId, businessId)` - Get user's permissions
- `validatePermissions(permissions)` - Validate permission array

### 2. Using Permission Middleware in Routes

**Example**: Protecting job creation endpoint
```javascript
router.post('/jobs',
  authMiddleware.protect,
  requirePermissions('create_jobs'),
  async (req, res, next) => {
    // User is guaranteed to have 'create_jobs' permission
    // Implement job creation logic
  }
);
```

**Example**: Multiple permissions (any one required)
```javascript
router.post('/applications/process',
  authMiddleware.protect,
  requirePermissions(['approve_applications', 'reject_applications']),
  async (req, res, next) => {
    // User has either approve or reject permission
  }
);
```

**Example**: Multiple permissions (all required)
```javascript
router.post('/sensitive-operation',
  authMiddleware.protect,
  requirePermissions(['manage_payments', 'view_financial_reports'], { requireAll: true }),
  async (req, res, next) => {
    // User has both permissions
  }
);
```

## Available Permissions

### Business Management
- `create_business` - Create new business
- `edit_business` - Edit business details
- `delete_business` - Delete business
- `view_business_analytics` - View business analytics

### Job Management
- `create_jobs` - Create new jobs
- `edit_jobs` - Edit existing jobs
- `delete_jobs` - Delete jobs
- `view_jobs` - View job listings
- `post_jobs` - Publish jobs

### Worker & Application Management
- `hire_workers` - Hire workers
- `fire_workers` - Fire workers
- `view_applications` - View job applications
- `manage_applications` - Manage applications
- `approve_applications` - Approve applications
- `reject_applications` - Reject applications

### Schedule & Attendance Management
- `create_schedules` - Create schedules
- `edit_schedules` - Edit schedules
- `delete_schedules` - Delete schedules
- `manage_schedules` - Manage schedules
- `view_attendance` - View attendance records
- `manage_attendance` - Manage attendance
- `approve_attendance` - Approve attendance

### Payment & Financial Management
- `view_payments` - View payments
- `manage_payments` - Manage payments
- `process_payments` - Process payments
- `view_financial_reports` - View financial reports

### Team Management
- `invite_team_members` - Invite team members
- `edit_team_members` - Edit team members
- `remove_team_members` - Remove team members
- `manage_permissions` - Manage permissions

### Analytics & Reporting
- `view_analytics` - View analytics
- `view_reports` - View reports
- `export_data` - Export data

### System Administration
- `manage_settings` - Manage settings
- `view_audit_logs` - View audit logs
- `manage_integrations` - Manage integrations

## Role-Based Default Permissions

### Owner/Admin
- **All permissions** - Complete access to everything

### Manager
- Most business operations including:
  - Business editing and analytics
  - Job creation and management
  - Worker hiring and application management
  - Schedule and attendance management
  - Payment management
  - Team member invitation and editing
  - Analytics and reporting

### Supervisor
- Limited management permissions:
  - Job viewing and posting
  - Application viewing and management
  - Schedule management
  - Attendance viewing and management
  - Payment viewing
  - Analytics and reporting

### Staff
- Basic permissions:
  - Job viewing
  - Application viewing
  - Attendance viewing
  - Analytics viewing

## Implementation Steps

### 1. Update Team Management
The team management screen now uses permission-aware widgets:
- Invite button only shows for users with `invite_team_members` permission
- Edit/Remove actions only show for users with appropriate permissions

### 2. Protect API Endpoints
Add permission middleware to your existing routes:
```javascript
// Before
router.post('/jobs', jobController.createJob);

// After
router.post('/jobs', 
  authMiddleware.protect,
  requirePermissions('create_jobs'),
  jobController.createJob
);
```

### 3. Update UI Components
Replace regular buttons/widgets with permission-aware versions:
```dart
// Before
ElevatedButton(
  onPressed: () => createJob(),
  child: Text('Create Job'),
)

// After
PermissionAwareButton(
  permission: 'create_jobs',
  onPressed: () => createJob(),
  child: Text('Create Job'),
)
```

### 4. Update Navigation
Use the permission-aware navigation components to hide menu items that users can't access.

## Security Considerations

1. **Frontend permissions are for UX only** - They hide UI elements but don't provide security
2. **Backend validation is mandatory** - Always validate permissions on the server
3. **Permissions are business-scoped** - Users may have different permissions in different businesses
4. **Owner permissions** - Business owners always have all permissions
5. **Role inheritance** - Higher roles inherit permissions from lower roles

## Testing

1. **Create test users** with different roles
2. **Verify UI changes** - Ensure appropriate elements show/hide
3. **Test API endpoints** - Verify permission enforcement works
4. **Test role changes** - Ensure permissions update when roles change
5. **Test business switching** - Verify permissions change with business context

This permission system provides comprehensive access control that ensures team members can only access features they're authorized to use, creating a secure and organized team management environment.