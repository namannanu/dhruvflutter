import 'package:flutter/material.dart';
import 'package:talent/core/services/permission_service.dart';
import 'package:talent/core/widgets/permission_widgets.dart';

/// Example navigation drawer with permission-based menu items
class PermissionAwareNavigationDrawer extends StatelessWidget {
  const PermissionAwareNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'WorkConnect',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),

          // Dashboard - Always visible
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pushNamed(context, '/dashboard'),
          ),

          // Business Management Section
          PermissionGuard(
            permissions: const [
              'create_business',
              'edit_business',
              'view_business_analytics'
            ],
            child: ExpansionTile(
              leading: const Icon(Icons.business),
              title: const Text('Business'),
              children: [
                PermissionGuard(
                  permission: 'create_business',
                  child: ListTile(
                    leading: const Icon(Icons.add_business),
                    title: const Text('Create Business'),
                    onTap: () =>
                        Navigator.pushNamed(context, '/business/create'),
                  ),
                ),
                PermissionGuard(
                  permission: 'edit_business',
                  child: ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Manage Business'),
                    onTap: () =>
                        Navigator.pushNamed(context, '/business/manage'),
                  ),
                ),
                PermissionGuard(
                  permission: 'view_business_analytics',
                  child: ListTile(
                    leading: const Icon(Icons.analytics),
                    title: const Text('Business Analytics'),
                    onTap: () =>
                        Navigator.pushNamed(context, '/business/analytics'),
                  ),
                ),
              ],
            ),
          ),

          // Job Management Section
          PermissionGuard(
            permissions: const ['create_jobs', 'edit_jobs', 'view_jobs', 'post_jobs'],
            child: ExpansionTile(
              leading: const Icon(Icons.work),
              title: const Text('Jobs'),
              children: [
                PermissionGuard(
                  permission: 'view_jobs',
                  child: ListTile(
                    leading: const Icon(Icons.list),
                    title: const Text('View Jobs'),
                    onTap: () => Navigator.pushNamed(context, '/jobs'),
                  ),
                ),
                PermissionGuard(
                  permission: 'create_jobs',
                  child: ListTile(
                    leading: const Icon(Icons.add_circle),
                    title: const Text('Create Job'),
                    onTap: () => Navigator.pushNamed(context, '/jobs/create'),
                  ),
                ),
                PermissionGuard(
                  permission: 'post_jobs',
                  child: ListTile(
                    leading: const Icon(Icons.publish),
                    title: const Text('Post Jobs'),
                    onTap: () => Navigator.pushNamed(context, '/jobs/post'),
                  ),
                ),
              ],
            ),
          ),

          // Applications Section
          PermissionGuard(
            permissions: const [
              'view_applications',
              'manage_applications',
              'approve_applications'
            ],
            child: ExpansionTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Applications'),
              children: [
                PermissionGuard(
                  permission: 'view_applications',
                  child: ListTile(
                    leading: const Icon(Icons.visibility),
                    title: const Text('View Applications'),
                    onTap: () => Navigator.pushNamed(context, '/applications'),
                  ),
                ),
                PermissionGuard(
                  permission: 'manage_applications',
                  child: ListTile(
                    leading: const Icon(Icons.manage_accounts),
                    title: const Text('Manage Applications'),
                    onTap: () =>
                        Navigator.pushNamed(context, '/applications/manage'),
                  ),
                ),
                PermissionGuard(
                  permission: 'approve_applications',
                  child: ListTile(
                    leading: const Icon(Icons.check_circle),
                    title: const Text('Approve Applications'),
                    onTap: () =>
                        Navigator.pushNamed(context, '/applications/approve'),
                  ),
                ),
              ],
            ),
          ),

          // Attendance & Schedules Section
          PermissionGuard(
            permissions: const [
              'view_attendance',
              'manage_attendance',
              'create_schedules',
              'manage_schedules'
            ],
            child: ExpansionTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Attendance & Schedules'),
              children: [
                PermissionGuard(
                  permission: 'view_attendance',
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('View Attendance'),
                    onTap: () => Navigator.pushNamed(context, '/attendance'),
                  ),
                ),
                PermissionGuard(
                  permission: 'manage_attendance',
                  child: ListTile(
                    leading: const Icon(Icons.edit_calendar),
                    title: const Text('Manage Attendance'),
                    onTap: () =>
                        Navigator.pushNamed(context, '/attendance/manage'),
                  ),
                ),
                PermissionGuard(
                  permission: 'create_schedules',
                  child: ListTile(
                    leading: const Icon(Icons.add_alarm),
                    title: const Text('Create Schedule'),
                    onTap: () =>
                        Navigator.pushNamed(context, '/schedules/create'),
                  ),
                ),
                PermissionGuard(
                  permission: 'manage_schedules',
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: const Text('Manage Schedules'),
                    onTap: () => Navigator.pushNamed(context, '/schedules'),
                  ),
                ),
              ],
            ),
          ),

          // Team Management Section
          PermissionGuard(
            permissions: const [
              'invite_team_members',
              'edit_team_members',
              'manage_permissions'
            ],
            child: ExpansionTile(
              leading: const Icon(Icons.group),
              title: const Text('Team'),
              children: [
                PermissionGuard(
                  permission: 'invite_team_members',
                  child: ListTile(
                    leading: const Icon(Icons.person_add),
                    title: const Text('Invite Members'),
                    onTap: () => Navigator.pushNamed(context, '/team/invite'),
                  ),
                ),
                PermissionGuard(
                  permission: 'edit_team_members',
                  child: ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Manage Team'),
                    onTap: () => Navigator.pushNamed(context, '/team'),
                  ),
                ),
                PermissionGuard(
                  permission: 'manage_permissions',
                  child: ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Permissions'),
                    onTap: () =>
                        Navigator.pushNamed(context, '/team/permissions'),
                  ),
                ),
              ],
            ),
          ),

          // Payments Section
          PermissionGuard(
            permissions: const [
              'view_payments',
              'manage_payments',
              'process_payments',
              'view_financial_reports'
            ],
            child: ExpansionTile(
              leading: const Icon(Icons.payment),
              title: const Text('Payments'),
              children: [
                PermissionGuard(
                  permission: 'view_payments',
                  child: ListTile(
                    leading: const Icon(Icons.receipt),
                    title: const Text('View Payments'),
                    onTap: () => Navigator.pushNamed(context, '/payments'),
                  ),
                ),
                PermissionGuard(
                  permission: 'manage_payments',
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: const Text('Manage Payments'),
                    onTap: () =>
                        Navigator.pushNamed(context, '/payments/manage'),
                  ),
                ),
                PermissionGuard(
                  permission: 'process_payments',
                  child: ListTile(
                    leading: const Icon(Icons.send),
                    title: const Text('Process Payments'),
                    onTap: () =>
                        Navigator.pushNamed(context, '/payments/process'),
                  ),
                ),
                PermissionGuard(
                  permission: 'view_financial_reports',
                  child: ListTile(
                    leading: const Icon(Icons.assessment),
                    title: const Text('Financial Reports'),
                    onTap: () =>
                        Navigator.pushNamed(context, '/reports/financial'),
                  ),
                ),
              ],
            ),
          ),

          // Analytics & Reports Section
          PermissionGuard(
            permissions: const ['view_analytics', 'view_reports', 'export_data'],
            child: ExpansionTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Analytics & Reports'),
              children: [
                PermissionGuard(
                  permission: 'view_analytics',
                  child: ListTile(
                    leading: const Icon(Icons.trending_up),
                    title: const Text('Analytics'),
                    onTap: () => Navigator.pushNamed(context, '/analytics'),
                  ),
                ),
                PermissionGuard(
                  permission: 'view_reports',
                  child: ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Reports'),
                    onTap: () => Navigator.pushNamed(context, '/reports'),
                  ),
                ),
                PermissionGuard(
                  permission: 'export_data',
                  child: ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Export Data'),
                    onTap: () => Navigator.pushNamed(context, '/export'),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Settings Section
          PermissionGuard(
            permissions: const [
              'manage_settings',
              'view_audit_logs',
              'manage_integrations'
            ],
            child: ExpansionTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              children: [
                PermissionGuard(
                  permission: 'manage_settings',
                  child: ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text('General Settings'),
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ),
                PermissionGuard(
                  permission: 'view_audit_logs',
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Audit Logs'),
                    onTap: () =>
                        Navigator.pushNamed(context, '/settings/audit'),
                  ),
                ),
                PermissionGuard(
                  permission: 'manage_integrations',
                  child: ListTile(
                    leading: const Icon(Icons.extension),
                    title: const Text('Integrations'),
                    onTap: () =>
                        Navigator.pushNamed(context, '/settings/integrations'),
                  ),
                ),
              ],
            ),
          ),

          // Profile & Logout - Always visible
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              // Implement logout logic
            },
          ),
        ],
      ),
    );
  }
}

/// Example bottom navigation bar with permission-based tabs
class PermissionAwareBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PermissionAwareBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService(context: context);
    final items = <BottomNavigationBarItem>[];

    // Dashboard - Always visible
    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ));

    // Jobs - Only if user can view jobs
    if (permissionService.hasPermission('view_jobs')) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.work),
        label: 'Jobs',
      ));
    }

    // Applications - Only if user can view applications
    if (permissionService.hasPermission('view_applications')) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.assignment),
        label: 'Applications',
      ));
    }

    // Attendance - Only if user can view attendance
    if (permissionService.hasPermission('view_attendance')) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.access_time),
        label: 'Attendance',
      ));
    }

    // Team - Only if user can manage team
    if (permissionService
        .hasAnyPermission(['invite_team_members', 'edit_team_members'])) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.group),
        label: 'Team',
      ));
    }

    return BottomNavigationBar(
      currentIndex: currentIndex < items.length ? currentIndex : 0,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: items,
    );
  }
}

/// Example app bar with permission-based actions
class PermissionAwareAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final List<String> requiredPermissions;

  const PermissionAwareAppBar({
    super.key,
    required this.title,
    this.requiredPermissions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        // Create button - Only if user can create
        PermissionGuard(
          permissions: const ['create_jobs', 'create_business', 'create_schedules'],
          child: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Show create options based on permissions
              _showCreateOptions(context);
            },
          ),
        ),

        // Settings button - Only if user can manage settings
        PermissionGuard(
          permission: 'manage_settings',
          child: IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ),
      ],
    );
  }

  void _showCreateOptions(BuildContext context) {
    final permissionService = PermissionService(context: context);
    final options = <String, String>{};

    if (permissionService.hasPermission('create_jobs')) {
      options['job'] = 'Create Job';
    }
    if (permissionService.hasPermission('create_business')) {
      options['business'] = 'Create Business';
    }
    if (permissionService.hasPermission('create_schedules')) {
      options['schedule'] = 'Create Schedule';
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.entries.map((entry) {
            return ListTile(
              leading: const Icon(Icons.add),
              title: Text(entry.value),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/${entry.key}/create');
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
