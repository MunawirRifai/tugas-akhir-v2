import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/food_mapper.dart';
import '../../../data/services/food_service.dart';
import '../../../shared/widgets/badges/halal_badge.dart';
import '../../../shared/widgets/badges/status_pill.dart';
import '../../../shared/widgets/common/app_empty_state.dart';
import '../../../shared/widgets/common/app_metric_tile.dart';
import '../../../shared/widgets/common/app_surface_card.dart';
import '../../../shared/widgets/common/shimmer_box.dart';
import '../../../shared/widgets/media/app_network_image.dart';
import '../../donation/pages/edit_food_page.dart';
import '../../donation/pages/food_detail_page.dart';

class HistoryPage extends StatefulWidget {
  final String token;

  const HistoryPage({super.key, required this.token});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isLoading = true;
  bool _isRefreshing = false;
  int? _busyFoodId;

  List<Map<String, dynamic>> _myDonations = [];
  List<Map<String, dynamic>> _myClaims = [];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool showRefreshState = false}) async {
    if (showRefreshState && mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final Map<String, dynamic> response = await FoodService.getHistory(
        widget.token,
      );

      if (!mounted) return;

      setState(() {
        _myDonations = _extractList(
          response,
          keys: [
            'myDonation',
            'myDonations',
            'my_donation',
            'my_donations',
            'donations',
            'postedFoods',
            'posted_foods',
          ],
        );

        _myClaims = _extractList(
          response,
          keys: [
            'myClaim',
            'myClaims',
            'my_claim',
            'my_claims',
            'claims',
            'pickedFoods',
            'picked_foods',
          ],
        );

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnack('Gagal memuat riwayat: $error', isError: true);
    } finally {
      if (mounted && showRefreshState) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> response, {
    required List<String> keys,
  }) {
    final Map<String, dynamic> data = FoodMapper.mapOf(response['data']);

    for (final String key in keys) {
      if (response[key] != null) {
        return FoodMapper.listOf(response[key]);
      }

      if (data[key] != null) {
        return FoodMapper.listOf(data[key]);
      }
    }

    return <Map<String, dynamic>>[];
  }

  Future<void> _refreshHistory() {
    return _loadHistory(showRefreshState: true);
  }

  Future<void> _openDetail(
    Map<String, dynamic> food, {
    required bool isDonation,
  }) async {
    final bool? result = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FoodDetailPage(
            token: widget.token,
            food: food,
            distanceLabel: '-',
          );
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

    if (!mounted) return;

    if (result == true) {
      await _refreshHistory();
    }
  }

  Future<void> _openEdit(Map<String, dynamic> food) async {
    final bool? result = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) {
          return EditFoodPage(token: widget.token, food: food);
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

    if (!mounted) return;

    if (result == true) {
      _showSnack('Postingan berhasil diperbarui.', isError: false);

      await _refreshHistory();
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> food) async {
    final FoodRecord foodRecord = FoodRecord(food);

    if (foodRecord.id == null) {
      _showSnack('ID makanan tidak valid.', isError: true);
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Batalkan Postingan?'),
          content: Text(
            'Postingan "${foodRecord.name}" akan Batalkan dari daftar donasi. '
            'Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _deleteFood(foodRecord.id!);
  }

  Future<void> _deleteFood(int foodId) async {
    setState(() {
      _busyFoodId = foodId;
    });

    try {
      await FoodService.deleteFood(token: widget.token, foodId: foodId);

      if (!mounted) return;

      _showSnack('Postingan berhasil dibatalkan.', isError: false);

      await _refreshHistory();
    } catch (error) {
      if (!mounted) return;

      _showSnack('Gagal batalkan postingan: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _busyFoodId = null;
        });
      }
    }
  }

  void _showSnack(String message, {required bool isError}) {
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
      return const _HistorySkeletonPage();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshHistory,
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
                  child: _HistoryHeader(
                    donationCount: _myDonations.length,
                    claimCount: _myClaims.length,
                    isRefreshing: _isRefreshing,
                    onRefresh: _refreshHistory,
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabHeaderDelegate(tabController: _tabController),
              ),
              SliverFillRemaining(
                hasScrollBody: true,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _HistoryList(
                      type: _HistoryType.donation,
                      foods: _myDonations,
                      busyFoodId: _busyFoodId,
                      onOpenDetail: (food) {
                        _openDetail(food, isDonation: true);
                      },
                      onEdit: _openEdit,
                      onDelete: _confirmDelete,
                    ),
                    _HistoryList(
                      type: _HistoryType.claim,
                      foods: _myClaims,
                      busyFoodId: _busyFoodId,
                      onOpenDetail: (food) {
                        _openDetail(food, isDonation: false);
                      },
                      onEdit: _openEdit,
                      onDelete: _confirmDelete,
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

enum _HistoryType { donation, claim }

class _HistoryHeader extends StatelessWidget {
  final int donationCount;
  final int claimCount;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  const _HistoryHeader({
    required this.donationCount,
    required this.claimCount,
    required this.isRefreshing,
    required this.onRefresh,
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
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Aktivitas',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pantau donasi dan makanan yang pernah Anda klaim.',
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
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Row(
            children: [
              Expanded(
                child: AppMetricTile.dark(
                  label: 'Donasi Saya',
                  value: '$donationCount',
                  icon: Icons.volunteer_activism_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: AppMetricTile.dark(
                  label: 'Klaim Saya',
                  value: '$claimCount',
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  const _TabHeaderDelegate({required this.tabController});

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
          borderRadius: AppRadius.xl,
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
            labelStyle: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            unselectedLabelStyle: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(
                text: 'Donasi',
                icon: Icon(Icons.volunteer_activism_rounded, size: 18),
              ),
              Tab(
                text: 'Klaim',
                icon: Icon(Icons.shopping_bag_outlined, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabHeaderDelegate oldDelegate) {
    return oldDelegate.tabController != tabController;
  }
}

class _HistoryList extends StatelessWidget {
  final _HistoryType type;
  final List<Map<String, dynamic>> foods;
  final int? busyFoodId;
  final ValueChanged<Map<String, dynamic>> onOpenDetail;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onDelete;

  const _HistoryList({
    required this.type,
    required this.foods,
    required this.busyFoodId,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return _EmptyHistoryState(type: type);
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
        final FoodRecord foodRecord = FoodRecord(food);

        return _HistoryFoodCard(
          type: type,
          food: food,
          foodRecord: foodRecord,
          isBusy: busyFoodId == foodRecord.id,
          onOpenDetail: () => onOpenDetail(food),
          onEdit: () => onEdit(food),
          onDelete: () => onDelete(food),
        );
      },
    );
  }
}

class _HistoryFoodCard extends StatelessWidget {
  final _HistoryType type;
  final Map<String, dynamic> food;
  final FoodRecord foodRecord;
  final bool isBusy;
  final VoidCallback onOpenDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HistoryFoodCard({
    required this.type,
    required this.food,
    required this.foodRecord,
    required this.isBusy,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onDelete,
  });

  bool get _isDonation {
    return type == _HistoryType.donation;
  }

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.x2),
      onTap: isBusy ? null : onOpenDetail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppNetworkImage.food(
                imageUrl: foodRecord.photoUrl,
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
                      foodRecord.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      foodRecord.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    
                    const SizedBox(height: AppSpacing.x1),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusPill.fromFoodStatus(foodRecord.status),
                        StatusPill(
                          icon: Icons.inventory_2_outlined,
                          label: '${foodRecord.quantity} porsi',
                          color: AppColors.teal,
                        ),
                        HalalBadge(isHalal: foodRecord.isHalal),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),

Row(
  children: [
    Expanded(
      child: ElevatedButton.icon(
        onPressed: isBusy ? null : onOpenDetail,
        icon: const Icon(Icons.visibility_outlined),
        label: const Text('Detail'),
      ),
    ),

    const SizedBox(width: AppSpacing.x1),

    Expanded(
      child: ElevatedButton.icon(
        onPressed: isBusy ? null : onDelete,
        icon: isBusy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.delete_outline),
        label: const Text('Batalkan'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  ],
),
        ],
      ),
    );
  }
}

class _HistoryMetaPanel extends StatelessWidget {
  final String category;
  final String expiredAtLabel;
  final String address;

  const _HistoryMetaPanel({
    required this.category,
    required this.expiredAtLabel,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard.soft(
      padding: const EdgeInsets.all(AppSpacing.x1),
      borderRadius: AppRadius.lg,
      child: Column(
        children: [
          _MetaLine(icon: Icons.category_outlined, label: category),
          const SizedBox(height: 6),
          _MetaLine(icon: Icons.schedule_rounded, label: expiredAtLabel),
          const SizedBox(height: 6),
          _MetaLine(icon: Icons.place_outlined, label: address),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaLine({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryDark),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  final _HistoryType type;

  const _EmptyHistoryState({required this.type});

  @override
  Widget build(BuildContext context) {
    final bool isDonation = type == _HistoryType.donation;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x3),
      children: [
        const SizedBox(height: AppSpacing.x5),
        AppEmptyState(
          icon: isDonation
              ? Icons.volunteer_activism_outlined
              : Icons.shopping_bag_outlined,
          title: isDonation ? 'Belum Ada Donasi' : 'Belum Ada Klaim',
          message: isDonation
              ? 'Postingan makanan yang Anda buat akan muncul di sini.'
              : 'Makanan yang Anda klaim akan muncul di sini.',
        ),
      ],
    );
  }
}

class _HistorySkeletonPage extends StatelessWidget {
  const _HistorySkeletonPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x3),
          child: Column(
            children: [
              const ShimmerBox(height: 180, borderRadius: AppRadius.xl),
              const SizedBox(height: AppSpacing.x2),
              const ShimmerBox(height: 64, borderRadius: AppRadius.xl),
              const SizedBox(height: AppSpacing.x2),
              Expanded(
                child: ListView.separated(
                  itemCount: 4,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: AppSpacing.x2);
                  },
                  itemBuilder: (context, index) {
                    return const ShimmerBox(
                      height: 190,
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
