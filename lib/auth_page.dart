import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPage extends StatefulWidget {
  final VoidCallback onContinue;

  const AuthPage({super.key, required this.onContinue});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isRegistering = false;
  bool loading = false;
  bool hidePassword = true;

  String message = '';
  bool isError = true;

  static const navy = Color(0xFF0A1330);
  static const mint = Color(0xFF59F0B5);

  void showNotice(String text, {bool error = true}) {
    if (!mounted) return;

    setState(() {
      message = text;
      isError = error;
    });
  }

  Future<void> authenticate() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showNotice('Enter your email and password.');
      return;
    }

    if (isRegistering && password.length < 6) {
      showNotice('Password must contain at least 6 characters.');
      return;
    }

    setState(() {
      loading = true;
      message = '';
    });

    try {
      final auth = FirebaseAuth.instance;

      if (isRegistering) {
        final user = auth.currentUser;

        if (user != null && user.isAnonymous) {
          await user.linkWithCredential(
            EmailAuthProvider.credential(email: email, password: password),
          );
        } else {
          await auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        }
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: password);
      }

      final user = auth.currentUser;

      if (user == null || user.isAnonymous) {
        showNotice('Authentication is required.');
        return;
      }

      if (!mounted) return;

      widget.onContinue();
    } on FirebaseAuthException catch (e) {
      showNotice(e.message ?? 'Authentication failed.');
    } catch (_) {
      showNotice('Unable to connect. Try again.');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showNotice('Enter your email address first.');
      return;
    }

    setState(() {
      loading = true;
      message = '';
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      showNotice(
        'If an account exists, check your email for reset instructions.',
        error: false,
      );
    } on FirebaseAuthException catch (e) {
      showNotice(e.message ?? 'Unable to reset password.');
    } catch (_) {
      showNotice('Unable to connect. Try again.');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: mint,
                    size: 76,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'TrustPay 360',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'One Payment. Two-Sided Protection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRegistering ? 'Create Account' : 'Welcome back',
                          style: const TextStyle(
                            color: navy,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          isRegistering
                              ? 'Start your financial journey.'
                              : 'Sign in to your account.',
                        ),

                        const SizedBox(height: 24),

                        TextField(
                          controller: emailController,
                          enabled: !loading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            prefixIcon: Icon(Icons.email_outlined),
                            fillColor: Color(0xFFF7F8FC),
                            filled: true,
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: passwordController,
                          enabled: !loading,
                          obscureText: hidePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            fillColor: const Color(0xFFF7F8FC),
                            filled: true,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  hidePassword = !hidePassword;
                                });
                              },
                              icon: Icon(
                                hidePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                        ),

                        if (!isRegistering)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: loading ? null : resetPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),

                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            message,
                            style: TextStyle(
                              color: isError ? Colors.red : Colors.green,
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: mint,
                              foregroundColor: navy,
                              minimumSize: const Size(0, 56),
                            ),
                            onPressed: loading ? null : authenticate,
                            child: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isRegistering
                                        ? 'Create Account'
                                        : 'Sign In',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Center(
                          child: TextButton(
                            onPressed: loading
                                ? null
                                : () {
                                    setState(() {
                                      isRegistering = !isRegistering;
                                      message = '';
                                    });
                                  },
                            child: Text(
                              isRegistering
                                  ? 'Already registered? Sign in'
                                  : 'New user? Create an account',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Authentication required. Simulated payments only.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
