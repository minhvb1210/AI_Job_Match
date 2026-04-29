import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final bool isLogin;
  const AuthScreen({super.key, this.isLogin = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'candidate';
  bool _isLoading = false;

  void _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
       ShadToaster.of(context).show(
         const ShadToast.destructive(
           title: Text('Error'),
           description: Text('Please fill in all fields'),
         ),
       );
       return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    bool success = false;
    if (widget.isLogin) {
      success = await auth.login(
        _emailController.text.trim(), 
        _passwordController.text,
      );
    } else {
      final role = _role;
      final normalizedRole = role.toLowerCase().trim();
      
      if (normalizedRole != 'candidate' && normalizedRole != 'recruiter') {
        setState(() => _isLoading = false);
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Invalid Role'),
            description: Text('Please select either Candidate or Employer.'),
          ),
        );
        return;
      }
      success = await auth.register(
        _emailController.text.trim(), 
        _passwordController.text, 
        normalizedRole,
      );
    }

    setState(() => _isLoading = false);

    if (success) {
      if (auth.role == 'recruiter') {
        context.go('/recruiter');
      } else {
        context.go('/candidate');
      }
    } else {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
             title: const Text('Authentication Error'),
             description: Text(widget.isLogin ? 'Login failed. Please check your credentials.' : 'Registration failed.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Ornaments
          Positioned(top: -100, left: -100, child: _buildBlob(const Color(0xFF6C63FF))),
          Positioned(bottom: -100, right: -100, child: _buildBlob(const Color(0xFF00FFC2))),
          
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: ShadCard(
                padding: const EdgeInsets.all(40.0),
                backgroundColor: Colors.white.withOpacity(0.05),
                border: ShadBorder.all(color: Colors.white.withOpacity(0.1)),
                radius: const BorderRadius.all(Radius.circular(30)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(30)),
                    color: Colors.black.withOpacity(0.2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 60, color: theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        widget.isLogin ? 'Welcome Back' : 'Get Started',
                        style: theme.textTheme.h2.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI-Powered Job Matching',
                        style: theme.textTheme.muted.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 40),
                      
                      ShadInput(
                        controller: _emailController,
                        placeholder: const Text('Email Address'),
                        leading: const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.email_outlined, size: 18),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      
                      ShadInput(
                        controller: _passwordController,
                        placeholder: const Text('Password'),
                        leading: const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.lock_outline, size: 18),
                        ),
                        obscureText: true,
                      ),
                      
                      if (!widget.isLogin) ...[
                        const SizedBox(height: 20),
                        ShadSelect<String>(
                          placeholder: const Text('Select your role'),
                          initialValue: _role,
                          options: const [
                            ShadOption(value: 'candidate', child: Text('I am a Candidate')),
                            ShadOption(value: 'recruiter', child: Text('I am an Employer')),
                          ],
                          onChanged: (v) => setState(() => _role = v!),
                          selectedOptionBuilder: (context, value) => Text(value == 'candidate' ? 'I am a Candidate' : 'I am an Employer'),
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      ShadButton(
                        width: double.infinity,
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.isLogin ? 'Sign In' : 'Create Account'),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.isLogin ? "New here? " : "Already have an account? ",
                            style: theme.textTheme.muted.copyWith(color: Colors.white60),
                          ),
                          ShadButton.link(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              if (widget.isLogin) {
                                context.go('/register');
                              } else {
                                context.go('/login');
                              }
                            },
                            child: Text(widget.isLogin ? "Sign Up" : "Sign In"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
