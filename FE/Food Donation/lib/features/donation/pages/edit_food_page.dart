import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/food_mapper.dart';
import '../../../data/services/food_service.dart';
import '../../../shared/widgets/common/app_bottom_sheet_handle.dart';
import '../../../shared/widgets/common/app_info_panel.dart';
import '../../../shared/widgets/common/app_metric_tile.dart';
import '../../../shared/widgets/common/app_section_card.dart';
import '../../../shared/widgets/common/app_surface_card.dart';
import '../../../shared/widgets/maps/map_marker_shell.dart';
import '../../../shared/widgets/media/app_network_image.dart';
import 'pick_location_page.dart';

enum EditFoodCategory {
  heavyMeal,
  drink,
  grocery,
  snack,
}

enum EditFoodCondition {
  fresh,
  consumeSoon,
  compost,
}

class EditFoodPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> food;

  const EditFoodPage({
    super.key,
    required this.token,
    required this.food,
  });

  @override
  State<EditFoodPage> createState() => _EditFoodPageState();
}

class _EditFoodPageState extends State<EditFoodPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  XFile? _selectedImage;
  Uint8List? _imagePreviewBytes;
  ImageOptimizationResult? _optimizationResult;

  late int _foodId;
  late int _quantity;
  late bool _isHalal;
  late double _latitude;
  late double _longitude;
  late DateTime _expiredAt;
  late EditFoodCategory _selectedCategory;
  late EditFoodCondition _selectedCondition;
  late String? _existingImageUrl;

  bool _isPickingImage = false;
  bool _isOptimizingImage = false;
  bool _isSubmitting = false;

  LatLng get _selectedLatLng {
    return LatLng(
      _latitude,
      _longitude,
    );
  }

  String get _coordinateDisplay {
    return '${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}';
  }

  String get _expiredAtDisplay {
    return '${_twoDigits(_expiredAt.day)}/${_twoDigits(_expiredAt.month)}/${_expiredAt.year} '
        '${_twoDigits(_expiredAt.hour)}:${_twoDigits(_expiredAt.minute)}';
  }

  String get _categoryApiValue {
    switch (_selectedCategory) {
      case EditFoodCategory.heavyMeal:
        return 'makanan berat';
      case EditFoodCategory.drink:
        return 'minuman';
      case EditFoodCategory.grocery:
        return 'sembako';
      case EditFoodCategory.snack:
        return 'kue snack';
    }
  }

  String get _conditionApiValue {
    switch (_selectedCondition) {
      case EditFoodCondition.fresh:
        return 'tahan lama segar';
      case EditFoodCondition.consumeSoon:
        return 'segera dihabiskan';
      case EditFoodCondition.compost:
        return 'basi kompos';
    }
  }

  IconData get _markerIcon {
    return MapMarkerStyle.iconFromCategory(
      _categoryApiValue,
    );
  }

  Color get _markerColor {
    return MapMarkerStyle.colorFromCondition(
      _conditionApiValue,
    );
  }

  @override
  void initState() {
    super.initState();

    final FoodRecord foodRecord = FoodRecord(widget.food);

    _foodId = foodRecord.id ?? 0;
    _quantity = foodRecord.quantity < 1 ? 1 : foodRecord.quantity;
    _isHalal = foodRecord.isHalal;
    _latitude = foodRecord.latitude ?? -6.9733;
    _longitude = foodRecord.longitude ?? 107.6300;
    _expiredAt = foodRecord.expiredAt ??
        DateTime.now().add(
          const Duration(hours: 3),
        );
    _selectedCategory = _categoryFromText(foodRecord.category);
    _selectedCondition = _conditionFromText(foodRecord.condition);
    _existingImageUrl = foodRecord.photoUrl;

    _foodNameController.text = foodRecord.name;
    _descriptionController.text = foodRecord.description;
    _addressController.text = foodRecord.address == 'Alamat belum tersedia.'
        ? _coordinateDisplay
        : foodRecord.address;
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  EditFoodCategory _categoryFromText(String value) {
    final String text = value.toLowerCase();

    if (_containsAny(text, [
      'minuman',
      'drink',
      'beverage',
      'teh',
      'kopi',
      'susu',
      'jus',
      'juice',
    ])) {
      return EditFoodCategory.drink;
    }

    if (_containsAny(text, [
      'sembako',
      'grocery',
      'beras',
      'minyak',
      'mie',
      'gula',
      'tepung',
    ])) {
      return EditFoodCategory.grocery;
    }

    if (_containsAny(text, [
      'kue',
      'snack',
      'roti',
      'cake',
      'cemilan',
      'camilan',
      'biskuit',
    ])) {
      return EditFoodCategory.snack;
    }

    return EditFoodCategory.heavyMeal;
  }

  EditFoodCondition _conditionFromText(String value) {
    final String text = value.toLowerCase();

    if (_containsAny(text, [
      'segera',
      'cepat habis',
      'consume soon',
      'kuning',
      'hari ini',
      'mendekati expired',
    ])) {
      return EditFoodCondition.consumeSoon;
    }

    if (_containsAny(text, [
      'basi',
      'kompos',
      'compost',
      'pakan',
      'animal feed',
      'merah',
    ])) {
      return EditFoodCondition.compost;
    }

    return EditFoodCondition.fresh;
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  Future<void> _pickImage() async {
    if (_isPickingImage || _isSubmitting) return;

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

    if (source == null) return;
    if (!mounted) return;

    setState(() {
      _isPickingImage = true;
      _isOptimizingImage = false;
    });

    XFile? image;

    try {
      image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 92,
      );
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal memilih gambar: $error',
        isError: true,
      );
    }

    if (!mounted) return;

    if (image == null) {
      setState(() {
        _isPickingImage = false;
        _isOptimizingImage = false;
      });

      return;
    }

    try {
      final Uint8List previewBytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _imagePreviewBytes = previewBytes;
        _optimizationResult = null;
        _isPickingImage = false;
        _isOptimizingImage = true;
      });

      final ImageOptimizationResult optimization =
          await FoodService.optimizeImageForUpload(image);

      if (!mounted) return;

      setState(() {
        _optimizationResult = optimization;
        _isOptimizingImage = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isPickingImage = false;
        _isOptimizingImage = false;
      });

      _showSnack(
        'Gagal membaca gambar: $error',
        isError: true,
      );
    }
  }

  Future<void> _pickExpiredAt() async {
    if (_isSubmitting) return;

    final DateTime now = DateTime.now();
    final DateTime maxTime = now.add(
      const Duration(days: 3),
    );

    DateTime initialDate = _expiredAt.isBefore(now) ? now : _expiredAt;

    if (initialDate.isAfter(maxTime)) {
      initialDate = maxTime;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(
        now.year,
        now.month,
        now.day,
      ),
      lastDate: DateTime(
        maxTime.year,
        maxTime.month,
        maxTime.day,
      ),
      helpText: 'Pilih Tanggal Batas Pengambilan',
    );

    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiredAt),
      helpText: 'Pilih Waktu Batas Pengambilan',
    );

    if (pickedTime == null) return;

    final DateTime combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (combined.isBefore(now)) {
      _showSnack(
        'Batas waktu tidak boleh di masa lalu.',
        isError: true,
      );
      return;
    }

    setState(() {
      _expiredAt = combined;
    });
  }

  Future<void> _openPickLocationPage() async {
    if (_isSubmitting) return;

    final LatLng? selectedLocation = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => PickLocationPage(
          initialLocation: _selectedLatLng,
        ),
      ),
    );

    if (selectedLocation == null || !mounted) return;

    setState(() {
      _latitude = selectedLocation.latitude;
      _longitude = selectedLocation.longitude;
      _addressController.text = _coordinateDisplay;
    });
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    if (_foodId <= 0) {
      _showSnack(
        'ID makanan tidak valid.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      ImageOptimizationResult? optimization;

      if (_selectedImage != null) {
        optimization = _optimizationResult ??
            await FoodService.optimizeImageForUpload(_selectedImage!);
      }

      final Map<String, dynamic> response = await FoodService.updateFood(
        token: widget.token,
        foodId: _foodId,
        foodName: _foodNameController.text,
        description: _descriptionController.text,
        quantity: _quantity,
        latitude: _latitude,
        longitude: _longitude,
        address: _addressController.text,
        expiredAt: _expiredAt.toIso8601String(),
        image: _selectedImage,
        optimizedImage: optimization,
        category: _categoryApiValue,
        isHalal: _isHalal,
        condition: _conditionApiValue,
      );

      if (!mounted) return;

      final bool isSuccess = response['success'] != false;

      if (!isSuccess) {
        _showSnack(
          FoodService.messageOf(
            response,
            fallback: 'Gagal memperbarui makanan.',
          ),
          isError: true,
        );

        setState(() {
          _isSubmitting = false;
        });

        return;
      }

      _showSnack(
        'Postingan makanan berhasil diperbarui.',
        isError: false,
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showSnack(
        'Gagal memperbarui makanan: $error',
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

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _categoryLabel(EditFoodCategory category) {
    switch (category) {
      case EditFoodCategory.heavyMeal:
        return 'Makanan Berat';
      case EditFoodCategory.drink:
        return 'Minuman';
      case EditFoodCategory.grocery:
        return 'Sembako';
      case EditFoodCategory.snack:
        return 'Kue/Snack';
    }
  }

  String _conditionLabel(EditFoodCondition condition) {
    switch (condition) {
      case EditFoodCondition.fresh:
        return 'Tahan Lama';
      case EditFoodCondition.consumeSoon:
        return 'Segera Dihabiskan';
      case EditFoodCondition.compost:
        return 'Basi/Kompos';
    }
  }

  String _conditionDescription(EditFoodCondition condition) {
    switch (condition) {
      case EditFoodCondition.fresh:
        return 'Kondisi segar dan relatif aman untuk disimpan lebih lama.';
      case EditFoodCondition.consumeSoon:
        return 'Sebaiknya segera diambil dan dikonsumsi hari ini.';
      case EditFoodCondition.compost:
        return 'Tidak disarankan untuk konsumsi manusia.';
    }
  }

  Color _conditionColor(EditFoodCondition condition) {
    switch (condition) {
      case EditFoodCondition.fresh:
        return AppColors.primary;
      case EditFoodCondition.consumeSoon:
        return AppColors.accent;
      case EditFoodCondition.compost:
        return AppColors.danger;
    }
  }

  IconData _categoryIcon(EditFoodCategory category) {
    switch (category) {
      case EditFoodCategory.heavyMeal:
        return Icons.restaurant_rounded;
      case EditFoodCategory.drink:
        return Icons.local_drink_rounded;
      case EditFoodCategory.grocery:
        return Icons.inventory_2_rounded;
      case EditFoodCategory.snack:
        return Icons.bakery_dining_rounded;
    }
  }

  IconData _conditionIcon(EditFoodCondition condition) {
    switch (condition) {
      case EditFoodCondition.fresh:
        return Icons.check_circle_rounded;
      case EditFoodCondition.consumeSoon:
        return Icons.schedule_rounded;
      case EditFoodCondition.compost:
        return Icons.warning_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasNewImage = _imagePreviewBytes != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Donasi'),
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
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppInfoPanel.surface(
                        icon: Icons.edit_note_rounded,
                        color: AppColors.primary,
                        title: 'Edit Donasi Makanan',
                        description:
                            'Perbarui data makanan tanpa menghilangkan sinkronisasi filter, peta, dan status pickup.',
                      ),
                      const SizedBox(height: AppSpacing.x3),
                      AppSectionCard(
                        title: 'Foto Makanan',
                        subtitle: hasNewImage
                            ? 'Foto baru akan menggantikan foto sebelumnya.'
                            : 'Biarkan kosong jika tidak ingin mengganti foto.',
                        icon: Icons.add_photo_alternate_outlined,
                        iconColor: AppColors.accent,
                        iconBackgroundColor: AppColors.accentSoft,
                        child: _ImagePickerBox(
                          imageBytes: _imagePreviewBytes,
                          existingImageUrl: _existingImageUrl,
                          isPicking: _isPickingImage,
                          isOptimizing: _isOptimizingImage,
                          onTap: _pickImage,
                        ),
                      ),
                      if (_optimizationResult != null) ...[
                        const SizedBox(height: AppSpacing.x2),
                        _ImageOptimizationCard(
                          result: _optimizationResult!,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.x2),
                      AppSectionCard(
                        title: 'Informasi Makanan',
                        subtitle:
                            'Perbarui nama, deskripsi, dan jumlah porsi makanan.',
                        icon: Icons.restaurant_menu_rounded,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _foodNameController,
                              enabled: !_isSubmitting,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nama makanan',
                                hintText: 'Contoh: Nasi Box Ayam',
                                prefixIcon:
                                    Icon(Icons.restaurant_menu_rounded),
                              ),
                              validator: (value) {
                                final String foodName = value?.trim() ?? '';

                                if (foodName.isEmpty) {
                                  return 'Nama makanan tidak boleh kosong';
                                }

                                if (foodName.length < 3) {
                                  return 'Nama makanan minimal 3 karakter';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.x2),
                            TextFormField(
                              controller: _descriptionController,
                              enabled: !_isSubmitting,
                              maxLines: 4,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Deskripsi',
                                hintText:
                                    'Jelaskan kondisi, isi paket, dan catatan pengambilan',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.notes_rounded),
                              ),
                              validator: (value) {
                                final String description = value?.trim() ?? '';

                                if (description.isEmpty) {
                                  return 'Deskripsi tidak boleh kosong';
                                }

                                if (description.length < 10) {
                                  return 'Deskripsi minimal 10 karakter';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.x2),
                            _QuantityStepper(
                              quantity: _quantity,
                              onDecrease: _quantity > 1
                                  ? () {
                                      setState(() {
                                        _quantity--;
                                      });
                                    }
                                  : null,
                              onIncrease: () {
                                setState(() {
                                  _quantity++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      AppSectionCard(
                        title: 'Kategori',
                        subtitle:
                            'Kategori memengaruhi ikon marker di peta dan filter Home.',
                        icon: Icons.category_outlined,
                        child: Wrap(
                          spacing: AppSpacing.x1,
                          runSpacing: AppSpacing.x1,
                          children: EditFoodCategory.values.map((item) {
                            return _CategoryChip(
                              selected: _selectedCategory == item,
                              label: _categoryLabel(item),
                              icon: _categoryIcon(item),
                              onSelected: () {
                                setState(() {
                                  _selectedCategory = item;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      AppSectionCard(
                        title: 'Status Halal',
                        subtitle:
                            'Label halal akan tampil pada kartu makanan dan detail makanan.',
                        icon: _isHalal
                            ? Icons.verified_rounded
                            : Icons.warning_amber_rounded,
                        iconColor:
                            _isHalal ? AppColors.primary : AppColors.danger,
                        iconBackgroundColor: _isHalal
                            ? AppColors.primarySoft
                            : AppColors.dangerSoft,
                        child: _HalalSwitchTile(
                          isHalal: _isHalal,
                          onChanged: (value) {
                            setState(() {
                              _isHalal = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      AppSectionCard(
                        title: 'Kondisi Kesiapan',
                        subtitle:
                            'Kondisi makanan menentukan warna marker dan prioritas pickup.',
                        icon: Icons.health_and_safety_outlined,
                        child: Column(
                          children: EditFoodCondition.values.map((condition) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.x1,
                              ),
                              child: _ConditionOption(
                                label: _conditionLabel(condition),
                                description: _conditionDescription(condition),
                                icon: _conditionIcon(condition),
                                color: _conditionColor(condition),
                                selected: _selectedCondition == condition,
                                onTap: () {
                                  setState(() {
                                    _selectedCondition = condition;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      AppSectionCard(
                        title: 'Lokasi Pickup',
                        subtitle:
                            'Ubah titik pickup jika lokasi pengambilan berubah.',
                        icon: Icons.map_outlined,
                        child: Column(
                          children: [
                            _MiniMapPreview(
                              location: _selectedLatLng,
                              markerColor: _markerColor,
                              markerIcon: _markerIcon,
                              categoryLabel: _categoryLabel(_selectedCategory),
                              conditionLabel:
                                  _conditionLabel(_selectedCondition),
                            ),
                            const SizedBox(height: AppSpacing.x2),
                            TextFormField(
                              controller: _addressController,
                              readOnly: true,
                              enabled: !_isSubmitting,
                              onTap: _openPickLocationPage,
                              decoration: const InputDecoration(
                                labelText: 'Koordinat / alamat pickup',
                                hintText: 'Pilih lokasi pickup',
                                prefixIcon: Icon(Icons.location_on_outlined),
                                suffixIcon: Icon(Icons.map_rounded),
                              ),
                              validator: (value) {
                                final String address = value?.trim() ?? '';

                                if (address.isEmpty) {
                                  return 'Lokasi pickup belum dipilih';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.x2),
                            SizedBox(
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed:
                                    _isSubmitting ? null : _openPickLocationPage,
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('Ubah Titik Lokasi'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      AppSectionCard(
                        title: 'Batas Pengambilan',
                        subtitle:
                            'Pastikan batas waktu masih masuk akal bagi penerima.',
                        icon: Icons.schedule_rounded,
                        iconColor: AppColors.accent,
                        iconBackgroundColor: AppColors.accentSoft,
                        child: _DatePickerTile(
                          expiredAtDisplay: _expiredAtDisplay,
                          onTap: _pickExpiredAt,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x3),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            _isSubmitting ? 'Menyimpan...' : 'Simpan Perubahan',
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ImagePickerBox extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? existingImageUrl;
  final bool isPicking;
  final bool isOptimizing;
  final VoidCallback onTap;

  const _ImagePickerBox({
    required this.imageBytes,
    required this.existingImageUrl,
    required this.isPicking,
    required this.isOptimizing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBusy = isPicking || isOptimizing;

    return InkWell(
      onTap: isBusy ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        height: 216,
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageBytes != null)
                Image.memory(
                  imageBytes!,
                  fit: BoxFit.cover,
                )
              else
                AppNetworkImage.food(
                  imageUrl: existingImageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: AppRadius.lg,
                ),
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
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Ganti Foto',
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
    );
  }
}

class _ImageOptimizationCard extends StatelessWidget {
  final ImageOptimizationResult result;

  const _ImageOptimizationCard({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppInlineInfoPanel.info(
            icon: Icons.network_check_rounded,
            message:
                'Foto baru melewati simulasi kompresi untuk analisis bandwidth upload.',
          ),
          const SizedBox(height: AppSpacing.x2),
          Row(
            children: [
              Expanded(
                child: AppMetricTile.compact(
                  label: 'Original',
                  value: result.originalSizeLabel,
                  icon: Icons.photo_size_select_actual_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: AppMetricTile.compact(
                  label: 'Upload',
                  value: result.estimatedUploadSizeLabel,
                  icon: Icons.cloud_upload_outlined,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: AppMetricTile.compact(
                  label: 'Hemat',
                  value:
                      '${result.estimatedSavedPercent.toStringAsFixed(1)}%',
                  icon: Icons.compress_rounded,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onSelected;

  const _CategoryChip({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
      ),
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? Colors.white : AppColors.primaryDark,
      ),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? Colors.white : AppColors.primaryDark,
          ),
      onSelected: (_) => onSelected(),
    );
  }
}

class _HalalSwitchTile extends StatelessWidget {
  final bool isHalal;
  final ValueChanged<bool> onChanged;

  const _HalalSwitchTile({
    required this.isHalal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Color identityColor =
        isHalal ? AppColors.primary : AppColors.danger;

    return AppSurfaceCard.soft(
      padding: const EdgeInsets.all(AppSpacing.x2),
      borderRadius: AppRadius.lg,
      borderColor: identityColor.withValues(alpha: 0.22),
      backgroundColor: identityColor.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(
            isHalal ? Icons.verified_rounded : Icons.warning_amber_rounded,
            color: identityColor,
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Text(
              isHalal ? 'Halal' : 'Non-Halal',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: identityColor,
                  ),
            ),
          ),
          Switch(
            value: isHalal,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.32),
            inactiveThumbColor: AppColors.danger,
            inactiveTrackColor: AppColors.danger.withValues(alpha: 0.22),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ConditionOption extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ConditionOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard.soft(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.x2),
      borderRadius: AppRadius.lg,
      backgroundColor:
          selected ? color.withValues(alpha: 0.12) : AppColors.surfaceSoft,
      borderColor: selected ? color : AppColors.border,
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (selected)
            Icon(
              Icons.check_circle_rounded,
              color: color,
            ),
        ],
      ),
    );
  }
}

class _MiniMapPreview extends StatelessWidget {
  final LatLng location;
  final Color markerColor;
  final IconData markerIcon;
  final String categoryLabel;
  final String conditionLabel;

  const _MiniMapPreview({
    required this.location,
    required this.markerColor,
    required this.markerIcon,
    required this.categoryLabel,
    required this.conditionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 214,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          children: [
            FlutterMap(
              key: ValueKey(
                '${location.latitude}-${location.longitude}-$categoryLabel-$conditionLabel',
              ),
              options: MapOptions(
                initialCenter: location,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.food_donation_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 72,
                      height: 72,
                      point: location,
                      child: MapMarkerShell(
                        color: markerColor,
                        icon: markerIcon,
                        size: MapMarkerShellSize.medium,
                        tooltip: '$categoryLabel • $conditionLabel',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: AppSpacing.x1,
              right: AppSpacing.x1,
              bottom: AppSpacing.x1,
              child: AppSurfaceCard(
                padding: const EdgeInsets.all(AppSpacing.x1),
                borderRadius: AppRadius.lg,
                backgroundColor: AppColors.surface.withValues(alpha: 0.94),
                child: Row(
                  children: [
                    Expanded(
                      child: _MapLegendPill(
                        icon: markerIcon,
                        color: AppColors.primaryDark,
                        label: categoryLabel,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _MapLegendPill(
                        icon: Icons.circle,
                        color: markerColor,
                        label: conditionLabel,
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

class _MapLegendPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _MapLegendPill({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x1,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard.soft(
      padding: const EdgeInsets.all(AppSpacing.x2),
      borderRadius: AppRadius.lg,
      child: Row(
        children: [
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$quantity',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  'porsi tersedia',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String expiredAtDisplay;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.expiredAtDisplay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard.soft(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.x2),
      borderRadius: AppRadius.md,
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: AppColors.accent,
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Text(
              expiredAtDisplay,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Icon(
            Icons.edit_calendar_rounded,
            color: AppColors.primaryDark,
          ),
        ],
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
                'Pilih Sumber Foto',
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