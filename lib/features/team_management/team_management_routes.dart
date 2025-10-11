import 'package:flutter/material.dart';
import 'screens/team_management_page.dart';

class TeamManagementRoutes {
  static const String teamManagement = '/team-management';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case teamManagement:
        return MaterialPageRoute(
          builder: (_) => const TeamManagementPage(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Route not found'),
            ),
          ),
        );
    }
  }
}

// Helper function to navigate to team management
void navigateToTeamManagement(BuildContext context) {
  Navigator.pushNamed(context, TeamManagementRoutes.teamManagement);
}
