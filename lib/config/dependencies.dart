import 'package:food_manager/data/services/scanner_service.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/services/shared_preferences_service.dart';
import '../data/services/scanner_service.dart';
import '../data/services/database/database_service.dart';
import '../data/services/database/database_service_sqflite.dart';

Future<List<SingleChildWidget>> initProviders() async {
  final sharedPreferencesService = SharedPreferencesService();
  await sharedPreferencesService.init();
  final DatabaseService databaseService = DatabaseServiceSqflite();
  await databaseService.init();

  return [
    Provider.value(value: sharedPreferencesService),
    Provider.value(value: databaseService),
    Provider(
      create: (context) {
        final String? scannerType = context.read<
            SharedPreferencesService>().getString('scannerType');
        return ScannerFactory.getScanner(scannerType);
      },
    ),
  ];
}