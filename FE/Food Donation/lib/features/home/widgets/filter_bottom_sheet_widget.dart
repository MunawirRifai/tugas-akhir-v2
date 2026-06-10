import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum FoodCategoryFilter {
  heavyMeal,
  drink,
  grocery,
  snack,
  compost,
}

enum HalalStatusFilter {
  all,
  halal,
  nonHalal,
}

enum FoodConditionFilter {
  fresh,
  consumeSoon,
  compost,
}

class HomeFoodFilter {
  final double? radiusKm;
  final Set<FoodCategoryFilter> categories;
  final HalalStatusFilter halalStatus;
  final Set<FoodConditionFilter> conditions;

  const HomeFoodFilter({
    required this.radiusKm,
    required this.categories,
    required this.halalStatus,
    required this.conditions,
  });

  const HomeFoodFilter.empty()
      : radiusKm = null,
        categories = const <FoodCategoryFilter>{},
        halalStatus = HalalStatusFilter.all,
        conditions = const <FoodConditionFilter>{};

  bool get hasActiveFilters {
    return radiusKm != null ||
        categories.isNotEmpty ||
        halalStatus != HalalStatusFilter.all ||
        conditions.isNotEmpty;
  }

  int get activeCount {
    return (radiusKm != null ? 1 : 0) +
        categories.length +
        (halalStatus != HalalStatusFilter.all ? 1 : 0) +
        conditions.length;
  }
}

class FilterBottomSheetWidget extends StatefulWidget {
  final HomeFoodFilter initialFilter;

  const FilterBottomSheetWidget({
    super.key,
    required this.initialFilter,
  });

  static Future<HomeFoodFilter?> show(
    BuildContext context, {
    required HomeFoodFilter initialFilter,
  }) {
    return showModalBottomSheet<HomeFoodFilter>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return FilterBottomSheetWidget(
          initialFilter: initialFilter,
        );
      },
    );
  }

  @override
  State<FilterBottomSheetWidget> createState() {
    return _FilterBottomSheetWidgetState();
  }
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  final TextEditingController _radiusController = TextEditingController();

  late Set<FoodCategoryFilter> _categories;
  late HalalStatusFilter _halalStatus;
  late Set<FoodConditionFilter> _conditions;

  String? _radiusError;

  @override
  void initState() {
    super.initState();

    final HomeFoodFilter initialFilter = widget.initialFilter;

    _radiusController.text = initialFilter.radiusKm == null
        ? ''
        : _formatRadius(initialFilter.radiusKm!);

    _categories = Set<FoodCategoryFilter>.of(initialFilter.categories);
    _halalStatus = initialFilter.halalStatus;
    _conditions = Set<FoodConditionFilter>.of(initialFilter.conditions);
  }

  @override
  void dispose() {
    _radiusController.dispose();
    super.dispose();
  }

  String _formatRadius(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  int get _currentActiveCount {
    return (_radiusController.text.trim().isNotEmpty ? 1 : 0) +
        _categories.length +
        (_halalStatus != HalalStatusFilter.all ? 1 : 0) +
        _conditions.length;
  }

  void _toggleCategory(FoodCategoryFilter value) {
    setState(() {
      if (_categories.contains(value)) {
        _categories.remove(value);
      } else {
        _categories.add(value);
      }
    });
  }

  void _toggleCondition(FoodConditionFilter value) {
    setState(() {
      if (_conditions.contains(value)) {
        _conditions.remove(value);
      } else {
        _conditions.add(value);
      }
    });
  }

  void _resetFilter() {
    Navigator.of(context).pop(
      const HomeFoodFilter.empty(),
    );
  }

  void _applyFilter() {
    final String rawRadius = _radiusController.text.trim().replaceAll(',', '.');

    double? radiusKm;

    if (rawRadius.isNotEmpty) {
      radiusKm = double.tryParse(rawRadius);

      if (radiusKm == null || radiusKm <= 0) {
        setState(() {
          _radiusError = 'Masukkan jarak valid, contoh: 2';
        });

        return;
      }

      if (radiusKm > 100) {
        setState(() {
          _radiusError = 'Maksimal radius 100 km';
        });

        return;
      }
    }

    Navigator.of(context).pop(
      HomeFoodFilter(
        radiusKm: radiusKm,
        categories: Set<FoodCategoryFilter>.of(_categories),
        halalStatus: _halalStatus,
        conditions: Set<FoodConditionFilter>.of(_conditions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                  AppSpacing.x2,
                  AppSpacing.x3,
                  AppSpacing.x3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    _FilterHeader(
                      activeCount: _currentActiveCount,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    _FilterSection(
                      title: 'Jarak Radius',
                      subtitle:
                          'Masukkan maksimal jarak makanan dalam kilometer.',
                      child: TextFormField(
                        controller: _radiusController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Radius maksimal',
                          hintText: 'Contoh: 2',
                          suffixText: 'km',
                          prefixIcon: const Icon(Icons.radar_rounded),
                          errorText: _radiusError,
                        ),
                        onChanged: (_) {
                          setState(() {
                            _radiusError = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    _FilterSection(
                      title: 'Kategori Makanan',
                      subtitle: 'Pilih satu atau lebih kategori makanan.',
                      child: Wrap(
                        spacing: AppSpacing.x1,
                        runSpacing: AppSpacing.x1,
                        children: FoodCategoryFilter.values.map((item) {
                          return _FilterChoiceChip(
                            label: _categoryLabel(item),
                            icon: _categoryIcon(item),
                            selected: _categories.contains(item),
                            onSelected: () => _toggleCategory(item),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    _FilterSection(
                      title: 'Status Halal',
                      subtitle: 'Pilih preferensi status makanan.',
                      child: Wrap(
                        spacing: AppSpacing.x1,
                        runSpacing: AppSpacing.x1,
                        children: HalalStatusFilter.values.map((item) {
                          return _FilterChoiceChip(
                            label: _halalLabel(item),
                            icon: _halalIcon(item),
                            selected: _halalStatus == item,
                            onSelected: () {
                              setState(() {
                                _halalStatus = item;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    _FilterSection(
                      title: 'Kondisi Makanan',
                      subtitle:
                          'Indikator kondisi membantu menentukan prioritas pickup.',
                      child: Wrap(
                        spacing: AppSpacing.x1,
                        runSpacing: AppSpacing.x1,
                        children: FoodConditionFilter.values.map((item) {
                          return _ConditionChip(
                            label: _conditionLabel(item),
                            color: _conditionColor(item),
                            selected: _conditions.contains(item),
                            onSelected: () => _toggleCondition(item),
                          );
                        }).toList(),
                      ),
                    ),
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
                        onPressed: _resetFilter,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reset Filter'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x1),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _applyFilter,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Terapkan Filter'),
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

  String _categoryLabel(FoodCategoryFilter value) {
    switch (value) {
      case FoodCategoryFilter.heavyMeal:
        return 'Makanan Berat';
      case FoodCategoryFilter.drink:
        return 'Minuman';
      case FoodCategoryFilter.grocery:
        return 'Sembako';
      case FoodCategoryFilter.snack:
        return 'Kue/Snack';
      case FoodCategoryFilter.compost:
        return 'Kompos';
    }
  }

  IconData _categoryIcon(FoodCategoryFilter value) {
    switch (value) {
      case FoodCategoryFilter.heavyMeal:
        return Icons.restaurant_rounded;
      case FoodCategoryFilter.drink:
        return Icons.local_drink_rounded;
      case FoodCategoryFilter.grocery:
        return Icons.inventory_2_rounded;
      case FoodCategoryFilter.snack:
        return Icons.bakery_dining_rounded;
      case FoodCategoryFilter.compost:
        return Icons.compost_rounded;
    }
  }

  String _halalLabel(HalalStatusFilter value) {
    switch (value) {
      case HalalStatusFilter.all:
        return 'Semua';
      case HalalStatusFilter.halal:
        return 'Halal';
      case HalalStatusFilter.nonHalal:
        return 'Non-Halal';
    }
  }

  IconData _halalIcon(HalalStatusFilter value) {
    switch (value) {
      case HalalStatusFilter.all:
        return Icons.all_inclusive_rounded;
      case HalalStatusFilter.halal:
        return Icons.verified_rounded;
      case HalalStatusFilter.nonHalal:
        return Icons.warning_amber_rounded;
    }
  }

  String _conditionLabel(FoodConditionFilter value) {
    switch (value) {
      case FoodConditionFilter.fresh:
        return 'Tahan Lama/Segar';
      case FoodConditionFilter.consumeSoon:
        return 'Segera Dihabiskan';
      case FoodConditionFilter.compost:
        return 'Pakan Ternak/Kompos';
    }
  }

  Color _conditionColor(FoodConditionFilter value) {
    switch (value) {
      case FoodConditionFilter.fresh:
        return AppColors.primary;
      case FoodConditionFilter.consumeSoon:
        return AppColors.accent;
      case FoodConditionFilter.compost:
        return AppColors.danger;
    }
  }
}

class _FilterHeader extends StatelessWidget {
  final int activeCount;

  const _FilterHeader({
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: AppSpacing.x2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Makanan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 2),
              Text(
                activeCount == 0
                    ? 'Tidak ada filter aktif.'
                    : '$activeCount filter sedang aktif.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _FilterSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.x2),
            child,
          ],
        ),
      ),
    );
  }
}

class _FilterChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
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

class _ConditionChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onSelected;

  const _ConditionChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      selectedColor: color,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? color : AppColors.border,
      ),
      avatar: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: selected ? Colors.white : color,
          shape: BoxShape.circle,
        ),
      ),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? Colors.white : color,
          ),
      onSelected: (_) => onSelected(),
    );
  }
}