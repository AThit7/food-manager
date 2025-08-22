import 'package:flutter/material.dart';
import 'package:food_manager/domain/models/meal_plan.dart';
import 'package:food_manager/domain/models/pantry_item.dart';
import 'package:food_manager/ui/meal_plan/view_models/planner_viewmodel.dart';
import 'package:food_manager/ui/meal_plan/widgets/planner_preferences_sheet.dart';

class DaySummaryCard extends StatelessWidget {
  const DaySummaryCard({
    super.key,
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.waste,
    required this.mealsCount,
    required this.mealsPerDayRange,
  });

  final DateTime date;
  final double calories, protein, carbs, fat, waste;
  final int mealsCount;
  final ({int lower, int upper}) mealsPerDayRange;

  @override
  Widget build(BuildContext context) {
    final inRange = mealsCount >= mealsPerDayRange.lower && mealsCount <= mealsPerDayRange.upper;

    Widget pill(String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                pill('${calories.toStringAsFixed(0)} kcal'),
                pill('Protein ${protein.toStringAsFixed(0)}g'),
                pill('Carbs ${carbs.toStringAsFixed(0)}g'),
                pill('Fat ${fat.toStringAsFixed(0)}g'),
                pill('Waste ${waste.toStringAsFixed(0)}g/ml'),
                if (!inRange) pill('Meals: $mealsCount / ${mealsPerDayRange.lower}-${mealsPerDayRange.upper}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeCard extends StatefulWidget {
  const RecipeCard({
    super.key,
    required this.slot,
    required this.onTapItem,
    required this.onConsume,
  });

  final MealPlanSlot slot;
  final void Function(PantryItem item) onTapItem;
  final void Function(MealPlanSlot slot) onConsume;

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final isEaten = widget.slot.isEaten;

    Widget macroPill(String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(widget.slot.recipe.name, style: titleStyle),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        macroPill('${widget.slot.calories.toStringAsFixed(0)} kcal'),
                        macroPill('P ${widget.slot.protein.toStringAsFixed(0)}g'),
                        macroPill('C ${widget.slot.carbs.toStringAsFixed(0)}g'),
                        macroPill('F ${widget.slot.fat.toStringAsFixed(0)}g'),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: isEaten ? null : () {
                  setState(() {
                    widget.onConsume(widget.slot);
                  });
                },
                icon: isEaten ? const Icon(Icons.no_meals) : const Icon(Icons.restaurant),
                tooltip: isEaten ? "Meal already consumed" : "Consume this meal",
              ),
            ],
          ),
          if (!widget.slot.isEaten) ...[
            const Divider(height: 1),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text('Ingredients', style: Theme.of(context).textTheme.bodyMedium),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final ingredient in widget.slot.recipe.ingredients) ...[
                    Text(
                      "${ingredient.tag.name} (${ingredient.amount} ${ingredient.unit})",
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    for (final comp in widget.slot.ingredients[ingredient.tag.name] ?? [])
                      _IngredientLine(
                        item: comp.item,
                        quantity: comp.quantity,
                        onTap: () => widget.onTapItem(comp.item),
                      ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IngredientLine extends StatelessWidget {
  const _IngredientLine({
    required this.item,
    required this.quantity,
    required this.onTap,
  });

  final PantryItem item;
  final double quantity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final expiresInDays = item.expirationDate.difference(DateTime.now()).inDays;
    final expiresText = expiresInDays >= 0 ? 'in ${expiresInDays}d' : '${expiresInDays.abs()}d ago';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text('$quantity${item.product.referenceUnit}'),
                const SizedBox(width: 8),
                Icon(Icons.schedule, size: 14),
                const SizedBox(width: 4),
                Text(expiresText, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key, required this.viewModel});

  final PlannerViewmodel viewModel;

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  PageController? _pageController;

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final wd = weekdays[(d.weekday - DateTime.monday) % 7];
    return '$wd, ${d.day} ${months[d.month-1]}';
  }

  int _idxFor(DateTime d, MealPlan p) => (d.difference(p.dayZero).inDays).clamp(0, p.length - 1);
  DateTime _dateFor(int i, MealPlan p) => p.dayZero.add(Duration(days: i));

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadMealPlan(true);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal plan'),
        actions: [
          IconButton(
            onPressed: () {
              if (!viewModel.isLoading) viewModel.loadMealPlan(false);
            },
            icon: Icon(Icons.autorenew),
            tooltip: 'Regenerate plan',
          ),
          IconButton(
            onPressed: () => showPlannerPreferencesSheet(context, viewModel),
            icon: Icon(Icons.settings),
            tooltip: 'Preferences',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final plan = widget.viewModel.mealPlan;
          if (viewModel.isLoading) {
            return const Center(child: Text('Please wait...'));
          } else if (viewModel.errorMessage != null) {
            return Center(child: Text(viewModel.errorMessage!));
          } else if (plan != null) {
            _pageController ??= PageController(initialPage: _idxFor(viewModel.selectedDate, plan));

            return PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => viewModel.selectedDate = _dateFor(i, plan)),
              itemCount: plan.length,
              itemBuilder: (context, i) {
                final date = _dateFor(i, plan);
                final slots = plan.getDate(date);
                final mealsCount = slots?.length ?? 0;
                final calories = plan.getCaloriesDate(date);
                final protein = plan.getProteinDate(date);
                final carbs = plan.getCarbsDate(date);
                final fat = plan.getFatDate(date);
                final waste = plan.getWasteDate(date);

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      Row(
                        children: [
                          Text(_formatDate(date), style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
                            onPressed: i <= 0 ? null : () => _pageController!.jumpToPage(0),
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_double_arrow_right_rounded),
                            onPressed: i >= plan.length - 1 ? null : () => _pageController!.jumpToPage(plan.length - 1),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      if (slots == null) Center(child: Text("This day is out of plan's range"))
                      else if (slots.isEmpty) Center(child: Text("There is no plan for this day"))
                      else ...[
                        DaySummaryCard(
                          date: date,
                          calories: calories,
                          protein: protein,
                          carbs: carbs,
                          fat: fat,
                          waste: waste,
                          mealsCount: mealsCount,
                          mealsPerDayRange: plan.mealsPerDayRange,
                        ),
                        SizedBox(height: 8),
                        for (final slot in slots) ...[
                          RecipeCard(
                            slot: slot,
                            onTapItem: (item) {
                              //Navigator.push();
                            },
                            onConsume: viewModel.consumeSlot,
                          ),
                        ],
                      ],
                    ],
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('Unexpected error'));
          }
        },
      ),
    );
  }
}