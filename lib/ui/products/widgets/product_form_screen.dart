import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

import '../view_models/product_form_viewmodel.dart';
import '../../../domain/models/product/local_product.dart';

class _Unit {
  String? name;
  double? value; // in base units
  final nameFieldKey = GlobalKey<FormFieldState>();
  final valueFieldKey = GlobalKey<FormFieldState>();
  final nameController = TextEditingController();
  final valueController = TextEditingController();

  _Unit({this.name, this.value});

  void dispose() {
    nameController.dispose();
    valueController.dispose();
  }
}

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen ({
    super.key,
    required this.viewModel,
    this.barcode,
    this.product,
    this.localProduct,
  });

  final Product? product;
  final String? barcode;
  final ProductFormViewmodel viewModel;
  final LocalProduct? localProduct;

  @override
  State<ProductFormScreen > createState() => _AddProductFormState();
}

class _AddProductFormState extends State<ProductFormScreen > {
  final _formKey = GlobalKey<FormState>();
  LocalProduct product = LocalProduct(
    name: "",
    units: {},
    referenceUnit: 'g',
    referenceValue: 100,
  );
  double? referenceValue = 100;
  final List<_Unit> units = [_Unit()];
  bool hasContainer = true;

  bool _isValidAmount(double? value) =>
      value != null && value.isFinite && value > 0;

  bool _isValidAmountOrZero(double? value) =>
      value != null && value.isFinite && value >= 0;

  FormFieldValidator<String?> _doubleFieldValidator(
      {required double? doubleValue, bool canBeZero = true}) =>
          (String? value) {
        if (value == null || value.isEmpty) {
          return 'Enter some value';
        } else if (canBeZero && !_isValidAmountOrZero(doubleValue)) {
          return 'Invalid value';
        } else if (!canBeZero && !_isValidAmount(doubleValue)) {
          return 'Invalid value';
        }
        return null;
      };

  String? _stringFieldValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter some name';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final remoteProduct = widget.product;
    final LocalProduct? localProduct = widget.localProduct;

    if (localProduct != null) {
      product = localProduct;
      product.barcode = widget.barcode;
      units.clear();
      for (final MapEntry<String, double> unit in product.units.entries) {
        units.add(_Unit(name: unit.key, value: unit.value));
      }
      units.add(_Unit());
      hasContainer = product.containerSize != null;
    } else if (remoteProduct != null) {
      product.name = remoteProduct.productName ?? "";
      product.barcode = widget.barcode;
      final match = RegExp(r'[a-zA-Z]+').firstMatch(
          remoteProduct.servingSize ?? "");
      product.referenceUnit = match?.group(0) ?? "g";
      product.referenceValue = remoteProduct.packagingQuantity ?? 100;
      product.calories = remoteProduct.nutriments?.getValue(
          Nutrient.energyKCal, PerSize.oneHundredGrams);
      product.carbs = remoteProduct.nutriments?.getValue(
          Nutrient.carbohydrates, PerSize.oneHundredGrams);
      product.protein = remoteProduct.nutriments?.getValue(
          Nutrient.proteins, PerSize.oneHundredGrams);
      product.fat = remoteProduct.nutriments?.getValue(
          Nutrient.fat, PerSize.oneHundredGrams);
    }
  }

  @override
  void dispose() {
    for (final unit in units) {
      unit.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountFormatters = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Bar code'),
                initialValue: product.barcode,
                onChanged: (String? value) {
                  product.barcode = value;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: "ex. Potatoes, [brand] ketchup",
                ),
                initialValue: product.name,
                onChanged: (String? value) => product.name = value ?? "",
                validator: _stringFieldValidator,
              ),
              Row(
                children: [
                  Text('Reference value:'),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: amountFormatters,
                      decoration: const InputDecoration(
                        labelText: "Amount",
                        hintText: 'ex. 100',
                      ),
                      textAlign: TextAlign.right,
                      initialValue: referenceValue.toString(),
                      onChanged: (String? value) =>
                          setState(() {
                            referenceValue = double.tryParse(value ?? '');
                          }),
                      validator: _doubleFieldValidator(
                        doubleValue: product.referenceValue,
                        canBeZero: false,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: "Unit",
                          hintText: 'ex. g, ml'
                      ),
                      initialValue: product.referenceUnit,
                      onChanged: (String? value) =>
                          setState(() {
                            product.referenceUnit = value ?? "";
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
                      onChanged: (bool value) {
                        setState(() {
                          hasContainer = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(""),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: amountFormatters,
                      decoration: InputDecoration(
                        labelText: "Container size",
                        hintText: 'ex. 250',
                        suffixText: product.referenceUnit,
                      ),
                      textAlign: TextAlign.right,
                      enabled: hasContainer,
                      initialValue: product.containerSize?.toString(),
                      onChanged: (String? value) =>
                      product.containerSize = double.tryParse(value ?? ""),
                      validator: (String? value) {
                        if (!hasContainer) return null;
                        return _doubleFieldValidator(
                          doubleValue: product.containerSize,
                          canBeZero: false,
                        )(value);
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  childrenPadding: const EdgeInsets.all(16.0),
                  backgroundColor: theme.colorScheme.surfaceContainer,
                  children: [
                    ...units.asMap().entries.map((entry) {
                      final index = entry.key;
                      final _Unit unit = entry.value;

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
                              onChanged: (String? value) {
                                if (value == null || value.isEmpty) {
                                  unit.name = null;
                                }
                                else {
                                  unit.name = value;
                                  if (unit.value != null &&
                                      index == units.length - 1) {
                                    setState(() {
                                      units.add(_Unit());
                                    });
                                  }
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
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: amountFormatters,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                hintText: 'ex. 120',
                                suffixText: product.referenceUnit,
                              ),
                              textAlign: TextAlign.right,
                              onChanged: (String? value) {
                                if (value == null || value.isEmpty) {
                                  unit.value = null;
                                }
                                else {
                                  unit.value = double.parse(value);
                                  if (unit.name != null &&
                                      index == units.length - 1) {
                                    setState(() {
                                      units.add(_Unit());
                                    });
                                  }
                                }
                              },
                              validator: (String? value) {
                                if (value != null && value.isNotEmpty
                                    && !_isValidAmount(unit.value)) {
                                  return 'Invalid value';
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, size: 20),
                            onPressed: () {
                              setState(() {
                                if(units.length - 1 == index) {
                                  // TODO: should it stay?
                                  unit.nameController.clear();
                                  unit.valueController.clear();
                                }
                                else {
                                  units.removeAt(index);
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
                        'Nutrition Facts per '
                            '${referenceValue ?? ""}${product.referenceUnit}',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.left,
                      ),
                      TextFormField(
                        keyboardType: TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: amountFormatters,
                        decoration: const InputDecoration(
                          labelText: 'Calories',
                          hintText: 'ex. 106',
                          suffixText: 'kcal',
                        ),
                        textAlign: TextAlign.right,
                        initialValue: product.calories?.toString(),
                        onChanged: (String? value) =>
                        product.calories = double.tryParse(value ?? ""),
                        validator: _doubleFieldValidator(
                            doubleValue: product.calories),
                      ),
                      TextFormField(
                        keyboardType: TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: amountFormatters,
                        decoration: const InputDecoration(
                          labelText: 'Carbohydrates',
                          hintText: 'ex. 36',
                          suffixText: 'g',
                        ),
                        textAlign: TextAlign.right,
                        initialValue: product.carbs?.toString(),
                        onChanged: (String? value) =>
                        product.carbs = double.tryParse(value ?? ""),
                        validator: _doubleFieldValidator(
                            doubleValue: product.carbs),
                      ),
                      TextFormField(
                        keyboardType: TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: amountFormatters,
                        decoration: const InputDecoration(
                          labelText: 'Protein',
                          hintText: 'ex. 20',
                          suffixText: 'g',
                        ),
                        textAlign: TextAlign.right,
                        initialValue: product.protein?.toString(),
                        onChanged: (String? value) =>
                        product.protein = double.tryParse(value ?? ""),
                        validator: _doubleFieldValidator(
                            doubleValue: product.protein),
                      ),
                      TextFormField(
                        keyboardType: TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: amountFormatters,
                        decoration: const InputDecoration(
                          labelText: 'Fat',
                          hintText: 'ex. 20',
                          suffixText: 'g',
                        ),
                        textAlign: TextAlign.right,
                        initialValue: product.fat?.toString(),
                        onChanged: (String? value) =>
                        product.fat = double.tryParse(value ?? ""),
                        validator: _doubleFieldValidator(
                            doubleValue: product.fat),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    // validate returns true if the form is valid
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      final unitsMap = <String, double>{};
                      for (final unit in units) {
                        if (unit.name != null && unit.value != null) {
                          unitsMap[unit.name!] = unit.value!;
                        }
                      }
                      product.units = unitsMap;
                      product.referenceValue = referenceValue!;

                      widget.viewModel.addProduct(product);
                    }
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          )
      ),
    );
  }
}
