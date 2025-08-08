import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:food_manager/ui/planner/view_models/planner_viewmodel.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key, required this.viewModel});

  final PlannerViewmodel viewModel;

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final months = List.unmodifiable(['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December']);
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal plan'),
        actions: [
          IconButton(
            onPressed: null, // TODO preferences
            icon: Icon(Icons.settings),
          )
        ],
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          if (!viewModel.isLoaded) {
            return Center(child: CircularProgressIndicator());
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  Row(
                    children: [
                      Text('${months[selectedDate.month]} ${selectedDate.day}'),
                      Expanded(child: SizedBox()), // TODO ?
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_left_rounded),
                        onPressed: () {
                          setState(() {
                            selectedDate = selectedDate.subtract(Duration(days: 1));
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_right_rounded),
                        onPressed: () {
                          setState(() {
                            selectedDate = selectedDate.add(Duration(days: 1));
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Card(child: Text("TODO")),
                  SizedBox(height: 8),
                  Card(child: Text("TODO")),
                  SizedBox(height: 8),
                  Card(child: Text("TODO")),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}