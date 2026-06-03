import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/food_mapper.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/common/app_bottom_sheet_handle.dart';
import '../../../shared/widgets/common/app_info_panel.dart';
import '../../../shared/widgets/common/app_metric_tile.dart';
import '../../../shared/widgets/common/app_surface_card.dart';
import '../../../shared/widgets/common/shimmer_box.dart';
import '../../../shared/widgets/media/app_network_image.dart';
import '../../auth/pages/login_page.dart';

class ProfilePage extends StatefulWidget {
  final String token;

  const ProfilePage({
    super.key,
    required this.token,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isUploadingPhoto = false;
  bool _isLoggingOut = false;

  _ProfileData _profile = const _ProfileData.empty();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile({
    bool showRefreshState = false,
  }) async {
    if (showRefreshState && mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final Map<String, dynamic> response =
          await AuthService.getProfile(widget.token);

      if (!mounted) return;

      if (response['success'] == false) {
        throw Exception(
          AuthService.messageOf(
            response,
            fallback: 'Gagal memuat profil.',
          ),
        );
      }

      setState(() {
        _profile = _ProfileData.fromResponse(response);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnack(
        'Gagal memuat profil: $error',
        isError: true,
      );
    } finally {
      if (mounted && showRefreshState) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshProfile() {
    return _loadProfile(
      showRefreshState: true,
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_isUploadingPhoto || _isLoggingOut) return;

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ImageSourceSheet(
          onGalleryTap: () => Navigator.of(context).pop(ImageSource.gallery),
          onCameraTap: () => Navigator.of(context).pop(ImageSource.camera),
        );
      },
    );

    if (source == null || !mounted) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final XFile? image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 76,
      );

      if (!mounted) return;

      if (image == null) {
        setState(() {
          _isUploadingPhoto = false;
        });
        return;
      }

      final Map<String, dynamic> response =
          await AuthService.uploadProfilePhoto(
        token: widget.token,
        image: image,
      );

      if (!mounted) return;

      if (response['success'] == false) {
        _showSnack(
          AuthService.messageOf(
            response,
            fallback: 'Gagal mengunggah foto profil.',
          ),
          isError: true,
        );

        setState(() {
          _isUploadingPhoto = false;
        });

        return;
      }

      _showSnack(
        'Foto profil berhasil diperbarui.',
        isError: false,
      );

      await _loadProfile();
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal memperbarui foto profil: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _openEditProfileSheet() async {
    if (_isLoggingOut) return;

    final _ProfileEditResult? result =
        await showModalBottomSheet<_ProfileEditResult>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _EditProfileSheet(
          profile: _profile,
        );
      },
    );

    if (result == null || !mounted) return;

    await _updateProfile(result);
  }

  Future<void> _updateProfile(_ProfileEditResult result) async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final Map<String, dynamic> response = await AuthService.updateProfile(
        token: widget.token,
        fullName: result.fullName,
        email: result.email,
        phone: result.phone,
      );

      if (!mounted) return;

      if (response['success'] == false) {
        _showSnack(
          AuthService.messageOf(
            response,
            fallback: 'Gagal memperbarui profil.',
          ),
          isError: true,
        );

        setState(() {
          _isRefreshing = false;
        });

        return;
      }

      _showSnack(
        'Profil berhasil diperbarui.',
        isError: false,
      );

      await _loadProfile();
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal memperbarui profil: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Keluar dari Akun?'),
          content: const Text(
            'Anda perlu login kembali untuk mengakses fitur donasi, klaim, dan riwayat pengambilan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await AuthService.logout(
        token: widget.token,
      );
    } catch (_) {
      // Logout tetap dilanjutkan di sisi FE walaupun endpoint logout gagal.
    }

    if (!mounted) return;

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

  void _showAboutSheet() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _AboutAppSheet();
      },
    );
  }

  void _showSecuritySheet() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _SecuritySheet();
      },
    );
  }

  void _showSnack(
    String message, {
    required bool isError,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.danger : AppColors.textPrimary,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _ProfileSkeletonPage();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  AppSpacing.x3,
                  AppSpacing.x3,
                  AppSpacing.x2,
                ),
                sliver: SliverToBoxAdapter(
                  child: _ProfileHeader(
                    profile: _profile,
                    isRefreshing: _isRefreshing,
                    isUploadingPhoto: _isUploadingPhoto,
                    onRefresh: _refreshProfile,
                    onChangePhoto: _pickAndUploadPhoto,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  0,
                  AppSpacing.x3,
                  AppSpacing.x2,
                ),
                sliver: SliverToBoxAdapter(
                  child: _RoleCard(
                    profile: _profile,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  0,
                  AppSpacing.x3,
                  AppSpacing.x2,
                ),
                sliver: SliverToBoxAdapter(
                  child: _ProfileActionGroup(
                    children: [
                      _ProfileActionTile(
                        icon: Icons.edit_rounded,
                        title: 'Edit Profil',
                        subtitle: 'Perbarui nama, email, dan nomor kontak.',
                        color: AppColors.primary,
                        onTap: _openEditProfileSheet,
                      ),
                      _ProfileActionTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Keamanan & Privasi',
                        subtitle: 'Informasi penggunaan data dan bukti pickup.',
                        color: AppColors.teal,
                        onTap: _showSecuritySheet,
                      ),
                      _ProfileActionTile(
                        icon: Icons.info_outline_rounded,
                        title: 'Tentang Aplikasi',
                        subtitle: 'Food Foundation Matching Platform.',
                        color: AppColors.accent,
                        onTap: _showAboutSheet,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  0,
                  AppSpacing.x3,
                  AppSpacing.x4,
                ),
                sliver: SliverToBoxAdapter(
                  child: _ProfileActionGroup(
                    children: [
                      _ProfileActionTile(
                        icon: Icons.logout_rounded,
                        title: 'Keluar',
                        subtitle: 'Akhiri sesi akun di perangkat ini.',
                        color: AppColors.danger,
                        isDestructive: true,
                        isLoading: _isLoggingOut,
                        onTap: _logout,
                      ),
                    ],
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

class _ProfileHeader extends StatelessWidget {
  final _ProfileData profile;
  final bool isRefreshing;
  final bool isUploadingPhoto;
  final Future<void> Function() onRefresh;
  final VoidCallback onChangePhoto;

  const _ProfileHeader({
    required this.profile,
    required this.isRefreshing,
    required this.isUploadingPhoto,
    required this.onRefresh,
    required this.onChangePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.x3),
      backgroundColor: AppColors.primary,
      borderColor: AppColors.primary,
      boxShadow: AppShadows.brand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ProfileAvatar(
                profile: profile,
                isUploading: isUploadingPhoto,
                onTap: onChangePhoto,
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: isRefreshing ? null : onRefresh,
                icon: isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Row(
            children: [
              const Expanded(
                child: AppMetricTile.dark(
                  icon: Icons.volunteer_activism_rounded,
                  label: 'Mode',
                  value: 'Donatur',
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              const Expanded(
                child: AppMetricTile.dark(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Mode',
                  value: 'Penerima',
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: AppMetricTile.dark(
                  icon: Icons.verified_user_outlined,
                  label: 'Akun',
                  value: profile.roleLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final _ProfileData profile;
  final bool isUploading;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.profile,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String initials = profile.initials;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: isUploading ? null : onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.42),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: profile.photoUrl == null
                    ? Center(
                        child: Text(
                          initials,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      )
                    : AppNetworkImage.avatar(
                        imageUrl: profile.photoUrl,
                        size: 78,
                      ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 3,
              ),
            ),
            child: isUploading
                ? const Padding(
                    padding: EdgeInsets.all(7),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.photo_camera_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final _ProfileData profile;

  const _RoleCard({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return AppInfoPanel.surface(
      icon: Icons.switch_account_rounded,
      color: AppColors.primary,
      title: 'Satu Akun, Dua Peran',
      description:
          'Akun ${profile.roleLabel} dapat membuat postingan makanan sekaligus mengklaim donasi terdekat.',
    );
  }
}

class _ProfileActionGroup extends StatelessWidget {
  final List<Widget> children;

  const _ProfileActionGroup({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const Divider(
                height: 1,
                indent: AppSpacing.x2,
                endIndent: AppSpacing.x2,
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDestructive;
  final bool isLoading;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = isDestructive ? AppColors.danger : color;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: foregroundColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                        ),
                      )
                    : Icon(
                        icon,
                        color: foregroundColor,
                      ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isDestructive
                                ? AppColors.danger
                                : AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDestructive ? AppColors.danger : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final _ProfileData profile;

  const _EditProfileSheet({
    required this.profile,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController(
      text: widget.profile.fullName,
    );

    _emailController = TextEditingController(
      text: widget.profile.email,
    );

    _phoneController = TextEditingController(
      text: widget.profile.phone,
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _ProfileEditResult(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppSpacing.x3,
            right: AppSpacing.x3,
            top: AppSpacing.x1,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.x3,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const AppBottomSheetHandle.compact(),
                const AppInfoPanel.surface(
                  icon: Icons.edit_rounded,
                  title: 'Edit Profil',
                  description: 'Perbarui nama, email, dan nomor kontak Anda.',
                ),
                const SizedBox(height: AppSpacing.x3),
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nama lengkap',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    final String fullName = value?.trim() ?? '';

                    if (fullName.isEmpty) {
                      return 'Nama tidak boleh kosong';
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
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
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
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Nomor HP',
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

                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.x3),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x1),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Simpan'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageSourceSheet extends StatelessWidget {
  final VoidCallback onGalleryTap;
  final VoidCallback onCameraTap;

  const _ImageSourceSheet({
    required this.onGalleryTap,
    required this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppBottomSheetHandle.compact(),
              Text(
                'Pilih Foto Profil',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.x2),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onGalleryTap,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galeri'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x1),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCameraTap,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Kamera'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutAppSheet extends StatelessWidget {
  const _AboutAppSheet();

  @override
  Widget build(BuildContext context) {
    return _InfoSheetShell(
      icon: Icons.info_outline_rounded,
      color: AppColors.accent,
      title: 'Food Foundation',
      description:
          'Food Foundation Matching Platform membantu menghubungkan donatur dan penerima makanan dalam satu akun, dengan dukungan peta, proof pickup, dan optimasi bandwidth gambar.',
      actionLabel: 'Tutup',
      onAction: () => Navigator.of(context).pop(),
    );
  }
}

class _SecuritySheet extends StatelessWidget {
  const _SecuritySheet();

  @override
  Widget build(BuildContext context) {
    return _InfoSheetShell(
      icon: Icons.privacy_tip_outlined,
      color: AppColors.teal,
      title: 'Keamanan & Privasi',
      description:
          'Aplikasi mengutamakan komunikasi in-app, bukti foto tanpa wajah, dan simulasi kompresi gambar untuk mendukung analisis keamanan, bandwidth, dan kinerja jaringan.',
      actionLabel: 'Mengerti',
      onAction: () => Navigator.of(context).pop(),
    );
  }
}

class _InfoSheetShell extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  const _InfoSheetShell({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x3,
            AppSpacing.x1,
            AppSpacing.x3,
            AppSpacing.x3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppBottomSheetHandle.compact(),
              AppInfoPanel.surface(
                icon: icon,
                color: color,
                title: title,
                description: description,
              ),
              const SizedBox(height: AppSpacing.x3),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileData {
  final int? id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? photoUrl;

  const _ProfileData({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.photoUrl,
  });

  const _ProfileData.empty()
      : id = null,
        fullName = 'User',
        email = 'email belum tersedia',
        phone = '-',
        role = 'USER',
        photoUrl = null;

  factory _ProfileData.fromResponse(Map<String, dynamic> response) {
    final Map<String, dynamic> data = FoodMapper.mapOf(response['data']);
    final Map<String, dynamic> user = FoodMapper.mapOf(data['user']);

    final Map<String, dynamic> source = user.isNotEmpty ? user : data;

    return _ProfileData(
      id: FoodMapper.nullableIntOf(
        FoodMapper.valueOf(
          source,
          [
            'id',
            'user_id',
            'userId',
          ],
        ),
      ),
      fullName: FoodMapper.textOf(
        FoodMapper.valueOf(
          source,
          [
            'fullName',
            'full_name',
            'name',
            'username',
            'displayName',
            'display_name',
          ],
        ),
        fallback: 'User',
      ),
      email: FoodMapper.textOf(
        FoodMapper.valueOf(
          source,
          [
            'email',
            'emailAddress',
            'email_address',
          ],
        ),
        fallback: 'email belum tersedia',
      ),
      phone: FoodMapper.textOf(
        FoodMapper.valueOf(
          source,
          [
            'phone',
            'phoneNumber',
            'phone_number',
            'mobile',
          ],
        ),
        fallback: '-',
      ),
      role: FoodMapper.textOf(
        FoodMapper.valueOf(
          source,
          [
            'role',
            'userRole',
            'user_role',
          ],
        ),
        fallback: 'USER',
      ).toUpperCase(),
      photoUrl: FoodMapper.nullablePhotoUrl(
        FoodMapper.valueOf(
          source,
          [
            'photoUrl',
            'photo_url',
            'avatar',
            'avatarUrl',
            'avatar_url',
            'profilePhoto',
            'profile_photo',
          ],
        ),
      ),
    );
  }

  String get initials {
    final List<String> words = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return 'U';
    }

    if (words.length == 1) {
      return words.first.characters.first.toUpperCase();
    }

    return '${words.first.characters.first}${words.last.characters.first}'
        .toUpperCase();
  }

  String get roleLabel {
    if (role == 'ADMIN') return 'Admin';
    return 'User';
  }
}

class _ProfileEditResult {
  final String fullName;
  final String email;
  final String phone;

  const _ProfileEditResult({
    required this.fullName,
    required this.email,
    required this.phone,
  });
}

class _ProfileSkeletonPage extends StatelessWidget {
  const _ProfileSkeletonPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.x3),
          child: Column(
            children: [
              ShimmerBox(
                height: 224,
                borderRadius: AppRadius.xl,
              ),
              SizedBox(height: AppSpacing.x2),
              ShimmerBox(
                height: 92,
                borderRadius: AppRadius.xl,
              ),
              SizedBox(height: AppSpacing.x2),
              ShimmerBox(
                height: 204,
                borderRadius: AppRadius.xl,
              ),
              SizedBox(height: AppSpacing.x2),
              ShimmerBox(
                height: 92,
                borderRadius: AppRadius.xl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}