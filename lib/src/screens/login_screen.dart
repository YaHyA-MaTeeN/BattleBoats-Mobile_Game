import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );
  bool _isLoginMode = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a username and a password (min 4 chars).'),
        ),
      );
      return;
    }

    if (!_isLoginMode && !_emailPattern.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.')),
      );
      return;
    }

    final bool success = _isLoginMode
        ? await widget.controller.login(username, password)
        : await widget.controller.signUp(username, email, password);

    if (!success && mounted) {
      final String error = widget.controller.error ?? 'Authentication failed.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _openForgotPasswordPage() async {
    await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ForgotPasswordScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          RepaintBoundary(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/signup.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          RepaintBoundary(child: Container(color: const Color(0x59000000))),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Image.asset(
                              'assets/images/logo.png',
                              width: 116,
                              height: 116,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 10),
                            Card(
                              color: const Color(0x52FFFFFF),
                              margin: const EdgeInsets.all(20),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: Color(0x80FFFFFF),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      _isLoginMode
                                          ? 'Command deck access'
                                          : 'Create your captain profile',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    TextField(
                                      controller: _usernameController,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      cursorColor: Colors.black87,
                                      decoration: const InputDecoration(
                                        hintText: 'Username',
                                        hintStyle: TextStyle(
                                          color: Colors.black54,
                                        ),
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.never,
                                        filled: true,
                                        fillColor: Color(0xCCFFFFFF),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (!_isLoginMode) ...<Widget>[
                                      TextField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        cursorColor: Colors.black87,
                                        decoration: const InputDecoration(
                                          hintText: 'Email',
                                          hintStyle: TextStyle(
                                            color: Colors.black54,
                                          ),
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.never,
                                          filled: true,
                                          fillColor: Color(0xCCFFFFFF),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      cursorColor: Colors.black87,
                                      decoration: const InputDecoration(
                                        hintText: 'Password',
                                        hintStyle: TextStyle(
                                          color: Colors.black54,
                                        ),
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.never,
                                        filled: true,
                                        fillColor: Color(0xCCFFFFFF),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: widget.controller.isBusy
                                            ? null
                                            : _submit,
                                        icon: Icon(
                                          _isLoginMode
                                              ? Icons.login
                                              : Icons.person_add,
                                        ),
                                        label: Text(
                                          _isLoginMode
                                              ? 'Enter Deck'
                                              : 'Create Account',
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      onPressed: widget.controller.isBusy
                                          ? null
                                          : () {
                                              setState(() {
                                                _isLoginMode = !_isLoginMode;
                                              });
                                            },
                                      child: Text(
                                        _isLoginMode
                                            ? 'No account? Sign up'
                                            : 'Already have an account? Login',
                                      ),
                                    ),
                                    if (_isLoginMode)
                                      TextButton(
                                        onPressed: widget.controller.isBusy
                                            ? null
                                            : _openForgotPasswordPage,
                                        child: const Text('Forgot password?'),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
