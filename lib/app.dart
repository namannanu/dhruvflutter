import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/providers/team_provider.dart';
import 'package:talent/core/services/locator/service_locator.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/core/theme/app_theme.dart';
import 'package:talent/core/widgets/message_notification_listener.dart';
import 'package:talent/features/auth/auth_gate.dart';

class WorkConnectApp extends StatelessWidget {
  const WorkConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    developer.log('🏗️ Building WorkConnectApp...', name: 'App');
    return FutureBuilder<ServiceLocator>(
      future: ServiceLocator.create(
        baseUrl: const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://dhruvbackend.vercel.app/api',
        ),
        enableLogging: true,
      ).then((locator) {
        developer.log('✅ ServiceLocator initialized successfully',
            name: 'ServiceLocator', error: null);
        return locator;
      }).catchError((error, stack) {
        developer.log('❌ ServiceLocator initialization failed',
            name: 'ServiceLocator',
            error: error,
            stackTrace: stack as StackTrace?);
        throw error as Object;
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Error initializing services: ${snapshot.error}'),
              ),
            ),
          );
        }

        final locator = snapshot.data!;

        return MultiProvider(
          providers: [
            Provider<ServiceLocator>.value(value: locator),
            ChangeNotifierProvider<AppState>(
              create: (_) => AppState(locator),
            ),
            ChangeNotifierProvider<TeamProvider>(
              create: (_) => TeamProvider(),
            ),
          ],
          child: MessageNotificationListener(
            child: MaterialApp(
              title: 'WorkConnect',
              theme: WorkConnectTheme.light,
              debugShowCheckedModeBanner: false,
              home: const AuthGate(),
            ),
          ),
        );
      },
    );
  }
}
