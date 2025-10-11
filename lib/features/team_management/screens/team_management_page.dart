// ignore_for_file: use_build_context_synchronously, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/auth_token_manager.dart';
import '../services/team_invitation_service.dart';
import '../widgets/invite_member_dialog.dart';

class TeamManagementPage extends StatefulWidget {
  final String? authToken; // Add auth token parameter

  const TeamManagementPage({super.key, this.authToken});

  @override
  State<TeamManagementPage> createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {
  final TeamInvitationService _teamService = TeamInvitationService();
  List<Map<String, dynamic>> _teamMembers = [];
  List<Map<String, dynamic>> _teamNotifications = [];
  bool _isLoading = false;
  bool _isNotificationsLoading = false;
  String? _error;
  String? _authToken;
  String? _businessId;
  String? _currentUserEmail; // Store current user email

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First check if we have stored login data
      _authToken = await AuthTokenManager.instance.getAuthToken();
      _businessId = await AuthTokenManager.instance.getFirstBusinessId();

      // If no stored token, automatically store your login token
      if (_authToken == null || _businessId == null) {
        print('🔑 No stored token found, storing your login token...');
        await AuthTokenManager.instance.storeYourToken();
        _authToken = await AuthTokenManager.instance.getAuthToken();
        _businessId = await AuthTokenManager.instance.getFirstBusinessId();
      }

      if (_authToken != null && _businessId != null) {
        print('🔑 Using login token for team management');
        
        // Get current user email
        _currentUserEmail = await _getUserEmail();
        print('👤 Current user email: $_currentUserEmail');
        
        // Try to get business context from user's access records
        await _getBusinessContext();
        
        await _loadTeamMembers();
        await _loadTeamNotifications();
      } else {
        setState(() {
          _error = 'Failed to get authentication token';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  Future<String?> _getUserEmail() async {
    try {
      final userInfo = await AuthTokenManager.instance.getUserInfo();
      return userInfo['email'];
    } catch (e) {
      print('❌ Error getting user email: $e');
      return null;
    }
  }

  Future<void> _getBusinessContext() async {
    try {
      // Get the user's access records to find business information
      final accessRecords = await _teamService.getMyAccess(authToken: _authToken);
      print('📊 Access records: ${accessRecords.length}');
      
      if (accessRecords.isNotEmpty) {
        // Extract business information from access records
        final businessContext = accessRecords.first['businessContext'] as Map<String, dynamic>?;
        if (businessContext != null && businessContext['businessId'] != null) {
          _businessId = businessContext['businessId'] as String;
          print('✅ Found business ID from access records: $_businessId');
        }
      }
    } catch (e) {
      print('⚠️ Error getting business context: $e');
    }
  }

  Future<void> _loadTeamMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔄 Loading team members...');
      final allTeamMembers =
          await _teamService.getTeamMembers(authToken: _authToken);

      print('📊 Received ${allTeamMembers.length} team members');

      // Filter out inactive members (revoked, suspended, etc.)
      final activeMembers = allTeamMembers.where((member) {
        final status = member['status'] as String? ?? 'pending';
        return status.toLowerCase() != 'revoked' &&
            status.toLowerCase() != 'suspended' &&
            status.toLowerCase() != 'inactive';
      }).toList();

      setState(() {
        _teamMembers = activeMembers;
        _isLoading = false;
      });

      print(
          '📊 Loaded ${activeMembers.length} active members (filtered from ${allTeamMembers.length} total)');
    } catch (e, stackTrace) {
      print('💥 Error loading team members: $e');
      print('📍 Stack trace: $stackTrace');
      setState(() {
        _error = 'Failed to load team members: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTeamNotifications() async {
    setState(() {
      _isNotificationsLoading = true;
    });

    try {
      final notifications =
          await _teamService.getTeamNotifications(authToken: _authToken);
      setState(() {
        _teamNotifications = notifications;
        _isNotificationsLoading = false;
      });
    } catch (e, stackTrace) {
      print('💥 Error loading notifications: $e');
      print('📍 Stack trace: $stackTrace');
      setState(() {
        _isNotificationsLoading = false;
      });
    }
  }

  Future<void> _refreshTeamData() async {
    await _loadTeamMembers();
    await _loadTeamNotifications();
  }

  Future<void> _showInviteDialog() async {
    if (_businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No business found. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => InviteMemberDialog(
        businessId: _businessId!,
        authToken: _authToken, // Pass auth token to dialog
      ),
    );

    if (result == true) {
      await _refreshTeamData(); // Refresh the list
    }
  }

  Future<void> _removeTeamMember(String accessId, String memberName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Team Member'),
        content:
            Text('Are you sure you want to remove $memberName from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _teamService.removeTeamMember(accessId,
            authToken: _authToken);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $memberName removed from team'),
              backgroundColor: Colors.green,
            ),
          );
          await _refreshTeamData(); // Refresh the list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to remove team member'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTeamData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showInviteDialog,
            tooltip: 'Invite Team Member',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading team data...'),
          ],
        ),
      );
    }

    if (_error != null) {
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
              'Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshTeamData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final hasMembers = _teamMembers.isNotEmpty;
    final hasNotifications = _teamNotifications.isNotEmpty;

    if (!hasMembers && !hasNotifications) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Team Activity Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Invite team members to start collaborating and receive updates here.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showInviteDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Invite Team Member'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTeamData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isNotificationsLoading && !hasNotifications)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: const [
                    CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(width: 12),
                    Text('Loading team notifications...'),
                  ],
                ),
              ),
            ),
          if (hasNotifications) _buildNotificationSection(),
          if (hasMembers)
            ..._teamMembers.map((member) => _buildTeamMemberCard(member)),
          if (!hasMembers)
            _buildInvitePromptCard(),
        ],
      ),
    );
  }


  Widget _buildTeamMemberCard(Map<String, dynamic> member) {
    // Debug: Print the complete member structure to understand the data
    print('🔍 Complete member data structure:');
    print(member.toString());
    
    // Extract the team member's email (the person who was granted access)
    String teamMemberEmail = 'Unknown Member';
    
    if (member['employee'] != null && member['employee']['email'] != null) {
      teamMemberEmail = member['employee']['email'] as String;
      print('✅ Found employee email: $teamMemberEmail');
    } else if (member['managedUser'] != null && member['managedUser']['email'] != null) {
      teamMemberEmail = member['managedUser']['email'] as String;
      print('✅ Found managedUser email: $teamMemberEmail');
    } else if (member['userEmail'] != null) {
      teamMemberEmail = member['userEmail'] as String;
      print('⚠️ Using userEmail field: $teamMemberEmail');
    } else if (member['email'] != null) {
      teamMemberEmail = member['email'] as String;
      print('⚠️ Using email field: $teamMemberEmail');
    } else {
      print('❌ No email field found in member data');
    }
    
    final role = member['role'] as String? ?? 'staff';
    final status = member['status'] as String? ?? 'pending';
    final accessLevel = member['accessLevel'] as String? ?? 'view_only';

    // Handle permissions safely - it could be a List or Map or null
    List<dynamic> permissions = [];
    try {
      final permissionsData = member['permissions'];
      if (permissionsData is List) {
        permissions = permissionsData;
      } else if (permissionsData is Map) {
        // If it's a map, get the keys where value is true
        permissions = (permissionsData as Map<String, dynamic>)
            .entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList();
      }
    } catch (e) {
      print('⚠️ Error parsing permissions for $teamMemberEmail: $e');
    }

    final accessId = member['id'] as String? ?? member['_id'] as String?;

    // Debug print the member data
    print('🧪 Building card for member: $teamMemberEmail');
    print('🧪 Member data: $member');
    print('🧪 Permissions: $permissions');

    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            _getStatusIcon(status),
            color: statusColor,
            size: 20,
          ),
        ),
        title: Text(
          teamMemberEmail,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _capitalizeFirstLetter(role),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              'Access: ${_getAccessLevelLabel(accessLevel)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            if (permissions.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Permissions: ${permissions.map((p) => p.toString()).join(", ")}',
                style: TextStyle(color: Colors.blue[600], fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: accessId != null
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _removeTeamMember(accessId, teamMemberEmail),
                tooltip: 'Remove member',
              )
            : null,
      ),
    );
  }


  Widget _buildNotificationSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Team Notifications',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._teamNotifications.take(10).map(_buildNotificationTile).toList(),
            if (_teamNotifications.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_teamNotifications.length - 10} more notification(s) hidden',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    final type = (notification['type'] as String? ?? 'team_update').toLowerCase();
    final isRead = notification['readAt'] != null;
    final title = notification['title']?.toString() ?? 'Team update';
    final message = notification['message']?.toString() ??
        notification['body']?.toString() ??
        '';
    final createdAtIso = notification['createdAt']?.toString();
    final createdAt = createdAtIso != null
        ? DateTime.tryParse(createdAtIso)
        : null;

    IconData leadingIcon;
    Color iconColor;
    switch (type) {
      case 'team_invite':
        leadingIcon = Icons.mail_outline;
        iconColor = Colors.blue;
        break;
      case 'team_update':
      default:
        leadingIcon = Icons.campaign_outlined;
        iconColor = Colors.deepPurple;
        break;
    }

    if (isRead) {
      iconColor = Colors.grey;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(leadingIcon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isNotEmpty)
            Text(
              message,
              style: const TextStyle(fontSize: 13),
            ),
          if (createdAt != null)
            Text(
              _formatNotificationTime(createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
      trailing: isRead
          ? const SizedBox.shrink()
          : TextButton(
              onPressed: () => _markNotificationRead(notification),
              child: const Text('Mark read'),
            ),
      onTap: () => _markNotificationRead(notification),
    );
  }

  Widget _buildInvitePromptCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group_add, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Invite teammates to collaborate',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Send an invitation to give your colleagues access to manage your business.',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _showInviteDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Invite Team Member'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markNotificationRead(Map<String, dynamic> notification) async {
    final notificationId =
        notification['id']?.toString() ?? notification['_id']?.toString();
    if (notificationId == null) {
      return;
    }

    if (notification['readAt'] != null) {
      return;
    }

    final success = await _teamService.markNotificationRead(
      notificationId,
      authToken: _authToken,
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark notification as read'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      final index = _teamNotifications.indexWhere((item) {
        final id = item['id']?.toString() ?? item['_id']?.toString();
        return id == notificationId;
      });
      if (index != -1) {
        _teamNotifications[index] = {
          ..._teamNotifications[index],
          'readAt': DateTime.now().toIso8601String(),
        };
      }
    });
  }

  String _formatNotificationTime(DateTime dateTime) {
    final formatter = DateFormat('MMM d, h:mm a');
    return formatter.format(dateTime.toLocal());
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'invited':
        return Colors.blue;
      case 'suspended':
        return Colors.red;
      case 'revoked':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'invited':
        return Icons.mail_outline;
      case 'suspended':
        return Icons.pause_circle;
      case 'revoked':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _getAccessLevelLabel(String accessLevel) {
    switch (accessLevel.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'manager':
        return 'Manager';
      case 'employee':
        return 'Employee';
      case 'viewer':
        return 'Viewer';
      default:
        return 'Unknown';
    }
  }
}
