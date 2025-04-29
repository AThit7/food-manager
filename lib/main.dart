import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as opf;

import 'ui/home/home_screen.dart';
import 'config/dependencies.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final providers = await initProviders();
  opf.OpenFoodAPIConfiguration.userAgent = opf.UserAgent(
    name: 'food_manager',
  );

  runApp(
    MultiProvider(
      providers: providers,
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Manager',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}