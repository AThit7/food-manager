import 'package:flutter/material.dart';
import 'package:food_manager/ui/settings/view_models/settings_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.viewModel,
  });

  final SettingsViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.isLoading) return const Center(child: CircularProgressIndicator());
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('Export database'),
                onTap: () async {
                  final msg = await viewModel.exportDatabaseWithPicker();
                  if(context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Import database'),
                onTap: () async {
                  final msg = await viewModel.importDatabaseWithPicker();
                  if(context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  }
                },
              ),
            ],
          );
        }
      ),
    );
  }
}
