import 'package:flutter/material.dart';

import '../view_models/add_recipe_viewmodel.dart';

class AddRecipeScreen extends StatelessWidget {
  AddRecipeScreen({
    super.key,
    required this.viewModel,
  });

  final AddRecipeViewmodel viewModel;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    String? formBarcode, formName;
    return Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: const InputDecoration(hintText: 'Bar code',),
              onSaved: (value) {
                formBarcode = value;
              },
            ),
            TextFormField(
              decoration: const InputDecoration(hintText: 'Name'),
              onSaved: (value) {
                formName = value;
              },
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some name';
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validate returns true if the form is valid, or false otherwise.
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    viewModel.addRecipe(formName!); // TODO: fill in args
                  }
                },
                child: const Text('Submit'),
              ),
            ),
          ],
        )
    );
  }
}