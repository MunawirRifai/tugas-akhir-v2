import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/food_mapper.dart';
import '../../../data/services/food_service.dart';
import '../../../shared/widgets/badges/halal_badge.dart';
import '../../../shared/widgets/badges/status_pill.dart';
import '../../../shared/widgets/common/app_info_panel.dart';
import '../../../shared/widgets/common/app_metric_tile.dart';
import '../../../shared/widgets/common/app_surface_card.dart';
import '../../../shared/widgets/media/app_network_image.dart';
import '../../pickup/widgets/proof_of_pickup_sheet.dart';
import 'edit_food_page.dart';

class FoodDetailPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> food;
  final int? currentUserId;
  final String? distanceLabel;

  const FoodDetailPage({
    super.key,
    required this.token,
    required this.food,
    this.currentUserId,
    this.distanceLabel,
  });

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  late Map<String, dynamic> _food;

  bool _isDeleting = false;
  bool _isActionBusy = false;

  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;

  FoodRecord get _foodRecord {
    return FoodRecord(_food);
  }

  bool get _isOwnedByCurrentUser {
    final int? ownerId = _foodRecord.userId;

    return ownerId != null &&
        widget.currentUserId != null &&
        ownerId == widget.currentUserId;
  }

  bool get _isClaimedByCurrentUser {
    final int? claimedBy = _foodRecord.claimedBy;

    return claimedBy != null &&
        widget.currentUserId != null &&
        claimedBy == widget.currentUserId;
  }

  bool get _canEdit {
    return _isOwnedByCurrentUser && _foodRecord.isEditable;
  }

  bool get _canDelete {
    return _isOwnedByCurrentUser && _foodRecord.isDeleteAllowed;
  }

  bool get _canCompletePickup {
    return _foodRecord.isOnTheWay && _isClaimedByCurrentUser;
  }

  @override
  void initState() {
    super.initState();
    _food = Map<String, dynamic>.from(widget.food);
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    final DateTime? claimedAt = FoodMapper.dateTimeOf(_food['claimed_at']);
    if (claimedAt == null) {
      _remainingTime = Duration.zero;
      return;
    }

    final DateTime targetTime = claimedAt.add(const Duration(minutes: 30));

    void updateRemaining() {
      final DateTime now = DateTime.now();
      final Duration diff = targetTime.difference(now);
      if (diff.isNegative) {
        _remainingTime = Duration.zero;
        _countdownTimer?.cancel();
      } else {
        _remainingTime = diff;
      }
      if (mounted) {
        setState(() {});
      }
    }

    updateRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateRemaining();
    });
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _openEditPage() async {
    if (!_canEdit || _isActionBusy) return;

    final bool? result = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) {
          return EditFoodPage(
            token: widget.token,
            food: _food,
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
      _showSnack(
        'Postingan berhasil diperbarui.',
        isError: false,
      );

      Navigator.of(context).pop(true);
    }
  }

  Future<void> _confirmDelete() async {
    if (!_canDelete || _isDeleting) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Postingan?'),
          content: const Text(
            'Postingan makanan akan dihapus dari daftar donasi. Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _deleteFood();
  }

  Future<void> _deleteFood() async {
    final int? foodId = _foodRecord.id;

    if (foodId == null) {
      _showSnack(
        'ID makanan tidak valid.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await FoodService.deleteFood(
        token: widget.token,
        foodId: foodId,
      );

      if (!mounted) return;

      _showSnack(
        'Postingan berhasil dihapus.',
        isError: false,
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      _showSnack(
        'Gagal menghapus postingan: $error',
        isError: true,
      );
    }
  }

  Future<void> _completePickupWithProof() async {
    final int? foodId = _foodRecord.id;

    if (foodId == null) {
      _showSnack(
        'ID makanan tidak valid.',
        isError: true,
      );
      return;
    }

    final bool? completed = await ProofOfPickupSheet.show(
      context: context,
      token: widget.token,
      foodId: foodId,
      foodName: _foodRecord.name,
    );

    if (completed != true || !mounted) return;

    setState(() {
      _food = {
        ..._food,
        'status': 'PICKED_UP',
      };
    });

    _showSnack(
      'Pengambilan selesai. Bukti foto berhasil diproses.',
      isError: false,
    );

    Navigator.of(context).pop(true);
  }

  Future<void> _cancelPickup() async {
    final int? foodId = _foodRecord.id;

    if (foodId == null) {
      _showSnack(
        'ID makanan tidak valid.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isActionBusy = true;
    });

    try {
      await FoodService.cancelPickup(
        token: widget.token,
        foodId: foodId,
      );

      if (!mounted) return;

      _showSnack(
        'Pengambilan berhasil dibatalkan.',
        isError: false,
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isActionBusy = false;
      });

      _showSnack(
        'Gagal membatalkan pengambilan: $error',
        isError: true,
      );
    }
  }

  void _showMockCommunication(String featureName) {
    _showSnack(
      '$featureName akan dihubungkan pada tahap komunikasi in-app.',
      isError: false,
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
    final FoodRecord foodRecord = _foodRecord;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Makanan'),
        actions: [
          if (_canEdit)
            IconButton(
              tooltip: 'Edit postingan',
              onPressed: _isActionBusy || _isDeleting ? null : _openEditPage,
              icon: const Icon(Icons.edit_rounded),
            ),
          if (_canDelete)
            IconButton(
              tooltip: 'Hapus postingan',
              onPressed: _isActionBusy || _isDeleting ? null : _confirmDelete,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.x3),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.x6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FoodHeroSection(
                      imageUrl: foodRecord.photoUrl,
                      heroTag: 'food-detail-${foodRecord.id ?? 'unknown'}',
                      status: foodRecord.status,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    _TitleSection(
                      name: foodRecord.name,
                      description: foodRecord.description,
                      isHalal: foodRecord.isHalal,
                      status: foodRecord.status,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    _MetaGrid(
                      quantity: foodRecord.quantity,
                      category: foodRecord.category,
                      condition: foodRecord.condition,
                      distanceLabel: widget.distanceLabel ?? '-',
                      expiredAtLabel: foodRecord.expiredAtLabel,
                      status: foodRecord.status,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    AppInfoPanel.surface(
                      icon: Icons.place_outlined,
                      title: 'Lokasi Pengambilan',
                      description: foodRecord.address,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    AppInfoPanel.surface(
                      icon: Icons.location_on_outlined,
                      title: 'Koordinat',
                      description: foodRecord.coordinateLabel,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    _CommunicationPanel(
                      onChatTap: () => _showMockCommunication('Chat room'),
                      onAudioTap: () => _showMockCommunication('Audio call'),
                      onVideoTap: () => _showMockCommunication('Video call'),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    _OwnershipNotice(
                      isOwnedByCurrentUser: _isOwnedByCurrentUser,
                      isClaimedByCurrentUser: _isClaimedByCurrentUser,
                      status: foodRecord.status,
                      remainingTime: _remainingTime,
                      hasClaimedAt: _food['claimed_at'] != null,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    _ActionSection(
                      canEdit: _canEdit,
                      canDelete: _canDelete,
                      canCompletePickup: _canCompletePickup,
                      isBusy: _isActionBusy || _isDeleting,
                      onEdit: _openEditPage,
                      onDelete: _confirmDelete,
                      onCompletePickup: _completePickupWithProof,
                      onCancelPickup: _canCompletePickup ? _cancelPickup : null,
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

class _FoodHeroSection extends StatelessWidget {
  final String? imageUrl;
  final String heroTag;
  final String status;

  const _FoodHeroSection({
    required this.imageUrl,
    required this.heroTag,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppNetworkImage.food(
          imageUrl: imageUrl,
          width: double.infinity,
          height: 250,
          borderRadius: AppRadius.xl,
          heroTag: heroTag,
        ),
        Positioned(
          left: AppSpacing.x2,
          top: AppSpacing.x2,
          child: StatusPill.fromFoodStatus(
            status,
            isLarge: true,
            showBorder: true,
          ),
        ),
      ],
    );
  }
}

class _TitleSection extends StatelessWidget {
  final String name;
  final String description;
  final bool isHalal;
  final String status;

  const _TitleSection({
    required this.name,
    required this.description,
    required this.isHalal,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.x1),
          Wrap(
            spacing: AppSpacing.x1,
            runSpacing: AppSpacing.x1,
            children: [
              HalalBadge(
                isHalal: isHalal,
                isLarge: true,
              ),
              StatusPill.fromFoodStatus(
                status,
                isLarge: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _MetaGrid extends StatelessWidget {
  final int quantity;
  final String category;
  final String condition;
  final String distanceLabel;
  final String expiredAtLabel;
  final String status;

  const _MetaGrid({
    required this.quantity,
    required this.category,
    required this.condition,
    required this.distanceLabel,
    required this.expiredAtLabel,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return AppMetricGrid(
      crossAxisCount: 2,
      childAspectRatio: 1.55,
      children: [
        AppMetricTile.compact(
          icon: Icons.inventory_2_outlined,
          label: 'Porsi',
          value: '$quantity porsi',
          color: AppColors.teal,
          valueMaxLines: 2,
        ),
        AppMetricTile.compact(
          icon: Icons.category_outlined,
          label: 'Kategori',
          value: category,
          color: AppColors.primary,
          valueMaxLines: 2,
        ),
        AppMetricTile.compact(
          icon: Icons.radar_rounded,
          label: 'Jarak',
          value: distanceLabel,
          color: AppColors.primaryDark,
          valueMaxLines: 2,
        ),
        AppMetricTile.compact(
          icon: Icons.schedule_rounded,
          label: 'Batas Waktu',
          value: expiredAtLabel,
          color: AppColors.accent,
          valueMaxLines: 2,
        ),
        AppMetricTile.compact(
          icon: Icons.health_and_safety_outlined,
          label: 'Kondisi',
          value: condition,
          color: _conditionColor(condition),
          valueMaxLines: 2,
        ),
        AppMetricTile.compact(
          icon: Icons.fact_check_outlined,
          label: 'Status',
          value: FoodMapper.statusLabel(status),
          color: _statusColor(status),
          valueMaxLines: 2,
        ),
      ],
    );
  }

  Color _conditionColor(String condition) {
    final String text = condition.toLowerCase();

    if (text.contains('segera') ||
        text.contains('consume') ||
        text.contains('kuning')) {
      return AppColors.accent;
    }

    if (text.contains('kompos') ||
        text.contains('pakan') ||
        text.contains('basi') ||
        text.contains('merah')) {
      return AppColors.danger;
    }

    return AppColors.primary;
  }

  Color _statusColor(String status) {
    final String normalizedStatus = status.toUpperCase();

    switch (normalizedStatus) {
      case 'ON_THE_WAY':
        return AppColors.teal;
      case 'PICKED_UP':
      case 'COMPLETED':
      case 'CLAIMED':
        return AppColors.textMuted;
      case 'CANCELED':
      case 'CANCELLED':
        return AppColors.danger;
      case 'POSTED':
      case 'AVAILABLE':
      default:
        return AppColors.primary;
    }
  }
}

class _CommunicationPanel extends StatelessWidget {
  final VoidCallback onChatTap;
  final VoidCallback onAudioTap;
  final VoidCallback onVideoTap;

  const _CommunicationPanel({
    required this.onChatTap,
    required this.onAudioTap,
    required this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Komunikasi In-App',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.x1),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChatTap,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Chat'),
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAudioTap,
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Audio'),
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onVideoTap,
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Video'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnershipNotice extends StatelessWidget {
  final bool isOwnedByCurrentUser;
  final bool isClaimedByCurrentUser;
  final String status;
  final Duration remainingTime;
  final bool hasClaimedAt;

  const _OwnershipNotice({
    required this.isOwnedByCurrentUser,
    required this.isClaimedByCurrentUser,
    required this.status,
    required this.remainingTime,
    required this.hasClaimedAt,
  });

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final String normalizedStatus = status.toUpperCase();

    if (isOwnedByCurrentUser) {
      return const AppInfoPanel.surface(
        icon: Icons.storefront_rounded,
        title: 'Postingan Anda',
        description:
            'Anda dapat mengedit atau menghapus postingan selama status masih memungkinkan.',
        color: AppColors.teal,
      );
    }

    if (isClaimedByCurrentUser && normalizedStatus == 'ON_THE_WAY') {
      final String desc = hasClaimedAt
          ? (remainingTime > Duration.zero
              ? 'Selesaikan pengambilan dengan mengunggah bukti foto setelah makanan diterima. Waktu tersisa: ${_formatDuration(remainingTime)}'
              : 'Waktu pengambilan telah habis.')
          : 'Selesaikan pengambilan dengan mengunggah bukti foto setelah makanan diterima.';
      return AppInfoPanel.warning(
        icon: Icons.shopping_bag_outlined,
        title: 'Sedang Anda Ambil',
        description: desc,
      );
    }

    return const AppInfoPanel.info(
      icon: Icons.info_outline_rounded,
      title: 'Informasi Donasi',
      description:
          'Pastikan data makanan, lokasi, dan batas waktu sudah sesuai sebelum melakukan pickup.',
    );
  }
}

class _ActionSection extends StatelessWidget {
  final bool canEdit;
  final bool canDelete;
  final bool canCompletePickup;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCompletePickup;
  final VoidCallback? onCancelPickup;

  const _ActionSection({
    required this.canEdit,
    required this.canDelete,
    required this.canCompletePickup,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
    required this.onCompletePickup,
    required this.onCancelPickup,
  });

  @override
  Widget build(BuildContext context) {
    if (canCompletePickup) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: isBusy ? null : onCompletePickup,
              icon: const Icon(Icons.fact_check_rounded),
              label: const Text('Selesaikan & Upload Bukti'),
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: isBusy ? null : onCancelPickup,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Batalkan Pengambilan'),
            ),
          ),
        ],
      );
    }

    if (!canEdit && !canDelete) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (canEdit)
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isBusy ? null : onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit'),
              ),
            ),
          ),
        if (canEdit && canDelete) const SizedBox(width: AppSpacing.x1),
        if (canDelete)
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: isBusy ? null : onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Hapus'),
              ),
            ),
          ),
      ],
    );
  }
}