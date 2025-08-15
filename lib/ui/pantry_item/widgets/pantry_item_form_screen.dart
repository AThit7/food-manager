import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../view_models/pantry_item_form_viewmodel.dart';
import '../models/pantry_item_form_model.dart';

class PantryItemFormScreen extends StatefulWidget {
  const PantryItemFormScreen ({
    super.key,
    required this.viewModel,
    this.form,
  });

  final PantryItemFormViewmodel viewModel;
  final PantryItemFormModel? form;

  @override
  State<PantryItemFormScreen > createState() => _PantryItemFormScreenState();
}

class _PantryItemFormScreenState extends State<PantryItemFormScreen > {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateFieldController;
  late PantryItemFormModel form;
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
  void dispose() {
    _dateFieldController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.form != null) {
      form = widget.form!.copyWith();
    } else {
      final quantity = widget.viewModel.product.containerSize ?? widget.viewModel.product.referenceValue;
      final expirationDate = DateTime.now().add(Duration(days: 14));
      form = PantryItemFormModel(
        quantity: quantity.toString(),
        expirationDate: expirationDate,
        isOpen: false,
        isBought: true,
      );
    }
    _dateFieldController = TextEditingController(text: form.textExpirationDate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountFormatters = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$')),
    ];
    final product = widget.viewModel.product;
    final units = List<DropdownMenuItem<String>>.unmodifiable(
        product.units.keys.map((unit) => DropdownMenuItem<String>(value: unit, child: Text(unit)))
    );

    return Scaffold(
      appBar: AppBar(title: form.id != null
          ? const Text('Modify pantry item')
          : const Text('Add pantry item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // TODO Display some product info
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: amountFormatters,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isSubmitting,
                      initialValue: form.quantity,
                      onChanged: (String value) {
                        form.quantity = value.isEmpty ? null : value;
                      },
                      validator: (String? value) {
                        if(!_isValidAmount(form.quantity)) return "Invalid amount";
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>( // TODO make this look better like in recipe form
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                        enabled: !isSubmitting,
                      ),
                      value: product.referenceUnit,
                      items: units,
                      onChanged: isSubmitting ? null : (value) {
                        setState(() {
                          form.unit = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _dateFieldController,
                decoration: const InputDecoration(
                  labelText: 'Expiration date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                readOnly: true,
                enabled: !isSubmitting,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: form.expirationDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(DateTime.now().year + 7),
                  );
                  if (picked != null) {
                    setState(() {
                      form.expirationDate = picked;
                      _dateFieldController.text = form.textExpirationDate;
                    });
                  }
                },
                validator: (String? value) {
                  if (form.expirationDate == null) return "Invalid date";
                  return null;
                },
              ),
              CheckboxListTile(
                title: const Text('Is open'),
                subtitle: Text(
                  form.isOpen == true
                      ? 'Example: opened yogurt, fresh strawberries'
                      : 'Example: sealed yogurt, canned goods',
                ),
                value: form.isOpen,
                onChanged: isSubmitting ? null : (v) {
                  setState(() =>form.isOpen = v ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    // validate returns true if the form is valid
                    setState(() => isSubmitting = true);

                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      final result = await widget.viewModel.savePantryItem(form.copyWith());
                      if (!context.mounted) return;

                      switch (result) {
                        case InsertSuccess():
                          Navigator.pop(context, result.pantryItem);
                        case InsertValidationFailure():
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to add pantry item. Invalid item details."))
                          );
                        case InsertRepoFailure():
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unexpected error.")));
                      }
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