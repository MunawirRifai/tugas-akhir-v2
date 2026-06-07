import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/pages/login_page.dart';
import '../../auth/pages/register_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  int _currentIndex = 0;

  static const List<_OnboardingSlideData> _slides = [
    _OnboardingSlideData(
      icon: Icons.restaurant_rounded,
      title: 'Selamatkan Makanan Layak Konsumsi',
      description:
          'Menyelamatkan makanan berlebih yang masih layak konsumsi agar dapat dimanfaatkan oleh penerima yang membutuhkan.',
      accentLabel: 'Reduce Waste',
    ),
    _OnboardingSlideData(
      icon: Icons.map_rounded,
      title: 'Temukan Bantuan Terdekat',
      description:
          'Menemukan donatur atau penerima terdekat secara real-time via peta dengan alur pickup yang lebih cepat dan terarah.',
      accentLabel: 'Real-Time Map',
    ),
    _OnboardingSlideData(
      icon: Icons.eco_rounded,
      title: 'Berkontribusi untuk Lingkungan',
      description:
          'Berkontribusi mengurangi masalah sampah makanan atau food waste melalui distribusi makanan yang lebih cerdas.',
      accentLabel: 'Food Impact',
    ),
  ];

  bool get _isLastPage {
    return _currentIndex == _slides.length - 1;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToNextPage() async {
    if (_isLastPage) {
      _openLoginPage();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skipToLastPage() async {
    await _pageController.animateToPage(
      _slides.length - 1,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
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

  @override
  Widget build(BuildContext context) {
    final _OnboardingSlideData activeSlide = _slides[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 430,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.x3,
                        AppSpacing.x2,
                        AppSpacing.x3,
                        0,
                      ),
                      child: Row(
                        children: [
                          const _BrandMiniBadge(),
                          const Spacer(),
                          TextButton(
                            onPressed: _isLastPage ? null : _skipToLastPage,
                            child: Text(
                              _isLastPage ? 'Siap Mulai' : 'Lewati',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _slides.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return _OnboardingSlide(
                            data: _slides[index],
                            index: index,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.x3,
                        0,
                        AppSpacing.x3,
                        AppSpacing.x3,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PageIndicator(
                            currentIndex: _currentIndex,
                            totalCount: _slides.length,
                          ),
                          const SizedBox(height: AppSpacing.x3),
                          _ImpactPreviewCard(
                            label: activeSlide.accentLabel,
                            icon: activeSlide.icon,
                          ),
                          const SizedBox(height: AppSpacing.x2),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _goToNextPage,
                              icon: Icon(
                                _isLastPage
                                    ? Icons.login_rounded
                                    : Icons.arrow_forward_rounded,
                              ),
                              label: Text(
                                _isLastPage ? 'Masuk Sekarang' : 'Lanjut',
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x1),
                          SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _openRegisterPage,
                              icon: const Icon(Icons.person_add_alt_rounded),
                              label: const Text('Buat Akun Baru'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandMiniBadge extends StatelessWidget {
  const _BrandMiniBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x1,
          vertical: 6,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Food Foundation',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingSlideData data;
  final int index;

  const _OnboardingSlide({
    required this.data,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x3,
        AppSpacing.x3,
        AppSpacing.x2,
      ),
      child: Column(
        children: [
          _HeroIllustration(
            data: data,
            index: index,
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  final _OnboardingSlideData data;
  final int index;

  const _HeroIllustration({
    required this.data,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(index),
      tween: Tween<double>(
        begin: 0.92,
        end: 1,
      ),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.12),
          ),
          boxShadow: AppShadows.card,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 22,
              right: 22,
              child: _FloatingBubble(
                size: 58,
                color: AppColors.primary.withValues(alpha: 0.16),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 26,
              child: _FloatingBubble(
                size: 44,
                color: AppColors.accent.withValues(alpha: 0.18),
              ),
            ),
            Positioned(
              top: 76,
              left: 28,
              child: _MiniMetricCard(
                icon: Icons.location_on_rounded,
                label: 'Nearby',
                color: AppColors.teal,
              ),
            ),
            Positioned(
              right: 26,
              bottom: 70,
              child: _MiniMetricCard(
                icon: Icons.eco_rounded,
                label: 'Impact',
                color: AppColors.accent,
              ),
            ),
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  boxShadow: AppShadows.brand,
                ),
                child: Icon(
                  data.icon,
                  color: AppColors.primary,
                  size: 76,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _FloatingBubble({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniMetricCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x1,
          vertical: AppSpacing.x1,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalCount;

  const _PageIndicator({
    required this.currentIndex,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalCount, (index) {
        final bool selected = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: selected ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _ImpactPreviewCard extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ImpactPreviewCard({
    required this.label,
    required this.icon,
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
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mulai dari satu makanan, bantu kurangi food waste.',
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _OnboardingSlideData {
  final IconData icon;
  final String title;
  final String description;
  final String accentLabel;

  const _OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentLabel,
  });
}