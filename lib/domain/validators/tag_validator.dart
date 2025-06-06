import 'package:food_manager/domain/models/tag.dart';
import '../../core/exceptions/exceptions.dart';

class TagValidator {
  static void validate(Tag tag) {
    if (tag.name.trim().isEmpty) throw ValidationError("Tag name can't be empty.");
  }

  static bool isValid(Tag tag) {
    try {
      validate(tag);
      return true;
    } catch (_) {
      return false;
    }
  }
}
