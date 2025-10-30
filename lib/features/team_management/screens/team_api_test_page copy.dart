// ignore_for_file: use_build_context_synchronously, avoid_print, file_names

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../services/auth_token_manager.dart';
import '../services/direct_team_test_service.dart';

void main() => runApp(const TeamApiTestApp());

class TeamApiTestApp extends StatelessWidget {
  const TeamApiTestApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team API Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const TeamApiTestPage(),
    );
  }
}

class TeamApiTestPage extends StatefulWidget {
  const TeamApiTestPage({super.key});
  @override
  State<TeamApiTestPage> createState() => _TeamApiTestPageState();
}

class _TeamApiTestPageState extends State<TeamApiTestPage> {
  // Inputs
  final _authTokenController = TextEditingController();
  final _emailController = TextEditingController();
  final _businessIdController = TextEditingController();

  // State
  String _selectedRole = 'staff';
  String _selectedAccessLevel = 'view_only';
  String? _selectedBusinessId; // <- the dropdown value
  bool _isLoading = false;

  // Business dropdown data
  List<Map<String, dynamic>> _businesses = [];
  bool _isLoadingBusinesses = false;

  // Team + access debug
  Map<String, dynamic>? _teamData;
  List<Map<String, dynamic>> _members = [];
  String? _fetchError;

  Map<String, dynamic>? _accessData;
  String? _accessError;

  // Last HTTP info (debug panes)
  String? _requestUrl;
  Map<String, String>? _requestHeaders;

  @override
  void initState() {
    super.initState();
    _businessIdController.text = '';
    _emailController.text = '';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // STEP 1: Try fetching cached login token
      final cachedToken = await AuthTokenManager.instance.getAuthToken();
      if (cachedToken != null && cachedToken.isNotEmpty) {
        _authTokenController.text = cachedToken;
        debugPrint(
            '✅ Loaded cached auth token (${cachedToken.substring(0, 12)}...)');
      } else {
        debugPrint('⚠️ No cached token found — please log in first');
      }

      // STEP 2: Load business list from cached login data
      await _loadBusinessesFromLogin();

      // STEP 3: Auto-fetch "my-access" using that token
      await _autoFetchMyAccess();
    });
  }

  @override
  void dispose() {
    _authTokenController.dispose();
    _emailController.dispose();
    _businessIdController.dispose();
    super.dispose();
  }

  // ---------- Business helpers ----------

  /// Safely set businesses while *preserving selection* when possible.
  void _applyBusinesses(List<Map<String, dynamic>> next) {
    // Ensure only items with _id exist
    final cleaned =
        next.where((m) => m['_id']?.toString().isNotEmpty ?? false).toList();

    String? preserved = _selectedBusinessId;
    if (preserved != null &&
        cleaned.every((b) => b['_id'].toString() != preserved)) {
      // previously selected does not exist in new list
      preserved = null;
    }
    final fallback =
        cleaned.isNotEmpty ? cleaned.first['_id'].toString() : null;

    if (!mounted) return;
    setState(() {
      _businesses = cleaned;
      _selectedBusinessId = preserved ?? fallback;
      _businessIdController.text = _selectedBusinessId ?? '';
    });
  }

  Future<void> _loadBusinessesFromLogin() async {
    try {
      setState(() => _isLoadingBusinesses = true);
      final loginData = await AuthTokenManager.instance.getUserData();

      print('🔍 DETAILED LOGIN DATA ANALYSIS:');
      print('🔍 Raw loginData: $loginData');
      print('🔍 loginData type: ${loginData.runtimeType}');

      if (loginData != null) {
        final user = loginData['user'];
        print('🔍 User info: ${user?['email']} (ID: ${user?['_id']})');

        final ownedBusinesses = loginData['ownedBusinesses'];
        final teamBusinesses = loginData['teamBusinesses'];

        print('🔍 Owned businesses type: ${ownedBusinesses.runtimeType}');
        print('🔍 Owned businesses content: $ownedBusinesses');
        print('🔍 Team businesses type: ${teamBusinesses.runtimeType}');
        print('🔍 Team businesses content: $teamBusinesses');
      }

      if (loginData == null) {
        // No login cache exists
        print('⚠️ No login data found in AuthTokenManager');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No login data found. Please log in again.'),
            backgroundColor: Colors.orange,
          ));
        }
        return;
      }

      final owned = (loginData['ownedBusinesses'] as List?) ?? const [];
      final team = (loginData['teamBusinesses'] as List?) ?? const [];

      print('🔍 Processing businesses:');
      print('🔍 Owned count: ${owned.length}');
      print('🔍 Team count: ${team.length}');

      final combined = <Map<String, dynamic>>[
        ...owned.map((b) => {
              '_id':
                  (b is Map ? (b['businessId'] ?? b['_id']) : null)?.toString(),
              'businessName': (b is Map
                      ? (b['businessName'] ?? b['name'] ?? 'Unnamed Business')
                      : 'Unnamed Business')
                  .toString(),
              'type': 'owned',
            }),
        ...team.map((b) => {
              '_id':
                  (b is Map ? (b['businessId'] ?? b['_id']) : null)?.toString(),
              'businessName': (b is Map
                      ? (b['businessName'] ?? b['name'] ?? 'Unnamed Business')
                      : 'Unnamed Business')
                  .toString(),
              'type': 'team',
              'grantedBy': (b is Map ? b['grantedBy'] : null)?.toString(),
              'source': (b is Map ? b['source'] : null)?.toString(),
            }),
      ];

      print('🔍 Combined businesses result: $combined');
      print('🔍 Combined count: ${combined.length}');

      // Debug: Print each business to see the data structure
      for (var business in combined) {
        print('🔍 Business: ${business['businessName']} - Type: ${business['type']} - GrantedBy: ${business['grantedBy']}');
      }

      _applyBusinesses(combined);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_businesses.isEmpty
              ? 'No businesses found in login data'
              : 'Loaded ${_businesses.length} businesses from login data'),
          backgroundColor: _businesses.isEmpty ? Colors.orange : Colors.green,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error loading businesses: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoadingBusinesses = false);
    }
  }

  // ---------- Access / Team ----------

  Future<void> _autoFetchMyAccess() async {
    String? token = _authTokenController.text.trim();
    if (token.isEmpty) {
      try {
        token = await AuthTokenManager.instance.getAuthToken();
      } catch (_) {}
    }
    if (token == null || token.isEmpty) {
      // last resort test token
      token =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4ZjBiNzgxMzczODI1ZDBlYWU1YWRjOCIsInJvbGUiOiJlbXBsb3llciIsImlhdCI6MTc2MDYwODY5NywiZXhwIjoxNzYxMjEzNDk3fQ.Depg0Z4dGs-NxNmEdKI8OWtXXAr9RPveQ_z1P22szss';
      _authTokenController.text = token;
    }

    try {
      final url =
          Uri.parse('https://dhruvbackend.vercel.app/api/team/my-access');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };
      final res = await http.get(url, headers: headers);

      dynamic decoded;
      try {
        decoded = json.decode(res.body);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        if (res.statusCode == 200 &&
            decoded is Map<String, dynamic> &&
            decoded['data'] is List &&
            (decoded['data'] as List).isNotEmpty) {
          _accessData = (decoded['data'] as List).first as Map<String, dynamic>;
          _accessError = null;
        } else {
          _accessData = null;
          _accessError = 'Failed (${res.statusCode})';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _accessError = 'My-access error: $e';
      });
    }
  }

  Future<void> _testGetTeamMembers({bool showStatus = true}) async {
    final token = _authTokenController.text.trim();
    if (token.isEmpty) {
      if (showStatus) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter auth token first'),
              backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (showStatus) setState(() => _isLoading = true);

    try {
      final url = Uri.parse('https://dhruvbackend.vercel.app/api/team/my-team');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };
      final res = await http.get(url, headers: headers);

      dynamic decoded;
      try {
        decoded = json.decode(res.body);
      } catch (_) {}

      final members = <Map<String, dynamic>>[];
      Map<String, dynamic>? team;

      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is List) {
          for (final m in data) {
            if (m is Map) members.add(m.cast<String, dynamic>());
          }
        }
        team = {
          'status': res.statusCode == 200 ? 'success' : 'error',
          'count': members.length,
          'data': members,
        };
      } else if (decoded is List) {
        for (final m in decoded) {
          if (m is Map) members.add(m.cast<String, dynamic>());
        }
        team = {
          'status': res.statusCode == 200 ? 'success' : 'error',
          'count': members.length,
          'data': members,
        };
      }

      if (!mounted) return;
      setState(() {
        _teamData = team;
        _members = members;
        _fetchError =
            res.statusCode == 200 ? null : 'Request failed (${res.statusCode})';
        _requestUrl = url.toString();
        _requestHeaders = Map<String, String>.from(headers);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fetchError = 'Failed to fetch team members: $e';
        _teamData = null;
        _members = [];
      });
    } finally {
      if (mounted && showStatus) setState(() => _isLoading = false);
    }
  }

  Future<void> _testCheckAccess() async {
    final token = _authTokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter auth token first'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final url =
          Uri.parse('https://dhruvbackend.vercel.app/api/team/my-access');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };
      final res = await http.get(url, headers: headers);
      dynamic decoded;
      try {
        decoded = json.decode(res.body);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        if (res.statusCode == 200 &&
            decoded is Map<String, dynamic> &&
            decoded['data'] is List &&
            (decoded['data'] as List).isNotEmpty) {
          _accessData = (decoded['data'] as List).first as Map<String, dynamic>;
          _accessError = null;
        } else {
          _accessData = null;
          _accessError = 'Failed (${res.statusCode})';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.statusCode == 200
            ? 'Access data refreshed'
            : 'Access check failed: ${res.statusCode}'),
        backgroundColor: res.statusCode == 200 ? Colors.green : Colors.red,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _accessError = 'My-access error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Access check failed: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _debugAuthTokenManager() async {
    try {
      final token = await AuthTokenManager.instance.getAuthToken();
      final userData = await AuthTokenManager.instance.getUserData();
      final businessData = await AuthTokenManager.instance.getBusinessData();
      print(
        '🔑 Token: ${token != null && token.isNotEmpty ? '${token.substring(0, 16)}...' : 'null'}',
      );
      print('👤 User keys: ${userData?.keys.toList()}');
      print('🏪 Business data: $businessData');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Debug info printed to console'),
          backgroundColor: Colors.purple,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Debug error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team API Sandbox'),
        actions: [
          IconButton(
            tooltip: 'Reload businesses from login',
            onPressed: () async {
              await _loadBusinessesFromLogin(); // preserves selection
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Request Setup',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email to Invite',
                        hintText: 'user@example.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ---------- Business dropdown ----------
                    Text(
                        '🐛 DEBUG: businesses=${_businesses.length}, selected=$_selectedBusinessId',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.red)),
                    const SizedBox(height: 8),

                    if (_businesses.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.business, size: 20),
                                const SizedBox(width: 8),
                                const Text('Select Business',
                                    style: TextStyle(fontSize: 16)),
                                const Spacer(),
                                if (_isLoadingBusinesses)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                else
                                  IconButton(
                                    tooltip: 'Reload from login',
                                    icon: const Icon(Icons.refresh, size: 20),
                                    onPressed: () async {
                                      await _loadBusinessesFromLogin();
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DropdownButton<String>(
                              value: _selectedBusinessId,
                              isExpanded: true,
                              underline: Container(),
                              hint: const Text('Choose a business'),
                              onChanged: (val) {
                                if (!mounted) return;
                                setState(() {
                                  _selectedBusinessId = val;
                                  _businessIdController.text = val ?? '';
                                });
                              },
                              items: _businesses.map((business) {
                                final id = business['_id'].toString();
                                final name = (business['businessName'] ??
                                        'Unnamed Business')
                                    .toString();
                                final type =
                                    (business['type'] ?? 'unknown').toString();
                                final isOwned = type == 'owned';
                                final grantedBy = business['grantedBy']?.toString();
                                
                                // Debug log for each business
                                print('🏢 Business: $name, Type: $type, IsOwned: $isOwned, GrantedBy: $grantedBy');
                                
                                return DropdownMenuItem(
                                  value: id,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(isOwned ? Icons.business : Icons.group,
                                            size: 16,
                                            color: isOwned
                                                ? Colors.green
                                                : Colors.blue),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(name,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text(
                                                    isOwned
                                                        ? 'Owned'
                                                        : 'Team Access',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: isOwned
                                                            ? Colors.green
                                                            : Colors.blue,
                                                        fontWeight:
                                                            FontWeight.w500)),
                                              ]),
                                        ),
                                        // Always show tag for team access businesses (for testing)
                                        if (!isOwned)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade200,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.orange.shade400,
                                                  width: 2),
                                            ),
                                            child: Text(
                                              grantedBy != null 
                                                ? 'ID: ${grantedBy.length > 8 ? grantedBy.substring(grantedBy.length - 8) : grantedBy}'
                                                : 'TEAM',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange.shade800,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      )
                    else
                      TextFormField(
                        controller: _businessIdController,
                        decoration: InputDecoration(
                          labelText: 'Business ID (no businesses found)',
                          hintText: 'Enter business id manually',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.business),
                          suffixIcon: _isLoadingBusinesses
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : IconButton(
                                  icon: const Icon(Icons.list),
                                  tooltip: 'Load from login',
                                  onPressed: () async =>
                                      _loadBusinessesFromLogin(),
                                ),
                          helperText: _isLoadingBusinesses
                              ? 'Loading businesses...'
                              : 'Use login data to auto-fill',
                          helperStyle: TextStyle(
                              color: _isLoadingBusinesses
                                  ? Colors.orange
                                  : Colors.grey),
                        ),
                      ),

                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      items: const ['staff', 'supervisor', 'manager', 'admin']
                          .map((r) => DropdownMenuItem(
                              value: r, child: Text(r.toUpperCase())))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedRole = v ?? _selectedRole),
                      decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedAccessLevel,
                      items: const [
                        'view_only',
                        'manage_operations',
                        'full_access'
                      ]
                          .map((lvl) => DropdownMenuItem(
                              value: lvl,
                              child:
                                  Text(lvl.replaceAll('_', ' ').toUpperCase())))
                          .toList(),
                      onChanged: (v) => setState(() =>
                          _selectedAccessLevel = v ?? _selectedAccessLevel),
                      decoration: const InputDecoration(
                          labelText: 'Access Level',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.security)),
                    ),
                  ]),
            ),
          ),
          const SizedBox(height: 16),

          // Buttons
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _testInvitation,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: const Text('Send Invitation'),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _testGetTeamMembers,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.group),
            label: const Text('Fetch My Team'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _testCheckAccess,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.verified_user),
            label: const Text('Refresh My Access'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _debugAuthTokenManager,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.bug_report),
            label: const Text('Debug Auth Storage'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 24),
          _buildApiInfoPanel(),
          const SizedBox(height: 24),
          _buildMyAccessSection(),
          const SizedBox(height: 24),
          _buildTeamDataSection(),
          const SizedBox(height: 24),
          _buildRequestSection(),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ---------- UI sections (unchanged structure, minor safety tweaks) ----------

  Widget _buildApiInfoPanel() {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.info, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            const Text('API Differences',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Row(children: [
                  Icon(Icons.verified_user,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                      child: Text(
                          'My Access\nShows permissions YOU have been granted by others',
                          style: TextStyle(fontSize: 12))),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(children: [
                  Icon(Icons.group, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                      child: Text(
                          'My Team\nShows people YOU have granted permissions to',
                          style: TextStyle(fontSize: 12))),
                ]),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildMyAccessSection() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.security, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('My Access (Auto-loaded)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            Icon(Icons.auto_awesome, color: Colors.orange.shade600, size: 20),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.yellow.shade300),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🐛 DEBUG INFO:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('_accessData is null: ${_accessData == null}'),
              Text('_accessError is null: ${_accessError == null}'),
              Text('_accessData type: ${_accessData.runtimeType}'),
              if (_accessData != null)
                Text('_accessData keys: ${_accessData!.keys.toList()}'),
              if (_accessError != null) Text('_accessError: $_accessError'),
            ]),
          ),
          const SizedBox(height: 12),
          if (_accessData != null)
            _buildAccessDetails(_accessData!)
          else if (_accessError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(children: [
                Icon(Icons.error, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_accessError!,
                        style: TextStyle(color: Colors.red.shade700))),
              ]),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.orange.shade700)),
                const SizedBox(width: 8),
                Text('Loading my access data...',
                    style: TextStyle(color: Colors.orange.shade700)),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _buildAccessDetails(Map<String, dynamic> accessData) {
    final permissions =
        (accessData['permissions'] as Map<String, dynamic>?) ?? {};
    final effectivePermissions =
        (accessData['effectivePermissions'] as Map<String, dynamic>?) ??
            permissions;
    final businessContext =
        (accessData['businessContext'] as Map<String, dynamic>?) ?? {};

    final userEmail = accessData['userEmail']?.toString() ?? 'N/A';
    final role = accessData['role']?.toString() ?? 'N/A';
    final accessLevel = accessData['accessLevel']?.toString() ?? 'N/A';
    final status = accessData['status']?.toString() ?? 'N/A';
    final businessId = businessContext['businessId']?.toString() ?? 'N/A';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.person, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Text('Access Information',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.green.shade700)),
          ]),
          const SizedBox(height: 8),
          Text('Email: $userEmail'),
          Text('Role: $role'),
          Text('Access Level: $accessLevel'),
          Text('Status: $status'),
          Text('Business ID: $businessId'),
          Text('Granted By: ${_formatUserInfo(accessData['grantedBy'])}'),
          Text('Created By: ${_formatUserInfo(accessData['createdBy'])}'),
        ]),
      ),
      const SizedBox(height: 12),
      if (businessContext.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(8)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.business, color: Colors.purple.shade700),
              const SizedBox(width: 8),
              Text('Business Context',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade700)),
            ]),
            const SizedBox(height: 8),
            Text('Business ID: ${businessContext['businessId'] ?? 'N/A'}'),
            Text(
                'All Businesses: ${businessContext['allBusinesses'] ?? false}'),
            Text(
                'Can Create New Business: ${businessContext['canCreateNewBusiness'] ?? false}'),
            Text(
                'Can Grant Access to Others: ${businessContext['canGrantAccessToOthers'] ?? false}'),
          ]),
        ),
        const SizedBox(height: 12),
      ],
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.lock, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Text('Permissions',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
          ]),
          const SizedBox(height: 8),
          if (effectivePermissions.isEmpty)
            const Text('No permissions data available')
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: effectivePermissions.entries.map((e) {
                final perm = e.key.toString();
                final enabled = e.value == true;
                return Chip(
                  label: Text(perm.replaceAll('can', ''),
                      style: TextStyle(
                          fontSize: 11,
                          color:
                              enabled ? Colors.white : Colors.grey.shade600)),
                  backgroundColor:
                      enabled ? Colors.blue.shade600 : Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
        ]),
      ),
    ]);
  }

  Widget _buildTeamDataSection() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.group, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Text('My Team (People I Manage)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (_isLoading)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
          ]),
          const SizedBox(height: 12),
          if (_teamData != null) ...[
            Row(children: [
              Chip(
                label: Text((_teamData!['status']?.toString() ?? 'unknown')
                    .toUpperCase()),
                backgroundColor:
                    (_teamData!['status']?.toString().toLowerCase() ==
                            'success')
                        ? Colors.green[100]
                        : Colors.orange[100],
              ),
              const SizedBox(width: 8),
              Text(
                  'Total Members: ${(_teamData!['count'] as num?)?.toInt() ?? _members.length}'),
            ]),
            const SizedBox(height: 12),
          ],
          if (_fetchError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300)),
              child: Row(children: [
                Icon(Icons.error, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_fetchError!,
                        style: TextStyle(color: Colors.red.shade700))),
              ]),
            ),
          if (_members.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _teamData == null
                    ? Colors.grey.shade100
                    : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _teamData == null
                        ? Colors.grey.shade300
                        : Colors.blue.shade300),
              ),
              child: Row(children: [
                Icon(_teamData == null ? Icons.info : Icons.people_outline,
                    color: _teamData == null
                        ? Colors.grey.shade600
                        : Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _teamData == null
                        ? 'Click "Fetch My Team" to see people you manage'
                        : 'No team members found. You haven\'t granted access to anyone yet.',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ]),
            )
          else
            ..._members.map(_buildMemberCard),
        ]),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    String formatName(Map<String, dynamic>? data) {
      if (data == null) return '';
      final full = data['fullName']?.toString().trim();
      if (full != null && full.isNotEmpty) return full;
      final first = data['firstName']?.toString().trim();
      final last = data['lastName']?.toString().trim();
      if ((first?.isNotEmpty ?? false) || (last?.isNotEmpty ?? false)) {
        return [first, last].where((e) => e?.isNotEmpty ?? false).join(' ');
      }
      final name = data['name']?.toString().trim();
      return (name != null && name.isNotEmpty) ? name : '';
    }

    final employee = (member['employee'] as Map?)?.cast<String, dynamic>();
    final managedUser =
        (member['managedUser'] as Map?)?.cast<String, dynamic>();

    final fullName = () {
      final n1 = formatName(employee);
      if (n1.isNotEmpty) return n1;
      final n2 = formatName(managedUser);
      if (n2.isNotEmpty) return n2;
      return 'Unnamed';
    }();

    final email = member['userEmail']?.toString() ??
        employee?['email']?.toString() ??
        managedUser?['email']?.toString() ??
        'N/A';

    final role = (member['role'] ?? '-').toString();
    final accessLevel = (member['accessLevel'] ?? '-').toString();
    final memberStatus = (member['status'] ?? '-').toString();
    final isActive = member['isAccessValid'] == true;
    final businessId =
        (member['businessContext']?['businessId'] ?? '—').toString();
    final grantedBy = member['grantedBy'] ?? '—';
    final createdBy = member['createdBy'] ?? '—';
    final permissions =
        (member['effectivePermissions'] as Map?)?.cast<String, dynamic>() ?? {};

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isActive ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ExpansionTile(
          title:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(fullName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(memberStatus.toUpperCase(),
                style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold)),
          ]),
          subtitle: Text('$email\nRole: $role | Access: $accessLevel'),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Business ID: $businessId'),
                    Text('Granted By: ${_formatUserInfo(grantedBy)}'),
                    Text('Created By: ${_formatUserInfo(createdBy)}'),
                    const SizedBox(height: 8),
                    const Text('Permissions:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (permissions.isEmpty)
                      const Text('No permissions granted.')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: permissions.entries.map((e) {
                          final label = e.key.toString().replaceAll('can', '');
                          final enabled = e.value == true;
                          return Chip(
                              label: Text(label),
                              backgroundColor: enabled
                                  ? Colors.blue[100]
                                  : Colors.grey[200]);
                        }).toList(),
                      ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestSection() {
    if (_requestUrl == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Request Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SelectableText('GET $_requestUrl',
              style: const TextStyle(fontFamily: 'monospace')),
          const SizedBox(height: 12),
          const Text('Headers:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          if (_requestHeaders != null && _requestHeaders!.isNotEmpty)
            ..._requestHeaders!.entries.map((e) => SelectableText(
                '${e.key}: ${e.value}',
                style: const TextStyle(fontFamily: 'monospace')))
          else
            const Text('No headers sent'),
        ]),
      ),
    );
  }

  // ---------- Utils ----------

  String _formatUserInfo(dynamic userInfo) {
    if (userInfo is Map<String, dynamic>) {
      final first = (userInfo['firstName'] ?? '').toString();
      final last = (userInfo['lastName'] ?? '').toString();
      final email = (userInfo['email'] ?? '').toString();
      final name = [first, last].where((p) => p.isNotEmpty).join(' ').trim();
      if (name.isNotEmpty && email.isNotEmpty) return '$name ($email)';
      if (name.isNotEmpty) return name;
      if (email.isNotEmpty) return email;
    }
    return userInfo?.toString() ?? 'Unknown';
  }

  // ---------- Actions ----------

  Future<void> _testInvitation() async {
    final token = _authTokenController.text.trim();
    final email = _emailController.text.trim();
    final businessId = _selectedBusinessId ?? _businessIdController.text.trim();

    if (token.isEmpty || email.isEmpty || businessId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Please fill in all required fields and select a business'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await DirectTeamTestService.testTeamInvitation(
        authToken: token,
        email: email,
        businessId: businessId,
        role: _selectedRole,
        accessLevel: _selectedAccessLevel,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invitation request sent. Check console for details.'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Test failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
