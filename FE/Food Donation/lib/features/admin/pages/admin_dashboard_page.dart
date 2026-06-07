import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/food_mapper.dart';
import '../../../data/services/admin_service.dart';
import '../../../shared/widgets/badges/halal_badge.dart';
import '../../../shared/widgets/badges/status_pill.dart';
import '../../../shared/widgets/common/app_bottom_sheet_handle.dart';
import '../../../shared/widgets/common/app_empty_state.dart';
import '../../../shared/widgets/common/app_info_panel.dart';
import '../../../shared/widgets/common/app_metric_tile.dart';
import '../../../shared/widgets/common/app_surface_card.dart';
import '../../../shared/widgets/common/shimmer_box.dart';
import '../../../shared/widgets/media/app_network_image.dart';

class AdminDashboardPage extends StatefulWidget {
  final String token;

  const AdminDashboardPage({
    super.key,
    required this.token,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isLoading = true;
  bool _isRefreshing = false;
  int? _busyUserId;
  int? _busyFoodId;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _foods = [];
  Map<String, dynamic> _stats = {};

  int get _totalUsers {
    return AdminService.intOf(
          FoodMapper.valueOf(
            _stats,
            [
              'totalUsers',
              'total_users',
              'users',
              'userCount',
              'user_count',
            ],
          ),
        ) ??
        _users.length;
  }

  int get _totalFoods {
    return AdminService.intOf(
          FoodMapper.valueOf(
            _stats,
            [
              'totalFoods',
              'total_foods',
              'foods',
              'foodCount',
              'food_count',
              'totalDonations',
              'total_donations',
            ],
          ),
        ) ??
        _foods.length;
  }

  int get _activeFoods {
    final int? value = AdminService.intOf(
      FoodMapper.valueOf(
        _stats,
        [
          'activeFoods',
          'active_foods',
          'availableFoods',
          'available_foods',
        ],
      ),
    );

    if (value != null) return value;

    return _foods.where((food) {
      final String status = FoodMapper.textOf(
        FoodMapper.valueOf(
          food,
          [
            'status',
            'food_status',
            'foodStatus',
          ],
        ),
        fallback: 'POSTED',
      ).toUpperCase();

      return status == 'POSTED' || status == 'AVAILABLE';
    }).length;
  }

  int get _completedFoods {
    final int? value = AdminService.intOf(
      FoodMapper.valueOf(
        _stats,
        [
          'completedFoods',
          'completed_foods',
          'pickedUpFoods',
          'picked_up_foods',
          'totalClaims',
          'total_claims',
        ],
      ),
    );

    if (value != null) return value;

    return _foods.where((food) {
      final String status = FoodMapper.textOf(
        FoodMapper.valueOf(
          food,
          [
            'status',
            'food_status',
            'foodStatus',
          ],
        ),
        fallback: 'POSTED',
      ).toUpperCase();

      return status == 'PICKED_UP' ||
          status == 'COMPLETED' ||
          status == 'CLAIMED';
    }).length;
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard({
    bool showRefreshState = false,
  }) async {
    if (showRefreshState && mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final Map<String, dynamic> response = await AdminService.getDashboard(
        widget.token,
      );

      if (!mounted) return;

      if (response['success'] == false) {
        throw Exception(
          AdminService.messageOf(
            response,
            fallback: 'Gagal memuat dashboard admin.',
          ),
        );
      }

      final Map<String, dynamic> data = FoodMapper.mapOf(response['data']);

      final List<Map<String, dynamic>> users = AdminService.listOf(
        FoodMapper.valueOf(
          data,
          [
            'users',
            'allUsers',
            'all_users',
          ],
        ),
      );

      final List<Map<String, dynamic>> foods = AdminService.listOf(
        FoodMapper.valueOf(
          data,
          [
            'foods',
            'donations',
            'items',
            'allFoods',
            'all_foods',
          ],
        ),
      );

      final Map<String, dynamic> stats = FoodMapper.mapOf(
        FoodMapper.valueOf(
          data,
          [
            'stats',
            'statistics',
            'summary',
            'dashboard',
          ],
        ),
      );

      setState(() {
        _users = users;
        _foods = foods;
        _stats = stats;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnack(
        'Gagal memuat dashboard admin: $error',
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

  Future<void> _refreshDashboard() {
    return _loadDashboard(
      showRefreshState: true,
    );
  }

  Future<void> _deleteFood(Map<String, dynamic> food) async {
    final int? foodId = FoodMapper.nullableIntOf(
      FoodMapper.valueOf(
        food,
        [
          'id',
          'food_id',
          'foodId',
        ],
      ),
    );

    if (foodId == null) {
      _showSnack(
        'ID makanan tidak valid.',
        isError: true,
      );
      return;
    }

    final String foodName = FoodMapper.textOf(
      FoodMapper.valueOf(
        food,
        [
          'food_name',
          'foodName',
          'name',
          'title',
        ],
      ),
      fallback: 'Makanan',
    );

    final bool? confirmed = await _showConfirmDialog(
      title: 'Hapus Makanan?',
      message:
          'Postingan "$foodName" akan dihapus dari sistem. Tindakan ini tidak dapat dibatalkan.',
      actionLabel: 'Hapus',
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _busyFoodId = foodId;
    });

    try {
      await AdminService.deleteFood(
        token: widget.token,
        foodId: foodId,
      );

      if (!mounted) return;

      _showSnack(
        'Postingan makanan berhasil dihapus.',
        isError: false,
      );

      await _refreshDashboard();
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal menghapus makanan: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyFoodId = null;
        });
      }
    }
  }

  Future<void> _verifyFood(Map<String, dynamic> food) async {
    final int? foodId = FoodMapper.nullableIntOf(
      FoodMapper.valueOf(
        food,
        [
          'id',
          'food_id',
          'foodId',
        ],
      ),
    );

    if (foodId == null) {
      _showSnack(
        'ID makanan tidak valid.',
        isError: true,
      );
      return;
    }

    setState(() {
      _busyFoodId = foodId;
    });

    try {
      await AdminService.verifyFood(
        token: widget.token,
        foodId: foodId,
      );

      if (!mounted) return;

      _showSnack(
        'Postingan makanan berhasil diverifikasi.',
        isError: false,
      );

      await _refreshDashboard();
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal memverifikasi makanan: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyFoodId = null;
        });
      }
    }
  }

  Future<void> _rejectFood(Map<String, dynamic> food) async {
    final int? foodId = FoodMapper.nullableIntOf(
      FoodMapper.valueOf(
        food,
        [
          'id',
          'food_id',
          'foodId',
        ],
      ),
    );

    if (foodId == null) {
      _showSnack(
        'ID makanan tidak valid.',
        isError: true,
      );
      return;
    }

    final String? reason = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _RejectReasonSheet();
      },
    );

    if (reason == null || !mounted) return;

    setState(() {
      _busyFoodId = foodId;
    });

    try {
      await AdminService.rejectFood(
        token: widget.token,
        foodId: foodId,
        reason: reason,
      );

      if (!mounted) return;

      _showSnack(
        'Postingan makanan berhasil ditolak.',
        isError: false,
      );

      await _refreshDashboard();
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal menolak makanan: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyFoodId = null;
        });
      }
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final int? userId = FoodMapper.nullableIntOf(
      FoodMapper.valueOf(
        user,
        [
          'id',
          'user_id',
          'userId',
        ],
      ),
    );

    if (userId == null) {
      _showSnack(
        'ID user tidak valid.',
        isError: true,
      );
      return;
    }

    final String name = _userName(user);

    final bool? confirmed = await _showConfirmDialog(
      title: 'Hapus User?',
      message:
          'Akun "$name" akan dihapus dari sistem. Pastikan tindakan ini sesuai kebijakan admin.',
      actionLabel: 'Hapus',
      icon: Icons.person_remove_alt_1_outlined,
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _busyUserId = userId;
    });

    try {
      await AdminService.deleteUser(
        token: widget.token,
        userId: userId,
      );

      if (!mounted) return;

      _showSnack(
        'User berhasil dihapus.',
        isError: false,
      );

      await _refreshDashboard();
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal menghapus user: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyUserId = null;
        });
      }
    }
  }

  Future<void> _toggleBlockUser(Map<String, dynamic> user) async {
    final int? userId = FoodMapper.nullableIntOf(
      FoodMapper.valueOf(
        user,
        [
          'id',
          'user_id',
          'userId',
        ],
      ),
    );

    if (userId == null) {
      _showSnack(
        'ID user tidak valid.',
        isError: true,
      );
      return;
    }

    final bool isBlocked = _isBlockedUser(user);

    setState(() {
      _busyUserId = userId;
    });

    try {
      if (isBlocked) {
        await AdminService.unblockUser(
          token: widget.token,
          userId: userId,
        );
      } else {
        await AdminService.blockUser(
          token: widget.token,
          userId: userId,
        );
      }

      if (!mounted) return;

      _showSnack(
        isBlocked ? 'Blokir user dibuka.' : 'User berhasil diblokir.',
        isError: false,
      );

      await _refreshDashboard();
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        isBlocked
            ? 'Gagal membuka blokir user: $error'
            : 'Gagal memblokir user: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyUserId = null;
        });
      }
    }
  }

  Future<void> _updateUserRole(
    Map<String, dynamic> user,
    String role,
  ) async {
    final int? userId = FoodMapper.nullableIntOf(
      FoodMapper.valueOf(
        user,
        [
          'id',
          'user_id',
          'userId',
        ],
      ),
    );

    if (userId == null) {
      _showSnack(
        'ID user tidak valid.',
        isError: true,
      );
      return;
    }

    setState(() {
      _busyUserId = userId;
    });

    try {
      await AdminService.updateUserRole(
        token: widget.token,
        userId: userId,
        role: role,
      );

      if (!mounted) return;

      _showSnack(
        'Role user berhasil diperbarui.',
        isError: false,
      );

      await _refreshDashboard();
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal memperbarui role user: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyUserId = null;
        });
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String actionLabel,
    required IconData icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: Icon(icon),
              label: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }

  void _showUserDetail(Map<String, dynamic> user) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _UserDetailSheet(
          user: user,
          onMakeUser: () {
            Navigator.of(context).pop();
            _updateUserRole(user, 'USER');
          },
          onMakeAdmin: () {
            Navigator.of(context).pop();
            _updateUserRole(user, 'ADMIN');
          },
          onToggleBlock: () {
            Navigator.of(context).pop();
            _toggleBlockUser(user);
          },
          onDelete: () {
            Navigator.of(context).pop();
            _deleteUser(user);
          },
        );
      },
    );
  }

  void _showFoodDetail(Map<String, dynamic> food) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AdminFoodDetailSheet(
          food: food,
          onVerify: () {
            Navigator.of(context).pop();
            _verifyFood(food);
          },
          onReject: () {
            Navigator.of(context).pop();
            _rejectFood(food);
          },
          onDelete: () {
            Navigator.of(context).pop();
            _deleteFood(food);
          },
        );
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

  String _userName(Map<String, dynamic> user) {
    return FoodMapper.textOf(
      FoodMapper.valueOf(
        user,
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
    );
  }

  String _userEmail(Map<String, dynamic> user) {
    return FoodMapper.textOf(
      FoodMapper.valueOf(
        user,
        [
          'email',
          'emailAddress',
          'email_address',
        ],
      ),
      fallback: 'email belum tersedia',
    );
  }

  String _userRole(Map<String, dynamic> user) {
    return FoodMapper.textOf(
      FoodMapper.valueOf(
        user,
        [
          'role',
          'userRole',
          'user_role',
        ],
      ),
      fallback: 'USER',
    ).toUpperCase();
  }

  bool _isBlockedUser(Map<String, dynamic> user) {
    return FoodMapper.boolOf(
      FoodMapper.valueOf(
        user,
        [
          'isBlocked',
          'is_blocked',
          'blocked',
          'isBanned',
          'is_banned',
          'banned',
        ],
      ),
      fallback: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _AdminSkeletonPage();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _isRefreshing ? null : _refreshDashboard,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  AppSpacing.x2,
                  AppSpacing.x3,
                  AppSpacing.x2,
                ),
                sliver: SliverToBoxAdapter(
                  child: _AdminHeaderCard(
                    totalUsers: _totalUsers,
                    totalFoods: _totalFoods,
                    activeFoods: _activeFoods,
                    completedFoods: _completedFoods,
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _AdminTabHeaderDelegate(
                  tabController: _tabController,
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: true,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _UsersTab(
                      users: _users,
                      busyUserId: _busyUserId,
                      userNameOf: _userName,
                      userEmailOf: _userEmail,
                      userRoleOf: _userRole,
                      isBlockedOf: _isBlockedUser,
                      onOpenDetail: _showUserDetail,
                      onToggleBlock: _toggleBlockUser,
                      onDelete: _deleteUser,
                    ),
                    _FoodsTab(
                      foods: _foods,
                      busyFoodId: _busyFoodId,
                      onOpenDetail: _showFoodDetail,
                      onVerify: _verifyFood,
                      onReject: _rejectFood,
                      onDelete: _deleteFood,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminHeaderCard extends StatelessWidget {
  final int totalUsers;
  final int totalFoods;
  final int activeFoods;
  final int completedFoods;

  const _AdminHeaderCard({
    required this.totalUsers,
    required this.totalFoods,
    required this.activeFoods,
    required this.completedFoods,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.x3),
      backgroundColor: AppColors.textPrimary,
      borderColor: AppColors.textPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kontrol Operasional',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pantau user, postingan, validasi donasi, dan status distribusi makanan.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.76),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          AppMetricGrid(
            children: [
              AppMetricTile.dark(
                label: 'Users',
                value: '$totalUsers',
                icon: Icons.people_alt_outlined,
                color: AppColors.primary,
              ),
              AppMetricTile.dark(
                label: 'Donasi',
                value: '$totalFoods',
                icon: Icons.volunteer_activism_rounded,
                color: AppColors.accent,
              ),
              AppMetricTile.dark(
                label: 'Aktif',
                value: '$activeFoods',
                icon: Icons.inventory_2_outlined,
                color: AppColors.teal,
              ),
              AppMetricTile.dark(
                label: 'Selesai',
                value: '$completedFoods',
                icon: Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminTabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  const _AdminTabHeaderDelegate({
    required this.tabController,
  });

  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x3,
          AppSpacing.x1,
          AppSpacing.x3,
          AppSpacing.x1,
        ),
        child: AppSurfaceCard(
          padding: const EdgeInsets.all(4),
          child: TabBar(
            controller: tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.primaryDark,
            labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            tabs: const [
              Tab(
                icon: Icon(
                  Icons.people_alt_outlined,
                  size: 18,
                ),
                text: 'Users',
              ),
              Tab(
                icon: Icon(
                  Icons.restaurant_menu_rounded,
                  size: 18,
                ),
                text: 'Foods',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _AdminTabHeaderDelegate oldDelegate) {
    return oldDelegate.tabController != tabController;
  }
}

class _UsersTab extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final int? busyUserId;
  final String Function(Map<String, dynamic> user) userNameOf;
  final String Function(Map<String, dynamic> user) userEmailOf;
  final String Function(Map<String, dynamic> user) userRoleOf;
  final bool Function(Map<String, dynamic> user) isBlockedOf;
  final ValueChanged<Map<String, dynamic>> onOpenDetail;
  final ValueChanged<Map<String, dynamic>> onToggleBlock;
  final ValueChanged<Map<String, dynamic>> onDelete;

  const _UsersTab({
    required this.users,
    required this.busyUserId,
    required this.userNameOf,
    required this.userEmailOf,
    required this.userRoleOf,
    required this.isBlockedOf,
    required this.onOpenDetail,
    required this.onToggleBlock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const _EmptyAdminState(
        icon: Icons.people_outline_rounded,
        title: 'Belum Ada User',
        description: 'Data user akan muncul setelah endpoint admin tersedia.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x2,
        AppSpacing.x3,
        AppSpacing.x4,
      ),
      itemCount: users.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: AppSpacing.x2);
      },
      itemBuilder: (context, index) {
        final Map<String, dynamic> user = users[index];

        final int? userId = FoodMapper.nullableIntOf(
          FoodMapper.valueOf(
            user,
            [
              'id',
              'user_id',
              'userId',
            ],
          ),
        );

        return _UserCard(
          user: user,
          name: userNameOf(user),
          email: userEmailOf(user),
          role: userRoleOf(user),
          isBlocked: isBlockedOf(user),
          isBusy: userId != null && userId == busyUserId,
          onOpenDetail: () => onOpenDetail(user),
          onToggleBlock: () => onToggleBlock(user),
          onDelete: () => onDelete(user),
        );
      },
    );
  }
}

class _FoodsTab extends StatelessWidget {
  final List<Map<String, dynamic>> foods;
  final int? busyFoodId;
  final ValueChanged<Map<String, dynamic>> onOpenDetail;
  final ValueChanged<Map<String, dynamic>> onVerify;
  final ValueChanged<Map<String, dynamic>> onReject;
  final ValueChanged<Map<String, dynamic>> onDelete;

  const _FoodsTab({
    required this.foods,
    required this.busyFoodId,
    required this.onOpenDetail,
    required this.onVerify,
    required this.onReject,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return const _EmptyAdminState(
        icon: Icons.restaurant_menu_rounded,
        title: 'Belum Ada Donasi',
        description:
            'Data postingan makanan akan muncul setelah endpoint admin tersedia.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x2,
        AppSpacing.x3,
        AppSpacing.x4,
      ),
      itemCount: foods.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: AppSpacing.x2);
      },
      itemBuilder: (context, index) {
        final Map<String, dynamic> food = foods[index];
        final FoodRecord record = FoodRecord(food);

        return _FoodAdminCard(
          food: food,
          record: record,
          isBusy: record.id != null && record.id == busyFoodId,
          onOpenDetail: () => onOpenDetail(food),
          onVerify: () => onVerify(food),
          onReject: () => onReject(food),
          onDelete: () => onDelete(food),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String name;
  final String email;
  final String role;
  final bool isBlocked;
  final bool isBusy;
  final VoidCallback onOpenDetail;
  final VoidCallback onToggleBlock;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.name,
    required this.email,
    required this.role,
    required this.isBlocked,
    required this.isBusy,
    required this.onOpenDetail,
    required this.onToggleBlock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color roleColor = role == 'ADMIN' ? AppColors.accent : AppColors.teal;
    final String initial = name.trim().isEmpty
        ? 'U'
        : name.trim().characters.first.toUpperCase();

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.x2),
      onTap: isBusy ? null : onOpenDetail,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: roleColor.withValues(alpha: 0.22),
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: roleColor,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusPill(
                          icon: Icons.verified_user_outlined,
                          label: role,
                          color: roleColor,
                        ),
                        if (isBlocked)
                          const StatusPill(
                            icon: Icons.block_rounded,
                            label: 'Blocked',
                            color: AppColors.danger,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isBusy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onToggleBlock,
                  icon: Icon(
                    isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                  ),
                  label: Text(isBlocked ? 'Unblock' : 'Block'),
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Hapus'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoodAdminCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final FoodRecord record;
  final bool isBusy;
  final VoidCallback onOpenDetail;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const _FoodAdminCard({
    required this.food,
    required this.record,
    required this.isBusy,
    required this.onOpenDetail,
    required this.onVerify,
    required this.onReject,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.x2),
      onTap: isBusy ? null : onOpenDetail,
      child: Column(
        children: [
          Row(
            children: [
              AppNetworkImage.food(
                imageUrl: record.photoUrl,
                width: 82,
                height: 82,
                borderRadius: AppRadius.lg,
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusPill.fromFoodStatus(
                          record.status,
                        ),
                        StatusPill(
                          icon: Icons.inventory_2_outlined,
                          label: '${record.quantity} porsi',
                          color: AppColors.teal,
                        ),
                        HalalBadge(
                          isHalal: record.isHalal,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isBusy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onVerify,
                  icon: const Icon(Icons.verified_rounded),
                  label: const Text('Verify'),
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onReject,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject'),
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: isBusy ? null : onDelete,
                  child: const Icon(Icons.delete_outline_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserDetailSheet extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onMakeUser;
  final VoidCallback onMakeAdmin;
  final VoidCallback onToggleBlock;
  final VoidCallback onDelete;

  const _UserDetailSheet({
    required this.user,
    required this.onMakeUser,
    required this.onMakeAdmin,
    required this.onToggleBlock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String name = FoodMapper.textOf(
      FoodMapper.valueOf(
        user,
        [
          'fullName',
          'full_name',
          'name',
          'username',
        ],
      ),
      fallback: 'User',
    );

    final String email = FoodMapper.textOf(
      FoodMapper.valueOf(
        user,
        [
          'email',
          'emailAddress',
          'email_address',
        ],
      ),
      fallback: 'email belum tersedia',
    );

    final String role = FoodMapper.textOf(
      FoodMapper.valueOf(
        user,
        [
          'role',
          'userRole',
          'user_role',
        ],
      ),
      fallback: 'USER',
    ).toUpperCase();

    final bool isBlocked = FoodMapper.boolOf(
      FoodMapper.valueOf(
        user,
        [
          'blocked',
          'isBlocked',
          'is_blocked',
          'banned',
        ],
      ),
      fallback: false,
    );

    return _AdminDetailSheetShell(
      icon: Icons.person_rounded,
      title: name,
      subtitle: email,
      children: [
        AppInfoPanel.surface(
          icon: Icons.verified_user_outlined,
          title: 'Role',
          description: role,
        ),
        const SizedBox(height: AppSpacing.x1),
        AppInfoPanel.surface(
          icon: Icons.block_rounded,
          title: 'Status',
          description: isBlocked ? 'Blocked' : 'Active',
          color: isBlocked ? AppColors.danger : AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.x2),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onMakeUser,
                icon: const Icon(Icons.person_outline_rounded),
                label: const Text('Set User'),
              ),
            ),
            const SizedBox(width: AppSpacing.x1),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onMakeAdmin,
                icon: const Icon(Icons.admin_panel_settings_rounded),
                label: const Text('Set Admin'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x1),
        OutlinedButton.icon(
          onPressed: onToggleBlock,
          icon: Icon(
            isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
          ),
          label: Text(isBlocked ? 'Unblock User' : 'Block User'),
        ),
        const SizedBox(height: AppSpacing.x1),
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Hapus User'),
        ),
      ],
    );
  }
}

class _AdminFoodDetailSheet extends StatelessWidget {
  final Map<String, dynamic> food;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const _AdminFoodDetailSheet({
    required this.food,
    required this.onVerify,
    required this.onReject,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final FoodRecord record = FoodRecord(food);

    return _AdminDetailSheetShell(
      icon: Icons.restaurant_menu_rounded,
      title: record.name,
      subtitle: record.description,
      children: [
        StatusPill.fromFoodStatus(
          record.status,
          isLarge: true,
          showBorder: true,
        ),
        const SizedBox(height: AppSpacing.x1),
        HalalBadge(
          isHalal: record.isHalal,
          isLarge: true,
        ),
        const SizedBox(height: AppSpacing.x2),
        AppMetricGrid(
          childAspectRatio: 1.55,
          children: [
            AppMetricTile.compact(
              icon: Icons.inventory_2_outlined,
              label: 'Porsi',
              value: '${record.quantity} porsi',
              color: AppColors.teal,
            ),
            AppMetricTile.compact(
              icon: Icons.category_outlined,
              label: 'Kategori',
              value: record.category,
              color: AppColors.primary,
              valueMaxLines: 2,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x2),
        AppInfoPanel.surface(
          icon: Icons.place_outlined,
          title: 'Lokasi',
          description: record.address,
        ),
        const SizedBox(height: AppSpacing.x2),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onVerify,
                icon: const Icon(Icons.verified_rounded),
                label: const Text('Verify'),
              ),
            ),
            const SizedBox(width: AppSpacing.x1),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Reject'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x1),
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Hapus Postingan'),
        ),
      ],
    );
  }
}

class _AdminDetailSheetShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _AdminDetailSheetShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x3,
            AppSpacing.x1,
            AppSpacing.x3,
            AppSpacing.x3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppBottomSheetHandle.compact(),
              AppInfoPanel.surface(
                icon: icon,
                title: title,
                description: subtitle,
              ),
              const SizedBox(height: AppSpacing.x3),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _RejectReasonSheet extends StatefulWidget {
  const _RejectReasonSheet();

  @override
  State<_RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<_RejectReasonSheet> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final String reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      Navigator.of(context).pop('Tidak memenuhi ketentuan validasi admin.');
      return;
    }

    Navigator.of(context).pop(reason);
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
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.x3,
            right: AppSpacing.x3,
            top: AppSpacing.x1,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.x3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppBottomSheetHandle.compact(),
              const AppInfoPanel.warning(
                icon: Icons.notes_rounded,
                title: 'Alasan Penolakan',
                description:
                    'Tambahkan catatan admin agar alasan penolakan dapat ditindaklanjuti.',
              ),
              const SizedBox(height: AppSpacing.x2),
              TextField(
                controller: _reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Catatan admin',
                  hintText: 'Contoh: foto tidak jelas atau data tidak lengkap',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
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
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Kirim'),
                      ),
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

class _EmptyAdminState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EmptyAdminState({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x3),
      children: [
        const SizedBox(height: AppSpacing.x5),
        AppEmptyState(
          icon: icon,
          title: title,
          message: description,
        ),
      ],
    );
  }
}

class _AdminSkeletonPage extends StatelessWidget {
  const _AdminSkeletonPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x3),
          child: Column(
            children: [
              const ShimmerBox(
                height: 256,
                borderRadius: AppRadius.xl,
              ),
              const SizedBox(height: AppSpacing.x2),
              const ShimmerBox(
                height: 64,
                borderRadius: AppRadius.xl,
              ),
              const SizedBox(height: AppSpacing.x2),
              Expanded(
                child: ListView.separated(
                  itemCount: 4,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: AppSpacing.x2);
                  },
                  itemBuilder: (context, index) {
                    return const ShimmerBox(
                      height: 174,
                      borderRadius: AppRadius.xl,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}