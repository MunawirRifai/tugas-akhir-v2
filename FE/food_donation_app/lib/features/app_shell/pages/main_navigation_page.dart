import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../account/pages/notification_page.dart';
import '../../account/pages/profile_page.dart';
import '../../donation/pages/add_food_page.dart';
import '../../history/pages/history_page.dart';
import '../../home/pages/home_page.dart';
import '../widgets/home_bottom_nav_bar.dart';

class MainNavigationPage extends StatefulWidget {
  final String token;

  const MainNavigationPage({
    super.key,
    required this.token,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  int _homeRefreshVersion = 0;
  int _historyRefreshVersion = 0;

  void _onTabChanged(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _openAddFoodPage() async {
    final bool? result = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) {
          return AddFoodPage(
            token: widget.token,
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

    if (!mounted) return;

    if (result == true) {
      setState(() {
        _homeRefreshVersion++;
        _historyRefreshVersion++;
        _currentIndex = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.textPrimary,
          content: Text('Postingan donasi berhasil diperbarui.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(
        key: ValueKey<String>('home-$_homeRefreshVersion'),
        token: widget.token,
      ),
      HistoryPage(
        key: ValueKey<String>('history-$_historyRefreshVersion'),
        token: widget.token,
      ),
      NotificationPage(
        token: widget.token,
      ),
      ProfilePage(
        token: widget.token,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _CreateDonationButton(
        onTap: _openAddFoodPage,
      ),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _currentIndex,
        onChanged: _onTabChanged,
      ),
    );
  }
}

class _CreateDonationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateDonationButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            boxShadow: AppShadows.accent,
            border: Border.all(
              color: AppColors.surface,
              width: 4,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 62,
                height: 62,
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}