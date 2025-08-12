import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../view_models/product_form_viewmodel.dart';
import '../models/product_form_model.dart';

class _Unit {
  final nameFieldKey = GlobalKey<FormFieldState>();
  final valueFieldKey = GlobalKey<FormFieldState>();
  final  TextEditingController nameController;
  final  TextEditingController valueController;

  _Unit({String? name, double? value})
      : nameController = TextEditingController(text: name),
        valueController = TextEditingController(text: value.toString());

  void dispose() {
    nameController.dispose();
    valueController.dispose();
  }
}

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen ({
    super.key,
    required this.viewModel,
    this.form,
  });

  final ProductFormViewmodel viewModel;
  final ProductFormModel? form;

  @override
  State<ProductFormScreen > createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen > {
  final _formKey = GlobalKey<FormState>();
  late ProductFormModel form;
  final List<_Unit> units = [_Unit()];
  late TextEditingController containerSizeController;
  bool hasContainer = true;
  bool isSubmitting = false;
  //double? referenceValue = 100; remove?

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

  FormFieldValidator<String?> _intFieldValidator([bool canBeZero = false]) =>
          (String? value) {
        if (value == null || value.isEmpty) {
          return 'Enter some value';
        }
        final parsed = int.tryParse(value);
        if (parsed == null) {
          return 'Invalid value';
        } else if (canBeZero && parsed < 0) {
          return 'The value must be non negative';
        } else if (!canBeZero && parsed <= 0) {
          return 'The value must be positive';
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
      form = ProductFormModel();
    }
    hasContainer = form.containerSize != null;
    containerSizeController = TextEditingController(text: form.containerSize);

    for (final entry in form.units?.entries ?? const Iterable<MapEntry<String, double>>.empty()) {
      units.add(_Unit(name: entry.key, value: entry.value));
    }
  }

  @override
  void dispose() {
    for (final unit in units) {
      unit.dispose();
    }
    containerSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountFormatters = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$')),
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
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*$')),
                ],
                decoration: const InputDecoration(labelText: 'Bar code'),
                enabled: !isSubmitting,
                initialValue: form.barcode,
                onChanged: (String value) {
                  form.barcode = value.isEmpty ? null : value;
                },
                validator: (String? value) {
                  if (value != null && value.isNotEmpty && value.contains(RegExp(r'\D'))) {
                    return 'Invalid barcode';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: "ex. Potatoes, [brand] ketchup",
                ),
                textCapitalization: TextCapitalization.sentences,
                enabled: !isSubmitting,
                initialValue: form.name,
                onChanged: (String? value) => form.name = value,
                validator: _stringFieldValidator,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Tag',
                  hintText: "ex. potatoes, ketchup, cheese",
                ),
                enabled: !isSubmitting,
                initialValue: form.tag,
                onChanged: (String? value) => form.tag = value,
                validator: _stringFieldValidator,
              ),
              Row(
                children: [
                  TextFormField(
                    keyboardType: TextInputType.numberWithOptions(),
                    inputFormatters: amountFormatters,
                    decoration: const InputDecoration(
                      labelText: 'Expected shelf life',
                      hintText: "ex. 14",
                      suffix: Text(" days"),
                    ),
                    enabled: !isSubmitting,
                    initialValue: form.expectedShelfLife,
                    onChanged: (String? value) => form.expectedShelfLife = value,
                    validator: _intFieldValidator(),
                  ),
                  SizedBox(width: 6),
                  TextFormField(
                    keyboardType: TextInputType.numberWithOptions(),
                    inputFormatters: amountFormatters,
                    decoration: const InputDecoration(
                      labelText: 'Shelf life after opening',
                      hintText: "ex. 3",
                      suffix: Text(" days"),
                    ),
                    enabled: !isSubmitting,
                    initialValue: form.shelfLifeAfterOpening,
                    onChanged: (String? value) => form.shelfLifeAfterOpening = value,
                    validator: _intFieldValidator(),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Reference value:'),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: amountFormatters,
                      decoration: const InputDecoration(
                        labelText: "Amount",
                        hintText: 'ex. 100',
                      ),
                      enabled: !isSubmitting,
                      textAlign: TextAlign.right,
                      initialValue: form.referenceValue?.toString(),
                      onChanged: (String? value) =>
                          setState(() {
                            form.referenceValue = value;
                          }),
                      validator: _doubleFieldValidator(),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField( // TODO has to be either g or ml
                      decoration: const InputDecoration(
                          labelText: "Unit",
                          hintText: 'ex. g, ml'
                      ),
                      enabled: !isSubmitting,
                      initialValue: form.referenceUnit,
                      onChanged: (String? value) =>
                          setState(() {
                            form.referenceUnit = value ?? "";
                          }),
                      validator: _stringFieldValidator,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: hasContainer,
                      onChanged: isSubmitting ? null : (bool value) {
                        setState(() {
                          hasContainer = value;
                          if (!value) {
                            containerSizeController.clear();
                            form.containerSize = null;
                          }
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(""),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: containerSizeController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: amountFormatters,
                      decoration: InputDecoration(
                        labelText: "Container size",
                        hintText: 'ex. 250',
                        suffixText: form.referenceUnit,
                      ),
                      textAlign: TextAlign.right,
                      enabled: hasContainer && !isSubmitting,
                      onChanged: (String? value) =>
                      form.containerSize = value,
                      validator: (String? value) {
                        if (!hasContainer) return null;
                        return _doubleFieldValidator()(value);
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.info_outline),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) =>
                            AlertDialog(
                              title: const Text(
                                'Container size',
                                textAlign: TextAlign.center,
                              ),
                              content: const Text(
                                "If this field is disabled, you’ll be prompted"
                                    " to enter the quantity every time you scan"
                                    " the barcode. This is helpful for products"
                                    " that come in varying amounts, like"
                                    " pre-packaged meat.",
                              ),
                              actions: [
                                Center(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ),
                              ],
                            ),
                      );
                    },
                  )
                ],
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: ExpansionTile(
                  title: Text(
                    "Alternative units",
                    style: theme.textTheme.titleMedium,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  childrenPadding: const EdgeInsets.all(16.0),
                  backgroundColor: theme.colorScheme.surfaceContainer,
                  children: [
                    ...units.map((final unit) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: unit.nameFieldKey,
                              controller: unit.nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                hintText: 'ex. ml, cup',
                                prefixText: '1',
                              ),
                              enabled: !isSubmitting,
                              onChanged: (String? value) {
                                if (value != null && value.isNotEmpty
                                    && unit.valueController.value.text.isNotEmpty
                                    && units.last == unit
                                ) {
                                  setState(() {
                                    units.add(_Unit());
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('='),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              key: unit.valueFieldKey,
                              controller: unit.valueController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: amountFormatters,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                hintText: 'ex. 120',
                                suffixText: form.referenceUnit,
                              ),
                              enabled: !isSubmitting,
                              textAlign: TextAlign.right,
                              onChanged: (String? value) {
                                if (value != null && value.isNotEmpty
                                    && unit.nameController.value.text.isNotEmpty
                                    && units.last == unit
                                ) {
                                  setState(() {
                                    units.add(_Unit());
                                  });
                                }
                              },
                              validator: (String? value) {
                                if (value != null && value.isNotEmpty && !_isValidAmount(value)) {
                                  return 'Invalid value';
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, size: 20),
                            onPressed: isSubmitting? null : () {
                              setState(() {
                                if(units.last == unit) {
                                  unit.nameController.clear();
                                  unit.valueController.clear();
                                }
                                else {
                                  units.remove(unit);
                                }
                              });
                            },
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(height: 2),
              Card(
                color: theme.colorScheme.surfaceContainer,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nutrition Facts per ${form.referenceValue ?? ""}${form.referenceUnit}',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.left,
                      ),
                      TextFormField(
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: amountFormatters,
                        decoration: const InputDecoration(
                          labelText: 'Calories',
                          hintText: 'ex. 106',
                          suffixText: 'kcal',
                        ),
                        enabled: !isSubmitting,
                        textAlign: TextAlign.right,
                        initialValue: form.calories?.toString(),
                        onChanged: (String? value) => form.calories = value,
                        validator: _doubleFieldValidator(true),
                      ),
                      TextFormField(
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: amountFormatters,
                        decoration: const InputDecoration(
                          labelText: 'Carbohydrates',
                          hintText: 'ex. 36',
                          suffixText: 'g',
                        ),
                        enabled: !isSubmitting,
                        textAlign: TextAlign.right,
                        initialValue: form.carbs?.toString(),
                        onChanged: (String? value) => form.carbs = value,
                        validator: _doubleFieldValidator(true),
                      ),
                      TextFormField(
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: amountFormatters,
                        decoration: const InputDecoration(
                          labelText: 'Protein',
                          hintText: 'ex. 20',
                          suffixText: 'g',
                        ),
                        enabled: !isSubmitting,
                        textAlign: TextAlign.right,
                        initialValue: form.protein?.toString(),
                        onChanged: (String? value) => form.protein = value,
                        validator: _doubleFieldValidator(true),
                      ),
                      TextFormField(
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: amountFormatters,
                        decoration: const InputDecoration(
                          labelText: 'Fat',
                          hintText: 'ex. 20',
                          suffixText: 'g',
                        ),
                        enabled: !isSubmitting,
                        textAlign: TextAlign.right,
                        initialValue: form.fat?.toString(),
                        onChanged: (String? value) => form.fat = value,
                        validator: _doubleFieldValidator(true),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    // validate returns true if the form is valid
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      final unitsMap = <String, double>{form.referenceUnit!: 1.0};
                      for (final unit in units) {
                        final name = unit.nameController.value.text;
                        final value = double.tryParse(unit.valueController.value.text);
                        if (name.isNotEmpty && _isValidAmountRaw(value, true)) {
                          unitsMap[name] = value!;
                        }
                      }
                      form.units = unitsMap;

                      setState(() => isSubmitting = true);
                      final result = await widget.viewModel.saveProduct(form.copyWith());
                      if (!context.mounted) return;

                      switch (result) {
                        case InsertSuccess():
                          Navigator.pop(context, result.product);
                        case InsertValidationFailure():
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to add product. ""Invalid product details.")));
                        case InsertRepoFailure():
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unexpected error.")));
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