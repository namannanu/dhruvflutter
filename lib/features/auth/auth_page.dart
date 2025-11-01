// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/user.dart';
import 'package:talent/core/state/app_state.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('WorkConnect'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sign in'),
              Tab(text: 'Create account'),
            ],
          ),
        ),
        body: const TabBarView(children: [_SignInForm(), _SignUpForm()]),
      ),
    );
  }
}

class _SignInForm extends StatefulWidget {
  const _SignInForm();

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'd@gmail.com');
  final _passwordController = TextEditingController(text: 'password');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text(
              'Welcome back',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Sign in to manage your shifts, applications, and team dashboards.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: appState.isBusy
                  ? null
                  : () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        try {
                          final message = await context.read<AppState>().login(
                                email: _emailController.text,
                                password: _passwordController.text,
                              );

                          if (!mounted) return;

                          final isSuccess = message == 'Login successful';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              backgroundColor:
                                  isSuccess ? Colors.green : Colors.red,
                            ),
                          );
                        } on HandshakeException catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Secure connection failed. Check your internet connection or VPN and try again.',
                              ),
                            ),
                          );
                        } on SocketException catch (error) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Network error: ${error.message}'),
                            ),
                          );
                        } catch (error) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Login failed: $error')),
                          );
                        }
                      }
                    },
              icon: appState.isBusy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Continue'),
              ),
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Developer sandbox',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Use the prefilled credentials to explore the end-to-end experience with seeded demo data.',
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
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm();

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _phoneController = TextEditingController();

  UserType _selectedType = UserType.worker;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text(
              'Create your account',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Choose a role to unlock worker tools or employer dashboards.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            DropdownButtonFormField<UserType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'I am a'),
              items: const [
                DropdownMenuItem(value: UserType.worker, child: Text('Worker')),
                DropdownMenuItem(
                    value: UserType.employer, child: Text('Employer')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstnameController,
              decoration: const InputDecoration(labelText: 'First name'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Enter your first name'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastnameController,
              decoration: const InputDecoration(labelText: 'Last name'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Enter your last name'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter your email' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: appState.isBusy
                  ? null
                  : () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        try {
                          await context.read<AppState>().signup(
                                email: _emailController.text,
                                password: _passwordController.text,
                                firstname: _firstnameController.text,
                                lastname: _lastnameController.text,
                                type: _selectedType,
                                phone: _phoneController.text.isEmpty
                                    ? null
                                    : _phoneController.text,
                              );
                        } catch (error) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Signup failed: $error')),
                          );
                        }
                      }
                    },
              icon: appState.isBusy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Create account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
