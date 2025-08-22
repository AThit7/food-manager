import 'package:food_manager/domain/models/local_product.dart';
import 'package:food_manager/domain/validators/tag_validator.dart';
import '../../core/exceptions/exceptions.dart';

class ProductValidator{
  static bool _isValidDouble(double value, [bool canBeZero = false]) {
      return value.isFinite && !value.isNaN && !value.isNegative && (canBeZero || value > 0);
  }

  static void validate(LocalProduct product) {
    if (product.name.trim().isEmpty) {
      throw ValidationError("Invalid name.");
    }
    if (product.referenceUnit.trim().isEmpty) {
      throw ValidationError("Invalid reference unit.");
    }
    if (product.referenceUnit != "g" && product.referenceUnit != "ml") {
      throw ValidationError("Reference unit must be either g or ml.");
    }
    if (product.barcode != null && (product.barcode!.isEmpty || product.barcode!.contains(RegExp(r'\D')))) {
      throw ValidationError("Invalid barcode.");
    }
    if (product.containerSize != null && !_isValidDouble(product.containerSize!)) {
      throw ValidationError("Invalid container size.");
    }
    if (!_isValidDouble(product.referenceValue)) {
      throw ValidationError("Invalid reference value.");
    }
    if (!_isValidDouble(product.calories, true)) {
      throw ValidationError("Invalid calories.");
    }
    if (!_isValidDouble(product.carbs, true)) {
      throw ValidationError("Invalid carbs.");
    }
    if (!_isValidDouble(product.protein, true)) {
      throw ValidationError("Invalid protein.");
    }
    if (!_isValidDouble(product.fat, true)) {
      throw ValidationError("Invalid fat.");
    }
    if (product.expectedShelfLife < 0) {
      throw ValidationError("Invalid expected shelf life.");
    }
    if (product.shelfLifeAfterOpening < 0) {
      throw ValidationError("Invalid shelf life after opening.");
    }
    TagValidator.validate(product.tag);

    product.units.forEach((key, value) {
      if (key.trim().isEmpty) throw ValidationError("Invalid unit name.");
      if (!_isValidDouble(value)) {
        throw ValidationError("Invalid unit value.");
      }
    });
  }

  static bool isValid(LocalProduct product) {
    try {
      validate(product);
      return true;
    } catch (_) {
      return false;
    }
  }
}