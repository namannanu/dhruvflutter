import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/user.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/employer/screens/employer_shell.dart';
import 'package:talent/features/worker/screens/worker_shell.dart';

class RoleShell extends StatelessWidget {
  const RoleShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final role = appState.activeRole ?? appState.currentUser?.type;
        if (role == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final child = role == UserType.worker
            ? const WorkerShell()
            : const EmployerShell();

        return Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: child,
            ),
            if (appState.isBusy)
              Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }
}
