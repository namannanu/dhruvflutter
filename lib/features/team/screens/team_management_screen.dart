// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/team_access.dart';
import '../../../core/providers/team_provider.dart';
import '../../../core/state/app_state.dart';
import '../../team_management/services/team_invitation_service.dart';
import '../widgets/edit_access_dialog.dart';
import '../widgets/grant_access_dialog.dart';
import '../widgets/invite_team_member_dialog.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load team data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);
      final currentUserId = appState.currentUser?.id;
      if (currentUserId != null) {
        teamProvider.loadAllTeamData(currentUserId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              text: 'My Team',
              icon: Icon(Icons.group),
            ),
            Tab(
              text: 'My Access',
              icon: Icon(Icons.admin_panel_settings),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final appState = Provider.of<AppState>(context, listen: false);
              final teamProvider =
                  Provider.of<TeamProvider>(context, listen: false);
              final currentUserId = appState.currentUser?.id;
              if (currentUserId != null) {
                teamProvider.refresh(currentUserId);
              }
            },
            tooltip: 'Refresh',
          ),
          // Debug button to test API directly
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              final appState = Provider.of<AppState>(context, listen: false);
              final businessId = appState.currentUser?.selectedBusinessId;

              if (businessId != null) {
                print('=== TESTING API DIRECTLY ===');
                print('Business ID: $businessId');
                final invitationService = TeamInvitationService();
                final testEmail =
                    'team-test+${DateTime.now().millisecondsSinceEpoch}@example.com';
                try {
                  final result = await invitationService.inviteTeamMember(
                    userEmail: testEmail,
                    businessId: businessId,
                    role: 'staff',
                    permissions: const {'view_team_members': true},
                  );

                  if (!mounted) {
                    return;
                  }

                  if (result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invitation sent to $testEmail'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invitation request failed - see logs'),
                      ),
                    );
                  }
                } catch (error) {
                  if (!mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Invitation error: ${error.toString().split('\n').first}',
                      ),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No business selected')),
                );
              }
            },
            tooltip: 'Test API',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final appState = Provider.of<AppState>(context, listen: false);
              final currentUserId = appState.currentUser?.id;
              if (currentUserId != null) {
                print('=== INVITE BUTTON PRESSED ===');
                print('Current User ID: $currentUserId');
                print(
                    'Selected Business ID: ${appState.currentUser?.selectedBusinessId}');
                // User permissions removed per user request

                showDialog(
                  context: context,
                  builder: (context) => const InviteTeamMemberDialog(),
                );
              }
            },
            tooltip: 'Invite Team Member',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyTeamTab(),
          _buildMyAccessTab(),
        ],
      ),
    );
  }

  Widget _buildMyTeamTab() {
    return Consumer2<AppState, TeamProvider>(
      builder: (context, appState, teamProvider, child) {
        final currentUserId = appState.currentUser?.id;

        if (currentUserId == null) {
          return const Center(
            child: Text('User not logged in'),
          );
        }

        if (teamProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (teamProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading team data',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  teamProvider.error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => teamProvider.loadTeamMembers(currentUserId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (teamProvider.teamMembers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No team members yet',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Grant access to team members to get started',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          GrantAccessDialog(currentUserId: currentUserId),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Grant Access'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Statistics cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Members',
                      teamProvider.totalTeamMembers.toString(),
                      Icons.group,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Active',
                      teamProvider.activeTeamMembersCount.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Expired',
                      teamProvider.expiredTeamMembers.length.toString(),
                      Icons.warning,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            // Team members list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: teamProvider.teamMembers.length,
                itemBuilder: (context, index) {
                  final teamAccess = teamProvider.teamMembers[index];
                  return TeamAccessCard(
                    teamAccess: teamAccess,
                    currentUserId: currentUserId,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyAccessTab() {
    return Consumer2<AppState, TeamProvider>(
      builder: (context, appState, teamProvider, child) {
        final currentUserId = appState.currentUser?.id;

        if (currentUserId == null) {
          return const Center(
            child: Text('User not logged in'),
          );
        }

        if (teamProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (teamProvider.managedAccess.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No access granted',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'You haven\'t been granted access to any teams yet',
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: teamProvider.managedAccess.length,
          itemBuilder: (context, index) {
            final access = teamProvider.managedAccess[index];
            return ManagedAccessCard(teamAccess: access);
          },
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class TeamAccessCard extends StatelessWidget {
  final TeamAccess teamAccess;
  final String currentUserId;

  const TeamAccessCard({
    super.key,
    required this.teamAccess,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: teamAccess.isActive ? Colors.green : Colors.grey,
          child: Text(
            teamAccess.managedUser?.name.substring(0, 1).toUpperCase() ?? 'U',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(teamAccess.managedUser?.name ?? 'Unknown User'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: ${teamAccess.roleDisplayName}'),
            Text('Status: ${teamAccess.statusDisplayName}'),
            if (teamAccess.expiresAt != null)
              Text(
                  'Expires: ${teamAccess.expiresAt!.toLocal().toString().split(' ')[0]}'),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            final teamProvider =
                Provider.of<TeamProvider>(context, listen: false);

            switch (value) {
              case 'edit':
                await showDialog(
                  context: context,
                  builder: (context) => EditAccessDialog(
                    teamAccess: teamAccess,
                    currentUserId: currentUserId,
                  ),
                );
                break;
              case 'revoke':
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Revoke Access'),
                    content: Text(
                        'Are you sure you want to revoke access for ${teamAccess.managedUser?.name}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Revoke'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await teamProvider.revokeAccess(
                    identifier: teamAccess.id,
                    reason: 'Revoked by user',
                  );
                }
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Access'),
              ),
            ),
            const PopupMenuItem(
              value: 'revoke',
              child: ListTile(
                leading: Icon(Icons.remove_circle),
                title: Text('Revoke Access'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManagedAccessCard extends StatelessWidget {
  final TeamAccess teamAccess;

  const ManagedAccessCard({
    super.key,
    required this.teamAccess,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: teamAccess.isActive ? Colors.blue : Colors.grey,
          child: Text(
            teamAccess.grantedByUser?.name.substring(0, 1).toUpperCase() ?? 'U',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
            'Access granted by ${teamAccess.grantedByUser?.name ?? 'Unknown'}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: ${teamAccess.roleDisplayName}'),
            Text('Status: ${teamAccess.statusDisplayName}'),
            Text(
                'Permissions: ${teamAccess.permissions.enabledPermissions.join(', ')}'),
            if (teamAccess.expiresAt != null)
              Text(
                  'Expires: ${teamAccess.expiresAt!.toLocal().toString().split(' ')[0]}'),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) =>
                  TeamAccessDetailSheet(teamAccess: teamAccess),
            );
          },
        ),
      ),
    );
  }
}

class TeamAccessDetailSheet extends StatelessWidget {
  final TeamAccess teamAccess;

  const TeamAccessDetailSheet({
    super.key,
    required this.teamAccess,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Access Details',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Role', teamAccess.roleDisplayName),
          _buildDetailRow('Status', teamAccess.statusDisplayName),
          _buildDetailRow('Created', teamAccess.createdAt.toLocal().toString()),
          if (teamAccess.expiresAt != null)
            _buildDetailRow(
                'Expires', teamAccess.expiresAt!.toLocal().toString()),
          if (teamAccess.lastUsedAt != null)
            _buildDetailRow(
                'Last Used', teamAccess.lastUsedAt!.toLocal().toString()),
          _buildDetailRow('Access Level', teamAccess.accessLevel),
          const SizedBox(height: 16),
          Text(
            'Permissions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: teamAccess.permissions.enabledPermissions
                .map((permission) => Chip(label: Text(permission)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
