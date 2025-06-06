import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_manager/ui/recipes/models/ingredient_data.dart';

import '../view_models/recipe_form_viewmodel.dart';
import '../models/recipe_form_model.dart';

bool _isValidAmountRaw(double? value, [bool canBeZero = false]) =>
    value != null && value.isFinite && !value.isNegative && (canBeZero || value > 0);

bool _isValidAmount(String? amount, [bool canBeZero = false]) {
  final value = double.tryParse(amount ?? "");
  return _isValidAmountRaw(value, canBeZero);
}

String? _stringFieldValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter some value';
  }
  return null;
}

class _Ingredient {
  final containerKey = GlobalKey();
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
  final String? Function(String, String) _checker;
  String? warningMessage;
  String? errorMessage;

  _Ingredient.fromIngredientData(IngredientData ingredientData, String? Function(String, String) tagUnitChecker)
      : tagController = TextEditingController(text: ingredientData.tag),
        tag = ingredientData.tag ?? "",
        unitController = TextEditingController(text: ingredientData.unit),
        unit = ingredientData.unit ?? "",
        amountController = TextEditingController(text: ingredientData.amount),
        amount = ingredientData.amount ?? "",
        originalValue = ingredientData.originalValue ?? "",
        _checker = tagUnitChecker {
    checkForWarnings();
    checkForErrors();
  }

  void checkForWarnings() {
    warningMessage = _checker(tag, unit);
  }

  void checkForErrors() {
    String? s;
    s ??= _stringFieldValidator(amount);
    s ??= _stringFieldValidator(unit);
    s ??= _stringFieldValidator(tag);

    if (s != null) {
      errorMessage = 'Fill in all the fields.';
    }
    else if (!_isValidAmount(amount)) {
      errorMessage = 'Invalid amount.';
    }
  }

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
  final _nameFieldKey = GlobalKey<FormFieldState>();
  final _prepTimeFieldKey = GlobalKey<FormFieldState>();
  late RecipeFormModel form;
  bool isSubmitting = false;
  bool isParsingIngredients = false;
  final ingredientsFieldController = TextEditingController();
  final ingredients = <_Ingredient>[];

  _loadIngredients(String text) {
    final results = widget.viewModel.parseIngredients(text);
    setState(() {
      ingredients.addAll(results.map((e) => _Ingredient.fromIngredientData(e, widget.viewModel.getTagUnitStatus)));
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.form != null) {
      form = widget.form!.copyWith();
      if (form.ingredients != null) {
        ingredients.addAll(
          form.ingredients!.map((e) => _Ingredient.fromIngredientData(e, widget.viewModel.getTagUnitStatus)),
        );
      }
    } else {
      form = RecipeFormModel();
    }
    // TODO: load products?
    //ingredientsFieldController = TextEditingController(text: form.ingredients);
    widget.viewModel.loadTagsAndUnits();
  }

  Widget _buildEditableIngredientCard(_Ingredient ingredient) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ingredient.amountFieldKey,
                        controller: ingredient.amountController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: 'Amount',
                        ),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$'))],
                        enabled: !isSubmitting,
                        validator: (String? value) {
                          if (value != null && value.isNotEmpty && !_isValidAmount(value)) {
                            return 'Invalid value';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final tag = ingredient.tagController.text;
                          final unit = ingredient.unitController.text;

                          if (textEditingValue.text.isEmpty) return widget.viewModel.getUnits(unit); // TODO: remove?
                          return widget.viewModel.unitSearch(unit, tag);
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          final fieldBox = ingredient.unitFieldKey.currentContext?.findRenderObject() as RenderBox?;
                          final fieldWidth = fieldBox?.size.width ?? 200;

                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: fieldWidth), // adjust width here
                                child: ListView(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  children: options.map((String option) {
                                    return ListTile(
                                      title: Text(option),
                                      onTap: () => onSelected(option),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          controller.text = ingredient.unitController.text;
                          return TextFormField(
                            key: ingredient.unitFieldKey,
                            focusNode: focusNode,
                            controller: controller,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              floatingLabelBehavior:
                              FloatingLabelBehavior.always,
                              labelText: 'Unit',
                            ),
                            enabled: !isSubmitting,
                            onChanged: (String value) => ingredient.unitController.text = value,
                            onFieldSubmitted: (_) => onFieldSubmitted(),
                          );
                        },
                        onSelected: (String selection) {
                          ingredient.unitController.text = selection;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final tag = ingredient.tagController.text;

                    if (textEditingValue.text.isEmpty) return widget.viewModel.tags;
                    return widget.viewModel.tagSearch(tag);
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    final fieldBox = ingredient.tagFieldKey.currentContext?.findRenderObject() as RenderBox?;
                    final fieldWidth = fieldBox?.size.width ?? 200;

                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: fieldWidth, maxHeight: 5*48), // adjust width here
                          child: ListView(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            children: options.map((String option) {
                              return ListTile(
                                title: Text(option),
                                onTap: () => onSelected(option),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    controller.text = ingredient.tagController.text;
                    return TextFormField(
                      key: ingredient.tagFieldKey,
                      focusNode: focusNode,
                      controller: controller,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        floatingLabelBehavior:
                        FloatingLabelBehavior.always,
                        labelText: 'Tag',
                        hintText: 'ex. chicken breast',
                      ),
                      enabled: !isSubmitting,
                      onChanged: (String value) => ingredient.tagController.text = value,
                      onFieldSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
                  onSelected: (String selection) {
                    ingredient.tagController.text = selection;
                  },
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
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
          // TODO: put buttons in a column?
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isSubmitting ? null : () {
                setState(() {
                  ingredient.isEditable = false;
                });
                ingredient.tag = ingredient.tagController.value.text;
                ingredient.unit = ingredient.unitController.value.text;
                ingredient.amount = ingredient.amountController.value.text;
                ingredient.checkForWarnings();
                ingredient.checkForErrors();
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
    );
  }


  Widget _buildReadOnlyIngredientCard(_Ingredient ingredient, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyLarge,
                    children: [
                      TextSpan(
                        text: ingredient.amount.isEmpty ? null : '${ingredient.amount} ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextSpan(
                        text: ingredient.unit.isEmpty ? null : '${ingredient.unit} ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey,
                        ),
                      ),
                      TextSpan(
                        text: ingredient.tag.isEmpty ? null : ingredient.tag,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (ingredient.errorMessage != null)
                Tooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  message: ingredient.errorMessage,
                  child: Icon(Icons.warning, color: Colors.red),
                ),
              if (ingredient.errorMessage == null && ingredient.warningMessage != null)
                Tooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  message: ingredient.warningMessage,
                  child: Icon(Icons.warning, color: Colors.orange),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            cacheExtent: double.infinity,
            children: [
              TextFormField(
                key: _nameFieldKey,
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
                key: _prepTimeFieldKey,
                decoration: const InputDecoration(
                  labelText: 'Preparation time',
                  hintText: "ex. 25",
                  suffix: Text("minutes"),
                ),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*$'))],
                keyboardType: TextInputType.number,
                textCapitalization: TextCapitalization.sentences,
                enabled: !isSubmitting,
                initialValue: form.preparationTime,
                onChanged: (String? value) => form.preparationTime = value,
                validator: (String? value) => _isValidAmount(value, true) ? null : "Enter a valid time",
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
                          Card(
                            key: ingredient.containerKey,
                            child: ingredient.isEditable
                                ? _buildEditableIngredientCard(ingredient)
                                : _buildReadOnlyIngredientCard(ingredient, theme),
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
                      labelText: ingredients.isEmpty ? 'Ingredients' : 'Add more ingredients',
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
                        _loadIngredients(ingredientsFieldController.value.text);
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
                    final isValid = _formKey.currentState!.validate();

                    if (!isValid) {
                      final fieldKeys = [_nameFieldKey, _prepTimeFieldKey];

                      for (final key in fieldKeys) {
                        if (key.currentState?.hasError ?? false) {
                          final context = key.currentContext;
                          if (context != null && context.mounted) {
                            await Scrollable.ensureVisible(
                              context,
                              duration: Duration(milliseconds: 300),
                            );
                          }
                          break;
                        }
                      }
                      return;
                    }

                    final firstInvalidIngredient = ingredients.where((e) => e.errorMessage != null).firstOrNull;
                    if (firstInvalidIngredient != null) {
                      final context = firstInvalidIngredient.containerKey.currentContext;
                      if (context != null && context.mounted) {
                        await Scrollable.ensureVisible(context, duration: Duration(milliseconds: 300));
                      }
                      return;
                    }

                    if (ingredients.where((e) => e.warningMessage != null).isNotEmpty) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            actionsAlignment: MainAxisAlignment.spaceAround,
                            content: const Text(
                              "At least one ingredient has a tag-unit pair which does not match any "
                                  "product. The recipe won't be used until you make sure that all tag-unit pairs match "
                                  "at least one product in the database. Do you want to add the recipe regardless?",
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('No'),
                                onPressed: () => Navigator.of(context).pop(false),
                              ),
                              TextButton(
                                child: const Text('Yes'),
                                onPressed: () => Navigator.of(context).pop(true),
                              ),
                            ],
                          );
                        },
                      ) ?? false;

                      if (!confirmed) return;
                    }

                    setState(() => isSubmitting = true);
                    form.ingredients = ingredients.map((e) => IngredientData(
                      tag: e.tag,
                      unit: e.unit,
                      amount: e.amount,
                    )).toList(growable: false);
                    final result = await viewModel.saveRecipe(form.copyWith());
                    if (!context.mounted) return;

                    switch (result) {
                      case InsertSuccess():
                        Navigator.pop(context, result.recipe);
                      case InsertValidationFailure():
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to add recipe. Invalid recipe details.')));
                      case InsertRepoFailure():
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unexpected error.')));
                    }

                    setState(() => isSubmitting = false);
                  },
                  child: isSubmitting
                      ? Transform.scale(scale: 0.5, child: CircularProgressIndicator())
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