import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_manager/ui/recipes/models/ingredient_data.dart';

import '../view_models/recipe_form_viewmodel.dart';
import '../models/recipe_form_model.dart';

class _Ingredient {
  final tagFieldKey = GlobalKey<FormFieldState>();
  final unitFieldKey = GlobalKey<FormFieldState>();
  final amountFieldKey = GlobalKey<FormFieldState>();
  final TextEditingController tagController;
  final TextEditingController unitController;
  final TextEditingController amountController;
  String tag;
  String unit;
  String amount;
  String originalValue;
  bool isEditable = false;

  _Ingredient.fromIngredientData(IngredientData ingredientData)
      : tagController = TextEditingController(text: ingredientData.tag),
        tag = ingredientData.tag ?? "",
        unitController = TextEditingController(text: ingredientData.unit),
        unit = ingredientData.unit ?? "",
        amountController = TextEditingController(text: ingredientData.amount),
        amount = ingredientData.amount ?? "",
        originalValue = "100 g chicken breast"; // TODO

  void dispose() {
    tagController.dispose();
    unitController.dispose();
    amountController.dispose();
  }
}

class RecipeFormScreen extends StatefulWidget {
  const RecipeFormScreen ({
    super.key,
    required this.viewModel,
    this.form,
  });

  final RecipeFormViewmodel viewModel;
  final RecipeFormModel? form;

  @override
  State<RecipeFormScreen > createState() => _RecipeFormState();
}

// TODO: add shelf life field to form (and tag)
class _RecipeFormState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late RecipeFormModel form;
  bool isSubmitting = false;
  bool isParsingIngredients = false;
  final ingredientsFieldController = TextEditingController();
  final ingredients = <_Ingredient>[];

  bool _isValidAmountRaw(double? value, [bool canBeZero = false]) =>
      value != null && value.isFinite && !value.isNegative &&
          (canBeZero || value > 0);

  bool _isValidAmount(String? amount, [bool canBeZero = false]) {
    final value = double.tryParse(amount ?? "");
    return _isValidAmountRaw(value, canBeZero);
  }

  FormFieldValidator<String?> _doubleFieldValidator([bool canBeZero = false]) =>
          (String? value) {
        if (value == null || value.isEmpty) {
          return 'Enter some value';
        } else if (!_isValidAmount(value, canBeZero)) {
          return 'Invalid value';
        }
        return null;
      };

  String? _stringFieldValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter some value';
    }
    return null;
  }

  _loadIngredients(String text) {
    final results = widget.viewModel.parseIngredients(text);
    setState(() {
      ingredients.addAll(results.map((e) => _Ingredient.fromIngredientData(e)));
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.form != null) {
      form = widget.form!.copyWith();
    } else {
      form = RecipeFormModel();
    }
    // TODO: load products?
    //ingredientsFieldController = TextEditingController(text: form.ingredients);
    widget.viewModel.loadTagsAndUnits();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountFormatters = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$')),
    ];
    final viewModel = widget.viewModel;

    return Scaffold(
      appBar: AppBar(title: form.id != null
          ? const Text('Modify product')
          : const Text('Add product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: "ex. Chicken stew, scrambled eggs",
                ),
                textCapitalization: TextCapitalization.sentences,
                enabled: !isSubmitting,
                initialValue: form.name,
                onChanged: (String? value) => form.name = value,
                validator: _stringFieldValidator,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Preparation time',
                  hintText: "ex. 25",
                  suffix: Text("minutes"),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*$')),
                ],
                keyboardType: TextInputType.number,
                textCapitalization: TextCapitalization.sentences,
                enabled: !isSubmitting,
                initialValue: form.name,
                onChanged: (String? value) => form.name = value,
                validator: _stringFieldValidator,
              ),
              SizedBox(height: 8),
              if (ingredients.isNotEmpty)
                Card(
                  color: theme.colorScheme.surfaceContainer,
                  elevation: 0,
                  margin: EdgeInsets.symmetric(vertical: 4.0),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ingredients',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.left,
                        ),
                        for (final ingredient in ingredients)
                          ingredient.isEditable ? Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      key: ingredient.amountFieldKey,
                                      controller: ingredient.amountController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                        labelText: 'Amount',
                                      ),
                                      enabled: !isSubmitting,
                                      validator: (String? value) {
                                        if (value != null && value.isNotEmpty && !_isValidAmount(value)) {
                                          return 'Invalid value';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      key: ingredient.unitFieldKey,
                                      controller: ingredient.unitController,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                        labelText: 'Unit',
                                      ),
                                      enabled: !isSubmitting,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    flex: 5,
                                    child: TextFormField(
                                      key: ingredient.tagFieldKey,
                                      controller: ingredient.tagController,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                        labelText: 'Tag',
                                        hintText: 'ex. chicken breast',
                                      ),
                                      enabled: !isSubmitting,
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent, // keeps background invisible
                                    child: InkWell(
                                      onTap: isSubmitting ? null : () {
                                        setState(() {
                                          ingredient.isEditable = false;
                                        });
                                        ingredient.tagController.text = ingredient.tag;
                                        ingredient.unitController.text = ingredient.unit;
                                        ingredient.amountController.text = ingredient.amount;
                                      },
                                      borderRadius: BorderRadius.circular(999),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(Icons.close, size: 20, color: Colors.redAccent),
                                      ),
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent, // keeps background invisible
                                    child: InkWell(
                                      onTap: isSubmitting ? null : () {
                                        setState(() {
                                          ingredient.isEditable = false;
                                        });
                                        ingredient.tag = ingredient.tagController.value.text;
                                        ingredient.unit = ingredient.unitController.value.text;
                                        ingredient.amount = ingredient.amountController.value.text;
                                      },
                                      borderRadius: BorderRadius.circular(999),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(Icons.check, size: 20, color: Colors.green),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          : Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: theme.textTheme.bodyLarge,
                                            children: [
                                              TextSpan(
                                                text: '${ingredient.amount} ',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              TextSpan(
                                                text: '${ingredient.unit} ',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                              TextSpan(
                                                text: ingredient.tag,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (!viewModel.tagExists(ingredient.tagController.value.text))
                                        const Tooltip(
                                          message: 'Tag not found in database',
                                          child: Icon(Icons.warning, color: Colors.red),
                                        ),
                                      Material(
                                        color: Colors.transparent, // keeps background invisible
                                        child: InkWell(
                                          onTap: isSubmitting ? null : () {
                                            setState(() {
                                              ingredient.isEditable = true;
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(999),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Icon(Icons.edit, size: 20),
                                          ),
                                        ),
                                      ),
                                      Material(
                                        color: Colors.transparent, // keeps background invisible
                                        child: InkWell(
                                          onTap: isSubmitting ? null : () {
                                            setState(() {
                                              ingredients.remove(ingredient);
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(999),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Icon(Icons.delete, size: 20),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    ingredient.originalValue, //'“${ingredient.originalInput.toLowerCase()}”',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 8),
              Stack(
                children: [
                  TextFormField(
                    controller: ingredientsFieldController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelText: ingredients.isEmpty
                          ? 'Ingredients'
                          : 'Add more ingredients',
                      hintText: 'Recommended order is "[amount] [unit] [product tag]"\n'
                          'Example:\n330 g chicken breast\n100 ml yogurt',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainer,
                      contentPadding: EdgeInsets.fromLTRB(16, 16, 48, 16),
                    ),
                    keyboardType: TextInputType.multiline,
                    minLines: 6,
                    maxLines: 6,
                    enabled: !isSubmitting && !isParsingIngredients,
                    validator: (String? value) {
                      if (value != null && value.isNotEmpty) {
                        return "Add the ingredients or clear this field";
                      }
                      return null;
                    },
                  ),
                  Positioned(
                    top: 4,
                    right: 0,
                    child: IconButton(
                      icon: isParsingIngredients
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.add),
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        setState(() { isParsingIngredients = true; });
                        _loadIngredients(
                            ingredientsFieldController.value.text);
                        await Future.delayed(const Duration(seconds: 2));
                        ingredientsFieldController.clear();
                        setState(() { isParsingIngredients = false; });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelText: 'Instructions',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainer,
                ),
                keyboardType: TextInputType.multiline,
                minLines: 6,
                maxLines: 6,
                enabled: !isSubmitting,
                initialValue: form.instructions,
                onChanged: (String? value) => form.instructions = value,
                validator: _stringFieldValidator,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    // validate returns true if the form is valid
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      setState(() => isSubmitting = true);
                      final result = await widget.viewModel.saveRecipe(
                          form.copyWith());
                      if (!context.mounted) return;

                      switch (result) {
                        case InsertSuccess():
                          Navigator.pop(context, result.recipe);
                        case InsertValidationFailure():
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to add recipe. "
                                  "Invalid recipe details.")));
                        case InsertRepoFailure():
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Unexpected error.")));
                      }

                      setState(() => isSubmitting = false);
                    }
                  },
                  child: isSubmitting
                      ? Transform.scale(
                    scale: 0.5,
                    child: CircularProgressIndicator(),
                  )
                      : const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}