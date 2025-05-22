import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../view_models/recipe_form_viewmodel.dart';
import '../models/recipe_form_model.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen ({
    super.key,
    required this.viewModel,
    this.form,
  });

  final RecipeFormViewmodel viewModel;
  final RecipeFormModel? form;

  @override
  State<ProductFormScreen > createState() => _AddProductFormState();
}

// TODO: add shelf life field to form (and tag)
class _AddProductFormState extends State<ProductFormScreen > {
  final _formKey = GlobalKey<FormState>();
  late RecipeFormModel form;
  bool isSubmitting = false;

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
      return 'Please enter some name';
    }
    return null;
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountFormatters = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
    ];

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
