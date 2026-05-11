import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/l10n_extension.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      if (_isLogin) {
        await auth.signInWithEmailAndPassword(
          _emailController.text.trim(), _passwordController.text);
      } else {
        await auth.createUserWithEmailAndPassword(
          _emailController.text.trim(), _passwordController.text);
      }
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppColors.darkGradient)),
          Positioned(top: -100, right: -80, child: _GoldBlob(size: 300)),
          Positioned(bottom: -80, left: -60, child: _GoldBlob(size: 200)),
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: const BoxDecoration(
                          gradient: AppColors.goldGradient, shape: BoxShape.circle),
                        child: const Icon(Icons.celebration_rounded,
                            color: AppColors.charcoal, size: 36),
                      ),
                      const SizedBox(height: 20),
                      Text('Planea',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: AppColors.brushedGold,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          )),
                      Text(l.loginSubtitle,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.white54)),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                              color: AppColors.brushedGold.withValues(alpha: 0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brushedGold.withValues(alpha: 0.08),
                              blurRadius: 40,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isLogin ? l.loginSignIn : l.loginCreateAccount,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: l.loginEmail,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                                validator: (v) =>
                                    v != null && v.contains('@') ? null : l.loginInvalidEmail,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: l.loginPassword,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) =>
                                    v != null && v.length >= 6 ? null : l.loginMinPassword,
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(_error!,
                                      style: TextStyle(
                                          color: Colors.red[300], fontSize: 13)),
                                ),
                              ],
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 52,
                                child: _loading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                            color: AppColors.brushedGold))
                                    : ElevatedButton(
                                        onPressed: _submit,
                                        child: Text(_isLogin
                                            ? l.loginSignIn
                                            : l.loginCreateAccount),
                                      ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _isLogin = !_isLogin),
                                child: Text(
                                  _isLogin ? l.loginNoAccount : l.loginHasAccount,
                                  style: const TextStyle(
                                      color: AppColors.brushedGold,
                                      fontWeight: FontWeight.w500),
                                ),
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
          ),
        ],
      ),
    );
  }
}

class _GoldBlob extends StatelessWidget {
  final double size;
  const _GoldBlob({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          AppColors.brushedGold.withValues(alpha: 0.12),
          AppColors.brushedGold.withValues(alpha: 0),
        ]),
      ),
    );
  }
}
