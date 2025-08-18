import 'package:flutter/material.dart';
import 'package:food_manager/ui/planner/view_models/planner_viewmodel.dart';

Future<void> showPlannerPreferencesSheet(
    BuildContext context,
    PlannerViewmodel viewModel,
    ) async {
  await showModalBottomSheet(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => PlannerPreferencesSheet(viewModel: viewModel),
  );
}

class PlannerPreferencesSheet extends StatefulWidget {
  const PlannerPreferencesSheet({super.key, required this.viewModel});
  final PlannerViewmodel viewModel;

  @override
  State<PlannerPreferencesSheet> createState() => _PlannerPreferencesSheetState();
}

class _PlannerPreferencesSheetState extends State<PlannerPreferencesSheet> {
  static const int mealsMin = 1;
  static const int mealsMax = 6;

  static const int kcalMin = 800;
  static const int kcalMax = 5000;

  static const int proteinMin = 0;
  static const int proteinMax = 400;

  static const int carbsMin = 0;
  static const int carbsMax = 800;

  static const int fatMin = 0;
  static const int fatMax = 300;

  late int _mealsLo;
  late int _mealsHi;

  late int _kcalLo;
  late int _kcalHi;

  late int _protLo;
  late int _protHi;

  late int _carbLo;
  late int _carbHi;

  late int _fatLo;
  late int _fatHi;

  @override
  void initState() {
    super.initState();
    final vm = widget.viewModel;

    final meals = vm.mealCountRange;
    _mealsLo = meals.lower.clamp(mealsMin, mealsMax);
    _mealsHi = meals.upper.clamp(mealsMin, mealsMax);

    final cal = vm.calorieRange;
    _kcalLo = cal.lower.clamp(kcalMin, kcalMax);
    _kcalHi = cal.upper.clamp(kcalMin, kcalMax);

    final pr = vm.proteinRange;
    _protLo = pr.lower.clamp(proteinMin, proteinMax);
    _protHi = pr.upper.clamp(proteinMin, proteinMax);

    final cb = vm.carbsRange;
    _carbLo = cb.lower.clamp(carbsMin, carbsMax);
    _carbHi = cb.upper.clamp(carbsMin, carbsMax);

    final ft = vm.fatRange;
    _fatLo = ft.lower.clamp(fatMin, fatMax);
    _fatHi = ft.upper.clamp(fatMin, fatMax);

    if (_mealsLo > _mealsHi) _mealsLo = _mealsHi;
    if (_kcalLo > _kcalHi) _kcalLo = _kcalHi;
    if (_protLo > _protHi) _protLo = _protHi;
    if (_carbLo > _carbHi) _carbLo = _carbHi;
    if (_fatLo > _fatHi) _fatLo = _fatHi;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ListView(
          shrinkWrap: true,
          children: [
            // meals
            _sectionHeader(Icons.restaurant, 'Meals per day'),
            _rangeTile(
              label: 'Meals',
              unit: '',
              min: mealsMin,
              max: mealsMax,
              values: (_mealsLo, _mealsHi),
              divisions: mealsMax - mealsMin,
              onChanged: (lo, hi) => setState(() {
                _mealsLo = lo;
                _mealsHi = hi;
              }),
            ),
            const SizedBox(height: 12),

            // calories
            _sectionHeader(Icons.local_fire_department, 'Calories'),
            _rangeTile(
              label: 'Calories',
              unit: 'kcal',
              min: kcalMin,
              max: kcalMax,
              values: (_kcalLo, _kcalHi),
              divisions: (kcalMax - kcalMin) ~/ 10, // ~10 kcal steps
              onChanged: (lo, hi) => setState(() {
                _kcalLo = lo;
                _kcalHi = hi;
              }),
            ),
            const SizedBox(height: 12),

            // protein
            _sectionHeader(Icons.egg_alt, 'Protein'),
            _rangeTile(
              label: 'Protein',
              unit: 'g',
              min: proteinMin,
              max: proteinMax,
              values: (_protLo, _protHi),
              divisions: proteinMax - proteinMin,
              onChanged: (lo, hi) => setState(() {
                _protLo = lo;
                _protHi = hi;
              }),
            ),
            const SizedBox(height: 12),

            // carbs
            _sectionHeader(Icons.rice_bowl, 'Carbs'),
            _rangeTile(
              label: 'Carbs',
              unit: 'g',
              min: carbsMin,
              max: carbsMax,
              values: (_carbLo, _carbHi),
              divisions: (carbsMax - carbsMin) ~/ 5, // 5g steps
              onChanged: (lo, hi) => setState(() {
                _carbLo = lo;
                _carbHi = hi;
              }),
            ),
            const SizedBox(height: 12),

            // fat
            _sectionHeader(Icons.water_drop, 'Fat'),
            _rangeTile(
              label: 'Fat',
              unit: 'g',
              min: fatMin,
              max: fatMax,
              values: (_fatLo, _fatHi),
              divisions: fatMax - fatMin,
              onChanged: (lo, hi) => setState(() {
                _fatLo = lo;
                _fatHi = hi;
              }),
            ),
            const SizedBox(height: 16),

            // actions
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _apply,
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apply() async {
    if (_mealsLo > _mealsHi ||
        _kcalLo > _kcalHi ||
        _protLo > _protHi ||
        _carbLo > _carbHi ||
        _fatLo  > _fatHi) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid range')));
      return;
    }

    final vm = widget.viewModel;
    await vm.savePreferences(
      mealCountRang: (lower: _mealsLo, upper: _mealsHi),
      calorieRange:  (lower: _kcalLo,  upper: _kcalHi),
      proteinRange:  (lower: _protLo,  upper: _protHi),
      carbsRange:    (lower: _carbLo,  upper: _carbHi),
      fatRange:      (lower: _fatLo,   upper: _fatHi),
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Preferences saved')));
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _rangeTile({
    required String label,
    required String unit,
    required int min,
    required int max,
    required (int, int) values,
    required int divisions,
    required void Function(int lower, int upper) onChanged,
  }) {
    final lo = values.$1.clamp(min, max);
    final hi = values.$2.clamp(min, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label),
            const Spacer(),
            Text('$lo$unit  –  $hi$unit'),
          ],
        ),
        RangeSlider(
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions > 0 ? divisions : null,
          values: RangeValues(lo.toDouble(), hi.toDouble()),
          labels: RangeLabels('$lo', '$hi'),
          onChanged: (v) => onChanged(v.start.round(), v.end.round()),
        ),
      ],
    );
  }
}