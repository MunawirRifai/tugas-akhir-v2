import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class HomeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  static const List<_BottomNavItemData> _items = [
    _BottomNavItemData(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _BottomNavItemData(
      label: 'Riwayat',
      icon: Icons.history_rounded,
      activeIcon: Icons.history_toggle_off_rounded,
    ),
    _BottomNavItemData(
      label: 'Notifikasi',
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_rounded,
    ),
    _BottomNavItemData(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 4),
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(
                child: _BottomNavItem(
                  data: _items[0],
                  index: 0,
                  isActive: currentIndex == 0,
                  onTap: onChanged,
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  data: _items[1],
                  index: 1,
                  isActive: currentIndex == 1,
                  onTap: onChanged,
                ),
              ),
              const SizedBox(width: 68),
              Expanded(
                child: _BottomNavItem(
                  data: _items[2],
                  index: 2,
                  isActive: currentIndex == 2,
                  onTap: onChanged,
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  data: _items[3],
                  index: 3,
                  isActive: currentIndex == 3,
                  onTap: onChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final _BottomNavItemData data;
  final int index;
  final bool isActive;
  final ValueChanged<int> onTap;

  const _BottomNavItem({
    required this.data,
    required this.index,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor =
        isActive ? AppColors.primaryDark : AppColors.textMuted;

    return Semantics(
      selected: isActive,
      button: true,
      label: data.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            height: 60,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive ? data.activeIcon : data.icon,
                      color: foregroundColor,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        data.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              height: 1.0,
                              color: foregroundColor,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _BottomNavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}