import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../app_shell/pages/main_navigation_page.dart';
import '../widgets/auth_scaffold.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Map<String, dynamic> response = await AuthService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      final bool isSuccess = response['success'] != false;
      final String? token = AuthService.extractAccessToken(response);

      if (!isSuccess || token == null || token.trim().isEmpty) {
        _showSnack(
          AuthService.messageOf(
            response,
            fallback: 'Login gagal. Periksa email dan password Anda.',
          ),
          isError: true,
        );

        setState(() {
          _isSubmitting = false;
        });

        return;
      }

      _showSnack(
        'Login berhasil.',
        isError: false,
      );

      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (context, animation, secondaryAnimation) {
            return MainNavigationPage(
              token: token,
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final Animation<double> fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            final Animation<Offset> slideAnimation = Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
        ),
      );
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Tidak dapat login: $error',
        isError: true,
      );

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _openRegisterPage() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const RegisterPage();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final Animation<double> fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          final Animation<Offset> slideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _showSnack(
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.danger : AppColors.textPrimary,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Masuk ke Akun',
      subtitle:
          'Akses donasi makanan terdekat, kelola pickup, dan bantu kurangi food waste.',
      icon: Icons.login_rounded,
      footer: _RegisterPrompt(
        onRegisterTap: _isSubmitting ? null : _openRegisterPage,
      ),
      bottom: const _SecurityNote(),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LoginInfoBanner(
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: AppSpacing.x2),
            TextFormField(
              controller: _emailController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.email,
              ],
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Masukkan email Anda',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final String email = value?.trim() ?? '';

                if (email.isEmpty) {
                  return 'Email tidak boleh kosong';
                }

                if (!email.contains('@') || !email.contains('.')) {
                  return 'Format email tidak valid';
                }

                return null;
              },
            ),
            const SizedBox(height: AppSpacing.x2),
            TextFormField(
              controller: _passwordController,
              enabled: !_isSubmitting,
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done,
              autofillHints: const [
                AutofillHints.password,
              ],
              onFieldSubmitted: (_) {
                if (!_isSubmitting) {
                  _submitLogin();
                }
              },
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Masukkan password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _isPasswordVisible
                      ? 'Sembunyikan password'
                      : 'Tampilkan password',
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) {
                final String password = value ?? '';

                if (password.isEmpty) {
                  return 'Password tidak boleh kosong';
                }

                if (password.length < 6) {
                  return 'Password minimal 6 karakter';
                }

                return null;
              },
            ),
            const SizedBox(height: AppSpacing.x1),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        _showSnack(
                          'Fitur lupa password akan dihubungkan dengan endpoint backend.',
                          isError: false,
                        );
                      },
                child: const Text('Lupa password?'),
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitLogin,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  _isSubmitting ? 'Memproses...' : 'Masuk',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginInfoBanner extends StatelessWidget {
  final bool isLoading;

  const _LoginInfoBanner({
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: isLoading ? AppColors.accentSoft : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isLoading
              ? AppColors.accent.withValues(alpha: 0.20)
              : AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              isLoading ? Icons.sync_rounded : Icons.verified_user_outlined,
              color: isLoading ? AppColors.accent : AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Text(
              isLoading
                  ? 'Menghubungkan akun dengan server.'
                  : 'Satu akun dapat menjadi donatur dan penerima makanan.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        isLoading ? AppColors.accentDark : AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterPrompt extends StatelessWidget {
  final VoidCallback? onRegisterTap;

  const _RegisterPrompt({
    required this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x2,
          vertical: AppSpacing.x1,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Belum punya akun?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: onRegisterTap,
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text('Daftar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Data akun digunakan untuk mengamankan proses donasi, klaim, dan bukti pengambilan makanan.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
    );
  }
}