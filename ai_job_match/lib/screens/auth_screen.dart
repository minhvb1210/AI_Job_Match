import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class AuthScreen extends StatefulWidget {
  final bool isLogin;
  const AuthScreen({super.key, this.isLogin = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'candidate';
  bool _isLoading = false;
  bool _showPassword = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Required Fields'),
          description: Text('Please enter your email and password to continue.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    bool success = false;
    
    try {
      if (widget.isLogin) {
        success = await auth.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        success = await auth.register(
          _emailController.text.trim(),
          _passwordController.text,
          _role,
        );
      }
    } catch (e) {
      success = false;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      context.go(auth.role == 'recruiter' || auth.role == 'employer' ? '/recruiter' : '/candidate');
    } else {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Authentication Failed'),
          description: Text(widget.isLogin 
            ? 'Invalid email or password. Please try again.' 
            : 'Email might already be registered.'),
        ),
      );
    }
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    
    final success = await auth.signInWithGoogle(_role);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      context.go(auth.role == 'recruiter' || auth.role == 'employer' ? '/recruiter' : '/candidate');
    } else {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Google Sign-In Failed'),
          description: Text('Could not complete Google Sign-In. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (!isMobile)
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.premiumGradient,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.sparkles, size: 80, color: Colors.white),
                          const SizedBox(height: 32),
                          const Text(
                            'AI Job Match Platform',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Connecting top talent with elite companies through AI.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 40,
                    child: Row(
                      children: [
                        const Icon(LucideIcons.briefcase, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Antigravity AI',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isMobile) ...[
                            const Center(
                              child: Icon(LucideIcons.briefcase, color: AppColors.primary, size: 48),
                            ),
                            const SizedBox(height: 32),
                          ],
                          Text(
                            widget.isLogin ? 'Welcome back' : 'Create an account',
                            style: theme.textTheme.h2.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isLogin 
                              ? 'Enter your credentials to access your account' 
                              : 'Sign up to start your AI-powered career journey',
                            style: theme.textTheme.muted.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 40),
                          
                          const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 8),
                          ShadInput(
                            controller: _emailController,
                            placeholder: const Text('name@example.com'),
                            leading: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(LucideIcons.mail, size: 16, color: AppColors.textPlaceholder),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              if (widget.isLogin)
                                ShadButton.link(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {},
                                  child: const Text('Forgot password?', style: TextStyle(fontSize: 13)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ShadInput(
                            controller: _passwordController,
                            placeholder: const Text('Enter your password'),
                            obscureText: !_showPassword,
                            leading: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(LucideIcons.lock, size: 16, color: AppColors.textPlaceholder),
                            ),
                            trailing: IconButton(
                              icon: Icon(_showPassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 16, color: AppColors.textSecondary),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                          ),

                          if (!widget.isLogin) ...[
                            const SizedBox(height: 24),
                            const Text('I am signing up as a', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _RoleCard(
                                    title: 'Candidate',
                                    icon: LucideIcons.user,
                                    isSelected: _role == 'candidate',
                                    onTap: () => setState(() => _role = 'candidate'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _RoleCard(
                                    title: 'Employer',
                                    icon: LucideIcons.building,
                                    isSelected: _role == 'recruiter',
                                    onTap: () => setState(() => _role = 'recruiter'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 40),
                          ShadButton(
                            width: double.infinity,
                            size: ShadButtonSize.lg,
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(widget.isLogin ? 'Sign In' : 'Sign Up'),
                          ),
                          
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR CONTINUE WITH', style: theme.textTheme.small.copyWith(color: AppColors.textPlaceholder, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 32),
                          ShadButton.outline(
                            width: double.infinity,
                            leading: _isLoading 
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                              : const Icon(LucideIcons.globe, size: 18),
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            child: Text(_isLoading ? 'Connecting Google...' : 'Continue with Google'),
                          ),
                          
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.isLogin ? "Don't have an account? " : "Already have an account? ",
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                              ShadButton.link(
                                padding: EdgeInsets.zero,
                                onPressed: () => context.go(widget.isLogin ? '/register' : '/login'),
                                child: Text(widget.isLogin ? 'Sign up' : 'Sign in'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
