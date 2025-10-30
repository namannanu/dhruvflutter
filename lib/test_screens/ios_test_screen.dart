import 'package:flutter/material.dart';
import 'package:talent/core/services/location_service.dart';
import 'package:talent/core/services/push_notification_service.dart';
import 'package:talent/core/widgets/ios_location_permission_dialog.dart';
import 'package:talent/core/services/ios_notification_permissions.dart';

class IOSTestScreen extends StatefulWidget {
  const IOSTestScreen({Key? key}) : super(key: key);

  @override
  State<IOSTestScreen> createState() => _IOSTestScreenState();
}

class _IOSTestScreenState extends State<IOSTestScreen> {
  String _locationStatus = 'Not checked';
  String _notificationStatus = 'Not checked';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('iOS Permissions Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'iOS Permissions Testing',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Location Permission Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Location Permission',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Status: $_locationStatus',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading ? null : _testLocationPermission,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Test Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _showLocationDialog,
                            icon: const Icon(Icons.info),
                            label: const Text('Show Dialog'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notification Permission Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Notification Permission',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Status: $_notificationStatus',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading ? null : _testNotificationPermission,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Test Notifications'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading ? null : _sendTestNotification,
                            icon: const Icon(Icons.send),
                            label: const Text('Send Test'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Test All Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testAllPermissions,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isLoading ? 'Testing...' : 'Test All Permissions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.info, color: Colors.white, size: 24),
                    SizedBox(height: 8),
                    Text(
                      'iOS Testing Tips',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Test on a physical iOS device\n'
                      '• Check Settings > Privacy & Security\n'
                      '• Location and Notifications should work\n'
                      '• Pop-ups should appear for permissions',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testLocationPermission() async {
    setState(() {
      _isLoading = true;
      _locationStatus = 'Testing...';
    });

    try {
      final hasPermission =
          await IOSLocationPermissionDialog.ensureLocationPermission(context);
      if (hasPermission) {
        final location =
            await LocationService.instance.getCurrentLocation(context: context);
        setState(() {
          _locationStatus = location != null
              ? 'Permission granted - Location obtained'
              : 'Permission granted - No location';
        });
      } else {
        setState(() {
          _locationStatus = 'Permission denied';
        });
      }
    } catch (e) {
      setState(() {
        _locationStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showLocationDialog() async {
    await IOSLocationPermissionDialog.showLocationPermissionDialog(context);
  }

  Future<void> _testNotificationPermission() async {
    setState(() {
      _isLoading = true;
      _notificationStatus = 'Testing...';
    });

    try {
      final granted =
          await IOSNotificationPermissions.requestNotificationPermissions();
      setState(() {
        _notificationStatus =
            granted ? 'Permission granted' : 'Permission denied';
      });
    } catch (e) {
      setState(() {
        _notificationStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await PushNotificationService.instance.showTestNotification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testAllPermissions() async {
    setState(() {
      _isLoading = true;
    });

    // Test location first
    await _testLocationPermission();

    // Wait a bit
    await Future.delayed(const Duration(seconds: 1));

    // Test notifications
    await _testNotificationPermission();

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All permission tests completed!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
