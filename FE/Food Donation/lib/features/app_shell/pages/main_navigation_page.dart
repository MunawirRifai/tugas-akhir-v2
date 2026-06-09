import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/auth_storage.dart';
import '../../../data/services/notification_service.dart';
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
  int _notificationRefreshVersion = 0;

  Timer? _notificationPollTimer;
  int _unreadCount = 0;
  final Set<String> _seenUnreadNotificationIds = {};
  bool _isFirstPoll = true;
  late String _currentToken;

  @override
  void initState() {
    super.initState();
    _currentToken = widget.token;
    _startNotificationPolling();
  }

  @override
  void dispose() {
    _notificationPollTimer?.cancel();
    super.dispose();
  }

  void _startNotificationPolling() {
    _pollNotifications();
    _notificationPollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _pollNotifications();
    });
  }

  Future<void> _pollNotifications() async {
    try {
      final List<Map<String, dynamic>> result =
          await NotificationService.getNotifications(token: _currentToken);

      if (!mounted) return;

      final List<Map<String, dynamic>> unreadNotifications = result
          .where((item) => item['is_read'] == false || item['is_read'] == 0)
          .toList();

      final int newUnreadCount = unreadNotifications.length;

      if (_isFirstPoll) {
        for (final item in unreadNotifications) {
          final String id = item['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            _seenUnreadNotificationIds.add(id);
          }
        }
        _isFirstPoll = false;
      } else {
        for (final item in unreadNotifications) {
          final String id = item['id']?.toString() ?? '';
          if (id.isNotEmpty && !_seenUnreadNotificationIds.contains(id)) {
            _seenUnreadNotificationIds.add(id);
            _showInAppNotificationOverlay(
              item['title']?.toString() ?? 'Donasi Makanan Baru',
              item['message']?.toString() ?? 'Ada postingan makanan baru.',
            );
          }
        }
      }

      if (_unreadCount != newUnreadCount) {
        setState(() {
          _unreadCount = newUnreadCount;
        });
      }
    } catch (error) {
      debugPrint('POLLING NOTIFICATIONS ERROR: $error');
      final String errStr = error.toString().toLowerCase();
      if (errStr.contains('403') || errStr.contains('401') || errStr.contains('unauthorized') || errStr.contains('forbidden')) {
        _trySilentTokenRefresh();
      }
    }
  }

  Future<void> _trySilentTokenRefresh() async {
    final String? refreshToken = await AuthStorage.getRefreshToken();
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      try {
        final Map<String, dynamic> refreshResponse = await AuthService.refresh(refreshToken: refreshToken);
        final String? newToken = AuthService.extractAccessToken(refreshResponse);
        final String? newRefreshToken = AuthService.extractRefreshToken(refreshResponse);

        if (newToken != null && newToken.trim().isNotEmpty) {
          await AuthStorage.saveToken(newToken);
          if (newRefreshToken != null && newRefreshToken.trim().isNotEmpty) {
            await AuthStorage.saveRefreshToken(newRefreshToken);
          }
          if (!mounted) return;
          setState(() {
            _currentToken = newToken;
          });
          debugPrint('Sesi token berhasil diperbarui di background.');
        }
      } catch (e) {
        debugPrint('Gagal memperbarui token di background: $e');
      }
    }
  }

  void _showInAppNotificationOverlay(String title, String message) {
    final OverlayState overlayState = Overlay.of(context);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _InAppNotificationBanner(
        title: title,
        message: message,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
        onTap: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
          _onTabChanged(2);
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }

  void _onTabChanged(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
      if (index == 2) {
        _notificationRefreshVersion++;
        Future.delayed(const Duration(milliseconds: 500), _pollNotifications);
      }
    });
  }

  Future<void> _openAddFoodPage() async {
    final bool? result = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) {
          return AddFoodPage(
            token: _currentToken,
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
        token: _currentToken,
      ),
      HistoryPage(
        key: ValueKey<String>('history-$_historyRefreshVersion'),
        token: _currentToken,
      ),
      NotificationPage(
        key: ValueKey<String>('notification-$_notificationRefreshVersion'),
        token: _currentToken,
      ),
      ProfilePage(
        token: _currentToken,
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
        unreadCount: _unreadCount,
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

class _InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InAppNotificationBanner({
    required this.title,
    required this.message,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_InAppNotificationBanner> createState() => _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<_InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    _dismissTimer = Timer(const Duration(seconds: 4), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    onPressed: _dismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}