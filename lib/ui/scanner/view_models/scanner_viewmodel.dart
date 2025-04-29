import 'package:flutter/material.dart';
import 'package:food_manager/core/result/repo_result.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/local_product_repository.dart';
import '../../products/widgets/add_product_screen.dart';
import '../../products/view_models/add_product_viewmodel.dart';
import '../../products/widgets/product_screen.dart';

// TODO: remove?
class ScannerViewModel extends ChangeNotifier {
  final LocalProductRepository _localProductRepository;

  ScannerViewModel({
    required LocalProductRepository localProductRepository,
  }) : _localProductRepository = localProductRepository;

}