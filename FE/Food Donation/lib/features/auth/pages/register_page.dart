import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../widgets/auth_scaffold.dart';
import 'login_page.dart';
import 'verify_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSubmitting = false;
  bool _acceptTerms = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    if (!_acceptTerms) {
      _showSnack(
        'Setujui ketentuan penggunaan aplikasi terlebih dahulu.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Map<String, dynamic> response = await AuthService.register(
        fullName: _fullNameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
      );

      debugPrint("REGISTER RESPONSE = $response");

      if (!mounted) return;

      final bool isSuccess = response['success'] != false;

      if (!isSuccess) {
        _showSnack(
          AuthService.messageOf(
            response,
            fallback: 'Registrasi gagal. Periksa data Anda lalu coba lagi.',
          ),
          isError: true,
        );

        setState(() {
          _isSubmitting = false;
        });

        return;
      }

      _showSnack('Registrasi berhasil. Silakan login.', isError: false);

      // _showSnack(
      //   'Registrasi berhasil. Silakan verifikasi akun Anda.',
      //   isError: false,
      // );

      Navigator.of(context).pushReplacement(
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

            final Animation<Offset> slideAnimation =
                Tween<Offset>(
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
              child: SlideTransition(position: slideAnimation, child: child),
            );
          },
        ),
      );
    } catch (error) {
      if (!mounted) return;

      _showSnack('Tidak dapat mendaftar: $error', isError: true);

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _openLoginPage() {
    Navigator.of(context).pushReplacement(
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

          final Animation<Offset> slideAnimation =
              Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
      ),
    );
  }

  void _showSnack(String message, {required bool isError}) {
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
      title: 'Buat Akun Baru',
      subtitle:
          'Satu akun dapat digunakan untuk membagikan makanan dan mengambil donasi terdekat.',
      icon: Icons.person_add_alt_rounded,
      showBackButton: true,
      footer: _LoginPrompt(onLoginTap: _isSubmitting ? null : _openLoginPage),
      bottom: const _PrivacyNote(),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _RegisterInfoBanner(),
            const SizedBox(height: AppSpacing.x2),
            TextFormField(
              controller: _fullNameController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Nama lengkap',
                hintText: 'Masukkan nama lengkap',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) {
                final String fullName = value?.trim() ?? '';

                if (fullName.isEmpty) {
                  return 'Nama lengkap tidak boleh kosong';
                }

                if (fullName.length < 3) {
                  return 'Nama minimal 3 karakter';
                }

                return null;
              },
            ),
            const SizedBox(height: AppSpacing.x2),
            TextFormField(
              controller: _emailController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Contoh: nama@email.com',
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
              controller: _phoneController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(
                labelText: 'Nomor HP',
                hintText: 'Contoh: 081234567890',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                final String phone = value?.trim() ?? '';

                if (phone.isEmpty) {
                  return 'Nomor HP tidak boleh kosong';
                }

                if (phone.length < 10) {
                  return 'Nomor HP terlalu pendek';
                }

                if (!RegExp(r'^[0-9+]+$').hasMatch(phone)) {
                  return 'Nomor HP hanya boleh angka atau tanda +';
                }

                return null;
              },
            ),
            const SizedBox(height: AppSpacing.x2),
            TextFormField(
              controller: _passwordController,
              enabled: !_isSubmitting,
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Minimal 6 karakter',
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
            const SizedBox(height: AppSpacing.x2),
            TextFormField(
              controller: _confirmPasswordController,
              enabled: !_isSubmitting,
              obscureText: !_isConfirmPasswordVisible,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) {
                if (!_isSubmitting) {
                  _submitRegister();
                }
              },
              decoration: InputDecoration(
                labelText: 'Konfirmasi password',
                hintText: 'Ulangi password',
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                suffixIcon: IconButton(
                  tooltip: _isConfirmPasswordVisible
                      ? 'Sembunyikan password'
                      : 'Tampilkan password',
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) {
                final String confirmPassword = value ?? '';

                if (confirmPassword.isEmpty) {
                  return 'Konfirmasi password tidak boleh kosong';
                }

                if (confirmPassword != _passwordController.text) {
                  return 'Konfirmasi password tidak sama';
                }

                return null;
              },
            ),
            const SizedBox(height: AppSpacing.x2),
            _TermsAgreementTile(
              value: _acceptTerms,
              enabled: !_isSubmitting,
              onChanged: (value) {
                setState(() {
                  _acceptTerms = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.x3),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitRegister,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : const Icon(Icons.person_add_alt_rounded),
                label: Text(_isSubmitting ? 'Mendaftarkan...' : 'Daftar Akun'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterInfoBanner extends StatelessWidget {
  const _RegisterInfoBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
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
                Icons.group_rounded,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Text(
                'Akun tunggal: Anda bisa menjadi donatur sekaligus penerima makanan.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsAgreementTile extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _TermsAgreementTile({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: value
                  ? AppColors.primary.withValues(alpha: 0.30)
                  : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: value,
                activeColor: AppColors.primary,
                onChanged: enabled
                    ? (checked) {
                        onChanged(checked ?? false);
                      }
                    : null,
              ),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Saya menyetujui penggunaan data untuk proses autentikasi, donasi, klaim, dan bukti pengambilan makanan.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  final VoidCallback? onLoginTap;

  const _LoginPrompt({required this.onLoginTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
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
                'Sudah punya akun?',
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

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Data Anda digunakan untuk menjaga keamanan transaksi donasi dan pengambilan makanan.',
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
    );
  }
}
