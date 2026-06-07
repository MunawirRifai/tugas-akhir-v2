import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../widgets/auth_scaffold.dart';
import 'login_page.dart';

class VerifyPage extends StatefulWidget {
  final String email;

  const VerifyPage({
    super.key,
    required this.email,
  });

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _otpController = TextEditingController();

  bool _isSubmitting = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Map<String, dynamic> response = await AuthService.verifyEmail(
        email: widget.email,
        otp: _otpController.text,
      );

      if (!mounted) return;

      final bool isSuccess = response['success'] != false;

      if (!isSuccess) {
        _showSnack(
          AuthService.messageOf(
            response,
            fallback: 'Verifikasi gagal. Periksa kode OTP Anda.',
          ),
          isError: true,
        );

        setState(() {
          _isSubmitting = false;
        });

        return;
      }

      _showSnack(
        'Akun berhasil diverifikasi. Silakan masuk.',
        isError: false,
      );

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (context, animation, secondaryAnimation) {
            return const LoginPage();
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
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Tidak dapat memverifikasi akun: $error',
        isError: true,
      );

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _resendCode() async {
    if (_isResending || _isSubmitting) return;

    setState(() {
      _isResending = true;
    });

    try {
      final Map<String, dynamic> response =
          await AuthService.resendVerification(
        email: widget.email,
      );

      if (!mounted) return;

      final bool isSuccess = response['success'] != false;

      _showSnack(
        isSuccess
            ? 'Kode verifikasi baru telah dikirim.'
            : AuthService.messageOf(
                response,
                fallback: 'Gagal mengirim ulang kode verifikasi.',
              ),
        isError: !isSuccess,
      );
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal mengirim ulang kode: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _openLoginPage() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const LoginPage();
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
      (route) => false,
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
      title: 'Verifikasi Akun',
      subtitle:
          'Masukkan kode OTP yang dikirim ke email Anda untuk mengaktifkan akun.',
      icon: Icons.verified_user_rounded,
      showBackButton: true,
      onBackPressed: _openLoginPage,
      footer: _LoginPrompt(
        onLoginTap: _isSubmitting ? null : _openLoginPage,
      ),
      bottom: const _SecurityNote(),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EmailTargetCard(
              email: widget.email,
            ),
            const SizedBox(height: AppSpacing.x2),
            TextFormField(
              controller: _otpController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    letterSpacing: 6,
                    fontWeight: FontWeight.w800,
                  ),
              onFieldSubmitted: (_) {
                if (!_isSubmitting) {
                  _submitVerification();
                }
              },
              decoration: const InputDecoration(
                counterText: '',
                labelText: 'Kode OTP',
                hintText: '000000',
                prefixIcon: Icon(Icons.password_rounded),
              ),
              validator: (value) {
                final String otp = value?.trim() ?? '';

                if (otp.isEmpty) {
                  return 'Kode OTP tidak boleh kosong';
                }

                if (otp.length < 4) {
                  return 'Kode OTP terlalu pendek';
                }

                if (!RegExp(r'^[0-9]+$').hasMatch(otp)) {
                  return 'Kode OTP hanya boleh angka';
                }

                return null;
              },
            ),
            const SizedBox(height: AppSpacing.x2),
            const _VerificationHint(),
            const SizedBox(height: AppSpacing.x3),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitVerification,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  _isSubmitting ? 'Memverifikasi...' : 'Verifikasi Akun',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x1),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isResending || _isSubmitting ? null : _resendCode,
                icon: _isResending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(
                  _isResending ? 'Mengirim ulang...' : 'Kirim Ulang Kode',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailTargetCard extends StatelessWidget {
  final String email;

  const _EmailTargetCard({
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kode dikirim ke',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email.trim().isEmpty ? 'email terdaftar' : email.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationHint extends StatelessWidget {
  const _VerificationHint();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.x1),
            Expanded(
              child: Text(
                'Jika kode belum diterima, periksa folder spam atau gunakan tombol kirim ulang.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  final VoidCallback? onLoginTap;

  const _LoginPrompt({
    required this.onLoginTap,
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
                'Sudah verifikasi?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: onLoginTap,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Masuk'),
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
      'Verifikasi akun membantu mencegah penyalahgunaan fitur donasi dan klaim makanan.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
    );
  }
}