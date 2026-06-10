import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/notifications/local_notification_helper.dart';
import 'features/onboarding/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await LocalNotificationHelper.init();
  } catch (e) {
    debugPrint('FAILED TO INITIALIZE LOCAL NOTIFICATIONS: $e');
  }

  runApp(
    const FoodFoundationApp(),
  );
}

class FoodFoundationApp extends StatelessWidget {
  const FoodFoundationApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Foundation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
      builder: (context, child) {
        final MediaQueryData mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.86,
              maxScaleFactor: 1.18,
            ),
          ),
          child: _ResponsiveAppShell(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _ResponsiveAppShell extends StatelessWidget {
  final Widget child;

  const _ResponsiveAppShell({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool shouldUseCenteredMobileFrame = constraints.maxWidth >= 640;

          if (!shouldUseCenteredMobileFrame) {
            return child;
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  boxShadow: AppShadows.card,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}