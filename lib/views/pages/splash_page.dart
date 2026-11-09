import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/auth_service.dart';
import '../../providers/employee_provider.dart';
import 'login_page.dart';
import 'main_shell.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _restoreAndNavigate();
  }

  Future<void> _restoreAndNavigate() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    final employee = await AuthService.instance.restoreSession();
    if (!mounted) return;

    if (employee != null) {
      context.read<EmployeeProvider>().setEmployee(employee);
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            employee != null ? const MainShell() : const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003250),
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/splash_screen.jpg',
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text(
                'SDL PSR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
