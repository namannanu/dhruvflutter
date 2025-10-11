import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/user.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/auth/auth_page.dart';
import 'package:talent/features/employer/screens/employer_shell.dart';
import 'package:talent/features/worker/screens/worker_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.isBusy && !appState.hasValidSession) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!appState.hasValidSession) {
          return const AuthPage();
        }

        final user = appState.currentUser;
        if (user == null) {
          return const AuthPage();
        }

        if (user.type == UserType.worker) {
          return const WorkerShell();
        }
        return const EmployerShell();
      },
    );
  }
}
