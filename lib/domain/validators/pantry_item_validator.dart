import 'package:food_manager/domain/models/product/pantry_item.dart';
import '../../core/exceptions/exceptions.dart';

class PantryItemValidator{
  static bool _isValidDouble(double value, [bool canBeZero = false]) {
    return value.isFinite && !value.isNaN && !value.isNegative &&
        (canBeZero || value > 0);
  }

  static void validate(PantryItem item) {
    if (_isValidDouble(item.quantity)) {
      throw ValidationError("Invalid quantity.");
    }
    if (item.product.id != null) {
      throw ValidationError("Linked product's ID can't be null.");
    }
  }

  static bool isValid(PantryItem item) {
    try {
      validate(item);
      return true;
    } catch (_) {
      return false;
    }
  }
}