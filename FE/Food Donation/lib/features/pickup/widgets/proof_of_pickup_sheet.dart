import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/food_service.dart';
import '../../../shared/widgets/common/app_bottom_sheet_handle.dart';
import '../../../shared/widgets/common/app_info_panel.dart';
import '../../../shared/widgets/common/app_surface_card.dart';

class ProofOfPickupSheet extends StatefulWidget {
  final String token;
  final int foodId;
  final String foodName;

  const ProofOfPickupSheet({
    super.key,
    required this.token,
    required this.foodId,
    required this.foodName,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String token,
    required int foodId,
    required String foodName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ProofOfPickupSheet(
          token: token,
          foodId: foodId,
          foodName: foodName,
        );
      },
    );
  }

  @override
  State<ProofOfPickupSheet> createState() => _ProofOfPickupSheetState();
}

class _ProofOfPickupSheetState extends State<ProofOfPickupSheet> {
  XFile? _proofImage;
  Uint8List? _previewBytes;
  ProofImageOptimizationResult? _optimization;

  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool _isCapturing = false;
  bool _isCompressing = false;
  bool _isSubmitting = false;
  bool _isSuccess = false;

  bool get _isBusy {
    return _isCapturing || _isCompressing || _isSubmitting;
  }

  Future<void> _captureProofPhoto() async {
    if (_isCapturing || _isSubmitting) return;

    setState(() {
      _isCapturing = true;
      _isCompressing = false;
      _isSuccess = false;
    });

    XFile? image;

    try {
      image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 42,
      );
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal membuka kamera: $error',
        isError: true,
      );
    }

    if (!mounted) return;

    if (image == null) {
      setState(() {
        _isCapturing = false;
        _isCompressing = false;
      });

      return;
    }

    try {
      final Uint8List previewBytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _proofImage = image;
        _previewBytes = previewBytes;
        _optimization = null;
        _isCapturing = false;
        _isCompressing = true;
      });

      final ProofImageOptimizationResult optimization =
          await FoodService.optimizePickupProofImage(image);

      if (!mounted) return;

      setState(() {
        _optimization = optimization;
        _isCompressing = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isCapturing = false;
        _isCompressing = false;
      });

      _showSnack(
        'Gagal membaca bukti foto: $error',
        isError: true,
      );
    }
  }

  Future<void> _submitProof() async {
    if (_isSubmitting) return;

    if (_proofImage == null) {
      _showSnack(
        'Ambil bukti foto terlebih dahulu.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isSuccess = false;
    });

    try {
      final ProofImageOptimizationResult optimization =
          _optimization ?? await FoodService.optimizePickupProofImage(_proofImage!);

      final Map<String, dynamic> response =
          await FoodService.completePickupWithProof(
        token: widget.token,
        foodId: widget.foodId,
        proofImage: _proofImage!,
        optimizedProof: optimization,
        claimerNote: _noteController.text.trim(),
      );

      if (!mounted) return;

      if (response['success'] == false) {
        _showSnack(
          FoodService.messageOf(
            response,
            fallback: 'Gagal menyelesaikan pengambilan.',
          ),
          isError: true,
        );

        setState(() {
          _isSubmitting = false;
        });

        return;
      }

      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
      });

      await Future<void>.delayed(
        const Duration(milliseconds: 900),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showSnack(
        'Gagal mengunggah bukti pengambilan: $error',
        isError: true,
      );
    }
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
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  0,
                  AppSpacing.x3,
                  AppSpacing.x3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppBottomSheetHandle(),
                    _HeaderCard(
                      foodName: widget.foodName,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    if (_isSuccess)
                      const _SuccessStateCard()
                    else ...[
                      _CameraProofBox(
                        previewBytes: _previewBytes,
                        isBusy: _isBusy,
                        onCapture: _captureProofPhoto,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      const AppInfoPanel.info(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Ramah Privasi',
                        description:
                            'Tidak perlu foto wajah. Cukup foto makanan atau tangan Anda yang sedang menerima makanan sebagai bukti.',
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      TextFormField(
                        controller: _noteController,
                        enabled: !_isSubmitting,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Pesan / Catatan untuk Donatur',
                          hintText: 'Tulis ucapan terima kasih atau pesan lainnya...',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.rate_review_outlined),
                        ),
                      ),
                      if (_isCompressing) ...[
                        const SizedBox(height: AppSpacing.x2),
                        const AppInlineInfoPanel.info(
                          icon: Icons.compress_rounded,
                          message:
                              'Menjalankan simulasi kompresi ekstrem bukti foto...',
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  AppSpacing.x2,
                  AppSpacing.x3,
                  AppSpacing.x3,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x1),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isBusy || _isSuccess ? null : _submitProof,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : const Icon(Icons.verified_rounded),
                          label: Text(
                            _isSubmitting ? 'Mengunggah...' : 'Selesaikan',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String foodName;

  const _HeaderCard({
    required this.foodName,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.x3),
      backgroundColor: AppColors.primary,
      borderColor: AppColors.primary,
      boxShadow: AppShadows.brand,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selesaikan Pengambilan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  foodName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraProofBox extends StatelessWidget {
  final Uint8List? previewBytes;
  final bool isBusy;
  final VoidCallback onCapture;

  const _CameraProofBox({
    required this.previewBytes,
    required this.isBusy,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.x2),
      child: InkWell(
        onTap: isBusy ? null : onCapture,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          height: 236,
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (previewBytes != null)
                  Image.memory(
                    previewBytes!,
                    fit: BoxFit.cover,
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: const Icon(
                          Icons.photo_camera_rounded,
                          color: AppColors.accent,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        'Ambil Bukti Foto',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kamera langsung, bukan galeri.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                if (previewBytes != null)
                  Positioned(
                    right: AppSpacing.x1,
                    bottom: AppSpacing.x1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.x2,
                          vertical: AppSpacing.x1,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.photo_camera_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Ambil Ulang',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (isBusy)
                  ColoredBox(
                    color: Colors.black.withValues(alpha: 0.38),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessStateCard extends StatelessWidget {
  const _SuccessStateCard();

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.x4),
      backgroundColor: AppColors.primarySoft,
      borderColor: AppColors.primary.withValues(alpha: 0.22),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0.7,
              end: 1,
            ),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.brand,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            'Pengambilan Selesai',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            'Bukti foto berhasil diproses. Status makanan berubah menjadi Selesai/Terklaim.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}