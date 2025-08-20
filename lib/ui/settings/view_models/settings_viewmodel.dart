import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:food_manager/data/services/database/database_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsViewmodel extends ChangeNotifier {
  SettingsViewmodel({required DatabaseService databaseService}) : _db = databaseService;

  final DatabaseService _db;
  bool isLoading = false;

  Future<String> exportDatabaseWithPicker() async {
    isLoading = true;
    notifyListeners();

    try {
      final tmpDir = await getTemporaryDirectory();
      final tmpPath = join(tmpDir.path, 'export_${DateTime.now().toIso8601String().replaceAll(':', '-')}.db');
      await _db.exportToFile(tmpPath);

      final bytes = await File(tmpPath).readAsBytes();
      final XFile file = XFile.fromData(bytes, mimeType: 'application/octet-stream');

      final fileName = 'food_manager_${DateTime.now().toIso8601String().replaceAll(':', '-')}.db';
      final params = ShareParams(
        files: [file],
        fileNameOverrides: [fileName],
      );
      final result = await SharePlus.instance.share(params);

      try { await File(tmpPath).delete(); } catch (_) {}

      switch (result.status) {
        case ShareResultStatus.dismissed:
          return 'Cancelled';
        case ShareResultStatus.unavailable:
          return 'Something went wrong';
        case ShareResultStatus.success:
          return 'Database exported successfully';
      }
    } catch (e) {
      return 'Export failed: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> importDatabaseWithPicker() async {
    isLoading = true;
    notifyListeners();

    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'SQLite',
            extensions: ['db', 'sqlite', 'sqlite3'],
            mimeTypes: ['application/octet-stream'],
          ),
        ],
      );
      if (file == null) return 'Cancelled';

      final bytes = await file.readAsBytes();
      final tmpDir = await getTemporaryDirectory();
      final tmpPath = join(tmpDir.path, 'import_${DateTime.now().toIso8601String().replaceAll(':', '-')}.db');
      await File(tmpPath).writeAsBytes(bytes);
      await _db.importFromFile(tmpPath);

      try { await File(tmpPath).delete(); } catch (_) {}

      return 'Database imported successfully';
    } catch (e) {
      return 'Import failed: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}