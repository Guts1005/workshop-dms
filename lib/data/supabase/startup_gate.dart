import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routing/app_router.dart';
import '../../ui_kit/tokens/app_tokens.dart';

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  Future<Map<String, dynamic>?>? _membershipFuture;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      _,
    ) {
      if (Supabase.instance.client.auth.currentSession != null) {
        _loadMembership();
      } else {
        _membershipFuture = null;
      }
      if (mounted) setState(() {});
    });
    if (Supabase.instance.client.auth.currentSession != null) {
      _loadMembership();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _loadMembership() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _membershipFuture = null;
      if (mounted) setState(() {});
      return;
    }
    _membershipFuture = Supabase.instance.client
        .from('workshop_memberships')
        .select('workshop_id, role')
        .eq('user_id', userId)
        .maybeSingle();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      return _SignInScreen(onSignedIn: _loadMembership);
    }

    final membershipFuture = _membershipFuture;
    if (membershipFuture == null) {
      return const _LoadingScreen();
    }
    return FutureBuilder<Map<String, dynamic>?>(
      future: membershipFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingScreen();
        }
        if (snapshot.hasError) {
          return _StartupErrorScreen(
            message: 'Could not load your workshop. Check your connection and try again.',
            onRetry: _loadMembership,
            onSignOut: () => client.auth.signOut(),
          );
        }
        if (snapshot.data == null) {
          return _CreateWorkshopScreen(onCreated: _loadMembership);
        }
        return MaterialApp.router(
          title: 'Workshop DMS',
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
          theme: _theme,
        );
      },
    );
  }
}

final ThemeData _theme = ThemeData(
  textTheme: GoogleFonts.interTextTheme(),
  scaffoldBackgroundColor: AppTokens.base,
  colorScheme: const ColorScheme.light(
    primary: AppTokens.inverse,
    surface: AppTokens.raised,
    error: AppTokens.brandRed,
  ),
  cardTheme: const CardThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    elevation: 0,
  ),
);

class _SignInScreen extends StatefulWidget {
  const _SignInScreen({required this.onSignedIn});

  final VoidCallback onSignedIn;

  @override
  State<_SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<_SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isCreatingAccount = false;
  bool _busy = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (_isCreatingAccount) {
        final response = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
        );
        if (response.session == null) {
          setState(
            () => _message =
                'Check your email to confirm your account, then sign in.',
          );
        } else {
          widget.onSignedIn();
        }
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        widget.onSignedIn();
      }
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(
        () => _error =
            'Could not reach the service. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    title: _isCreatingAccount
        ? 'Create your account'
        : 'Sign in to your workshop',
    subtitle: 'Your customer and vehicle records stay inside your workshop.',
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || !value.contains('@')
                ? 'Enter a valid email address'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            obscureText: true,
            autofillHints: [
              _isCreatingAccount
                  ? AutofillHints.newPassword
                  : AutofillHints.password,
            ],
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.length < 8
                ? 'Use at least 8 characters'
                : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTokens.brandRed)),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: const TextStyle(color: AppTokens.green)),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isCreatingAccount ? 'Create account' : 'Sign in'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _isCreatingAccount = !_isCreatingAccount;
                    _error = null;
                    _message = null;
                  }),
            child: Text(
              _isCreatingAccount
                  ? 'I already have an account'
                  : 'Create a workshop account',
            ),
          ),
        ],
      ),
    ),
  );
}

class _CreateWorkshopScreen extends StatefulWidget {
  const _CreateWorkshopScreen({required this.onCreated});

  final VoidCallback onCreated;

  @override
  State<_CreateWorkshopScreen> createState() => _CreateWorkshopScreenState();
}

class _CreateWorkshopScreenState extends State<_CreateWorkshopScreen> {
  final _name = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Enter your workshop name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.rpc(
        'create_workshop',
        params: {'workshop_name': _name.text.trim()},
      );
      widget.onCreated();
    } on PostgrestException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(
        () => _error = 'Could not create the workshop. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    title: 'Set up your workshop',
    subtitle: 'Create the private workspace that will hold your applications and vehicle records.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Workshop name',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppTokens.brandRed)),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _busy ? null : _create,
          child: Text(_busy ? 'Creating…' : 'Create workshop'),
        ),
        TextButton(
          onPressed: () => Supabase.instance.client.auth.signOut(),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
}

class BackendConfigurationScreen extends StatelessWidget {
  const BackendConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AuthScaffold(
    title: 'Connect your database',
    subtitle: 'Add your Supabase project URL and publishable key to the local build configuration to continue.',
    child: SelectableText(
      'Run Flutter with --dart-define-from-file=env.json. See env.example.json and the setup guide.',
    ),
  );
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    title: 'Workshop connection unavailable',
    subtitle: message,
    child: Column(
      children: [
        FilledButton(onPressed: onRetry, child: const Text('Try again')),
        TextButton(onPressed: onSignOut, child: const Text('Sign out')),
      ],
    ),
  );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTokens.base,
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTokens.raised,
              borderRadius: AppTokens.cardRadius,
              border: Border.all(color: AppTokens.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.directions_car_filled_outlined,
                  color: AppTokens.brandRed,
                  size: 36,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    height: 1.45,
                    color: AppTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
