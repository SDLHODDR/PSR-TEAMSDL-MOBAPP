import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/employee_provider.dart';
import 'main_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final code = TextEditingController(text: '05262');
  final password = TextEditingController();
  bool obscure = true;
  bool submitting = false;
  @override
  void dispose() {
    code.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.spa_outlined,
                            size: 64, color: AppColors.navy),
                        const SizedBox(height: 20),
                        const Text('Welcome back',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy)),
                        const SizedBox(height: 8),
                        const Text('Sign in to PSR Field App',
                            textAlign: TextAlign.center),
                        Image.asset(
                          'assets/images/sdl_logo.gif',
                          width: 200,
                          height: 110,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 32),
                        const Text('Employee Code'),
                        const SizedBox(height: 8),
                        TextField(
                            controller: code,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline),
                                hintText: 'Enter employee code')),
                        const SizedBox(height: 18),
                        const Text('Password'),
                        const SizedBox(height: 8),
                        TextField(
                            controller: password,
                            obscureText: obscure,
                            decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline),
                                hintText: 'Enter password',
                                suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => obscure = !obscure),
                                    icon: Icon(obscure
                                        ? Icons.visibility
                                        : Icons.visibility_off)))),
                        const SizedBox(height: 24),
                        SizedBox(
                            height: 52,
                            child: FilledButton(
                                onPressed: submitting ? null : _signIn,
                                child: submitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Text('SIGN IN'))),
                        const SizedBox(height: 14),
                        const Text(
                            'Sign in using your SDL employee code and password.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 11, color: AppColors.muted))
                      ])))));

  Future<void> _signIn() async {
    final username = code.text.trim();
    final pass = password.text;
    if (username.isEmpty || pass.isEmpty) {
      _showError('Employee code and password are required.');
      return;
    }

    setState(() => submitting = true);
    try {
      final employee = await AuthService.instance.login(username, pass);
      if (!mounted) return;
      context.read<EmployeeProvider>().setEmployee(employee);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainShell(),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
