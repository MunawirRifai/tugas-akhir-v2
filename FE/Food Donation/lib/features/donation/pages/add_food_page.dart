import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/food_mapper.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/food_service.dart';
import '../../../shared/widgets/common/app_info_panel.dart';
import '../../../shared/widgets/common/app_section_card.dart';
import '../../../shared/widgets/common/app_surface_card.dart';
import '../../../shared/widgets/maps/map_marker_shell.dart';
import 'pick_location_page.dart';

enum DonationFoodCategory {
  heavyMeal,
  drink,
  grocery,
  snack,
  compost,
}

enum DonationFoodCondition {
  fresh,
  consumeSoon,
  compost,
}

class AddFoodPage extends StatefulWidget {
  final String token;

  const AddFoodPage({
    super.key,
    required this.token,
  });

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final GlobalKey _photoKey = GlobalKey();
  final GlobalKey _nameDescKey = GlobalKey();
  final GlobalKey _addressKey = GlobalKey();
  final GlobalKey _phoneKey = GlobalKey();

  XFile? _selectedImage;
  Uint8List? _imagePreviewBytes;
  ImageOptimizationResult? _optimizationResult;

  DonationFoodCategory _selectedCategory = DonationFoodCategory.heavyMeal;
  DonationFoodCondition _selectedCondition = DonationFoodCondition.fresh;

  int _quantity = 1;
  bool _isHalal = true;
  bool _isPickingImage = false;
  bool _isOptimizingImage = false;
  bool _isGettingLocation = false;
  bool _isSubmitting = false;

  double _latitude = -6.9733;
  double _longitude = 107.6300;

  DateTime _expiredAt = DateTime.now().add(
    const Duration(hours: 3),
  );

  String get _expiredAtDisplay {
    return '${_twoDigits(_expiredAt.day)}/${_twoDigits(_expiredAt.month)}/${_expiredAt.year} '
        '${_twoDigits(_expiredAt.hour)}:${_twoDigits(_expiredAt.minute)}';
  }

  String get _coordinateDisplay {
    return '${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}';
  }

  LatLng get _selectedLatLng {
    return LatLng(
      _latitude,
      _longitude,
    );
  }

  String get _categoryApiValue {
    switch (_selectedCategory) {
      case DonationFoodCategory.heavyMeal:
        return 'makanan berat';
      case DonationFoodCategory.drink:
        return 'minuman';
      case DonationFoodCategory.grocery:
        return 'sembako';
      case DonationFoodCategory.snack:
        return 'kue snack';
      case DonationFoodCategory.compost:
        return 'kompos';
    }
  }

  String get _conditionApiValue {
    switch (_selectedCondition) {
      case DonationFoodCondition.fresh:
        return 'tahan lama segar';
      case DonationFoodCondition.consumeSoon:
        return 'segera dihabiskan';
      case DonationFoodCondition.compost:
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
    _loadUserProfile();
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final Map<String, dynamic> profile = await AuthService.getProfile(widget.token);
      if (!mounted) return;

      final Map<String, dynamic> data = FoodMapper.mapOf(profile['data']);
      final Map<String, dynamic> user = FoodMapper.mapOf(data['user']);
      final Map<String, dynamic> source = user.isNotEmpty ? user : data;

      final String phone = FoodMapper.textOf(
        FoodMapper.valueOf(source, ['phone', 'telephone', 'phone_number']),
        fallback: '',
      );

      setState(() {
        _phoneController.text = phone;
      });
    } catch (error) {
      debugPrint('LOAD USER PROFILE ERROR: $error');
    }
  }

  void _scrollToField(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
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
      const Duration(hours: 6),
    );

    final DateTime firstDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime lastDate = DateTime(
      maxTime.year,
      maxTime.month,
      maxTime.day,
    );

    final DateTime initialDate = _expiredAt.isAfter(maxTime)
        ? lastDate
        : DateTime(
            _expiredAt.year,
            _expiredAt.month,
            _expiredAt.day,
          );

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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

    if (combined.isAfter(maxTime)) {
      _showSnack(
        'Batas waktu maksimal 6 jam dari sekarang.',
        isError: true,
      );
      return;
    }

    setState(() {
      _expiredAt = combined;
    });
  }

  Future<void> _useCurrentLocation() async {
    if (_isGettingLocation || _isSubmitting) return;

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!mounted) return;

      if (!serviceEnabled) {
        setState(() {
          _isGettingLocation = false;
        });

        _showSnack(
          'Location service belum aktif.',
          isError: true,
        );

        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) return;

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isGettingLocation = false;
        });

        _showSnack(
          'Izin lokasi belum diberikan.',
          isError: true,
        );

        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _addressController.text = _coordinateDisplay;
        _isGettingLocation = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isGettingLocation = false;
      });

      _showSnack(
        'Gagal membaca lokasi: $error',
        isError: true,
      );
    }
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
    // 1. Check if photo is chosen
    if (_selectedImage == null) {
      _showSnack('Pilih foto makanan terlebih dahulu.', isError: true);
      _scrollToField(_photoKey);
      return;
    }

    // 2. Validate form fields using _formKey
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      if (_foodNameController.text.trim().isEmpty || _foodNameController.text.trim().length < 3) {
        _showSnack('Nama makanan tidak boleh kosong (minimal 3 karakter).', isError: true);
        _scrollToField(_nameDescKey);
      } else if (_descriptionController.text.trim().isEmpty || _descriptionController.text.trim().length < 10) {
        _showSnack('Deskripsi tidak boleh kosong (minimal 10 karakter).', isError: true);
        _scrollToField(_nameDescKey);
      } else if (_addressController.text.trim().isEmpty) {
        _showSnack('Lokasi pickup belum dipilih.', isError: true);
        _scrollToField(_addressKey);
      } else if (_phoneController.text.trim().isEmpty || _phoneController.text.trim().length < 9) {
        _showSnack('Nomor HP tidak boleh kosong (minimal 9 digit).', isError: true);
        _scrollToField(_phoneKey);
      }
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final ImageOptimizationResult optimization =
          _optimizationResult ??
              await FoodService.optimizeImageForUpload(_selectedImage!);

      final Map<String, dynamic> response = await FoodService.createFood(
        token: widget.token,
        foodName: _foodNameController.text,
        description: _descriptionController.text,
        quantity: _quantity,
        latitude: _latitude,
        longitude: _longitude,
        address: _addressController.text,
        expiredAt: _expiredAt.toIso8601String(),
        image: _selectedImage!,
        optimizedImage: optimization,
        category: _categoryApiValue,
        isHalal: _isHalal,
        condition: _conditionApiValue,
        phone: _phoneController.text,
      );

      if (!mounted) return;

      final bool isSuccess = response['success'] != false;

      if (!isSuccess) {
        _showSnack(
          FoodService.messageOf(
            response,
            fallback: 'Gagal memposting makanan.',
          ),
          isError: true,
        );

        setState(() {
          _isSubmitting = false;
        });

        return;
      }

      await _showSuccessDialog(optimization);

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showSnack(
        'Gagal membuat postingan: $error',
        isError: true,
      );
    }
  }

  Future<void> _showSuccessDialog(
    ImageOptimizationResult optimization,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          contentPadding: const EdgeInsets.all(AppSpacing.x3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 42,
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                'Donasi Berhasil Diposting',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                'Estimasi payload gambar: ${optimization.estimatedUploadSizeLabel}. '
                'Kategori, halal, kondisi, dan marker peta sudah ikut disiapkan.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.x3),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
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

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _categoryLabel(DonationFoodCategory category) {
    switch (category) {
      case DonationFoodCategory.heavyMeal:
        return 'Makanan Berat';
      case DonationFoodCategory.drink:
        return 'Minuman';
      case DonationFoodCategory.grocery:
        return 'Sembako';
      case DonationFoodCategory.snack:
        return 'Kue/Snack';
      case DonationFoodCategory.compost:
        return 'Kompos';
    }
  }

  String _conditionLabel(DonationFoodCondition condition) {
    switch (condition) {
      case DonationFoodCondition.fresh:
        return 'Tahan Lama';
      case DonationFoodCondition.consumeSoon:
        return 'Segera Dihabiskan';
      case DonationFoodCondition.compost:
        return 'Basi/Kompos';
    }
  }

  Color _conditionColor(DonationFoodCondition condition) {
    switch (condition) {
      case DonationFoodCondition.fresh:
        return AppColors.primary;
      case DonationFoodCondition.consumeSoon:
        return AppColors.accent;
      case DonationFoodCondition.compost:
        return AppColors.danger;
    }
  }

  IconData _categoryIcon(DonationFoodCategory category) {
    switch (category) {
      case DonationFoodCategory.heavyMeal:
        return Icons.restaurant_rounded;
      case DonationFoodCategory.drink:
        return Icons.local_drink_rounded;
      case DonationFoodCategory.grocery:
        return Icons.inventory_2_rounded;
      case DonationFoodCategory.snack:
        return Icons.bakery_dining_rounded;
      case DonationFoodCategory.compost:
        return Icons.compost_rounded;
    }
  }

  IconData _conditionIcon(DonationFoodCondition condition) {
    switch (condition) {
      case DonationFoodCondition.fresh:
        return Icons.check_circle_rounded;
      case DonationFoodCondition.consumeSoon:
        return Icons.schedule_rounded;
      case DonationFoodCondition.compost:
        return Icons.warning_rounded;
    }
  }

  String _conditionDescription(DonationFoodCondition condition) {
    switch (condition) {
      case DonationFoodCondition.fresh:
        return 'Kondisi segar dan relatif aman untuk disimpan lebih lama.';
      case DonationFoodCondition.consumeSoon:
        return 'Sebaiknya segera diambil dan dikonsumsi hari ini.';
      case DonationFoodCondition.compost:
        return 'Tidak disarankan untuk konsumsi manusia.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tambah Donasi'),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.x3),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppInfoPanel.surface(
                          icon: Icons.volunteer_activism_rounded,
                          color: AppColors.primary,
                          title: 'Upload Donasi Makanan',
                          description:
                              'Kategori, halal, kondisi, dan koordinat akan sinkron dengan filter Home dan marker peta.',
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        AppSectionCard(
                          key: _photoKey,
                          title: '1. Foto Makanan',
                          subtitle:
                              'Upload foto makanan.',
                          icon: Icons.add_photo_alternate_outlined,
                          iconColor: AppColors.accent,
                          iconBackgroundColor: AppColors.accentSoft,
                          child: _ImagePickerBox(
                            imageBytes: _imagePreviewBytes,
                            isPicking: _isPickingImage,
                            isOptimizing: _isOptimizingImage,
                            onTap: _pickImage,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        AppSectionCard(
                          key: _nameDescKey,
                          title: '2. Nama & Deskripsi',
                          subtitle:
                              'Tuliskan informasi makanan secara jelas agar mudah ditemukan.',
                          icon: Icons.edit_note_rounded,
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
                                  final String foodName =
                                      value?.trim() ?? '';

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
                                  final String description =
                                      value?.trim() ?? '';

                                  if (description.isEmpty) {
                                    return 'Deskripsi tidak boleh kosong';
                                  }

                                  if (description.length < 10) {
                                    return 'Deskripsi minimal 10 karakter';
                                  }

                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        AppSectionCard(
                          title: '3. Kategori',
                          subtitle:
                              'Ikon marker pada peta mini akan mengikuti kategori yang dipilih.',
                          icon: Icons.category_outlined,
                          child: Wrap(
                            spacing: AppSpacing.x1,
                            runSpacing: AppSpacing.x1,
                            children: DonationFoodCategory.values.map((item) {
                              return _CategoryChip(
                                category: item,
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
                          title: '4. Status Halal',
                          subtitle:
                              'Default makanan adalah Halal. Nonaktifkan jika makanan tidak halal.',
                          icon: Icons.verified_rounded,
                          iconColor: _isHalal
                              ? AppColors.primary
                              : AppColors.danger,
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
                          title: '5. Kondisi Kesiapan',
                          subtitle:
                              'Kondisi makanan menentukan warna marker dan prioritas pickup.',
                          icon: Icons.health_and_safety_outlined,
                          child: Column(
                            children:
                                DonationFoodCondition.values.map((condition) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.x1,
                                ),
                                child: _ConditionOption(
                                  condition: condition,
                                  label: _conditionLabel(condition),
                                  description:
                                      _conditionDescription(condition),
                                  icon: _conditionIcon(condition),
                                  color: _conditionColor(condition),
                                  selected:
                                      _selectedCondition == condition,
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
                          key: _addressKey,
                          title: '6. Lokasi & Map Preview',
                          subtitle:
                              'Pilih koordinat pickup. Pin peta menyesuaikan ikon kategori dan warna kondisi.',
                          icon: Icons.map_outlined,
                          child: Column(
                            children: [
                              _MiniMapPreview(
                                location: _selectedLatLng,
                                markerColor: _markerColor,
                                markerIcon: _markerIcon,
                                categoryLabel: _categoryLabel(
                                  _selectedCategory,
                                ),
                                conditionLabel: _conditionLabel(
                                  _selectedCondition,
                                ),
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
                                  prefixIcon:
                                      Icon(Icons.location_on_outlined),
                                  suffixIcon: Icon(Icons.map_rounded),
                                ),
                                validator: (value) {
                                  final String address =
                                      value?.trim() ?? '';

                                  if (address.isEmpty) {
                                    return 'Lokasi pickup belum dipilih';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.x2),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isGettingLocation ||
                                              _isSubmitting
                                          ? null
                                          : _useCurrentLocation,
                                      icon: _isGettingLocation
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.my_location_rounded,
                                            ),
                                      label: const Text('Lokasi Saat Ini'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.x1),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isSubmitting
                                          ? null
                                          : _openPickLocationPage,
                                      icon: const Icon(Icons.map_outlined),
                                      label: const Text('Buka Peta'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        AppSectionCard(
                          key: _phoneKey,
                          title: '7. Nomor HP Kontak',
                          subtitle:
                              'Nomor HP yang dapat dihubungi oleh penerima manfaat. Default diambil dari profil Anda.',
                          icon: Icons.phone_rounded,
                          iconColor: AppColors.primary,
                          child: TextFormField(
                            controller: _phoneController,
                            enabled: !_isSubmitting,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nomor HP Hubungi',
                              hintText: 'Contoh: 08123456789',
                              prefixIcon: Icon(Icons.phone_android_rounded),
                            ),
                            validator: (value) {
                              final String phone = value?.trim() ?? '';
                              if (phone.isEmpty) {
                                return 'Nomor HP tidak boleh kosong';
                              }
                              if (phone.length < 9) {
                                return 'Nomor HP minimal 9 digit';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        AppSectionCard(
                          title: '8. Detail Jumlah & Waktu',
                          subtitle:
                              'Data ini tetap diperlukan untuk validasi stok dan batas pengambilan.',
                          icon: Icons.inventory_2_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
                              const SizedBox(height: AppSpacing.x2),
                              _DatePickerTile(
                                expiredAtDisplay: _expiredAtDisplay,
                                onTap: _pickExpiredAt,
                              ),
                            ],
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
                                : const Icon(Icons.publish_rounded),
                            label: Text(
                              _isSubmitting
                                  ? 'Memposting...'
                                  : 'Posting Donasi',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                      ],
                    ),
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
  final bool isPicking;
  final bool isOptimizing;
  final VoidCallback onTap;

  const _ImagePickerBox({
    required this.imageBytes,
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.accent,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      'Tambah Foto Makanan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Foto akan dianalisis untuk simulasi kompresi upload.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              if (imageBytes != null)
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
                            'Ganti',
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

class _CategoryChip extends StatelessWidget {
  final DonationFoodCategory category;
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onSelected;

  const _CategoryChip({
    required this.category,
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
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isHalal ? AppColors.primarySoft : AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              isHalal ? Icons.verified_rounded : Icons.warning_amber_rounded,
              color: identityColor,
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHalal ? 'Halal' : 'Non-Halal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: identityColor,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  isHalal
                      ? 'Makanan aman untuk pengguna yang mencari makanan halal.'
                      : 'Makanan akan diberi label Non-Halal pada kartu dan detail.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
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
  final DonationFoodCondition condition;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ConditionOption({
    required this.condition,
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon,
              color: color,
            ),
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
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batas Pengambilan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  expiredAtDisplay,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
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
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
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